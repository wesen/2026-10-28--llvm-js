/*
 * Direct LLVM backend for Static Hermes.
 * Licensed under the MIT license in the repository root.
 */
#ifndef HERMES_BCGEN_SH_LLVM_H
#define HERMES_BCGEN_SH_LLVM_H
#include "hermes/BCGen/SH/SH.h"
namespace hermes { namespace sh {
/// Lower Hermes IR and emit textual opaque-pointer LLVM IR. Unsupported IR
/// produces a source diagnostic and false; the caller must discard the output.
bool generateLLVM(Module *M, llvh::raw_ostream &OS,
                  const BytecodeGenerationOptions &options);
} }
#endif
