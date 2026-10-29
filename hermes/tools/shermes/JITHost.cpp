#include "hermes/LLVMJIT/Host.h"
#include "hermes/VM/static_h.h"
#include "hermes/hermes.h"
#include "jsi/instrumentation.h"
#include <vector>
#include <memory>
#include <cmath>
struct SHConsoleContext;
extern "C" SHConsoleContext *init_console_bindings(SHRuntime *, int, const char *const *);
extern "C" void release_console_bindings(SHConsoleContext *);
extern "C" void free_console_context(SHConsoleContext *);
extern "C" bool run_event_loop(SHRuntime *, SHConsoleContext *, bool);
struct Host {
  SHRuntime *runtime = nullptr;
  SHConsoleContext *console = nullptr;
  std::vector<int> entries; // 0 pending, 1 fulfilled, 2 rejected.
  ~Host() {
    if (console) release_console_bindings(console);
    if (runtime) _sh_done(runtime);
    if (console) free_console_context(console);
  }
};
extern "C" SHERMES_EXPORT void *shllvm_host_create() {
  using namespace facebook;
  auto host = std::make_unique<Host>();
  host->runtime = _sh_init(::hermes::vm::RuntimeConfig::Builder()
      .withMicrotaskQueue(true).build());
  try {
    host->console = init_console_bindings(host->runtime, 0, nullptr);
    auto &rt = *_sh_get_hermes_runtime(host->runtime);
    auto *state = host.get();
    // Private trusted-bundle protocol, not a security boundary. It never uses
    // stdout as a completion signal and does not apply to ordinary scripts.
    rt.global().setProperty(rt, "__shllvmModuleBegin",
      jsi::Function::createFromHostFunction(rt,
        jsi::PropNameID::forAscii(rt, "__shllvmModuleBegin"), 0,
        [state](jsi::Runtime &, const jsi::Value &, const jsi::Value *, size_t) {
          state->entries.push_back(0);
          return jsi::Value(double(state->entries.size() - 1));
        }));
    rt.global().setProperty(rt, "__shllvmModuleEnd",
      jsi::Function::createFromHostFunction(rt,
        jsi::PropNameID::forAscii(rt, "__shllvmModuleEnd"), 2,
        [state](jsi::Runtime &rt, const jsi::Value &, const jsi::Value *args, size_t n) {
          if (n != 2 || !args[0].isNumber() || !args[1].isBool())
            throw jsi::JSError(rt, "Invalid module completion notification");
          double id = args[0].getNumber();
          if (!std::isfinite(id) || id < 0 || std::floor(id) != id ||
              id >= state->entries.size() || state->entries[size_t(id)] != 0)
            throw jsi::JSError(rt, "Invalid module completion token");
          state->entries[size_t(id)] = args[1].getBool() ? 1 : 2;
          return jsi::Value::undefined();
        }));
    return host.release();
  } catch (const std::exception &e) {
    fprintf(stderr, "JIT host initialization: %s\n", e.what());
    return nullptr;
  }
}
extern "C" SHERMES_EXPORT int shllvm_host_execute(void *raw, void *creator) {
  // _sh_initialize_units catches the source exception and prints it through a
  // runtime handle, so no unrooted tagged value escapes into the C++ engine.
  return _sh_initialize_units(static_cast<Host *>(raw)->runtime, 1,
                             reinterpret_cast<SHUnitCreator>(creator)) ? 0 : 1;
}
extern "C" SHERMES_EXPORT int shllvm_host_drain(void *raw) {
  auto &host = *static_cast<Host *>(raw);
  if (!run_event_loop(host.runtime, host.console, false)) return 1;
  for (auto state : host.entries) if (state == 2) return 1;
  for (auto state : host.entries) if (state == 0) return 2;
  return 0;
}
extern "C" SHERMES_EXPORT void shllvm_host_collect(void *raw) {
  _sh_get_hermes_runtime(static_cast<Host *>(raw)->runtime)
      ->instrumentation().collectGarbage("native-jit-test");
}
extern "C" SHERMES_EXPORT void shllvm_host_destroy(void *raw) {
  delete static_cast<Host *>(raw);
}
