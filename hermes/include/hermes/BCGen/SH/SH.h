/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#ifndef HERMES_BCGEN_SH_SH_H
#define HERMES_BCGEN_SH_SH_H

#include "hermes/IR/IR.h"
#include "hermes/Utils/Options.h"

namespace hermes {
namespace sh {

/// Given a module \p M and an ostream \p OS, compiles the module into C, and
/// outputs the code to the ostream.
void generateSH(
    Module *M,
    llvh::raw_ostream &OS,
    const BytecodeGenerationOptions &options);

/// Apply the shared Static Hermes lowering while retaining SSA values.
/// The LLVM backend must call this before emission, and must not apply the
/// subsequent SH register allocation or allocated-function call lowering.
bool lowerForLLVM(Module *M, bool optimize);

} // namespace sh
} // namespace hermes

#endif
