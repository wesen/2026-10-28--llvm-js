/* Direct LLVM emission runtime bridge. Built once, never generated per program. */
#ifndef SH_LLVM_RUNTIME_H
#define SH_LLVM_RUNTIME_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
/* All value pointers address rooted eight-byte SHLegacyValue slots. No helper
 * has an aggregate argument/result. Native JS callbacks retain the established
 * host64 Hermes ABI: an eight-byte SHLegacyValue returned in an integer register.
 */
enum SHLLVMBinary {
  SHLLVM_ADD=0, SHLLVM_SUB=1, SHLLVM_MUL=2, SHLLVM_DIV=3, SHLLVM_MOD=4,
  SHLLVM_EQ=5, SHLLVM_NE=6, SHLLVM_STRICT_EQ=7, SHLLVM_STRICT_NE=8,
  SHLLVM_LT=9, SHLLVM_LE=10, SHLLVM_GT=11, SHLLVM_GE=12,
  SHLLVM_BIT_OR=13, SHLLVM_BIT_AND=14, SHLLVM_BIT_XOR=15,
  SHLLVM_SHL=16, SHLLVM_SHR=17, SHLLVM_USHR=18,
  SHLLVM_IN=19, SHLLVM_INSTANCEOF=20
};
enum SHLLVMUnary {
  SHLLVM_NEG=0, SHLLVM_POS=1, SHLLVM_NOT=2, SHLLVM_BIT_NOT=3,
  SHLLVM_TYPEOF=4, SHLLVM_INC=5, SHLLVM_DEC=6, SHLLVM_TO_NUMERIC=7,
  SHLLVM_TO_STRING=8, SHLLVM_TO_INT32=9, SHLLVM_TO_UINT32=10,
  SHLLVM_TO_PROPERTY_KEY=11
};
enum SHLLVMConstant {
  SHLLVM_UNDEFINED=0, SHLLVM_NULL=1, SHLLVM_BOOLEAN=2, SHLLVM_NUMBER=3,
  SHLLVM_EMPTY=4, SHLLVM_UNINIT=5
};
void shllvm_constant(void *out, uint32_t kind, uint64_t bits);
void shllvm_number(void *out, double value);
void shllvm_boolean(void *out, uint32_t value);
uint64_t shllvm_frame_size(uint32_t root_count);
void *shllvm_enter(void *shr, void *storage, uint32_t root_count,
                   uint32_t max_args, uint32_t unit_index);
void *shllvm_roots(void *storage);
void shllvm_leave(void *shr, void *storage, void *frame);
void *shllvm_get_unit(void *shr, uint32_t unit_index);
void shllvm_param(void *out, void *frame, uint32_t index);
void shllvm_global(void *out, void *shr);
void shllvm_symbol(void *out, void *shr, void *unit, uint32_t index);
void shllvm_declare_global(void *shr, void *unit, uint32_t index);
void shllvm_env_create(void *out, void *shr, void *parent, uint32_t size);
void shllvm_env_from_closure(void *out, void *shr, void *closure);
void shllvm_env_from_frame(void *out, void *shr, void *frame);
void shllvm_env_resolve(void *out, void *shr, void *env, uint32_t levels);
void shllvm_env_load(void *out, void *env, uint32_t index);
void shllvm_env_store(void *shr, void *env, void *value, uint32_t index);
void shllvm_closure(void *out, void *shr, void *env, void *unit,
                    void *function, uint32_t function_index);
void shllvm_generator(void *out, void *shr, void *env, void *unit,
                      void *function, uint32_t function_index);
void shllvm_iterator_begin(void *out, void *shr, void *source_or_next);
void shllvm_iterator_next(void *out, void *shr, void *iterator, void *source_or_next);
void shllvm_iterator_close(void *shr, void *iterator, uint32_t ignore_exception);
uint32_t shllvm_pnames(void *out, void *shr, void *base, void *index, void *size);
uint32_t shllvm_pname_next(void *out, void *shr, void *iterator,
                          void *base, void *index, void *size);
/* argc excludes this; argv is contiguous SHLegacyValue data. */
void shllvm_class(void *out, void *shr, void *env, void *unit,
                  void *function, uint32_t function_index, void *home_out, void *super_class);
void shllvm_call(void *out, void *shr, void *frame, void *callee, void *this_value,
                 void *new_target, uint32_t argc, void *argv);
void shllvm_builtin(void *out, void *shr, void *frame,
                    uint32_t builtin_index, uint32_t argc, void *argv);
void shllvm_builtin_closure(void *out, void *shr, uint32_t builtin_index);
void shllvm_binary(void *out, void *shr, uint32_t op, void *lhs, void *rhs);
void shllvm_unary(void *out, void *shr, uint32_t op, void *value);
uint32_t shllvm_truthy(void *value);
uint32_t shllvm_is_object(void *value);
void shllvm_object(void *out, void *shr);
void shllvm_object_parent(void *out, void *shr, void *unit, void *parent);
void shllvm_array(void *out, void *shr, uint32_t length);
void shllvm_get(void *out, void *shr, void *object, void *key);
/* get-id try flag produces ReferenceError on missing global binding. */
void shllvm_get_id(void *out, void *shr, void *unit, void *object,
                   uint32_t key_index, uint32_t try_flag);
void shllvm_set(void *shr, void *object, void *key, void *value, uint32_t strict);
void shllvm_set_id(void *shr, void *unit, void *object, uint32_t key_index,
                   void *value, uint32_t strict, uint32_t try_flag);
void shllvm_define(void *shr, void *object, void *key, void *value,
                   uint32_t enumerable);
void shllvm_define_index(void *shr, void *object, uint32_t index, void *value);
void shllvm_define_accessor(void *shr, void *object, void *key,
                            void *getter, void *setter, uint32_t enumerable);
void shllvm_delete(void *out, void *shr, void *object, void *key, uint32_t strict);
void shllvm_coerce_this(void *out, void *shr, void *value);
void shllvm_create_this(void *out, void *shr, void *callee, void *new_target);
void shllvm_constructed_object(void *out, void *this_value, void *returned);
void shllvm_get_parent(void *out, void *shr, void *object);
/* Matches Function::ProhibitInvoke: 0 none, 1 construct, 2 call. */
void shllvm_check_invocation(void *shr, void *frame, uint32_t prohibit);
void shllvm_typeof_is(void *out, void *value, uint32_t bits);
void shllvm_get_receiver(void *out, void *shr, void *object, void *key, void *receiver);
void shllvm_set_receiver(void *shr, void *object, void *key, void *value,
                         void *receiver, uint32_t strict);
void shllvm_args_length(void *out, void *shr, void *frame, void *lazy);
void shllvm_args_get(void *out, void *shr, void *frame, void *key, void *lazy, uint32_t strict);
void shllvm_args_reify(void *shr, void *frame, void *lazy, uint32_t strict);
void shllvm_new_target(void *out, void *frame);
void shllvm_throw(void *shr, void *value);
void shllvm_throw_type_error(void *shr, void *message);
void shllvm_check_empty(void *shr, void *value);
void shllvm_check_tdz(void *shr, void *value, uint32_t mask);
void shllvm_check_this_initialized(void *shr, void *value);
uint64_t shllvm_try_size(void);
void *shllvm_try_begin(void *shr, void *storage);
void shllvm_try_end(void *shr, void *storage);
void shllvm_catch_prepare(void *shr, void *locals, void *frame, uint32_t max_args);
void shllvm_catch_value(void *out, void *shr);
void shllvm_rethrow(void *shr);
/* LLVM emits an array of {i32,i32,i32,i32}; C copies the descriptors
 * into native SHNativeFuncInfo, so bitfield layouts never cross this ABI. */
typedef struct SHLLVMFunctionInfo {
  uint32_t name_index, arg_count, kind, prohibit_invoke;
} SHLLVMFunctionInfo;
void *shllvm_create_unit(void *index, uint32_t num_strings,
                         const void *ascii_pool, const void *u16_pool,
                         const void *string_triples, uint32_t num_functions,
                         const void *function_info, void *main_function,
                         const char *unit_name);
int32_t shllvm_run(int32_t argc, void *argv, void *creator);
#ifdef __cplusplus
}
#endif
#endif
