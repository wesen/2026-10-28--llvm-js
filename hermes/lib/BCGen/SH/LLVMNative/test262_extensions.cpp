/* Test262 diagnostics for the direct LLVM host. SPDX-License-Identifier: MIT. */
#include "hermes/VM/JSObject.h"
#include "hermes/VM/StaticHUtils.h"
#include "hermes/VM/StringPrimitive.h"
#include "hermes/VM/StringView.h"
#include <cstdio>
#include <string>

using namespace hermes;
using namespace hermes::vm;

// Inspect the actual thrown value, never its user-controlled printed stack.
// The caller invokes this immediately after guarded unit initialization, before
// any allocation. All potentially allocating property reads use rooted handles.
extern "C" SHERMES_EXPORT void shllvm_test262_exception(
    SHRuntime *shr, const SHLegacyValue *value) {
  Runtime &runtime = getRuntime(shr);
  GCScope gcScope{runtime};
  auto thrown = runtime.makeHandle(HermesValue::fromRaw(value->raw));
  auto object = Handle<JSObject>::dyn_vmcast(thrown);
  std::string name;
  if (object) {
    auto constructor = JSObject::getNamed_RJS(
        object, runtime, Predefined::getSymbolID(Predefined::constructor));
    if (constructor != ExecutionStatus::EXCEPTION && (*constructor)->isObject()) {
      auto ctor = runtime.makeHandle<JSObject>(constructor->getHermesValue());
      auto result = JSObject::getNamed_RJS(
          ctor, runtime, Predefined::getSymbolID(Predefined::name));
      if (result != ExecutionStatus::EXCEPTION && (*result)->isString()) {
        auto string = runtime.makeHandle<StringPrimitive>(result->getHermesValue());
        auto view = StringPrimitive::createStringView(runtime, string);
        if (view.length() <= 128) {
          for (size_t i = 0; i < view.length(); ++i) {
            auto c = view[i];
            if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'))) {
              name.clear();
              break;
            }
            name.push_back(static_cast<char>(c));
          }
        }
      }
    }
  }
  // A throwing accessor or non-object throw cannot impersonate an error type.
  runtime.clearThrownValue();
  std::fprintf(stderr, "SHLLVM_TEST262_EXCEPTION:%s\n",
               name.empty() ? "INVALID" : name.c_str());
}
