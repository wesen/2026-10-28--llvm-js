; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [13 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [6 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 5, i32 2794059355]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [1 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 }
]

declare i32 @_setjmp(ptr) returns_twice
declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_catch_prepare(ptr, ptr, ptr, i32)
declare void @shllvm_catch_value(ptr, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_constant(ptr, i32, i64)
declare ptr @shllvm_create_unit(ptr, i32, ptr, ptr, ptr, i32, ptr, ptr, ptr)
declare ptr @shllvm_enter(ptr, ptr, i32, i32, i32)
declare void @shllvm_env_create(ptr, ptr, ptr, i32)
declare void @shllvm_env_load(ptr, ptr, i32)
declare void @shllvm_env_store(ptr, ptr, ptr, i32)
declare i64 @shllvm_frame_size(i32)
declare void @shllvm_get_id(ptr, ptr, ptr, ptr, i32, i32)
declare ptr @shllvm_get_unit(ptr, i32)
declare void @shllvm_global(ptr, ptr)
declare void @shllvm_leave(ptr, ptr, ptr)
declare void @shllvm_rethrow(ptr)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)
declare void @shllvm_throw(ptr, ptr)
declare ptr @shllvm_try_begin(ptr, ptr)
declare void @shllvm_try_end(ptr, ptr)
declare i64 @shllvm_try_size()

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 24)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 24, i32 1, i32 %unit_index)
  %roots = call ptr @shllvm_roots(ptr %storage)
  %unit = call ptr @shllvm_get_unit(ptr %shr, i32 %unit_index)
  %s0 = getelementptr i64, ptr %roots, i32 0
  %s1 = getelementptr i64, ptr %roots, i32 1
  %s2 = getelementptr i64, ptr %roots, i32 2
  %s3 = getelementptr i64, ptr %roots, i32 3
  %s4 = getelementptr i64, ptr %roots, i32 4
  %s5 = getelementptr i64, ptr %roots, i32 5
  %s6 = getelementptr i64, ptr %roots, i32 6
  %s7 = getelementptr i64, ptr %roots, i32 7
  %s8 = getelementptr i64, ptr %roots, i32 8
  %s9 = getelementptr i64, ptr %roots, i32 9
  %s10 = getelementptr i64, ptr %roots, i32 10
  %s11 = getelementptr i64, ptr %roots, i32 11
  %s12 = getelementptr i64, ptr %roots, i32 12
  %s13 = getelementptr i64, ptr %roots, i32 13
  %s14 = getelementptr i64, ptr %roots, i32 14
  %s15 = getelementptr i64, ptr %roots, i32 15
  %s16 = getelementptr i64, ptr %roots, i32 16
  %s17 = getelementptr i64, ptr %roots, i32 17
  %s18 = getelementptr i64, ptr %roots, i32 18
  %s19 = getelementptr i64, ptr %roots, i32 19
  %s20 = getelementptr i64, ptr %roots, i32 20
  %s21 = getelementptr i64, ptr %roots, i32 21
  %s22 = getelementptr i64, ptr %roots, i32 22
  %scratch = getelementptr i64, ptr %roots, i32 23
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s19, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s20, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_constant(ptr %s21, i32 2, i64 0)
  call void @shllvm_constant(ptr %s22, i32 3, i64 4607182418800017408)
  %t1 = call i64 @shllvm_try_size()
  %try_storage = alloca i8, i64 %t1, align 16
  %try_state = alloca i32, align 4
  store volatile i32 0, ptr %try_state, align 4
  %t2 = call ptr @shllvm_try_begin(ptr %shr, ptr %try_storage)
  %t3 = call i32 @_setjmp(ptr %t2) returns_twice
  %t4 = icmp ne i32 %t3, 0
  br i1 %t4, label %catch.dispatch, label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t5 = load volatile i64, ptr %s19, align 8
  store volatile i64 %t5, ptr %s2, align 8
  ; Hermes StoreStackInst
  %t6 = load volatile i64, ptr %s2, align 8
  store volatile i64 %t6, ptr %s1, align 8
  ; Hermes TryStartInst
  store volatile i32 1, ptr %try_state, align 4
  br label %b3
b1:
  ; Hermes CatchInst
  store volatile i32 0, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s5, ptr %shr)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s5, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s7, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s8, ptr %shr, ptr %unit, ptr %s7, i32 1, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s9, ptr %s0, i32 0)
  ; Hermes LIRLoadConstInst
  %t7 = load volatile i64, ptr %s19, align 8
  store volatile i64 %t7, ptr %s10, align 8
  ; Hermes LIRLoadConstInst
  %t8 = load volatile i64, ptr %s19, align 8
  store volatile i64 %t8, ptr %s11, align 8
  ; Hermes CallInst
  %t9 = getelementptr i64, ptr %argv, i32 0
  %t10 = load volatile i64, ptr %s9, align 8
  store volatile i64 %t10, ptr %t9, align 8
  call void @shllvm_call(ptr %s12, ptr %shr, ptr %frame, ptr %s8, ptr %s11, ptr %s10, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t11 = load volatile i64, ptr %s12, align 8
  store volatile i64 %t11, ptr %s1, align 8
  ; Hermes BranchInst
  br label %b2
b2:
  ; Hermes LoadStackInst
  %t12 = load volatile i64, ptr %s1, align 8
  store volatile i64 %t12, ptr %s15, align 8
  ; Hermes ReturnInst
  %t13 = load volatile i64, ptr %s15, align 8
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t13
b3:
  ; Hermes LIRLoadConstInst
  %t14 = load volatile i64, ptr %s22, align 8
  store volatile i64 %t14, ptr %s17, align 8
  ; Hermes ThrowInst
  call void @shllvm_throw(ptr %shr, ptr %s17)
  unreachable
catch.dispatch:
  %t15 = load volatile i32, ptr %try_state, align 4
  call void @shllvm_catch_prepare(ptr %shr, ptr %storage, ptr %frame, i32 1)
  switch i32 %t15, label %catch.rethrow [
    i32 1, label %b1
  ]
catch.rethrow:
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_rethrow(ptr %shr)
  unreachable
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 2, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 1, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
