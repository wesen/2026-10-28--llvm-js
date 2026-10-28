/*
 * Existing Static Hermes value operations exposed through the rooted-slot ABI.
 * This bridge is built once, not generated for individual JavaScript programs.
 * Licensed under the MIT license in the repository root.
 */
#include "value_extensions.h"
#include "hermes/VM/static_h.h"
#include <stdio.h>
#include <stdlib.h>

#define VALUE(p) (*(SHLegacyValue *)(p))
#define RUNTIME(p) ((SHRuntime *)(p))

/* The unit's symbol array is registered with Hermes for its entire lifetime.
 * This lookup performs no allocation and does not manufacture a new GC root.
 */
static SHSymbolID unit_symbol(void *unit_ptr, uint32_t index) {
  SHUnit *unit = (SHUnit *)unit_ptr;
  if (index >= unit->num_symbols) {
    fputs("Static Hermes LLVM bridge: symbol index out of range\n", stderr);
    abort();
  }
  return unit->symbols[index];
}

void shllvm_regexp(
    void *out,
    void *shr,
    void *unit,
    uint32_t pattern_index,
    uint32_t flags_index) {
  VALUE(out) = _sh_ljs_create_regexp(
      RUNTIME(shr),
      unit_symbol(unit, pattern_index),
      unit_symbol(unit, flags_index));
}

void shllvm_bigint(
    void *out,
    void *shr,
    const void *bytes,
    uint32_t byte_count) {
  /* Bytes are the exact serialized ParsedBigInt representation emitted by the
   * compiler, including its sign. They are not a decimal string or Number.
   */
  VALUE(out) = _sh_ljs_create_bigint(
      RUNTIME(shr), (const uint8_t *)bytes, byte_count);
}

void shllvm_private_name(
    void *out,
    void *shr,
    void *unit,
    uint32_t description_index) {
  VALUE(out) = _sh_ljs_create_private_name(
      RUNTIME(shr), unit_symbol(unit, description_index));
}

void shllvm_private_get(
    void *out,
    void *shr,
    void *object,
    void *private_name) {
  /* A null cache is a supported runtime path. Private membership caches store
   * a boolean in their slot field, whereas access caches store a field offset;
   * never share one cache between those operations. The uncached path avoids
   * additional weak-cache layout/lifetime assumptions in this first lowering.
   */
  VALUE(out) = _sh_ljs_get_own_private_by_sym(
      RUNTIME(shr), object, private_name, NULL);
}

void shllvm_private_set(
    void *shr,
    void *object,
    void *private_name,
    void *value) {
  _sh_ljs_put_own_private_by_sym(
      RUNTIME(shr), object, private_name, value, NULL);
}

void shllvm_private_add(
    void *shr,
    void *object,
    void *private_name,
    void *value) {
  _sh_ljs_add_own_private_by_sym(
      RUNTIME(shr), object, private_name, value);
}

void shllvm_private_in(
    void *out,
    void *shr,
    void *private_name,
    void *object) {
  VALUE(out) = _sh_ljs_private_is_in_rjs(
      RUNTIME(shr), private_name, object, NULL);
}
