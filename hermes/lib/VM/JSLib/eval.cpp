/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include "JSLibInternal.h"

#include "hermes/BCGen/HBC/HBC.h"
#include "hermes/Parser/JSParser.h"
#include "hermes/Support/MemoryBuffer.h"
#include "hermes/Support/ScopeChain.h"
#include "hermes/Support/SimpleDiagHandler.h"
#include "hermes/VM/JSLib.h"
#include "hermes/VM/Runtime.h"
#include "hermes/VM/StringPrimitive.h"
#include "hermes/VM/StringView.h"
#include "llvh/Support/ConvertUTF.h"
#include "llvh/Support/raw_ostream.h"

namespace hermes {
namespace vm {

CallResult<bool> evalSourceIsStrict(Runtime &runtime, llvh::StringRef utf8code) {
  bool parsed = false;
  bool strict = false;
  std::string error;
  executeInStack(runtime.getStackExecutor(), [&]() {
    Context context;
    context.setEnableES6BlockScoping(true);
    context.setEnableAsyncGenerators(runtime.hasAsyncGenerators());
    SimpleDiagHandlerRAII diagnostics(context.getSourceErrorManager());
    parser::JSParser parser(context, utf8code);
    auto program = parser.parse();
    if (!program || diagnostics.haveErrors()) {
      error = diagnostics.getErrorString();
      return;
    }
    parsed = true;
    // Use the parser's raw directive spelling: escaped and parenthesized
    // strings must not become strict directives. Do not resolve a global AST
    // here, because eval may legitimately inherit constructor new.target.
    for (auto &node : (*program)->_body) {
      auto *statement = llvh::dyn_cast<ESTree::ExpressionStatementNode>(&node);
      if (!statement || !statement->_directive)
        break;
      if (statement->_directive->str() == "use strict") {
        strict = true;
        break;
      }
    }
  });
  if (!parsed)
    return runtime.raiseSyntaxError(TwineChar16(error));
  return strict;
}

CallResult<HermesValue> evalInEnvironment(
    Runtime &runtime,
    llvh::StringRef utf8code,
    bool strictCaller,
    Handle<Environment> environment,
    const CodeBlock *codeBlock,
    Handle<> thisArg,
    Handle<> newTarget,
    bool singleFunction,
    OptValue<uint32_t> lexicalScopeIdxInParentFunction) {
  if (!runtime.enableEval) {
    return runtime.raiseEvalUnsupported(utf8code);
  }

  hbc::CompileFlags compileFlags;
  compileFlags.strict = strictCaller;
  compileFlags.includeLibHermes = false;
  compileFlags.verifyIR = runtime.verifyEvalIR;
  compileFlags.emitAsyncBreakCheck = runtime.asyncBreakCheckInEval;
  // Future direct eval can capture any local in a dynamically compiled
  // function. Keep the compiler's semantic scope data independently of whether
  // the interactive debugger was enabled in this build.
  compileFlags.lazy = false;
  compileFlags.enableES6BlockScoping = true;
  compileFlags.enableTDZ = true;
  compileFlags.enableAsyncGenerators = runtime.hasAsyncGenerators();
  // Const writes are runtime TypeErrors, not early parser errors.
  compileFlags.test262 = true;
  compileFlags.requireSingleFunction = singleFunction;
  compileFlags.debug = true;

  // Full optimization can delete scope metadata or locals that a later eval
  // reads. It is intentionally disabled for runtime source compilation until
  // that pipeline has a metadata-preservation contract.
  std::function<void(Module &)> runOptimizationPasses;

  std::unique_ptr<hbc::BCProvider> bytecode;
  {
    std::unique_ptr<hermes::Buffer> buffer =
        makeCompilationSourceBuffer(utf8code, compileFlags);

    if (codeBlock) {
      assert(
          lexicalScopeIdxInParentFunction &&
          "lexical scope required for non-global eval");
      assert(
          !singleFunction && "Function constructor must always be global eval");
      // Local eval.
      std::unique_ptr<hbc::BCProvider> newBCProvider;
      std::string error;
      executeInStack(
          runtime.getStackExecutor(),
          [&newBCProvider,
           &error,
           &buffer,
           codeBlock,
           compileFlags,
           lexicalScopeIdxInParentFunction]() {
            std::tie(newBCProvider, error) = hbc::compileEvalModule(
                std::move(buffer),
                codeBlock->getRuntimeModule()->getBytecode(),
                codeBlock->getFunctionID(),
                compileFlags,
                *lexicalScopeIdxInParentFunction);
          });
      if (!newBCProvider) {
        return runtime.raiseSyntaxError(llvh::StringRef(error));
      }
      bytecode = std::move(newBCProvider);
    } else {
      // Global eval.
      // Creates a new AST Context and compiles everything independently:
      // new SemContext, new IR Module, everything.
      std::pair<std::unique_ptr<hbc::BCProvider>, std::string> bytecode_err;
      executeInStack(
          runtime.getStackExecutor(),
          [&bytecode_err, &buffer, compileFlags, &runOptimizationPasses]() {
            bytecode_err = hbc::createBCProviderFromSrc(
                std::move(buffer),
                "",
                {},
                compileFlags,
                "eval",
                {},
                nullptr,
                runOptimizationPasses);
          });
      if (!bytecode_err.first) {
        return runtime.raiseSyntaxError(TwineChar16(bytecode_err.second));
      }
      bytecode = std::move(bytecode_err.first);
    }
  }

  // TODO: pass a sourceURL derived from a '//# sourceURL' comment.
  llvh::StringRef sourceURL{};
  return runtime.runBytecode(
      std::move(bytecode),
      RuntimeModuleFlags{},
      sourceURL,
      environment,
      thisArg,
      newTarget);
}

CallResult<HermesValue> directEval(
    Runtime &runtime,
    Handle<StringPrimitive> str,
    bool strictCaller,
    const CodeBlock *codeBlock,
    bool singleFunction) {
  // Convert the code into UTF8.
  std::string code;
  auto view = StringPrimitive::createStringView(runtime, str);
  if (view.isASCII()) {
    code = std::string(view.begin(), view.end());
  } else {
    SmallU16String<4> allocator;
    convertUTF16ToUTF8WithReplacements(code, view.getUTF16Ref(allocator));
  }

  return evalInEnvironment(
      runtime,
      code,
      strictCaller,
      Runtime::makeNullHandle<Environment>(),
      codeBlock,
      runtime.getGlobal(),
      Runtime::getUndefinedValue(),
      singleFunction,
      /* lexScope */ llvh::None);
}

CallResult<HermesValue> eval(void *, Runtime &runtime) {
  NativeArgs args = runtime.getCurrentFrame().getNativeArgs();
  GCScope gcScope(runtime);

  if (!args.getArg(0).isString()) {
    return args.getArg(0);
  }

  return directEval(
      runtime, args.dyncastArg<StringPrimitive>(0), false, nullptr, false);
}

} // namespace vm
} // namespace hermes
