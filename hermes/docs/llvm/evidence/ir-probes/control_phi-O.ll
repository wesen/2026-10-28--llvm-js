; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [28 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 102, i8 105, i8 98, i8 0, i8 108, i8 111, i8 111, i8 112, i8 0, i8 116, i8 111, i8 117, i8 99, i8 104, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [15 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 3, i32 2473893398, i32 11, i32 4, i32 4022468815, i32 16, i32 5, i32 4027080319, i32 22, i32 5, i32 2794059355]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [4 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 1, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 2, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 3, i32 1, i32 0, i32 2 }
]

declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_binary(ptr, ptr, i32, ptr, ptr)
declare void @shllvm_boolean(ptr, i32)
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
declare void @shllvm_number(ptr, double)
declare void @shllvm_param(ptr, ptr, i32)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_set_id(ptr, ptr, ptr, i32, ptr, i32, i32)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)
declare i32 @shllvm_truthy(ptr)
declare void @shllvm_unary(ptr, ptr, i32, ptr)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 47)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [4 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 47, i32 4, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 46
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s36, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_symbol(ptr %s37, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s38, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s39, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s40, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_constant(ptr %s41, i32 3, i64 4626322717216342016)
  call void @shllvm_constant(ptr %s42, i32 2, i64 0)
  call void @shllvm_constant(ptr %s43, i32 3, i64 0)
  call void @shllvm_constant(ptr %s44, i32 3, i64 4631107791820423168)
  call void @shllvm_constant(ptr %s45, i32 2, i64 1)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 2)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s38, align 8
  store i64 %t1, ptr %s3, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s3, i32 0)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 3)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s6, ptr %shr)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s7, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s6, i32 1, ptr %s7, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s9, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s6, i32 2, ptr %s9, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s11, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s6, i32 3, ptr %s11, i32 0, i32 0)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s13, ptr %shr, ptr %unit, ptr %s6, i32 4, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s14, ptr %shr, ptr %unit, ptr %s6, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s41, align 8
  store i64 %t2, ptr %s15, align 8
  ; Hermes CallInst
  %t3 = getelementptr i64, ptr %argv, i32 0
  %t4 = load i64, ptr %s15, align 8
  store i64 %t4, ptr %t3, align 8
  call void @shllvm_call(ptr %s16, ptr %shr, ptr %frame, ptr %s14, ptr %s3, ptr %s3, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s17, ptr %shr, ptr %unit, ptr %s6, i32 2, i32 0)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s18, ptr %shr, ptr %frame, ptr %s17, ptr %s3, ptr %s3, i32 0, ptr %argv)
  ; Hermes CallInst
  %t5 = getelementptr i64, ptr %argv, i32 0
  %t6 = load i64, ptr %s16, align 8
  store i64 %t6, ptr %t5, align 8
  %t7 = getelementptr i64, ptr %argv, i32 1
  %t8 = load i64, ptr %s18, align 8
  store i64 %t8, ptr %t7, align 8
  call void @shllvm_call(ptr %s19, ptr %shr, ptr %frame, ptr %s13, ptr %s3, ptr %s3, i32 2, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s43, align 8
  store i64 %t9, ptr %s20, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s20, i32 0)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s22, ptr %shr, ptr %unit, ptr %s6, i32 4, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s23, ptr %shr, ptr %unit, ptr %s6, i32 3, i32 0)
  ; Hermes CallInst
  %t10 = getelementptr i64, ptr %argv, i32 0
  %t11 = load i64, ptr %s20, align 8
  store i64 %t11, ptr %t10, align 8
  call void @shllvm_call(ptr %s24, ptr %shr, ptr %frame, ptr %s23, ptr %s3, ptr %s3, i32 1, ptr %argv)
  ; Hermes CondBranchInst
  %t12 = call i32 @shllvm_truthy(ptr %s24)
  %t13 = icmp ne i32 %t12, 0
  br i1 %t13, label %edge0, label %b1
b1:
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s26, ptr %shr, ptr %unit, ptr %s6, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t14 = load i64, ptr %s44, align 8
  store i64 %t14, ptr %s27, align 8
  ; Hermes CallInst
  %t15 = getelementptr i64, ptr %argv, i32 0
  %t16 = load i64, ptr %s27, align 8
  store i64 %t16, ptr %t15, align 8
  call void @shllvm_call(ptr %s28, ptr %shr, ptr %frame, ptr %s26, ptr %s3, ptr %s3, i32 1, ptr %argv)
  ; Hermes BranchInst
  br label %edge1
b2:
  ; Hermes PhiInst
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s31, ptr %s0, i32 0)
  ; Hermes LIRLoadConstInst
  %t17 = load i64, ptr %s45, align 8
  store i64 %t17, ptr %s32, align 8
  ; Hermes LIRLoadConstInst
  %t18 = load i64, ptr %s42, align 8
  store i64 %t18, ptr %s33, align 8
  ; Hermes CallInst
  %t19 = getelementptr i64, ptr %argv, i32 0
  %t20 = load i64, ptr %s33, align 8
  store i64 %t20, ptr %t19, align 8
  %t21 = getelementptr i64, ptr %argv, i32 1
  %t22 = load i64, ptr %s32, align 8
  store i64 %t22, ptr %t21, align 8
  %t23 = getelementptr i64, ptr %argv, i32 2
  %t24 = load i64, ptr %s30, align 8
  store i64 %t24, ptr %t23, align 8
  %t25 = getelementptr i64, ptr %argv, i32 3
  %t26 = load i64, ptr %s31, align 8
  store i64 %t26, ptr %t25, align 8
  call void @shllvm_call(ptr %s34, ptr %shr, ptr %frame, ptr %s22, ptr %s3, ptr %s3, i32 4, ptr %argv)
  ; Hermes ReturnInst
  %t27 = load i64, ptr %s34, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t27
edge0:
  %t28 = load i64, ptr %s24, align 8
  store i64 %t28, ptr %s30, align 8
  br label %b2
edge1:
  %t29 = load i64, ptr %s28, align 8
  store i64 %t29, ptr %s30, align 8
  br label %b2
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 17)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 17, i32 0, i32 %unit_index)
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
  call void @shllvm_constant(ptr %s14, i32 3, i64 0)
  call void @shllvm_constant(ptr %s15, i32 3, i64 4607182418800017408)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s14, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s2, ptr %shr, i32 9, ptr %s1, ptr %s0)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s15, align 8
  store i64 %t2, ptr %s3, align 8
  ; Hermes CondBranchInst
  %t3 = call i32 @shllvm_truthy(ptr %s2)
  %t4 = icmp ne i32 %t3, 0
  br i1 %t4, label %edge0, label %edge1
b1:
  ; Hermes PhiInst
  ; Hermes PhiInst
  ; Hermes PhiInst
  ; Hermes FAddInst
  %t5 = load i64, ptr %s7, align 8
  %t6 = bitcast i64 %t5 to double
  %t7 = load i64, ptr %s6, align 8
  %t8 = bitcast i64 %t7 to double
  %t9 = fadd double %t6, %t8
  call void @shllvm_number(ptr %s8, double %t9)
  ; Hermes FAddInst
  %t10 = load i64, ptr %s5, align 8
  %t11 = bitcast i64 %t10 to double
  %t12 = load i64, ptr %s3, align 8
  %t13 = bitcast i64 %t12 to double
  %t14 = fadd double %t11, %t13
  call void @shllvm_number(ptr %s9, double %t14)
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s10, ptr %shr, i32 9, ptr %s9, ptr %s0)
  ; Hermes CondBranchInst
  %t15 = call i32 @shllvm_truthy(ptr %s10)
  %t16 = icmp ne i32 %t15, 0
  br i1 %t16, label %edge2, label %edge3
b2:
  ; Hermes PhiInst
  ; Hermes ReturnInst
  %t17 = load i64, ptr %s12, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t17
edge0:
  %t18 = load i64, ptr %s1, align 8
  %t19 = load i64, ptr %s3, align 8
  %t20 = load i64, ptr %s1, align 8
  store i64 %t18, ptr %s5, align 8
  store i64 %t19, ptr %s6, align 8
  store i64 %t20, ptr %s7, align 8
  br label %b1
edge1:
  %t21 = load i64, ptr %s1, align 8
  store i64 %t21, ptr %s12, align 8
  br label %b2
edge2:
  %t22 = load i64, ptr %s9, align 8
  %t23 = load i64, ptr %s8, align 8
  %t24 = load i64, ptr %s6, align 8
  store i64 %t22, ptr %s5, align 8
  store i64 %t23, ptr %s6, align 8
  store i64 %t24, ptr %s7, align 8
  br label %b1
edge3:
  %t25 = load i64, ptr %s6, align 8
  store i64 %t25, ptr %s12, align 8
  br label %b2
}

define internal i64 @shllvm_f2(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 21)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 21, i32 0, i32 %unit_index)
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
  call void @shllvm_constant(ptr %s16, i32 3, i64 0)
  call void @shllvm_constant(ptr %s17, i32 3, i64 4622945017495814144)
  call void @shllvm_constant(ptr %s18, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s19, i32 3, i64 4611686018427387904)
  br label %b0
b0:
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s16, align 8
  store i64 %t1, ptr %s0, align 8
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s17, align 8
  store i64 %t2, ptr %s1, align 8
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s18, align 8
  store i64 %t3, ptr %s2, align 8
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s19, align 8
  store i64 %t4, ptr %s3, align 8
  ; Hermes BranchInst
  br label %edge0
b1:
  ; Hermes PhiInst
  ; Hermes PhiInst
  ; Hermes FAddInst
  %t5 = load i64, ptr %s6, align 8
  %t6 = bitcast i64 %t5 to double
  %t7 = load i64, ptr %s2, align 8
  %t8 = bitcast i64 %t7 to double
  %t9 = fadd double %t6, %t8
  call void @shllvm_number(ptr %s7, double %t9)
  ; Hermes FModuloInst
  %t10 = load i64, ptr %s7, align 8
  %t11 = bitcast i64 %t10 to double
  %t12 = load i64, ptr %s3, align 8
  %t13 = bitcast i64 %t12 to double
  %t14 = frem double %t11, %t13
  call void @shllvm_number(ptr %s8, double %t14)
  ; Hermes FEqualInst
  %t15 = load i64, ptr %s8, align 8
  %t16 = load i64, ptr %s0, align 8
  %t17 = bitcast i64 %t15 to double
  %t18 = bitcast i64 %t16 to double
  %t19 = fcmp oeq double %t17, %t18
  %t20 = zext i1 %t19 to i32
  call void @shllvm_boolean(ptr %s9, i32 %t20)
  ; Hermes CondBranchInst
  %t21 = call i32 @shllvm_truthy(ptr %s9)
  %t22 = icmp ne i32 %t21, 0
  br i1 %t22, label %edge1, label %b3
b2:
  ; Hermes ReturnInst
  %t23 = load i64, ptr %s5, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t23
b3:
  ; Hermes FGreaterThanInst
  %t24 = load i64, ptr %s7, align 8
  %t25 = load i64, ptr %s1, align 8
  %t26 = bitcast i64 %t24 to double
  %t27 = bitcast i64 %t25 to double
  %t28 = fcmp ogt double %t26, %t27
  %t29 = zext i1 %t28 to i32
  call void @shllvm_boolean(ptr %s12, i32 %t29)
  ; Hermes CondBranchInst
  %t30 = call i32 @shllvm_truthy(ptr %s12)
  %t31 = icmp ne i32 %t30, 0
  br i1 %t31, label %b2, label %b4
b4:
  ; Hermes FAddInst
  %t32 = load i64, ptr %s5, align 8
  %t33 = bitcast i64 %t32 to double
  %t34 = load i64, ptr %s7, align 8
  %t35 = bitcast i64 %t34 to double
  %t36 = fadd double %t33, %t35
  call void @shllvm_number(ptr %s14, double %t36)
  ; Hermes BranchInst
  br label %edge2
edge0:
  %t37 = load i64, ptr %s0, align 8
  %t38 = load i64, ptr %s0, align 8
  store i64 %t37, ptr %s5, align 8
  store i64 %t38, ptr %s6, align 8
  br label %b1
edge1:
  %t39 = load i64, ptr %s5, align 8
  %t40 = load i64, ptr %s7, align 8
  store i64 %t39, ptr %s5, align 8
  store i64 %t40, ptr %s6, align 8
  br label %b1
edge2:
  %t41 = load i64, ptr %s14, align 8
  %t42 = load i64, ptr %s7, align 8
  store i64 %t41, ptr %s5, align 8
  store i64 %t42, ptr %s6, align 8
  br label %b1
}

define internal i64 @shllvm_f3(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 7)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 7, i32 0, i32 %unit_index)
  %roots = call ptr @shllvm_roots(ptr %storage)
  %unit = call ptr @shllvm_get_unit(ptr %shr, i32 %unit_index)
  %s0 = getelementptr i64, ptr %roots, i32 0
  %s1 = getelementptr i64, ptr %roots, i32 1
  %s2 = getelementptr i64, ptr %roots, i32 2
  %s3 = getelementptr i64, ptr %roots, i32 3
  %s4 = getelementptr i64, ptr %roots, i32 4
  %s5 = getelementptr i64, ptr %roots, i32 5
  %scratch = getelementptr i64, ptr %roots, i32 6
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s1, ptr %s0, i32 0)
  ; Hermes UnaryIncInst
  call void @shllvm_unary(ptr %s2, ptr %shr, i32 5, ptr %s1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s2, i32 0)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s4, ptr %frame, i32 1)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s4, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 5, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 4, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
