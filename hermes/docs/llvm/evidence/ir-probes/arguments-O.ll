; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [38 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 105, i8 110, i8 115, i8 112, i8 101, i8 99, i8 116, i8 0, i8 116, i8 111, i8 116, i8 97, i8 108, i8 0, i8 99, i8 97, i8 112, i8 116, i8 117, i8 114, i8 101, i8 0, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 58, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [21 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 7, i32 57933841, i32 15, i32 5, i32 4270060150, i32 21, i32 7, i32 2573446312, i32 29, i32 0, i32 0, i32 30, i32 5, i32 2794059355, i32 36, i32 1, i32 60314]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [5 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 2, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 2, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 3, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 4, i32 0, i32 0, i32 1 }
]

declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_args_get(ptr, ptr, ptr, ptr, ptr, i32)
declare void @shllvm_args_length(ptr, ptr, ptr, ptr)
declare void @shllvm_args_reify(ptr, ptr, ptr, i32)
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
declare void @shllvm_get(ptr, ptr, ptr, ptr)
declare void @shllvm_get_id(ptr, ptr, ptr, ptr, i32, i32)
declare ptr @shllvm_get_unit(ptr, i32)
declare void @shllvm_global(ptr, ptr)
declare void @shllvm_leave(ptr, ptr, ptr)
declare void @shllvm_number(ptr, double)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_set_id(ptr, ptr, ptr, i32, ptr, i32, i32)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)
declare i32 @shllvm_truthy(ptr)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 48)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [5 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 48, i32 5, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 47
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s31, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_symbol(ptr %s32, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s33, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s34, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_constant(ptr %s35, i32 3, i64 4621256167635550208)
  call void @shllvm_constant(ptr %s36, i32 3, i64 4620693217682128896)
  call void @shllvm_constant(ptr %s37, i32 3, i64 4619567317775286272)
  call void @shllvm_constant(ptr %s38, i32 0, i64 0)
  call void @shllvm_constant(ptr %s39, i32 2, i64 0)
  call void @shllvm_constant(ptr %s40, i32 3, i64 4629700416936869888)
  call void @shllvm_constant(ptr %s41, i32 3, i64 4616189618054758400)
  call void @shllvm_constant(ptr %s42, i32 3, i64 4613937818241073152)
  call void @shllvm_constant(ptr %s43, i32 3, i64 4611686018427387904)
  call void @shllvm_constant(ptr %s44, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s45, i32 3, i64 4627167142146473984)
  call void @shllvm_constant(ptr %s46, i32 3, i64 4626041242239631360)
  br label %b0
b0:
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 2)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 3)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s3, ptr %shr)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s4, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s3, i32 1, ptr %s4, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s6, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s3, i32 2, ptr %s6, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s8, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s3, i32 3, ptr %s8, i32 0, i32 0)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s10, ptr %shr, ptr %unit, ptr %s3, i32 5, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s11, ptr %shr, ptr %unit, ptr %s3, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s35, align 8
  store i64 %t1, ptr %s12, align 8
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s36, align 8
  store i64 %t2, ptr %s13, align 8
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s37, align 8
  store i64 %t3, ptr %s14, align 8
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s38, align 8
  store i64 %t4, ptr %s15, align 8
  ; Hermes CallInst
  %t5 = getelementptr i64, ptr %argv, i32 0
  %t6 = load i64, ptr %s14, align 8
  store i64 %t6, ptr %t5, align 8
  %t7 = getelementptr i64, ptr %argv, i32 1
  %t8 = load i64, ptr %s13, align 8
  store i64 %t8, ptr %t7, align 8
  %t9 = getelementptr i64, ptr %argv, i32 2
  %t10 = load i64, ptr %s12, align 8
  store i64 %t10, ptr %t9, align 8
  call void @shllvm_call(ptr %s16, ptr %shr, ptr %frame, ptr %s11, ptr %s15, ptr %s15, i32 3, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s17, ptr %shr, ptr %unit, ptr %s3, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t11 = load i64, ptr %s40, align 8
  store i64 %t11, ptr %s18, align 8
  ; Hermes LIRLoadConstInst
  %t12 = load i64, ptr %s41, align 8
  store i64 %t12, ptr %s19, align 8
  ; Hermes LIRLoadConstInst
  %t13 = load i64, ptr %s42, align 8
  store i64 %t13, ptr %s20, align 8
  ; Hermes LIRLoadConstInst
  %t14 = load i64, ptr %s43, align 8
  store i64 %t14, ptr %s21, align 8
  ; Hermes LIRLoadConstInst
  %t15 = load i64, ptr %s44, align 8
  store i64 %t15, ptr %s22, align 8
  ; Hermes CallInst
  %t16 = getelementptr i64, ptr %argv, i32 0
  %t17 = load i64, ptr %s22, align 8
  store i64 %t17, ptr %t16, align 8
  %t18 = getelementptr i64, ptr %argv, i32 1
  %t19 = load i64, ptr %s21, align 8
  store i64 %t19, ptr %t18, align 8
  %t20 = getelementptr i64, ptr %argv, i32 2
  %t21 = load i64, ptr %s20, align 8
  store i64 %t21, ptr %t20, align 8
  %t22 = getelementptr i64, ptr %argv, i32 3
  %t23 = load i64, ptr %s19, align 8
  store i64 %t23, ptr %t22, align 8
  %t24 = getelementptr i64, ptr %argv, i32 4
  %t25 = load i64, ptr %s18, align 8
  store i64 %t25, ptr %t24, align 8
  call void @shllvm_call(ptr %s23, ptr %shr, ptr %frame, ptr %s17, ptr %s15, ptr %s15, i32 5, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s24, ptr %shr, ptr %unit, ptr %s3, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t26 = load i64, ptr %s45, align 8
  store i64 %t26, ptr %s25, align 8
  ; Hermes LIRLoadConstInst
  %t27 = load i64, ptr %s46, align 8
  store i64 %t27, ptr %s26, align 8
  ; Hermes CallInst
  %t28 = getelementptr i64, ptr %argv, i32 0
  %t29 = load i64, ptr %s26, align 8
  store i64 %t29, ptr %t28, align 8
  %t30 = getelementptr i64, ptr %argv, i32 1
  %t31 = load i64, ptr %s25, align 8
  store i64 %t31, ptr %t30, align 8
  call void @shllvm_call(ptr %s27, ptr %shr, ptr %frame, ptr %s24, ptr %s15, ptr %s15, i32 2, ptr %argv)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s28, ptr %shr, ptr %frame, ptr %s27, ptr %s15, ptr %s15, i32 0, ptr %argv)
  ; Hermes CallInst
  %t32 = getelementptr i64, ptr %argv, i32 0
  %t33 = load i64, ptr %s16, align 8
  store i64 %t33, ptr %t32, align 8
  %t34 = getelementptr i64, ptr %argv, i32 1
  %t35 = load i64, ptr %s23, align 8
  store i64 %t35, ptr %t34, align 8
  %t36 = getelementptr i64, ptr %argv, i32 2
  %t37 = load i64, ptr %s28, align 8
  store i64 %t37, ptr %t36, align 8
  call void @shllvm_call(ptr %s29, ptr %shr, ptr %frame, ptr %s10, ptr %s15, ptr %s15, i32 3, ptr %argv)
  ; Hermes ReturnInst
  %t38 = load i64, ptr %s29, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t38
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 20)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 20, i32 0, i32 %unit_index)
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
  call void @shllvm_constant(ptr %s15, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s16, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_constant(ptr %s17, i32 3, i64 0)
  call void @shllvm_constant(ptr %s18, i32 3, i64 4611686018427387904)
  br label %b0
b0:
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s15, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes StoreStackInst
  %t2 = load i64, ptr %s1, align 8
  store i64 %t2, ptr %s0, align 8
  ; Hermes LoadStackInst
  %t3 = load i64, ptr %s0, align 8
  store i64 %t3, ptr %s3, align 8
  ; Hermes LIRGetArgumentsLengthInst
  call void @shllvm_args_length(ptr %s4, ptr %shr, ptr %frame, ptr %s3)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s16, align 8
  store i64 %t4, ptr %s5, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 0, ptr %s4, ptr %s5)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s17, align 8
  store i64 %t5, ptr %s7, align 8
  ; Hermes LIRGetArgumentsPropByValLooseInst
  call void @shllvm_args_get(ptr %s8, ptr %shr, ptr %frame, ptr %s7, ptr %s0, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s9, ptr %shr, i32 0, ptr %s6, ptr %s8)
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s18, align 8
  store i64 %t6, ptr %s10, align 8
  ; Hermes LIRGetArgumentsPropByValLooseInst
  call void @shllvm_args_get(ptr %s11, ptr %shr, ptr %frame, ptr %s10, ptr %s0, i32 0)
  ; Hermes StringConcatInst
  %t7 = load i64, ptr %s9, align 8
  store i64 %t7, ptr %s12, align 8
  call void @shllvm_binary(ptr %s12, ptr %shr, i32 0, ptr %s12, ptr %s5)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s13, ptr %shr, i32 0, ptr %s12, ptr %s11)
  ; Hermes ReturnInst
  %t8 = load i64, ptr %s13, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t8
}

define internal i64 @shllvm_f2(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 24)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 24, i32 0, i32 %unit_index)
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
  call void @shllvm_constant(ptr %s20, i32 0, i64 0)
  call void @shllvm_constant(ptr %s21, i32 3, i64 0)
  call void @shllvm_constant(ptr %s22, i32 3, i64 4607182418800017408)
  br label %b0
b0:
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s20, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes StoreStackInst
  %t2 = load i64, ptr %s1, align 8
  store i64 %t2, ptr %s0, align 8
  ; Hermes LoadStackInst
  %t3 = load i64, ptr %s0, align 8
  store i64 %t3, ptr %s3, align 8
  ; Hermes LIRGetArgumentsLengthInst
  call void @shllvm_args_length(ptr %s4, ptr %shr, ptr %frame, ptr %s3)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s21, align 8
  store i64 %t4, ptr %s5, align 8
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 9, ptr %s5, ptr %s4)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s22, align 8
  store i64 %t5, ptr %s7, align 8
  ; Hermes CondBranchInst
  %t6 = call i32 @shllvm_truthy(ptr %s6)
  %t7 = icmp ne i32 %t6, 0
  br i1 %t7, label %edge0, label %edge1
b1:
  ; Hermes PhiInst
  ; Hermes PhiInst
  ; Hermes LIRGetArgumentsPropByValLooseInst
  call void @shllvm_args_get(ptr %s11, ptr %shr, ptr %frame, ptr %s9, ptr %s0, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s12, ptr %shr, i32 0, ptr %s10, ptr %s11)
  ; Hermes FAddInst
  %t8 = load i64, ptr %s9, align 8
  %t9 = bitcast i64 %t8 to double
  %t10 = load i64, ptr %s7, align 8
  %t11 = bitcast i64 %t10 to double
  %t12 = fadd double %t9, %t11
  call void @shllvm_number(ptr %s13, double %t12)
  ; Hermes LoadStackInst
  %t13 = load i64, ptr %s0, align 8
  store i64 %t13, ptr %s14, align 8
  ; Hermes LIRGetArgumentsLengthInst
  call void @shllvm_args_length(ptr %s15, ptr %shr, ptr %frame, ptr %s14)
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s16, ptr %shr, i32 9, ptr %s13, ptr %s15)
  ; Hermes CondBranchInst
  %t14 = call i32 @shllvm_truthy(ptr %s16)
  %t15 = icmp ne i32 %t14, 0
  br i1 %t15, label %edge2, label %edge3
b2:
  ; Hermes PhiInst
  ; Hermes ReturnInst
  %t16 = load i64, ptr %s18, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t16
edge0:
  %t17 = load i64, ptr %s5, align 8
  %t18 = load i64, ptr %s5, align 8
  store i64 %t17, ptr %s9, align 8
  store i64 %t18, ptr %s10, align 8
  br label %b1
edge1:
  %t19 = load i64, ptr %s5, align 8
  store i64 %t19, ptr %s18, align 8
  br label %b2
edge2:
  %t20 = load i64, ptr %s13, align 8
  %t21 = load i64, ptr %s12, align 8
  store i64 %t20, ptr %s9, align 8
  store i64 %t21, ptr %s10, align 8
  br label %b1
edge3:
  %t22 = load i64, ptr %s12, align 8
  store i64 %t22, ptr %s18, align 8
  br label %b2
}

define internal i64 @shllvm_f3(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 12)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 12, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 11
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s10, i32 0, i64 0)
  br label %b0
b0:
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s10, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes StoreStackInst
  %t2 = load i64, ptr %s1, align 8
  store i64 %t2, ptr %s0, align 8
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s3, ptr %shr, ptr null, i32 1)
  ; Hermes LIRReifyArgumentsLooseInst
  call void @shllvm_args_reify(ptr %shr, ptr %frame, ptr %s0, i32 0)
  ; Hermes LoadStackInst
  %t3 = load i64, ptr %s0, align 8
  store i64 %t3, ptr %s5, align 8
  ; Hermes UnionNarrowTrustedInst
  %t4 = load i64, ptr %s5, align 8
  store i64 %t4, ptr %s6, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s6, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s8, ptr %shr, ptr %s3, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes ReturnInst
  %t5 = load i64, ptr %s8, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t5
}

define internal i64 @shllvm_f4(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 9)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 9, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 8
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_constant(ptr %s6, i32 3, i64 0)
  call void @shllvm_constant(ptr %s7, i32 3, i64 4607182418800017408)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s1, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s2, ptr %shr, ptr %s1, ptr %s6)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s3, ptr %shr, ptr %s1, ptr %s7)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s4, ptr %shr, i32 0, ptr %s2, ptr %s3)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s4, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 7, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 5, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
