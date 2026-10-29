#include <llvm/ExecutionEngine/Orc/LLJIT.h>
#include <llvm/ExecutionEngine/Orc/ExecutionUtils.h>
#include <llvm/IRReader/IRReader.h>
#include <llvm/Support/SourceMgr.h>
#include <llvm/Support/TargetSelect.h>
#include <dlfcn.h>
#include <cstdio>
#include <cstdint>
int main(int argc, char **argv) {
  if (argc != 4) return 2;
  auto *lib = dlopen(argv[1], RTLD_NOW | RTLD_GLOBAL);
  if (!lib) { fprintf(stderr,"%s\n",dlerror()); return 2; }
  llvm::InitializeNativeTarget(); llvm::InitializeNativeTargetAsmPrinter();
  llvm::ExitOnError check;
  auto jit = check(llvm::orc::LLJITBuilder().create());
  jit->getMainJITDylib().addGenerator(check(llvm::orc::DynamicLibrarySearchGenerator::GetForCurrentProcess(jit->getDataLayout().getGlobalPrefix())));
  auto init = (void*(*)(int,char**))dlsym(lib,"_sh_init");
  auto execute = (bool(*)(void*,void*,uint64_t*))dlsym(lib,"_sh_unit_init_guarded");
  auto done = (void(*)(void*))dlsym(lib,"_sh_done");
  auto consoleInit = (void*(*)(void*,int,const char*const*))dlsym(lib,"init_console_bindings");
  auto release = (void(*)(void*))dlsym(lib,"release_console_bindings");
  auto freeConsole = (void(*)(void*))dlsym(lib,"free_console_context");
  if (!init||!execute||!done||!consoleInit||!release||!freeConsole) return 3;
  char name[]="probe"; char *args[]={name,nullptr};
  auto rt=init(1,args); auto console=consoleInit(rt,0,nullptr);
  for (int i=2;i<4;++i) {
    auto ctx=std::make_unique<llvm::LLVMContext>(); llvm::SMDiagnostic diag;
    auto m=llvm::parseIRFile(argv[i],diag,*ctx);
    if (!m) {diag.print("probe",llvm::errs()); return 4;}
    m->setDataLayout(jit->getDataLayout());
    check(jit->addIRModule(llvm::orc::ThreadSafeModule(std::move(m),std::move(ctx))));
    auto creator=check(jit->lookup(i==2?"sh_export_a":"sh_export_b"));
    uint64_t value;
    if(!execute(rt,creator.toPtr<void*>(),&value))return 5;
  }
  release(console); done(rt); freeConsole(console);
  jit.reset(); dlclose(lib); puts("linkage-lifetime-ok");
}
