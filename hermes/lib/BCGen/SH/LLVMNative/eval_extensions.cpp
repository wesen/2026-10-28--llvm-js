/*
 * Direct LLVM lexical evaluation support. SPDX-License-Identifier: MIT.
 *
 * This file is built inside the full Hermes VM, because the source compiler
 * and the VM implementation symbols intentionally are not a public ABI.
 */
#include "eval_extensions.h"

#include "hermes/BCGen/HBC/BCProviderFromSrc.h"
#include "hermes/BCGen/HBC/HBC.h"
#include "hermes/IR/IR.h"
#include "hermes/IR/Instrs.h"
#include "hermes/Sema/SemContext.h"
#include "hermes/Support/Buffer.h"
#include "hermes/VM/Callable.h"
#include "hermes/VM/JSLib.h"
#include "hermes/VM/StaticHUtils.h"
#include "hermes/VM/StringPrimitive.h"
#include "hermes/VM/StringView.h"
#include "llvh/Support/ConvertUTF.h"

#include <algorithm>
#include <cstddef>
#include <string>
#include <utility>
#include <vector>

using namespace hermes;
using namespace hermes::vm;

static_assert(sizeof(void *) == 8, "The direct LLVM bridge requires host64");
static_assert(sizeof(SHLLVMEvalBinding) == 16, "LLVM binding ABI mismatch");
static_assert(sizeof(SHLLVMEvalScope) == 16, "LLVM scope ABI mismatch");
static_assert(offsetof(SHLLVMEvalBinding, name) == 0, "LLVM binding ABI");
static_assert(offsetof(SHLLVMEvalBinding, slot) == 8, "LLVM binding ABI");
static_assert(offsetof(SHLLVMEvalBinding, flags) == 12, "LLVM binding ABI");
static_assert(offsetof(SHLLVMEvalScope, bindings) == 0, "LLVM scope ABI");
static_assert(offsetof(SHLLVMEvalScope, binding_count) == 8, "LLVM scope ABI");
static_assert(offsetof(SHLLVMEvalScope, slot_count) == 12, "LLVM scope ABI");

namespace {

using CompileResult =
    std::pair<std::unique_ptr<hbc::BCProvider>, std::string>;

/// Reconstruct enough compiler metadata to resolve the string against an
/// existing chain of native environments. The synthetic parent is never run.
///
/// Each anonymous function owns exactly one physical environment. Ordinary
/// source blocks would be incorrect here: IRGen can merge several lexical
/// blocks into a single VariableScope. The caller has already filtered bindings
/// to the nearest visible declaration for each name at the eval site.
CompileResult compileInNativeEnvironment(
    std::string code,
    const SHLLVMEvalScope *scopes,
    uint32_t scopeCount,
    const hbc::CompileFlags &evalFlags,
    bool globalCaller) {
  if (!scopeCount)
    return {nullptr, "LLVM direct eval is missing its lexical environment"};

  if (globalCaller) {
    // A synthetic function must not accidentally make new.target legal in a
    // script's direct eval. Validate the unexecuted source in a real global
    // syntactic context first; nested real functions retain their own rules.
    auto validationFlags = evalFlags;
    validationFlags.debug = false;
    auto validation = hbc::createBCProviderFromSrc(
        std::make_unique<StdStringBuffer>(std::string(code)),
        "<llvm-eval-global-validation>",
        {},
        validationFlags,
        "eval");
    if (!validation.first)
      return validation;
  }

  std::string parentSource;
  for (uint32_t depth = 0; depth != scopeCount; ++depth) {
    parentSource += "(function(){\n";
    for (uint32_t i = 0; i != scopes[depth].binding_count; ++i) {
      const auto &binding = scopes[depth].bindings[i];
      // Source spelling provides the semantic binding. Its initialization is
      // irrelevant because no synthetic-parent instruction will execute.
      // Use var for semantic resolution and restore Variable rules below.
      // Unlike let, var can spell inherited non-strict names such as "let".
      // That makes an attempted assignment to an existing native const throw
      // a catchable TypeError, rather than being rejected as a parse error.
      parentSource += "var ";
      parentSource += binding.name;
      parentSource += "=void 0;\n";
    }
  }
  for (uint32_t depth = 0; depth != scopeCount; ++depth)
    parentSource += "});\n";

  hbc::CompileFlags parentFlags = evalFlags;
  // The synthetic declaration of "arguments" is legal in this non-strict
  // scaffold. The selected parent SemInfo is marked strict below, before the
  // real eval text is resolved. This does not change any executed source.
  parentFlags.strict = false;
  parentFlags.debug = true;
  parentFlags.lazy = false;
  auto parentResult = hbc::createBCProviderFromSrc(
      std::make_unique<StdStringBuffer>(std::move(parentSource)),
      "<llvm-eval-scope>",
      {},
      parentFlags);
  if (!parentResult.first)
    return parentResult;

  auto *provider =
      llvh::cast<hbc::BCProviderFromSrc>(parentResult.first.get());
  auto *module = provider->getBytecodeModule();
  struct ParentFunction {
    uint32_t functionID;
    Function *function;
    sema::LexicalScope *lexicalScope;
  };
  std::vector<ParentFunction> parents;
  for (uint32_t i = 0; i != module->getNumFunctions(); ++i) {
    Function *function = module->getFunction(i).getFunctionIR();
    if (!function || function->isGlobalScope())
      continue;
    auto *evalData = function->getEvalCompilationDataInst();
    if (!evalData)
      return {nullptr, "LLVM direct eval could not retain scope metadata"};
    if (globalCaller) {
      // Nested eval resolves new.target through the retained semantic parent
      // chain. These non-executed scaffold functions describe script scopes;
      // like eval program nodes, they must not introduce a function context.
      // Mark every level so nearestNonArrow reaches the real global function.
      evalData->getData().semInfo->isProgramNode = true;
    }
    auto *lexicalScope = evalData->getData().semInfo->getFunctionBodyScope();
    parents.push_back({i, function, lexicalScope});
  }
  if (parents.size() != scopeCount)
    return {nullptr, "LLVM direct eval reconstructed an invalid scope chain"};
  std::sort(
      parents.begin(),
      parents.end(),
      [](const ParentFunction &left, const ParentFunction &right) {
        return left.lexicalScope->depth < right.lexicalScope->depth;
      });

  // Keep the semantic names connected to the actual native Variable slots.
  // BCProviderFromSrc retains the Module/SemContext through all escaped eval
  // closures. This is metadata ownership, not a raw pointer to the stack.
  std::vector<sema::Decl *> visibleDecls;
  bool hasArguments = false;
  for (uint32_t depth = 0; depth != scopeCount; ++depth) {
    const SHLLVMEvalScope &nativeScope = scopes[depth];
    auto *lexicalScope = parents[depth].lexicalScope;
    for (uint32_t i = 0; i != nativeScope.binding_count; ++i) {
      const SHLLVMEvalBinding &binding = nativeScope.bindings[i];
      if (binding.slot >= nativeScope.slot_count)
        return {nullptr, "LLVM direct eval received an invalid slot index"};
      sema::Decl *decl = nullptr;
      for (auto *candidate : lexicalScope->decls) {
        if (candidate->name.str() == binding.name &&
            candidate->special != sema::Decl::Special::Arguments) {
          decl = candidate;
          break;
        }
      }
      if (!decl)
        return {nullptr, "LLVM direct eval could not reconstruct a binding"};
      auto *variable = llvh::dyn_cast_or_null<Variable>(getDeclCustomData(decl));
      if (!variable)
        return {nullptr, "LLVM direct eval binding has no environment slot"};
      variable->setNativeEvalEnvironmentIndex(binding.slot);
      variable->setObeysTDZ(binding.flags & SHLLVM_EVAL_BINDING_TDZ);
      variable->setType(
          binding.flags & SHLLVM_EVAL_BINDING_TDZ
          ? provider->getModule()->getTypeContext().unionTy(
                Type::createAnyType(), Type::createEmpty())
          : Type::createAnyType());
      variable->setConstness(
          binding.flags & SHLLVM_EVAL_BINDING_CONST
          ? sema::Decl::Constness::Always
          : binding.flags & SHLLVM_EVAL_BINDING_SILENT_CONST
          ? sema::Decl::Constness::StrictModeOnly
          : sema::Decl::Constness::Never);
      visibleDecls.push_back(decl);
      hasArguments |= decl->name.str() == "arguments";
    }
  }

  ParentFunction &parent = parents.back();
  auto *semContext = provider->getSemCtx();
  auto &bindingTable = semContext->getBindingTable();
  // Anonymous scaffolding functions have their own implicit "arguments".
  // Publish exactly the original lexical view in the innermost semantic scope,
  // keeping each Variable in its original physical environment.
  bindingTable.activateScope(parent.lexicalScope->bindingTableScope);
  for (auto *decl : visibleDecls)
    bindingTable.put(decl->name.getUnderlyingPointer(), {decl, nullptr});
  if (!hasArguments) {
    // A top-level arrow has no implicit arguments binding. Resolve the name as
    // a global property instead of exposing a synthetic parent's arguments.
    auto *name = provider->getModule()
                     ->getContext()
                     .getIdentifier("arguments")
                     .getUnderlyingPointer();
    auto *decl = semContext->newGlobal(
        name, sema::Decl::Kind::UndeclaredGlobalProperty);
    bindingTable.put(name, {decl, nullptr});
  }
  bindingTable.activateScope({});
  parent.function->getEvalCompilationDataInst()->getData().semInfo->strict =
      true;

  auto result = hbc::compileEvalModule(
      std::make_unique<StdStringBuffer>(std::move(code)),
      provider,
      parent.functionID,
      evalFlags,
      parent.lexicalScope->idxInParentFunction);
  if (result.first) {
    // A BytecodeFunction normally destroys its retained FunctionIR. The
    // synthetic provider is about to go away, while the result still shares
    // its Module and may need Module::getTopLevelFunction for a future eval.
    // Transfer ONLY these non-executed parent Function nodes to the Module's
    // owning compiled-functions list. Module::~Module will destroy them; the
    // returned provider still owns its real eval functions in the usual way.
    for (uint32_t i = 0; i != module->getNumFunctions(); ++i)
      module->getFunction(i).setFunctionIR(nullptr);
  }
  return result;
}

CallResult<HermesValue> evaluate(
    Runtime &runtime,
    SHLegacyValue *source,
    SHLegacyValue *environment,
    SHLegacyValue *thisValue,
    SHLegacyValue *newTarget,
    const SHLLVMEvalScope *scopes,
    uint32_t scopeCount,
    uint32_t callerFlags) {
  // The public entry point receives pointers into the generated SHLocals root
  // frame. Handles below borrow those existing roots; no movable raw pointer
  // is kept across a call that can allocate.
  if (!toPHV(source)->isString())
    return *toPHV(source);
  std::string code;
  {
    auto view = StringPrimitive::createStringView(
        runtime, Handle<StringPrimitive>::vmcast(toPHV(source)));
    if (view.isASCII()) {
      code.assign(view.begin(), view.end());
    } else {
      SmallU16String<4> allocator;
      convertUTF16ToUTF8WithReplacements(code, view.getUTF16Ref(allocator));
    }
  }
  if (!runtime.enableEval)
    return runtime.raiseEvalUnsupported(code);
  if (!(callerFlags & 1)) {
    auto strictSource = evalSourceIsStrict(runtime, code);
    if (strictSource == ExecutionStatus::EXCEPTION)
      return ExecutionStatus::EXCEPTION;
    if (!*strictSource)
      return runtime.raiseSyntaxError(
          "LLVM backend: sloppy direct string eval is unsupported; "
          "use strict evaluated source, a strict caller, or indirect global eval");
  }

  hbc::CompileFlags flags;
  flags.strict = true;
  flags.debug = true;
  flags.lazy = false;
  flags.includeLibHermes = false;
  flags.enableES6BlockScoping = true;
  flags.enableTDZ = true;
  flags.enableAsyncGenerators = runtime.hasAsyncGenerators();
  flags.verifyIR = runtime.verifyEvalIR;
  flags.emitAsyncBreakCheck = runtime.asyncBreakCheckInEval;
  // Defer invalid assignment to a const to IRGen's runtime TypeError path.
  flags.test262 = true;

  CompileResult compiled;
  executeInStack(runtime.getStackExecutor(), [&]() {
    compiled = compileInNativeEnvironment(
        std::move(code), scopes, scopeCount, flags, callerFlags & 2);
  });
  if (!compiled.first)
    return runtime.raiseSyntaxError(TwineChar16(compiled.second));

  return runtime.runBytecode(
      std::move(compiled.first),
      RuntimeModuleFlags{},
      "<llvm-direct-eval>",
      Handle<Environment>::vmcast(toPHV(environment)),
      Handle<>(toPHV(thisValue)),
      Handle<>(toPHV(newTarget)));
}
} // namespace

extern "C" SHERMES_EXPORT void shllvm_eval_direct(
    void *out,
    void *runtime,
    void *source,
    void *environment,
    void *thisValue,
    void *newTarget,
    const SHLLVMEvalScope *scopes,
    uint32_t scopeCount,
    uint32_t callerFlags) {
  SHRuntime *shr = static_cast<SHRuntime *>(runtime);
  auto result = evaluate(
      getRuntime(shr),
      static_cast<SHLegacyValue *>(source),
      static_cast<SHLegacyValue *>(environment),
      static_cast<SHLegacyValue *>(thisValue),
      static_cast<SHLegacyValue *>(newTarget),
      scopes,
      scopeCount,
      callerFlags);
  // evaluate has returned and all strings/compiler owners/RAII guards have
  // been destroyed before SH's longjmp-based exception propagation.
  if (LLVM_UNLIKELY(result == ExecutionStatus::EXCEPTION))
    _sh_throw_current(shr);
  *static_cast<SHLegacyValue *>(out) = *result;
}
