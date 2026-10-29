#include "hermes/LLVMJIT/Engine.h"
#include "hermes/AST/NativeContext.h"
#include "hermes/AST/TransformAST.h"
#include "hermes/BCGen/SH/LLVM.h"
#include "hermes/IR/IRVerifier.h"
#include "hermes/IRGen/IRGen.h"
#include "hermes/Optimizer/PassManager/Pipeline.h"
#include "hermes/Runtime/Libhermes.h"
#include "hermes/Sema/FlowContext.h"
#include "hermes/Sema/SemContext.h"
#include "hermes/Sema/SemResolve.h"
#include "hermes/Support/SimpleDiagHandler.h"
#include "hermes/SourceMap/SourceMapTranslator.h"
#include "llvh/Support/Host.h"
#include "ParseJSFile.h"
namespace hermes { namespace nativejit {
Result compileSource(const std::string &source, const std::string &filename,
                     const std::string &unitName, SourceOptions options,
                     std::string &ir) {
  ir.clear();
  CodeGenerationSettings code;
  code.test262 = true; // Same catchable error timing as direct LLVM CLI.
  code.enableTDZ = true;
  OptimizationSettings optimization;
  optimization.inlining = options.optimize;
  NativeSettings native;
  native.targetTriple = llvh::Triple(llvh::sys::getDefaultTargetTriple());
  auto context = std::make_shared<Context>(std::move(code), optimization, &native);
  context->setEnableEval(true);
  context->setEnableES6BlockScoping(true);
  context->setEnableAsyncGenerators(options.asyncGenerators);
  context->setLazyCompilation(false);
  context->getSourceErrorManager().setWarningStatus(Warning::DirectEval, false);
  SimpleDiagHandlerRAII diagnostics(context->getSourceErrorManager());
  auto failure = [&](const char *phase) -> Result {
    return {false, phase, filename + ": " + (diagnostics.haveErrors()
        ? diagnostics.getErrorString() : "compiler rejected source")};
  };
  DeclarationFileListTy globals;
  if (!loadGlobalDefinition(*context, llvh::MemoryBuffer::getMemBuffer(libhermes), globals))
    return failure("frontend");
  auto id = context->getSourceErrorManager().addNewSourceBuffer(
      llvh::MemoryBuffer::getMemBufferCopy(source, filename));
  std::shared_ptr<SourceMapTranslator> translator;
  auto *parsed = parseJSFile(context.get(), SourceMappingCommentMode::Off,
      StaticBuiltinSetting::AutoDetect, id, {}, translator);
  if (!parsed) return failure("parse");
  auto *ast = llvh::cast_or_null<ESTree::ProgramNode>(
      transformASTForCompilation(*context, false, parsed));
  if (!ast) return failure("transform");
  sema::SemContext sem(*context);
  flow::FlowContext flow;
  if (!sema::resolveAST(*context, sem, nullptr, ast, globals)) return failure("semantic");
  Module module(context);
  generateIRFromESTree(&module, sem, flow, ast);
  if (context->getSourceErrorManager().getErrorCount()) return failure("irgen");
  std::string verification;
  llvh::raw_string_ostream verifier(verification);
  if (!verifyModule(module, &verifier)) return {false, "hermes-verify", verifier.str()};
  runNativeBackendOptimizationPasses(module);
  if (options.optimize) runFullOptimizationPasses(module);
  else runNoOptimizationPasses(module);
  if (context->getSourceErrorManager().getErrorCount()) return failure("optimize");
  BytecodeGenerationOptions generation(OutputFormatKind::DumpBytecode);
  generation.emitMain = false;
  generation.unitName = unitName;
  generation.verifyIR = true;
  generation.optimizationEnabled = options.optimize;
  generation.staticBuiltinsEnabled = context->getStaticBuiltinOptimization();
  llvh::raw_string_ostream output(ir);
  if (!sh::generateLLVM(&module, output, generation)) {
    output.flush(); ir.clear(); return failure("backend");
  }
  output.flush();
  return {true, "compiled", {}};
}
}}
