/*
 * Additional value operations for the direct LLVM backend.
 * Licensed under the MIT license in the repository root.
 */
#ifndef SH_LLVM_VALUE_EXTENSIONS_H
#define SH_LLVM_VALUE_EXTENSIONS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Result and value arguments address caller-owned, registered SHLegacyValue
 * root slots. Compilation-unit symbols and literal bytes have unit lifetime.
 */
void shllvm_regexp(
    void *out,
    void *shr,
    void *unit,
    uint32_t pattern_index,
    uint32_t flags_index);
void shllvm_bigint(
    void *out,
    void *shr,
    const void *bytes,
    uint32_t byte_count);
void shllvm_private_name(
    void *out,
    void *shr,
    void *unit,
    uint32_t description_index);
void shllvm_private_get(
    void *out,
    void *shr,
    void *object,
    void *private_name);
void shllvm_private_set(
    void *shr,
    void *object,
    void *private_name,
    void *value);
void shllvm_private_add(
    void *shr,
    void *object,
    void *private_name,
    void *value);
void shllvm_private_in(
    void *out,
    void *shr,
    void *private_name,
    void *object);

#ifdef __cplusplus
}
#endif
#endif
