#include "hermes/LLVMJIT/Engine.h"
#include "hermes/LLVMJIT/Host.h"
#include "llvm/ExecutionEngine/Orc/LLJIT.h"
#include "llvm/ExecutionEngine/Orc/ExecutionUtils.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/TargetSelect.h"
#include <dlfcn.h>
#include <mutex>
#include <thread>
#include <vector>
#include <cstdlib>
extern "C" uint64_t shllvm_frame_size(uint32_t);
namespace hermes { namespace nativejit {
static Result fail(const char *phase, std::string message) {
  return {false, phase, std::move(message)};
}
struct Engine::Impl {
  std::unique_ptr<llvm::orc::LLJIT> jit;
  void *host = nullptr;
  std::thread::id owner = std::this_thread::get_id();
  size_t nextName = 0;
  struct Unit { void *creator; bool executed; llvm::orc::ResourceTrackerSP tracker; };
  std::vector<Unit> units;
  Result available() const {
    if (owner != std::this_thread::get_id()) return fail("state", "engine called from non-owner thread");
    if (!host) return fail("state", "engine is closed");
    return {true, "ready", {}};
  }
};
Engine::Engine(std::unique_ptr<Impl> impl) : impl_(std::move(impl)) {}
std::unique_ptr<Engine> Engine::create(std::string &error) {
  error.clear();
  static std::once_flag targets;
  std::call_once(targets, [] {
    llvm::InitializeNativeTarget(); llvm::InitializeNativeTargetAsmPrinter();
  });
  auto impl = std::make_unique<Impl>();
  auto jit = llvm::orc::LLJITBuilder().create();
  if (!jit) { error = llvm::toString(jit.takeError()); return nullptr; }
  impl->jit = std::move(*jit);
  auto triple = impl->jit->getTargetTriple();
  if (triple.getArch() != llvm::Triple::x86_64 || !triple.isOSLinux() ||
      impl->jit->getDataLayout().getPointerSize() != 8) {
    error = "initial native engine requires Linux x86-64 host64"; return nullptr;
  }
  // Find the linked bridge, rather than opening a second configured VM copy.
  // Its dependency closure supplies Hermes helpers and the C runtime symbols.
  Dl_info library{};
  if (!dladdr(reinterpret_cast<void *>(&shllvm_frame_size), &library)) {
    error = "cannot locate linked LLVM runtime bridge"; return nullptr;
  }
  auto symbols = llvm::orc::DynamicLibrarySearchGenerator::Load(
      library.dli_fname, impl->jit->getDataLayout().getGlobalPrefix());
  if (!symbols) { error = llvm::toString(symbols.takeError()); return nullptr; }
  impl->jit->getMainJITDylib().addGenerator(std::move(*symbols));
  impl->host = shllvm_host_create();
  if (!impl->host) { error = "runtime initialization failed"; return nullptr; }
  return std::unique_ptr<Engine>(new Engine(std::move(impl)));
}
Engine::~Engine() {
  // Destruction from another thread is a programming error, not permission to
  // race a live runtime. Explicit close() returns an actionable state error.
  if (impl_->host && impl_->owner != std::this_thread::get_id()) std::abort();
  close();
}
Result Engine::close() {
  if (impl_->owner != std::this_thread::get_id()) return fail("state", "close requires owner thread");
  if (!impl_->host) return {true, "closed", {}};
  shllvm_host_destroy(impl_->host);
  impl_->host = nullptr;
  impl_->units.clear();
  impl_->jit.reset();
  return {true, "closed", {}};
}
Result Engine::compile(const std::string &source, const std::string &filename, SourceOptions options) {
  auto state = impl_->available(); if (!state.ok) return state;
  std::string name = "engine_unit_" + std::to_string(impl_->nextName++), ir;
  auto result = compileSource(source, filename, name, options, ir);
  if (!result.ok) return result;
  return loadIR(ir, "sh_export_" + name);
}
Result Engine::loadIR(const std::string &ir, const std::string &creator) {
  auto state = impl_->available(); if (!state.ok) return state;
  auto context = std::make_unique<llvm::LLVMContext>();
  llvm::SMDiagnostic diagnostic;
  auto module = llvm::parseIR(llvm::MemoryBufferRef(ir, "jit-input"), diagnostic, *context);
  if (!module) {
    std::string message; llvm::raw_string_ostream stream(message);
    diagnostic.print("native-jit", stream); return fail("llvm-parse", stream.str());
  }
  auto &jit = *impl_->jit;
  if (!module->getTargetTriple().empty() &&
      llvm::Triple::normalize(module->getTargetTriple()) != llvm::Triple::normalize(jit.getTargetTriple().str()))
    return fail("target", "IR target differs from the engine target");
  if (!module->getDataLayoutStr().empty() && module->getDataLayout() != jit.getDataLayout())
    return fail("target", "IR data layout differs from the engine layout");
  module->setTargetTriple(jit.getTargetTriple().str());
  module->setDataLayout(jit.getDataLayout());
  auto *function = module->getFunction(creator);
  if (module->getFunction("main") || !function || function->isDeclaration() ||
      !function->getReturnType()->isPointerTy() || function->arg_size() || function->isVarArg() ||
      function->getCallingConv() != llvm::CallingConv::C || function->hasLocalLinkage())
    return fail("entry", "expected an exported ptr() unit creator and no main");
  std::string verification; llvm::raw_string_ostream verifier(verification);
  if (llvm::verifyModule(*module, &verifier)) return fail("llvm-verify", verifier.str());
  auto tracker = jit.getMainJITDylib().createResourceTracker();
  if (auto error = jit.addIRModule(tracker, llvm::orc::ThreadSafeModule(std::move(module), std::move(context))))
    return fail("llvm-add", llvm::toString(std::move(error)));
  auto symbol = jit.lookup(creator);
  if (!symbol) {
    std::string message = llvm::toString(symbol.takeError());
    if (auto removal = tracker->remove()) message += "; cleanup: " + llvm::toString(std::move(removal));
    return fail("llvm-link", std::move(message));
  }
  auto id = impl_->units.size();
  impl_->units.push_back({symbol->toPtr<void *>(), false, tracker});
  return {true, "loaded", {}, id};
}
Result Engine::execute(size_t id) {
  auto state = impl_->available(); if (!state.ok) return state;
  if (id >= impl_->units.size() || impl_->units[id].executed)
    return fail("state", "invalid unit or unit already executed");
  auto &unit = impl_->units[id]; unit.executed = true;
  if (shllvm_host_execute(impl_->host, unit.creator))
    return fail("execute", "JavaScript initializer threw; runtime diagnostic printed to stderr");
  return {true, "executed", {}, id};
}
Result Engine::drain() {
  auto state = impl_->available(); if (!state.ok) return state;
  switch (shllvm_host_drain(impl_->host)) {
    case 0: return {true, "completed", {}};
    case 2: return fail("pending", "module entry remains pending after draining host jobs");
    default: return fail("jobs", "JavaScript job or module entry failed");
  }
}
Result Engine::collect() {
  auto state = impl_->available(); if (!state.ok) return state;
  shllvm_host_collect(impl_->host); return {true, "collected", {}};
}
size_t Engine::unitCount() const { return impl_->units.size(); }
}}
