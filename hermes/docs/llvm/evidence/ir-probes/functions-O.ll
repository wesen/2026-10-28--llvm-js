; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [51 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 102, i8 97, i8 99, i8 116, i8 0, i8 101, i8 118, i8 101, i8 110, i8 0, i8 111, i8 100, i8 100, i8 0, i8 97, i8 112, i8 112, i8 108, i8 121, i8 0, i8 111, i8 117, i8 116, i8 101, i8 114, i8 0, i8 116, i8 119, i8 105, i8 99, i8 101, i8 0, i8 105, i8 110, i8 110, i8 101, i8 114, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [27 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 4, i32 882559840, i32 12, i32 4, i32 3058301720, i32 17, i32 3, i32 3813350531, i32 21, i32 5, i32 3820442164, i32 27, i32 5, i32 1946410666, i32 33, i32 5, i32 141293545, i32 39, i32 5, i32 546627241, i32 45, i32 5, i32 2794059355]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [8 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 1, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 2, i32 1, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 3, i32 1, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 4, i32 2, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 5, i32 1, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 6, i32 1, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 7, i32 1, i32 0, i32 2 }
]

declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_binary(ptr, ptr, i32, ptr, ptr)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_closure(ptr, ptr, ptr, ptr, ptr, i32)
declare void @shllvm_constant(ptr, i32, i64)
declare ptr @shllvm_create_unit(ptr, i32, ptr, ptr, ptr, i32, ptr, ptr, ptr)
declare void @shllvm_declare_global(ptr, ptr, i32)
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
declare void @shllvm_param(ptr, ptr, i32)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_set_id(ptr, ptr, ptr, i32, ptr, i32, i32)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)
declare i32 @shllvm_truthy(ptr)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 53)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [5 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 53, i32 5, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 52
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s38, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_symbol(ptr %s39, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s40, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s41, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s42, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_symbol(ptr %s43, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_constant(ptr %s44, i32 3, i64 4620693217682128896)
  call void @shllvm_constant(ptr %s45, i32 0, i64 0)
  call void @shllvm_constant(ptr %s46, i32 2, i64 0)
  call void @shllvm_constant(ptr %s47, i32 3, i64 4622945017495814144)
  call void @shllvm_constant(ptr %s48, i32 3, i64 4623507967449235456)
  call void @shllvm_constant(ptr %s49, i32 3, i64 4626604192193052672)
  call void @shllvm_constant(ptr %s50, i32 3, i64 4626041242239631360)
  call void @shllvm_constant(ptr %s51, i32 3, i64 4627167142146473984)
  br label %b0
b0:
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 2)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 3)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 4)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 5)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s5, ptr %shr)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s6, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s5, i32 1, ptr %s6, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s8, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s5, i32 2, ptr %s8, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s10, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s5, i32 3, ptr %s10, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s12, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s5, i32 4, ptr %s12, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s14, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f5, i32 5)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s5, i32 5, ptr %s14, i32 0, i32 0)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s16, ptr %shr, ptr %unit, ptr %s5, i32 8, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s17, ptr %shr, ptr %unit, ptr %s5, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s44, align 8
  store i64 %t1, ptr %s18, align 8
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s45, align 8
  store i64 %t2, ptr %s19, align 8
  ; Hermes CallInst
  %t3 = getelementptr i64, ptr %argv, i32 0
  %t4 = load i64, ptr %s18, align 8
  store i64 %t4, ptr %t3, align 8
  call void @shllvm_call(ptr %s20, ptr %shr, ptr %frame, ptr %s17, ptr %s19, ptr %s19, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s21, ptr %shr, ptr %unit, ptr %s5, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s47, align 8
  store i64 %t5, ptr %s22, align 8
  ; Hermes CallInst
  %t6 = getelementptr i64, ptr %argv, i32 0
  %t7 = load i64, ptr %s22, align 8
  store i64 %t7, ptr %t6, align 8
  call void @shllvm_call(ptr %s23, ptr %shr, ptr %frame, ptr %s21, ptr %s19, ptr %s19, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s24, ptr %shr, ptr %unit, ptr %s5, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t8 = load i64, ptr %s48, align 8
  store i64 %t8, ptr %s25, align 8
  ; Hermes CallInst
  %t9 = getelementptr i64, ptr %argv, i32 0
  %t10 = load i64, ptr %s25, align 8
  store i64 %t10, ptr %t9, align 8
  call void @shllvm_call(ptr %s26, ptr %shr, ptr %frame, ptr %s24, ptr %s19, ptr %s19, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s27, ptr %shr, ptr %unit, ptr %s5, i32 4, i32 0)
  ; Hermes LIRLoadConstInst
  %t11 = load i64, ptr %s49, align 8
  store i64 %t11, ptr %s28, align 8
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s29, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f6, i32 6)
  ; Hermes CallInst
  %t12 = getelementptr i64, ptr %argv, i32 0
  %t13 = load i64, ptr %s29, align 8
  store i64 %t13, ptr %t12, align 8
  %t14 = getelementptr i64, ptr %argv, i32 1
  %t15 = load i64, ptr %s28, align 8
  store i64 %t15, ptr %t14, align 8
  call void @shllvm_call(ptr %s30, ptr %shr, ptr %frame, ptr %s27, ptr %s19, ptr %s19, i32 2, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s31, ptr %shr, ptr %unit, ptr %s5, i32 5, i32 0)
  ; Hermes LIRLoadConstInst
  %t16 = load i64, ptr %s50, align 8
  store i64 %t16, ptr %s32, align 8
  ; Hermes CallInst
  %t17 = getelementptr i64, ptr %argv, i32 0
  %t18 = load i64, ptr %s32, align 8
  store i64 %t18, ptr %t17, align 8
  call void @shllvm_call(ptr %s33, ptr %shr, ptr %frame, ptr %s31, ptr %s19, ptr %s19, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t19 = load i64, ptr %s51, align 8
  store i64 %t19, ptr %s34, align 8
  ; Hermes CallInst
  %t20 = getelementptr i64, ptr %argv, i32 0
  %t21 = load i64, ptr %s34, align 8
  store i64 %t21, ptr %t20, align 8
  call void @shllvm_call(ptr %s35, ptr %shr, ptr %frame, ptr %s33, ptr %s19, ptr %s19, i32 1, ptr %argv)
  ; Hermes CallInst
  %t22 = getelementptr i64, ptr %argv, i32 0
  %t23 = load i64, ptr %s20, align 8
  store i64 %t23, ptr %t22, align 8
  %t24 = getelementptr i64, ptr %argv, i32 1
  %t25 = load i64, ptr %s23, align 8
  store i64 %t25, ptr %t24, align 8
  %t26 = getelementptr i64, ptr %argv, i32 2
  %t27 = load i64, ptr %s26, align 8
  store i64 %t27, ptr %t26, align 8
  %t28 = getelementptr i64, ptr %argv, i32 3
  %t29 = load i64, ptr %s30, align 8
  store i64 %t29, ptr %t28, align 8
  %t30 = getelementptr i64, ptr %argv, i32 4
  %t31 = load i64, ptr %s35, align 8
  store i64 %t31, ptr %t30, align 8
  call void @shllvm_call(ptr %s36, ptr %shr, ptr %frame, ptr %s16, ptr %s19, ptr %s19, i32 5, ptr %argv)
  ; Hermes ReturnInst
  %t32 = load i64, ptr %s36, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t32
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 17)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 17, i32 1, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 16
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s12, i32 3, i64 4607182418800017408)
  call void @shllvm_symbol(ptr %s13, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_constant(ptr %s14, i32 0, i64 0)
  call void @shllvm_constant(ptr %s15, i32 2, i64 0)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s12, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes BinaryLessThanOrEqualInst
  call void @shllvm_binary(ptr %s2, ptr %shr, i32 10, ptr %s0, ptr %s1)
  ; Hermes CondBranchInst
  %t2 = call i32 @shllvm_truthy(ptr %s2)
  %t3 = icmp ne i32 %t2, 0
  br i1 %t3, label %b1, label %b2
b1:
  ; Hermes ReturnInst
  %t4 = load i64, ptr %s1, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t4
b2:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s5, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s6, ptr %shr, ptr %unit, ptr %s5, i32 1, i32 0)
  ; Hermes BinarySubtractInst
  call void @shllvm_binary(ptr %s7, ptr %shr, i32 1, ptr %s0, ptr %s1)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s14, align 8
  store i64 %t5, ptr %s8, align 8
  ; Hermes CallInst
  %t6 = getelementptr i64, ptr %argv, i32 0
  %t7 = load i64, ptr %s7, align 8
  store i64 %t7, ptr %t6, align 8
  call void @shllvm_call(ptr %s9, ptr %shr, ptr %frame, ptr %s6, ptr %s8, ptr %s8, i32 1, ptr %argv)
  ; Hermes BinaryMultiplyInst
  call void @shllvm_binary(ptr %s10, ptr %shr, i32 2, ptr %s0, ptr %s9)
  ; Hermes ReturnInst
  %t8 = load i64, ptr %s10, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t8
}

define internal i64 @shllvm_f2(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 21)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 21, i32 1, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 20
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s14, i32 2, i64 1)
  call void @shllvm_constant(ptr %s15, i32 3, i64 0)
  call void @shllvm_symbol(ptr %s16, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_constant(ptr %s17, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s18, i32 0, i64 0)
  call void @shllvm_constant(ptr %s19, i32 2, i64 0)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s14, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s15, align 8
  store i64 %t2, ptr %s2, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s3, ptr %shr, i32 7, ptr %s0, ptr %s2)
  ; Hermes CondBranchInst
  %t3 = call i32 @shllvm_truthy(ptr %s3)
  %t4 = icmp ne i32 %t3, 0
  br i1 %t4, label %edge0, label %b1
b1:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s5, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s6, ptr %shr, ptr %unit, ptr %s5, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s17, align 8
  store i64 %t5, ptr %s7, align 8
  ; Hermes BinarySubtractInst
  call void @shllvm_binary(ptr %s8, ptr %shr, i32 1, ptr %s0, ptr %s7)
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s18, align 8
  store i64 %t6, ptr %s9, align 8
  ; Hermes CallInst
  %t7 = getelementptr i64, ptr %argv, i32 0
  %t8 = load i64, ptr %s8, align 8
  store i64 %t8, ptr %t7, align 8
  call void @shllvm_call(ptr %s10, ptr %shr, ptr %frame, ptr %s6, ptr %s9, ptr %s9, i32 1, ptr %argv)
  ; Hermes BranchInst
  br label %edge1
b2:
  ; Hermes PhiInst
  ; Hermes ReturnInst
  %t9 = load i64, ptr %s12, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t9
edge0:
  %t10 = load i64, ptr %s1, align 8
  store i64 %t10, ptr %s12, align 8
  br label %b2
edge1:
  %t11 = load i64, ptr %s10, align 8
  store i64 %t11, ptr %s12, align 8
  br label %b2
}

define internal i64 @shllvm_f3(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 20)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 20, i32 1, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 19
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s14, i32 2, i64 0)
  call void @shllvm_constant(ptr %s15, i32 3, i64 0)
  call void @shllvm_symbol(ptr %s16, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s17, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s18, i32 0, i64 0)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s14, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s15, align 8
  store i64 %t2, ptr %s2, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s3, ptr %shr, i32 7, ptr %s0, ptr %s2)
  ; Hermes CondBranchInst
  %t3 = call i32 @shllvm_truthy(ptr %s3)
  %t4 = icmp ne i32 %t3, 0
  br i1 %t4, label %edge0, label %b1
b1:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s5, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s6, ptr %shr, ptr %unit, ptr %s5, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s17, align 8
  store i64 %t5, ptr %s7, align 8
  ; Hermes BinarySubtractInst
  call void @shllvm_binary(ptr %s8, ptr %shr, i32 1, ptr %s0, ptr %s7)
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s18, align 8
  store i64 %t6, ptr %s9, align 8
  ; Hermes CallInst
  %t7 = getelementptr i64, ptr %argv, i32 0
  %t8 = load i64, ptr %s8, align 8
  store i64 %t8, ptr %t7, align 8
  call void @shllvm_call(ptr %s10, ptr %shr, ptr %frame, ptr %s6, ptr %s9, ptr %s9, i32 1, ptr %argv)
  ; Hermes BranchInst
  br label %edge1
b2:
  ; Hermes PhiInst
  ; Hermes ReturnInst
  %t9 = load i64, ptr %s12, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t9
edge0:
  %t10 = load i64, ptr %s1, align 8
  store i64 %t10, ptr %s12, align 8
  br label %b2
edge1:
  %t11 = load i64, ptr %s10, align 8
  store i64 %t11, ptr %s12, align 8
  br label %b2
}

define internal i64 @shllvm_f4(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 8)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 8, i32 1, i32 %unit_index)
  %roots = call ptr @shllvm_roots(ptr %storage)
  %unit = call ptr @shllvm_get_unit(ptr %shr, i32 %unit_index)
  %s0 = getelementptr i64, ptr %roots, i32 0
  %s1 = getelementptr i64, ptr %roots, i32 1
  %s2 = getelementptr i64, ptr %roots, i32 2
  %s3 = getelementptr i64, ptr %roots, i32 3
  %s4 = getelementptr i64, ptr %roots, i32 4
  %s5 = getelementptr i64, ptr %roots, i32 5
  %s6 = getelementptr i64, ptr %roots, i32 6
  %scratch = getelementptr i64, ptr %roots, i32 7
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s5, i32 0, i64 0)
  call void @shllvm_constant(ptr %s6, i32 2, i64 0)
  br label %b0
b0:
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s5, align 8
  store i64 %t1, ptr %s0, align 8
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s1, ptr %frame, i32 2)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s2, ptr %frame, i32 1)
  ; Hermes CallInst
  %t2 = getelementptr i64, ptr %argv, i32 0
  %t3 = load i64, ptr %s1, align 8
  store i64 %t3, ptr %t2, align 8
  call void @shllvm_call(ptr %s3, ptr %shr, ptr %frame, ptr %s2, ptr %s0, ptr %s0, i32 1, ptr %argv)
  ; Hermes ReturnInst
  %t4 = load i64, ptr %s3, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t4
}

define internal i64 @shllvm_f5(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 6)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 6, i32 0, i32 %unit_index)
  %roots = call ptr @shllvm_roots(ptr %storage)
  %unit = call ptr @shllvm_get_unit(ptr %shr, i32 %unit_index)
  %s0 = getelementptr i64, ptr %roots, i32 0
  %s1 = getelementptr i64, ptr %roots, i32 1
  %s2 = getelementptr i64, ptr %roots, i32 2
  %s3 = getelementptr i64, ptr %roots, i32 3
  %s4 = getelementptr i64, ptr %roots, i32 4
  %scratch = getelementptr i64, ptr %roots, i32 5
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s1, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s1, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s3, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f7, i32 7)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s3, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f6(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 6)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 6, i32 0, i32 %unit_index)
  %roots = call ptr @shllvm_roots(ptr %storage)
  %unit = call ptr @shllvm_get_unit(ptr %shr, i32 %unit_index)
  %s0 = getelementptr i64, ptr %roots, i32 0
  %s1 = getelementptr i64, ptr %roots, i32 1
  %s2 = getelementptr i64, ptr %roots, i32 2
  %s3 = getelementptr i64, ptr %roots, i32 3
  %s4 = getelementptr i64, ptr %roots, i32 4
  %scratch = getelementptr i64, ptr %roots, i32 5
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_constant(ptr %s4, i32 3, i64 4611686018427387904)
  br label %b0
b0:
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s4, align 8
  store i64 %t1, ptr %s0, align 8
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s1, ptr %frame, i32 1)
  ; Hermes BinaryMultiplyInst
  call void @shllvm_binary(ptr %s2, ptr %shr, i32 2, ptr %s1, ptr %s0)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s2, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f7(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 6)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 6, i32 0, i32 %unit_index)
  %roots = call ptr @shllvm_roots(ptr %storage)
  %unit = call ptr @shllvm_get_unit(ptr %shr, i32 %unit_index)
  %s0 = getelementptr i64, ptr %roots, i32 0
  %s1 = getelementptr i64, ptr %roots, i32 1
  %s2 = getelementptr i64, ptr %roots, i32 2
  %s3 = getelementptr i64, ptr %roots, i32 3
  %s4 = getelementptr i64, ptr %roots, i32 4
  %scratch = getelementptr i64, ptr %roots, i32 5
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s1, ptr %s0, i32 0)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s2, ptr %frame, i32 1)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s3, ptr %shr, i32 0, ptr %s1, ptr %s2)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s3, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 9, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 8, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
