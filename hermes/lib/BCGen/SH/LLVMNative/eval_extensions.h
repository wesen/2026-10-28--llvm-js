/* Direct LLVM lexical-eval bridge. SPDX-License-Identifier: MIT. */
#ifndef SH_LLVM_EVAL_EXTENSIONS_H
#define SH_LLVM_EVAL_EXTENSIONS_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

enum SHLLVMEvalBindingFlags {
  SHLLVM_EVAL_BINDING_TDZ = 1,
  SHLLVM_EVAL_BINDING_CONST = 2,
  SHLLVM_EVAL_BINDING_SILENT_CONST = 4
};

/* All names are NUL-terminated UTF-8. The descriptors contain no GC pointers.
 * scopes[0] is the outermost environment; scopes[count-1] is the environment
 * passed to shllvm_eval_direct. Hidden native slots are omitted, except for
 * captured arguments, which is published with the name "arguments". */
typedef struct SHLLVMEvalBinding {
  const char *name;
  uint32_t slot;
  uint32_t flags;
} SHLLVMEvalBinding;

typedef struct SHLLVMEvalScope {
  const SHLLVMEvalBinding *bindings;
  uint32_t binding_count;
  uint32_t slot_count;
} SHLLVMEvalScope;

/* Every value pointer addresses an existing rooted SHLegacyValue slot. Dynamic
 * strings are compiled to Hermes bytecode and run in the VM; this is a semantic
 * runtime service, not runtime LLVM compilation. caller_flags bit 0 is strict,
 * bit 1 indicates the global function. Non-string inputs pass through even in
 * a non-strict caller. Sloppy string direct eval raises an explicit SyntaxError. */
void shllvm_eval_direct(
    void *out,
    void *runtime,
    void *source,
    void *environment,
    void *this_value,
    void *new_target,
    const SHLLVMEvalScope *scopes,
    uint32_t scope_count,
    uint32_t caller_flags);

#ifdef __cplusplus
}
#endif
#endif
