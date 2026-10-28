; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [62 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 118, i8 97, i8 108, i8 117, i8 101, i8 79, i8 102, i8 0, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 118, i8 97, i8 108, i8 117, i8 101, i8 61, i8 0, i8 52, i8 50, i8 0, i8 111, i8 98, i8 106, i8 101, i8 99, i8 116, i8 0, i8 117, i8 110, i8 100, i8 101, i8 102, i8 105, i8 110, i8 101, i8 100, i8 0, i8 102, i8 117, i8 110, i8 99, i8 116, i8 105, i8 111, i8 110, i8 0, i8 97, i8 0, i8 98, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [33 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 7, i32 4132478529, i32 15, i32 0, i32 0, i32 16, i32 5, i32 2794059355, i32 22, i32 6, i32 544573503, i32 29, i32 2, i32 54679048, i32 32, i32 6, i32 343831328, i32 39, i32 9, i32 3628476847, i32 49, i32 8, i32 126745432, i32 58, i32 1, i32 98928, i32 60, i32 1, i32 101955]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [3 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 1, i32 0, i32 0, i32 1 }
]

declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_binary(ptr, ptr, i32, ptr, ptr)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_closure(ptr, ptr, ptr, ptr, ptr, i32)
declare void @shllvm_constant(ptr, i32, i64)
declare ptr @shllvm_create_unit(ptr, i32, ptr, ptr, ptr, i32, ptr, ptr, ptr)
declare void @shllvm_define(ptr, ptr, ptr, ptr, i32)
declare ptr @shllvm_enter(ptr, ptr, i32, i32, i32)
declare void @shllvm_env_create(ptr, ptr, ptr, i32)
declare void @shllvm_env_from_frame(ptr, ptr, ptr)
declare void @shllvm_env_load(ptr, ptr, i32)
declare void @shllvm_env_store(ptr, ptr, ptr, i32)
declare i64 @shllvm_frame_size(i32)
declare void @shllvm_get_id(ptr, ptr, ptr, ptr, i32, i32)
declare ptr @shllvm_get_unit(ptr, i32)
declare void @shllvm_global(ptr, ptr)
declare void @shllvm_leave(ptr, ptr, ptr)
declare void @shllvm_object(ptr, ptr)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_set_id(ptr, ptr, ptr, i32, ptr, i32, i32)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)
declare void @shllvm_unary(ptr, ptr, i32, ptr)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 55)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [4 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 55, i32 4, i32 %unit_index)
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
  %s23 = getelementptr i64, ptr %roots, i32 23
  %s24 = getelementptr i64, ptr %roots, i32 24
  %s25 = getelementptr i64, ptr %roots, i32 25
  %s26 = getelementptr i64, ptr %roots, i32 26
  %s27 = getelementptr i64, ptr %roots, i32 27
  %s28 = getelementptr i64, ptr %roots, i32 28
  %s29 = getelementptr i64, ptr %roots, i32 29
  %s30 = getelementptr i64, ptr %roots, i32 30
  %s31 = getelementptr i64, ptr %roots, i32 31
  %s32 = getelementptr i64, ptr %roots, i32 32
  %s33 = getelementptr i64, ptr %roots, i32 33
  %s34 = getelementptr i64, ptr %roots, i32 34
  %s35 = getelementptr i64, ptr %roots, i32 35
  %s36 = getelementptr i64, ptr %roots, i32 36
  %s37 = getelementptr i64, ptr %roots, i32 37
  %s38 = getelementptr i64, ptr %roots, i32 38
  %s39 = getelementptr i64, ptr %roots, i32 39
  %s40 = getelementptr i64, ptr %roots, i32 40
  %s41 = getelementptr i64, ptr %roots, i32 41
  %s42 = getelementptr i64, ptr %roots, i32 42
  %s43 = getelementptr i64, ptr %roots, i32 43
  %s44 = getelementptr i64, ptr %roots, i32 44
  %s45 = getelementptr i64, ptr %roots, i32 45
  %s46 = getelementptr i64, ptr %roots, i32 46
  %s47 = getelementptr i64, ptr %roots, i32 47
  %s48 = getelementptr i64, ptr %roots, i32 48
  %s49 = getelementptr i64, ptr %roots, i32 49
  %s50 = getelementptr i64, ptr %roots, i32 50
  %s51 = getelementptr i64, ptr %roots, i32 51
  %s52 = getelementptr i64, ptr %roots, i32 52
  %s53 = getelementptr i64, ptr %roots, i32 53
  %scratch = getelementptr i64, ptr %roots, i32 54
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s37, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s38, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_constant(ptr %s39, i32 1, i64 0)
  call void @shllvm_constant(ptr %s40, i32 3, i64 0)
  call void @shllvm_constant(ptr %s41, i32 2, i64 0)
  call void @shllvm_symbol(ptr %s42, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s43, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_constant(ptr %s44, i32 0, i64 0)
  call void @shllvm_constant(ptr %s45, i32 2, i64 1)
  call void @shllvm_constant(ptr %s46, i32 3, i64 4631107791820423168)
  call void @shllvm_symbol(ptr %s47, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_constant(ptr %s48, i32 3, i64 4746794007244308480)
  call void @shllvm_constant(ptr %s49, i32 3, i64 4751297606873776128)
  call void @shllvm_constant(ptr %s50, i32 3, i64 18442240474082181120)
  call void @shllvm_symbol(ptr %s51, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_symbol(ptr %s52, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_symbol(ptr %s53, ptr %shr, ptr %unit, i32 8)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s37, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s1, i32 0)
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object(ptr %s3, ptr %shr)
  call void @shllvm_define(ptr %shr, ptr %s3, ptr %s38, ptr %s39, i32 1)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s4, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes PrStoreInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s3, i32 1, ptr %s4, i32 1, i32 0)
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object(ptr %s6, ptr %shr)
  call void @shllvm_define(ptr %shr, ptr %s6, ptr %s38, ptr %s39, i32 1)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s7, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes PrStoreInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s6, i32 1, ptr %s7, i32 1, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s9, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s10, ptr %shr, ptr %unit, ptr %s9, i32 3, i32 1)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s11, ptr %shr, i32 0, ptr %s3, ptr %s6)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s12, ptr %s0, i32 0)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s43, align 8
  store i64 %t2, ptr %s13, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s14, ptr %shr, i32 0, ptr %s13, ptr %s3)
  ; Hermes AsNumberInst
  call void @shllvm_unary(ptr %s15, ptr %shr, i32 1, ptr %s6)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s44, align 8
  store i64 %t3, ptr %s16, align 8
  ; Hermes CallInst
  %t4 = getelementptr i64, ptr %argv, i32 0
  %t5 = load i64, ptr %s11, align 8
  store i64 %t5, ptr %t4, align 8
  %t6 = getelementptr i64, ptr %argv, i32 1
  %t7 = load i64, ptr %s12, align 8
  store i64 %t7, ptr %t6, align 8
  %t8 = getelementptr i64, ptr %argv, i32 2
  %t9 = load i64, ptr %s14, align 8
  store i64 %t9, ptr %t8, align 8
  %t10 = getelementptr i64, ptr %argv, i32 3
  %t11 = load i64, ptr %s15, align 8
  store i64 %t11, ptr %t10, align 8
  call void @shllvm_call(ptr %s17, ptr %shr, ptr %frame, ptr %s10, ptr %s16, ptr %s16, i32 4, ptr %argv)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s18, ptr %shr, ptr %unit, ptr %s9, i32 3, i32 1)
  ; Hermes LIRLoadConstInst
  %t12 = load i64, ptr %s41, align 8
  store i64 %t12, ptr %s19, align 8
  ; Hermes LIRLoadConstInst
  %t13 = load i64, ptr %s45, align 8
  store i64 %t13, ptr %s20, align 8
  ; Hermes LIRLoadConstInst
  %t14 = load i64, ptr %s46, align 8
  store i64 %t14, ptr %s21, align 8
  ; Hermes LIRLoadConstInst
  %t15 = load i64, ptr %s47, align 8
  store i64 %t15, ptr %s22, align 8
  ; Hermes BinaryEqualInst
  call void @shllvm_binary(ptr %s23, ptr %shr, i32 5, ptr %s22, ptr %s21)
  ; Hermes CallInst
  %t16 = getelementptr i64, ptr %argv, i32 0
  %t17 = load i64, ptr %s20, align 8
  store i64 %t17, ptr %t16, align 8
  %t18 = getelementptr i64, ptr %argv, i32 1
  %t19 = load i64, ptr %s19, align 8
  store i64 %t19, ptr %t18, align 8
  %t20 = getelementptr i64, ptr %argv, i32 2
  %t21 = load i64, ptr %s23, align 8
  store i64 %t21, ptr %t20, align 8
  %t22 = getelementptr i64, ptr %argv, i32 3
  %t23 = load i64, ptr %s19, align 8
  store i64 %t23, ptr %t22, align 8
  call void @shllvm_call(ptr %s24, ptr %shr, ptr %frame, ptr %s18, ptr %s16, ptr %s16, i32 4, ptr %argv)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s25, ptr %shr, ptr %unit, ptr %s9, i32 3, i32 1)
  ; Hermes LIRLoadConstInst
  %t24 = load i64, ptr %s48, align 8
  store i64 %t24, ptr %s26, align 8
  ; Hermes LIRLoadConstInst
  %t25 = load i64, ptr %s49, align 8
  store i64 %t25, ptr %s27, align 8
  ; Hermes LIRLoadConstInst
  %t26 = load i64, ptr %s50, align 8
  store i64 %t26, ptr %s28, align 8
  ; Hermes CallInst
  %t27 = getelementptr i64, ptr %argv, i32 0
  %t28 = load i64, ptr %s28, align 8
  store i64 %t28, ptr %t27, align 8
  %t29 = getelementptr i64, ptr %argv, i32 1
  %t30 = load i64, ptr %s19, align 8
  store i64 %t30, ptr %t29, align 8
  %t31 = getelementptr i64, ptr %argv, i32 2
  %t32 = load i64, ptr %s27, align 8
  store i64 %t32, ptr %t31, align 8
  %t33 = getelementptr i64, ptr %argv, i32 3
  %t34 = load i64, ptr %s26, align 8
  store i64 %t34, ptr %t33, align 8
  call void @shllvm_call(ptr %s29, ptr %shr, ptr %frame, ptr %s25, ptr %s16, ptr %s16, i32 4, ptr %argv)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s30, ptr %shr, ptr %unit, ptr %s9, i32 3, i32 1)
  ; Hermes LIRLoadConstInst
  %t35 = load i64, ptr %s51, align 8
  store i64 %t35, ptr %s31, align 8
  ; Hermes LIRLoadConstInst
  %t36 = load i64, ptr %s52, align 8
  store i64 %t36, ptr %s32, align 8
  ; Hermes LIRLoadConstInst
  %t37 = load i64, ptr %s53, align 8
  store i64 %t37, ptr %s33, align 8
  ; Hermes TypeOfInst
  call void @shllvm_unary(ptr %s34, ptr %shr, i32 4, ptr %s3)
  ; Hermes CallInst
  %t38 = getelementptr i64, ptr %argv, i32 0
  %t39 = load i64, ptr %s34, align 8
  store i64 %t39, ptr %t38, align 8
  %t40 = getelementptr i64, ptr %argv, i32 1
  %t41 = load i64, ptr %s33, align 8
  store i64 %t41, ptr %t40, align 8
  %t42 = getelementptr i64, ptr %argv, i32 2
  %t43 = load i64, ptr %s32, align 8
  store i64 %t43, ptr %t42, align 8
  %t44 = getelementptr i64, ptr %argv, i32 3
  %t45 = load i64, ptr %s31, align 8
  store i64 %t45, ptr %t44, align 8
  call void @shllvm_call(ptr %s35, ptr %shr, ptr %frame, ptr %s30, ptr %s16, ptr %s16, i32 4, ptr %argv)
  ; Hermes ReturnInst
  %t46 = load i64, ptr %s35, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t46
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 10)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 10, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 9
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_symbol(ptr %s7, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_constant(ptr %s8, i32 3, i64 4621819117588971520)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s1, ptr %s0, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s7, align 8
  store i64 %t1, ptr %s2, align 8
  ; Hermes StringConcatInst
  %t2 = load i64, ptr %s1, align 8
  store i64 %t2, ptr %s3, align 8
  call void @shllvm_binary(ptr %s3, ptr %shr, i32 0, ptr %s3, ptr %s2)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s3, i32 0)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s8, align 8
  store i64 %t3, ptr %s5, align 8
  ; Hermes ReturnInst
  %t4 = load i64, ptr %s5, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t4
}

define internal i64 @shllvm_f2(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 10)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 10, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 9
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_symbol(ptr %s7, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_constant(ptr %s8, i32 3, i64 4629700416936869888)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s1, ptr %s0, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s7, align 8
  store i64 %t1, ptr %s2, align 8
  ; Hermes StringConcatInst
  %t2 = load i64, ptr %s1, align 8
  store i64 %t2, ptr %s3, align 8
  call void @shllvm_binary(ptr %s3, ptr %shr, i32 0, ptr %s3, ptr %s2)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s3, i32 0)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s8, align 8
  store i64 %t3, ptr %s5, align 8
  ; Hermes ReturnInst
  %t4 = load i64, ptr %s5, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t4
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 11, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 3, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
