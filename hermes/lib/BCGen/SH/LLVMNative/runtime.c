/*
 * Direct LLVM IR backend: target-built adaptation of the existing Static Hermes
 * runtime. This file is compiled once per runtime/toolchain configuration.
 * Program functions and control flow are emitted directly as LLVM IR.
 */
#include "runtime.h"
#include "hermes/VM/static_h.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

_Static_assert(sizeof(SHLegacyValue) == 8, "LLVM slot ABI requires 8-byte values");
_Static_assert(sizeof(void *) == 8, "initial LLVM executable ABI is host64");
_Static_assert(sizeof(SHLLVMFunctionInfo) == 16, "descriptor ABI");
_Static_assert(offsetof(SHLLVMFunctionInfo, prohibit_invoke) == 12, "descriptor ABI");

typedef struct SHLLVMUnit {
  SHUnit unit;
  uint32_t function_count;
  SHNativeFuncInfo *functions;
  SHCompressedPointer empty_class;
  SHShapeTableEntry empty_shape;
} SHLLVMUnit;

#define V(p) (*(SHLegacyValue *)(p))
#define R(p) ((SHRuntime *)(p))
#define U(p) ((SHUnit *)(p))

static void bad(const char *what) {
  fprintf(stderr, "Static Hermes LLVM bridge: %s\n", what);
  abort();
}

void shllvm_constant(void *out, uint32_t kind, uint64_t bits) {
  switch (kind) {
    case SHLLVM_UNDEFINED: V(out) = _sh_ljs_undefined(); return;
    case SHLLVM_NULL: V(out) = _sh_ljs_null(); return;
    case SHLLVM_BOOLEAN: V(out) = _sh_ljs_bool(bits != 0); return;
    case SHLLVM_NUMBER: {
      double d;
      memcpy(&d, &bits, sizeof(d));
      V(out) = _sh_ljs_untrusted_double(d);
      return;
    }
    case SHLLVM_EMPTY: V(out) = _sh_ljs_empty(); return;
    case SHLLVM_UNINIT: V(out) = _sh_ljs_undefined(); return;
    default: bad("unknown constant kind");
  }
}
void shllvm_number(void *out, double number) {
  V(out) = _sh_ljs_untrusted_double(number);
}
void shllvm_boolean(void *out, uint32_t value) {
  V(out) = _sh_ljs_bool(value != 0);
}
uint64_t shllvm_frame_size(uint32_t count) {
  return offsetof(SHLocals, locals) + (uint64_t)count * sizeof(SHLegacyValue);
}
void *shllvm_get_unit(void *shr, uint32_t index) {
  if (!index || index >= sizeof(R(shr)->units)/sizeof(R(shr)->units[0]) ||
      !R(shr)->units[index]) bad("unregistered unit");
  return R(shr)->units[index];
}
void *shllvm_enter(void *shr, void *storage, uint32_t count,
                   uint32_t max_args, uint32_t index) {
  SHLocals *locals = storage;
  if (max_args > UINT32_MAX - 9) bad("argument frame too large");
  _sh_check_native_stack_overflow(R(shr));
  locals->count = count;
  locals->unit = shllvm_get_unit(shr, index);
  locals->src_location_idx = 0; /* SHSrcLocationTable::kInvalidLocIdx */
  for (uint32_t i = 0; i < count; ++i)
    locals->locals[i] = _sh_ljs_undefined();
  /* One debug slot, max_args values, this, and seven outgoing frame slots. */
  SHLegacyValue *frame = _sh_enter(R(shr), locals, max_args + 9);
  for (uint32_t i = 0; i < max_args + 9; ++i)
    frame[i] = _sh_ljs_undefined();
  frame[SHStackFrame_SHLocals] = _sh_ljs_native_pointer(locals);
  return frame;
}
void *shllvm_roots(void *storage) { return ((SHLocals *)storage)->locals; }
void shllvm_leave(void *shr, void *storage, void *frame) {
  _sh_leave(R(shr), storage, frame);
}
void shllvm_param(void *out, void *frame, uint32_t index) {
  V(out) = _sh_ljs_param(frame, index);
}
void shllvm_global(void *out, void *shr) {
  V(out) = _sh_ljs_get_global_object(R(shr));
}
void shllvm_symbol(void *out, void *shr, void *unit, uint32_t index) {
  if (index >= U(unit)->num_symbols) bad("string index out of range");
  V(out) = _sh_ljs_get_string(R(shr), U(unit)->symbols[index]);
}
void shllvm_declare_global(void *shr, void *unit, uint32_t index) {
  if (index >= U(unit)->num_symbols) bad("global string index out of range");
  _sh_ljs_declare_global_var(R(shr), U(unit)->symbols[index]);
}
void shllvm_env_create(void *out, void *shr, void *parent, uint32_t size) {
  /* An absent native environment cannot be an object(null) GC root. */
  if (parent && _sh_ljs_is_undefined(V(parent))) parent = NULL;
  V(out) = _sh_ljs_create_environment(R(shr), parent, size);
}
void shllvm_env_from_closure(void *out, void *shr, void *closure) {
  SHLegacyValue env = _sh_ljs_get_env_from_closure(R(shr), V(closure));
  V(out) = _sh_ljs_get_pointer(env) ? env : _sh_ljs_undefined();
}
void shllvm_env_from_frame(void *out, void *shr, void *frame) {
  shllvm_env_from_closure(out, shr,
      &((SHLegacyValue *)frame)[SHStackFrame_CalleeClosureOrCB]);
}
void shllvm_env_resolve(void *out, void *shr, void *env, uint32_t levels) {
  V(out) = _sh_ljs_get_env(R(shr), V(env), levels);
}
void shllvm_env_load(void *out, void *env, uint32_t index) {
  V(out) = _sh_ljs_load_from_env(V(env), index);
}
void shllvm_env_store(void *shr, void *env, void *value, uint32_t index) {
  _sh_ljs_store_to_env(R(shr), V(env), V(value), index);
}
void shllvm_closure(void *out, void *shr, void *env, void *unit,
                    void *function, uint32_t function_index) {
  SHLLVMUnit *llvm_unit = unit;
  if (function_index >= llvm_unit->function_count) bad("function index out of range");
  if (env && _sh_ljs_is_undefined(V(env))) env = NULL;
  V(out) = _sh_ljs_create_closure(R(shr), env,
      (SHLegacyValue (*)(SHRuntime *))function,
      &llvm_unit->functions[function_index], U(unit));
}
void shllvm_generator(void *out, void *shr, void *env, void *unit,
                      void *function, uint32_t function_index) {
  SHLLVMUnit *llvm_unit = unit;
  if (function_index >= llvm_unit->function_count)
    bad("generator function index out of range");
  if (env && _sh_ljs_is_undefined(V(env))) env = NULL;
  if (!env) bad("lowered generator has no environment");
  /* LowerGeneratorFunction has already moved suspended locals and control
   * state into a managed environment. This helper creates the runtime
   * generator object whose resumption callback is emitted directly in LLVM. */
  V(out) = _sh_ljs_create_generator_object(R(shr), env,
      (SHLegacyValue (*)(SHRuntime *))function,
      &llvm_unit->functions[function_index], U(unit));
}
void shllvm_iterator_begin(void *out, void *shr, void *source_or_next) {
  V(out) = _sh_ljs_iterator_begin_rjs(R(shr), source_or_next);
}
void shllvm_iterator_next(void *out, void *shr, void *iterator, void *source_or_next) {
  V(out) = _sh_ljs_iterator_next_rjs(R(shr), iterator, source_or_next);
}
void shllvm_iterator_close(void *shr, void *iterator, uint32_t ignore_exception) {
  _sh_ljs_iterator_close_rjs(R(shr), iterator, ignore_exception != 0);
}
uint32_t shllvm_pnames(void *out, void *shr, void *base, void *index, void *size) {
  V(out) = _sh_ljs_get_pname_list_rjs(R(shr), base, index, size);
  return !_sh_ljs_is_undefined(V(out));
}
uint32_t shllvm_pname_next(void *out, void *shr, void *iterator,
                          void *base, void *index, void *size) {
  V(out) = _sh_ljs_get_next_pname_rjs(R(shr), iterator, base, index, size);
  return !_sh_ljs_is_undefined(V(out));
}
static void copy_args(SHRuntime *shr, uint32_t argc, void *argv) {
  /* This loop does not allocate. During the following call the register frame
   * is traced by Hermes. Inputs must already have been evaluated and rooted. */
  for (uint32_t i = 0; i < argc; ++i)
    shr->stackPointer[SHStackFrame_FirstArg - (int32_t)i] = ((SHLegacyValue *)argv)[i];
}
void shllvm_call(void *out, void *shr, void *frame, void *callee, void *this_value,
                 void *new_target, uint32_t argc, void *argv) {
  SHLegacyValue *next = R(shr)->stackPointer;
  next[SHStackFrame_CalleeClosureOrCB] = V(callee);
  next[SHStackFrame_ThisArg] = V(this_value);
  next[SHStackFrame_NewTarget] = new_target ? V(new_target) : _sh_ljs_undefined();
  copy_args(R(shr), argc, argv);
  V(out) = _sh_ljs_call(R(shr), frame, argc);
}
void shllvm_builtin(void *out, void *shr, void *frame,
                    uint32_t builtin_index, uint32_t argc, void *argv) {
  copy_args(R(shr), argc, argv);
  V(out) = _sh_ljs_call_builtin(R(shr), frame, argc, builtin_index);
}
void shllvm_builtin_closure(void *out, void *shr, uint32_t index) {
  V(out) = _sh_ljs_get_builtin_closure(R(shr), index);
}
void shllvm_binary(void *out, void *shr, uint32_t op, void *a, void *b) {
  SHRuntime *s = R(shr);
  switch (op) {
    case SHLLVM_ADD: V(out) = _sh_ljs_add_rjs(s,a,b); return;
    case SHLLVM_SUB: V(out) = _sh_ljs_sub_rjs(s,a,b); return;
    case SHLLVM_MUL: V(out) = _sh_ljs_mul_rjs(s,a,b); return;
    case SHLLVM_DIV: V(out) = _sh_ljs_div_rjs(s,a,b); return;
    case SHLLVM_MOD: V(out) = _sh_ljs_mod_rjs(s,a,b); return;
    case SHLLVM_EQ: V(out) = _sh_ljs_bool(_sh_ljs_equal_rjs(s,a,b)); return;
    case SHLLVM_NE: V(out) = _sh_ljs_bool(!_sh_ljs_equal_rjs(s,a,b)); return;
    case SHLLVM_STRICT_EQ: V(out) = _sh_ljs_bool(_sh_ljs_strict_equal(V(a),V(b))); return;
    case SHLLVM_STRICT_NE: V(out) = _sh_ljs_bool(!_sh_ljs_strict_equal(V(a),V(b))); return;
    case SHLLVM_LT: V(out) = _sh_ljs_bool(_sh_ljs_less_rjs(s,a,b)); return;
    case SHLLVM_LE: V(out) = _sh_ljs_bool(_sh_ljs_less_equal_rjs(s,a,b)); return;
    case SHLLVM_GT: V(out) = _sh_ljs_bool(_sh_ljs_greater_rjs(s,a,b)); return;
    case SHLLVM_GE: V(out) = _sh_ljs_bool(_sh_ljs_greater_equal_rjs(s,a,b)); return;
    case SHLLVM_BIT_OR: V(out) = _sh_ljs_bit_or_rjs(s,a,b); return;
    case SHLLVM_BIT_AND: V(out) = _sh_ljs_bit_and_rjs(s,a,b); return;
    case SHLLVM_BIT_XOR: V(out) = _sh_ljs_bit_xor_rjs(s,a,b); return;
    case SHLLVM_SHL: V(out) = _sh_ljs_left_shift_rjs(s,a,b); return;
    case SHLLVM_SHR: V(out) = _sh_ljs_right_shift_rjs(s,a,b); return;
    case SHLLVM_USHR: V(out) = _sh_ljs_unsigned_right_shift_rjs(s,a,b); return;
    case SHLLVM_IN: V(out) = _sh_ljs_is_in_rjs(s,a,b); return;
    case SHLLVM_INSTANCEOF: V(out) = _sh_ljs_instance_of_rjs(s,a,b); return;
    default: bad("unknown binary opcode");
  }
}
void shllvm_unary(void *out, void *shr, uint32_t op, void *a) {
  SHRuntime *s = R(shr);
  switch (op) {
    case SHLLVM_NEG: V(out) = _sh_ljs_minus_rjs(s,a); return;
    case SHLLVM_POS: V(out) = _sh_ljs_untrusted_double(_sh_ljs_to_double_rjs(s,a)); return;
    case SHLLVM_NOT: V(out) = _sh_ljs_bool(!_sh_ljs_to_boolean(V(a))); return;
    case SHLLVM_BIT_NOT: V(out) = _sh_ljs_bit_not_rjs(s,a); return;
    case SHLLVM_TYPEOF: V(out) = _sh_ljs_typeof(s,a); return;
    case SHLLVM_INC: V(out) = _sh_ljs_inc_rjs(s,a); return;
    case SHLLVM_DEC: V(out) = _sh_ljs_dec_rjs(s,a); return;
    case SHLLVM_TO_NUMERIC: V(out) = _sh_ljs_to_numeric_rjs(s,a); return;
    case SHLLVM_TO_STRING: V(out) = _sh_ljs_add_empty_string_rjs(s,a); return;
    case SHLLVM_TO_INT32: V(out) = _sh_ljs_double(_sh_ljs_to_int32_rjs(s,a)); return;
    case SHLLVM_TO_UINT32: V(out) = _sh_ljs_double(_sh_ljs_to_uint32_rjs(s,a)); return;
    case SHLLVM_TO_PROPERTY_KEY: V(out) = _sh_ljs_to_property_key(s,a); return;
    default: bad("unknown unary opcode");
  }
}
uint32_t shllvm_truthy(void *value) { return _sh_ljs_to_boolean(V(value)); }
uint32_t shllvm_is_object(void *value) { return _sh_ljs_is_object(V(value)); }
void shllvm_object(void *out, void *shr) { V(out) = _sh_ljs_new_object(R(shr)); }
void shllvm_object_parent(void *out, void *shr, void *unit, void *parent) {
  V(out) = _sh_ljs_new_object_with_parent(R(shr),U(unit),parent,0);
}
void shllvm_array(void *out, void *shr, uint32_t length) {
  V(out) = _sh_ljs_new_array(R(shr),length);
}
void shllvm_get(void *out, void *shr, void *object, void *key) {
  V(out) = _sh_ljs_get_by_val_rjs(R(shr),object,key);
}
void shllvm_get_id(void *out, void *shr, void *unit, void *object,
                   uint32_t key_index, uint32_t try_flag) {
  if (key_index >= U(unit)->num_symbols) bad("property string index out of range");
  SHReadPropertyCacheEntry *cache = &U(unit)->read_prop_cache[key_index];
  V(out) = try_flag ? _sh_ljs_try_get_by_id_rjs(R(shr),object,U(unit)->symbols[key_index],cache)
                    : _sh_ljs_get_by_id_rjs(R(shr),object,U(unit)->symbols[key_index],cache);
}
void shllvm_set(void *shr, void *object, void *key, void *value, uint32_t strict) {
  if (strict) _sh_ljs_put_by_val_strict_rjs(R(shr),object,key,value);
  else _sh_ljs_put_by_val_loose_rjs(R(shr),object,key,value);
}
void shllvm_set_id(void *shr, void *unit, void *object, uint32_t key_index,
                   void *value, uint32_t strict, uint32_t try_flag) {
  if (key_index >= U(unit)->num_symbols) bad("property string index out of range");
  SHWritePropertyCacheEntry *cache = &U(unit)->write_prop_cache[key_index];
  SHSymbolID symbol = U(unit)->symbols[key_index];
  if (try_flag) {
    if (strict) _sh_ljs_try_put_by_id_strict_rjs(R(shr),U(unit),object,symbol,value,cache);
    else _sh_ljs_try_put_by_id_loose_rjs(R(shr),U(unit),object,symbol,value,cache);
  } else {
    if (strict) _sh_ljs_put_by_id_strict_rjs(R(shr),U(unit),object,symbol,value,cache);
    else _sh_ljs_put_by_id_loose_rjs(R(shr),U(unit),object,symbol,value,cache);
  }
}
void shllvm_define(void *shr, void *object, void *key, void *value, uint32_t enumerable) {
  if (enumerable) _sh_ljs_define_own_by_val(R(shr),object,key,value);
  else _sh_ljs_define_own_ne_by_val(R(shr),object,key,value);
}
void shllvm_define_index(void *shr, void *object, uint32_t index, void *value) {
  _sh_ljs_define_own_by_index(R(shr),object,index,value);
}
void shllvm_define_accessor(void *shr, void *object, void *key,
                            void *getter, void *setter, uint32_t enumerable) {
  _sh_ljs_define_own_getter_setter_by_val(R(shr),object,key,getter,setter,enumerable != 0);
}
void shllvm_delete(void *out, void *shr, void *object, void *key, uint32_t strict) {
  V(out) = strict ? _sh_ljs_del_by_val_strict(R(shr),object,key)
                  : _sh_ljs_del_by_val_loose(R(shr),object,key);
}
void shllvm_coerce_this(void *out, void *shr, void *value) {
  V(out) = _sh_ljs_coerce_this_ns(R(shr),V(value));
}
void shllvm_create_this(void *out, void *shr, void *callee, void *new_target) {
  V(out) = _sh_ljs_create_this(R(shr),callee,new_target,NULL,NULL);
}
void shllvm_constructed_object(void *out, void *this_value, void *returned) {
  V(out) = _sh_ljs_is_object(V(returned)) ? V(returned) : V(this_value);
}
void shllvm_get_parent(void *out, void *shr, void *object) {
  V(out) = _sh_ljs_load_parent_no_traps(R(shr),V(object));
}
void shllvm_new_target(void *out, void *frame) {
  V(out) = ((SHLegacyValue *)frame)[SHStackFrame_NewTarget];
}
void shllvm_throw(void *shr, void *value) { _sh_throw(R(shr),V(value)); }
void shllvm_throw_type_error(void *shr, void *message) { _sh_throw_type_error(R(shr),message); }
void shllvm_check_empty(void *shr, void *value) {
  if (_sh_ljs_is_empty(V(value))) _sh_throw_empty(R(shr));
}

/* The ABI descriptor uses fixed-width integers. Native struct layout, bitfields,
 * symbols and GC-visible caches stay exclusively on this side of the bridge. */
void *shllvm_create_unit(void *index, uint32_t num_strings,
                         const void *ascii_pool, const void *u16_pool,
                         const void *string_triples, uint32_t num_functions,
                         const void *function_info, void *main_function,
                         const char *unit_name) {
  if (!num_functions) bad("unit has no main function");
  size_t size = sizeof(SHLLVMUnit) +
      (size_t)num_strings * (sizeof(SHSymbolID) +
        sizeof(SHWritePropertyCacheEntry) + sizeof(SHReadPropertyCacheEntry)) +
      (size_t)num_functions * sizeof(SHNativeFuncInfo) + 32;
  SHLLVMUnit *u = calloc(1,size);
  if (!u) bad("cannot allocate compilation unit");
  unsigned char *p = (unsigned char *)(u + 1);
#define ALIGN_FOR(type) p = (unsigned char *)(((uintptr_t)p + _Alignof(type)-1) & ~(uintptr_t)(_Alignof(type)-1))
  ALIGN_FOR(SHSymbolID);
  u->unit.symbols = (SHSymbolID *)p; p += num_strings * sizeof(SHSymbolID);
  ALIGN_FOR(SHWritePropertyCacheEntry);
  u->unit.write_prop_cache = (SHWritePropertyCacheEntry *)p;
  p += num_strings * sizeof(SHWritePropertyCacheEntry);
  ALIGN_FOR(SHReadPropertyCacheEntry);
  u->unit.read_prop_cache = (SHReadPropertyCacheEntry *)p;
  p += num_strings * sizeof(SHReadPropertyCacheEntry);
  ALIGN_FOR(SHNativeFuncInfo);
  u->functions = (SHNativeFuncInfo *)p;
#undef ALIGN_FOR
  u->function_count = num_functions;
  const SHLLVMFunctionInfo *info = function_info;
  for (uint32_t i = 0; i < num_functions; ++i) {
    if (info[i].name_index >= num_strings || info[i].kind > 3 || info[i].prohibit_invoke > 3)
      bad("invalid function descriptor");
    u->functions[i].name_index = info[i].name_index;
    u->functions[i].arg_count = info[i].arg_count;
    u->functions[i].kind = info[i].kind;
    u->functions[i].prohibit_invoke = info[i].prohibit_invoke;
  }
  u->unit.index = index;
  u->unit.num_symbols = num_strings;
  u->unit.num_read_prop_cache_entries = num_strings;
  u->unit.num_write_prop_cache_entries = num_strings;
  u->unit.ascii_pool = ascii_pool;
  u->unit.u16_pool = u16_pool;
  u->unit.strings = string_triples;
  u->unit.unit_main = (SHLegacyValue (*)(SHRuntime *))main_function;
  u->unit.unit_main_info = &u->functions[0];
  u->unit.unit_name = unit_name;
  /* A registered weak cache for empty objects with explicit prototypes. The
   * bridge never assumes that a generic object's property slots match typed
   * allocation layouts. Properties are subsequently defined by name. */
  u->unit.object_literal_class_cache = &u->empty_class;
  u->unit.obj_shape_table = &u->empty_shape;
  u->unit.obj_shape_table_count = 1;
  return u;
}

typedef struct SHConsoleContext SHConsoleContext;
extern SHConsoleContext *init_console_bindings(SHRuntime *,int,const char *const *);
extern void release_console_bindings(SHConsoleContext *);
extern void free_console_context(SHConsoleContext *);
extern bool run_event_loop(SHRuntime *,SHConsoleContext *);
int32_t shllvm_run(int32_t argc, void *argv_raw, void *creator) {
  _SH_MODEL();
  char **argv = argv_raw;
  int script_argc = 0, cl_argc = argc;
  char **script_argv = NULL;
  for (int i = 1; i < argc; ++i) {
    if (strcmp(argv[i],"--") == 0) {
      script_argc = argc - i - 1;
      script_argv = argv + i + 1;
      cl_argc = i;
      break;
    }
  }
  SHRuntime *shr = _sh_init(cl_argc,argv);
  SHConsoleContext *console = init_console_bindings(shr,script_argc,(const char *const *)script_argv);
  bool success = _sh_initialize_units(shr,1,(SHUnitCreator)creator) && run_event_loop(shr,console);
  release_console_bindings(console);
  _sh_done(shr);
  free_console_context(console);
  return success ? 0 : 1;
}

void shllvm_check_invocation(void *shr, void *frame, uint32_t prohibit) {
  SHLegacyValue new_target = ((SHLegacyValue *)frame)[SHStackFrame_NewTarget];
  if (prohibit == 2 && _sh_ljs_is_undefined(new_target))
    _sh_throw_type_error_ascii(R(shr), "Class constructor invoked without new");
  if (prohibit == 1 && !_sh_ljs_is_undefined(new_target))
    _sh_throw_type_error_ascii(R(shr), "Function is not a constructor");
}
void shllvm_typeof_is(void *out, void *value, uint32_t bits) {
  V(out) = _sh_ljs_bool(_sh_ljs_typeof_is(V(value), (uint16_t)bits));
}
void shllvm_get_receiver(void *out, void *shr, void *object, void *key, void *receiver) {
  V(out) = _sh_ljs_get_by_val_with_receiver_rjs(R(shr),object,key,receiver);
}
void shllvm_set_receiver(void *shr, void *object, void *key, void *value,
                         void *receiver, uint32_t strict) {
  _sh_ljs_put_by_val_with_receiver_rjs(R(shr),object,key,value,receiver,strict != 0);
}
void shllvm_args_length(void *out, void *shr, void *frame, void *lazy) {
  V(out) = _sh_ljs_get_arguments_length(R(shr),frame,lazy);
}
void shllvm_args_get(void *out, void *shr, void *frame, void *key, void *lazy, uint32_t strict) {
  V(out) = strict ? _sh_ljs_get_arguments_prop_by_val_strict(R(shr),frame,key,lazy)
                  : _sh_ljs_get_arguments_prop_by_val_loose(R(shr),frame,key,lazy);
}
void shllvm_args_reify(void *shr, void *frame, void *lazy, uint32_t strict) {
  if (strict) _sh_ljs_reify_arguments_strict(R(shr),frame,lazy);
  else _sh_ljs_reify_arguments_loose(R(shr),frame,lazy);
}

void shllvm_class(void *out, void *shr, void *env, void *unit,
                  void *function, uint32_t function_index, void *home_out, void *super_class) {
  SHLLVMUnit *u = unit;
  if (function_index >= u->function_count) bad("class function index out of range");
  if (env && _sh_ljs_is_undefined(V(env))) env = NULL;
  V(out) = _sh_ljs_create_class(R(shr),env,
      (SHLegacyValue (*)(SHRuntime *))function, &u->functions[function_index],
      U(unit),home_out,super_class);
}
void shllvm_check_tdz(void *shr, void *value, uint32_t mask) {
  if (((mask & 1) && _sh_ljs_is_empty(V(value))) ||
      ((mask & 2) && _sh_ljs_is_undefined(V(value))))
    _sh_throw_empty(R(shr));
}
void shllvm_check_this_initialized(void *shr, void *value) {
  _sh_ljs_throw_if_this_initialized(R(shr),V(value));
}
uint64_t shllvm_try_size(void) { return sizeof(SHJmpBuf); }
void *shllvm_try_begin(void *shr, void *storage) {
  SHJmpBuf *buf = storage;
  _sh_push_try(R(shr),buf);
  return buf->buf;
}
void shllvm_try_end(void *shr, void *storage) { _sh_end_try(R(shr),storage); }
void shllvm_catch_prepare(void *shr, void *locals, void *frame, uint32_t max_args) {
  _sh_catch_no_pop(R(shr),locals,frame,max_args+9);
}
void shllvm_catch_value(void *out, void *shr) {
  V(out) = _sh_get_clear_thrown_value(R(shr));
}
void shllvm_rethrow(void *shr) { _sh_throw_current(R(shr)); }
