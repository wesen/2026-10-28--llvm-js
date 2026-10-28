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
declare void @shllvm_coerce_this(ptr, ptr, ptr)
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
declare void @shllvm_new_target(ptr, ptr)
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
  %t0 = call i64 @shllvm_frame_size(i32 69)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [5 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 69, i32 5, i32 %unit_index)
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
  %s54 = getelementptr i64, ptr %roots, i32 54
  %s55 = getelementptr i64, ptr %roots, i32 55
  %s56 = getelementptr i64, ptr %roots, i32 56
  %s57 = getelementptr i64, ptr %roots, i32 57
  %s58 = getelementptr i64, ptr %roots, i32 58
  %s59 = getelementptr i64, ptr %roots, i32 59
  %s60 = getelementptr i64, ptr %roots, i32 60
  %s61 = getelementptr i64, ptr %roots, i32 61
  %s62 = getelementptr i64, ptr %roots, i32 62
  %s63 = getelementptr i64, ptr %roots, i32 63
  %s64 = getelementptr i64, ptr %roots, i32 64
  %s65 = getelementptr i64, ptr %roots, i32 65
  %s66 = getelementptr i64, ptr %roots, i32 66
  %s67 = getelementptr i64, ptr %roots, i32 67
  %scratch = getelementptr i64, ptr %roots, i32 68
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s52, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_symbol(ptr %s53, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s54, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_constant(ptr %s55, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s56, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_constant(ptr %s57, i32 3, i64 4619567317775286272)
  call void @shllvm_constant(ptr %s58, i32 3, i64 4620693217682128896)
  call void @shllvm_constant(ptr %s59, i32 3, i64 4621256167635550208)
  call void @shllvm_constant(ptr %s60, i32 2, i64 0)
  call void @shllvm_constant(ptr %s61, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s62, i32 3, i64 4611686018427387904)
  call void @shllvm_constant(ptr %s63, i32 3, i64 4613937818241073152)
  call void @shllvm_constant(ptr %s64, i32 3, i64 4616189618054758400)
  call void @shllvm_constant(ptr %s65, i32 3, i64 4629700416936869888)
  call void @shllvm_constant(ptr %s66, i32 3, i64 4626041242239631360)
  call void @shllvm_constant(ptr %s67, i32 3, i64 4627167142146473984)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 0)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 2)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 3)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s4, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s5, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s5, i32 1, ptr %s4, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s7, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s8, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s8, i32 2, ptr %s7, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s10, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s11, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s11, i32 3, ptr %s10, i32 0, i32 0)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s55, align 8
  store i64 %t1, ptr %s14, align 8
  ; Hermes StoreStackInst
  %t2 = load i64, ptr %s14, align 8
  store i64 %t2, ptr %s13, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s16, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s17, ptr %shr, ptr %unit, ptr %s16, i32 5, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s18, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s19, ptr %shr, ptr %unit, ptr %s18, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s55, align 8
  store i64 %t3, ptr %s20, align 8
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s55, align 8
  store i64 %t4, ptr %s21, align 8
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s57, align 8
  store i64 %t5, ptr %s22, align 8
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s58, align 8
  store i64 %t6, ptr %s23, align 8
  ; Hermes LIRLoadConstInst
  %t7 = load i64, ptr %s59, align 8
  store i64 %t7, ptr %s24, align 8
  ; Hermes CallInst
  %t8 = getelementptr i64, ptr %argv, i32 0
  %t9 = load i64, ptr %s22, align 8
  store i64 %t9, ptr %t8, align 8
  %t10 = getelementptr i64, ptr %argv, i32 1
  %t11 = load i64, ptr %s23, align 8
  store i64 %t11, ptr %t10, align 8
  %t12 = getelementptr i64, ptr %argv, i32 2
  %t13 = load i64, ptr %s24, align 8
  store i64 %t13, ptr %t12, align 8
  call void @shllvm_call(ptr %s25, ptr %shr, ptr %frame, ptr %s19, ptr %s21, ptr %s20, i32 3, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s26, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s27, ptr %shr, ptr %unit, ptr %s26, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t14 = load i64, ptr %s55, align 8
  store i64 %t14, ptr %s28, align 8
  ; Hermes LIRLoadConstInst
  %t15 = load i64, ptr %s55, align 8
  store i64 %t15, ptr %s29, align 8
  ; Hermes LIRLoadConstInst
  %t16 = load i64, ptr %s61, align 8
  store i64 %t16, ptr %s30, align 8
  ; Hermes LIRLoadConstInst
  %t17 = load i64, ptr %s62, align 8
  store i64 %t17, ptr %s31, align 8
  ; Hermes LIRLoadConstInst
  %t18 = load i64, ptr %s63, align 8
  store i64 %t18, ptr %s32, align 8
  ; Hermes LIRLoadConstInst
  %t19 = load i64, ptr %s64, align 8
  store i64 %t19, ptr %s33, align 8
  ; Hermes LIRLoadConstInst
  %t20 = load i64, ptr %s65, align 8
  store i64 %t20, ptr %s34, align 8
  ; Hermes CallInst
  %t21 = getelementptr i64, ptr %argv, i32 0
  %t22 = load i64, ptr %s30, align 8
  store i64 %t22, ptr %t21, align 8
  %t23 = getelementptr i64, ptr %argv, i32 1
  %t24 = load i64, ptr %s31, align 8
  store i64 %t24, ptr %t23, align 8
  %t25 = getelementptr i64, ptr %argv, i32 2
  %t26 = load i64, ptr %s32, align 8
  store i64 %t26, ptr %t25, align 8
  %t27 = getelementptr i64, ptr %argv, i32 3
  %t28 = load i64, ptr %s33, align 8
  store i64 %t28, ptr %t27, align 8
  %t29 = getelementptr i64, ptr %argv, i32 4
  %t30 = load i64, ptr %s34, align 8
  store i64 %t30, ptr %t29, align 8
  call void @shllvm_call(ptr %s35, ptr %shr, ptr %frame, ptr %s27, ptr %s29, ptr %s28, i32 5, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s36, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s37, ptr %shr, ptr %unit, ptr %s36, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t31 = load i64, ptr %s55, align 8
  store i64 %t31, ptr %s38, align 8
  ; Hermes LIRLoadConstInst
  %t32 = load i64, ptr %s55, align 8
  store i64 %t32, ptr %s39, align 8
  ; Hermes LIRLoadConstInst
  %t33 = load i64, ptr %s66, align 8
  store i64 %t33, ptr %s40, align 8
  ; Hermes LIRLoadConstInst
  %t34 = load i64, ptr %s67, align 8
  store i64 %t34, ptr %s41, align 8
  ; Hermes CallInst
  %t35 = getelementptr i64, ptr %argv, i32 0
  %t36 = load i64, ptr %s40, align 8
  store i64 %t36, ptr %t35, align 8
  %t37 = getelementptr i64, ptr %argv, i32 1
  %t38 = load i64, ptr %s41, align 8
  store i64 %t38, ptr %t37, align 8
  call void @shllvm_call(ptr %s42, ptr %shr, ptr %frame, ptr %s37, ptr %s39, ptr %s38, i32 2, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t39 = load i64, ptr %s55, align 8
  store i64 %t39, ptr %s43, align 8
  ; Hermes LIRLoadConstInst
  %t40 = load i64, ptr %s55, align 8
  store i64 %t40, ptr %s44, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s45, ptr %shr, ptr %frame, ptr %s42, ptr %s44, ptr %s43, i32 0, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t41 = load i64, ptr %s55, align 8
  store i64 %t41, ptr %s46, align 8
  ; Hermes LIRLoadConstInst
  %t42 = load i64, ptr %s55, align 8
  store i64 %t42, ptr %s47, align 8
  ; Hermes CallInst
  %t43 = getelementptr i64, ptr %argv, i32 0
  %t44 = load i64, ptr %s25, align 8
  store i64 %t44, ptr %t43, align 8
  %t45 = getelementptr i64, ptr %argv, i32 1
  %t46 = load i64, ptr %s35, align 8
  store i64 %t46, ptr %t45, align 8
  %t47 = getelementptr i64, ptr %argv, i32 2
  %t48 = load i64, ptr %s45, align 8
  store i64 %t48, ptr %t47, align 8
  call void @shllvm_call(ptr %s48, ptr %shr, ptr %frame, ptr %s17, ptr %s47, ptr %s46, i32 3, ptr %argv)
  ; Hermes StoreStackInst
  %t49 = load i64, ptr %s48, align 8
  store i64 %t49, ptr %s13, align 8
  ; Hermes LoadStackInst
  %t50 = load i64, ptr %s13, align 8
  store i64 %t50, ptr %s50, align 8
  ; Hermes ReturnInst
  %t51 = load i64, ptr %s50, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t51
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 27)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 27, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 26
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s22, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s23, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_constant(ptr %s24, i32 3, i64 0)
  call void @shllvm_constant(ptr %s25, i32 3, i64 4611686018427387904)
  br label %b0
b0:
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s22, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes StoreStackInst
  %t2 = load i64, ptr %s1, align 8
  store i64 %t2, ptr %s0, align 8
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s3, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s4, ptr %shr, ptr %s3, i32 2)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s5, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s4, ptr %s5, i32 0)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s7, ptr %frame, i32 2)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s4, ptr %s7, i32 1)
  ; Hermes LoadStackInst
  %t3 = load i64, ptr %s0, align 8
  store i64 %t3, ptr %s9, align 8
  ; Hermes LIRGetArgumentsLengthInst
  call void @shllvm_args_length(ptr %s10, ptr %shr, ptr %frame, ptr %s9)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s23, align 8
  store i64 %t4, ptr %s11, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s12, ptr %shr, i32 0, ptr %s10, ptr %s11)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s24, align 8
  store i64 %t5, ptr %s13, align 8
  ; Hermes LIRGetArgumentsPropByValLooseInst
  call void @shllvm_args_get(ptr %s14, ptr %shr, ptr %frame, ptr %s13, ptr %s0, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s15, ptr %shr, i32 0, ptr %s12, ptr %s14)
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s23, align 8
  store i64 %t6, ptr %s16, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s17, ptr %shr, i32 0, ptr %s15, ptr %s16)
  ; Hermes LIRLoadConstInst
  %t7 = load i64, ptr %s25, align 8
  store i64 %t7, ptr %s18, align 8
  ; Hermes LIRGetArgumentsPropByValLooseInst
  call void @shllvm_args_get(ptr %s19, ptr %shr, ptr %frame, ptr %s18, ptr %s0, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s20, ptr %shr, i32 0, ptr %s17, ptr %s19)
  ; Hermes ReturnInst
  %t8 = load i64, ptr %s20, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t8
}

define internal i64 @shllvm_f2(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 38)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 38, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 37
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s35, i32 0, i64 0)
  call void @shllvm_constant(ptr %s36, i32 3, i64 0)
  br label %b0
b0:
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s35, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes StoreStackInst
  %t2 = load i64, ptr %s1, align 8
  store i64 %t2, ptr %s0, align 8
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s3, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s4, ptr %shr, ptr %s3, i32 2)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s35, align 8
  store i64 %t3, ptr %s5, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s4, ptr %s5, i32 0)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s36, align 8
  store i64 %t4, ptr %s7, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s4, ptr %s7, i32 0)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s35, align 8
  store i64 %t5, ptr %s9, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s4, ptr %s9, i32 1)
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s36, align 8
  store i64 %t6, ptr %s11, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s4, ptr %s11, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s13, ptr %s4, i32 1)
  ; Hermes LoadStackInst
  %t7 = load i64, ptr %s0, align 8
  store i64 %t7, ptr %s14, align 8
  ; Hermes LIRGetArgumentsLengthInst
  call void @shllvm_args_length(ptr %s15, ptr %shr, ptr %frame, ptr %s14)
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s16, ptr %shr, i32 9, ptr %s13, ptr %s15)
  ; Hermes CondBranchInst
  %t8 = call i32 @shllvm_truthy(ptr %s16)
  %t9 = icmp ne i32 %t8, 0
  br i1 %t9, label %b1, label %b2
b1:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s18, ptr %s4, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s19, ptr %s4, i32 1)
  ; Hermes LIRGetArgumentsPropByValLooseInst
  call void @shllvm_args_get(ptr %s20, ptr %shr, ptr %frame, ptr %s19, ptr %s0, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s21, ptr %shr, i32 0, ptr %s18, ptr %s20)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s4, ptr %s21, i32 0)
  ; Hermes BranchInst
  br label %b4
b2:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s24, ptr %s4, i32 0)
  ; Hermes ReturnInst
  %t10 = load i64, ptr %s24, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t10
b3:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s26, ptr %s4, i32 1)
  ; Hermes LoadStackInst
  %t11 = load i64, ptr %s0, align 8
  store i64 %t11, ptr %s27, align 8
  ; Hermes LIRGetArgumentsLengthInst
  call void @shllvm_args_length(ptr %s28, ptr %shr, ptr %frame, ptr %s27)
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s29, ptr %shr, i32 9, ptr %s26, ptr %s28)
  ; Hermes CondBranchInst
  %t12 = call i32 @shllvm_truthy(ptr %s29)
  %t13 = icmp ne i32 %t12, 0
  br i1 %t13, label %b1, label %b2
b4:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s31, ptr %s4, i32 1)
  ; Hermes UnaryIncInst
  call void @shllvm_unary(ptr %s32, ptr %shr, i32 5, ptr %s31)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s4, ptr %s32, i32 1)
  ; Hermes BranchInst
  br label %b3
}

define internal i64 @shllvm_f3(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 18)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 18, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 17
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s16, i32 0, i64 0)
  br label %b0
b0:
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s16, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes StoreStackInst
  %t2 = load i64, ptr %s1, align 8
  store i64 %t2, ptr %s0, align 8
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s3, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s4, ptr %shr, ptr %s3)
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s5, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s6, ptr %shr, ptr %s5, i32 3)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s6, ptr %s4, i32 0)
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s8, ptr %frame)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s6, ptr %s8, i32 1)
  ; Hermes LIRReifyArgumentsLooseInst
  call void @shllvm_args_reify(ptr %shr, ptr %frame, ptr %s0, i32 0)
  ; Hermes LoadStackInst
  %t3 = load i64, ptr %s0, align 8
  store i64 %t3, ptr %s11, align 8
  ; Hermes UnionNarrowTrustedInst
  %t4 = load i64, ptr %s11, align 8
  store i64 %t4, ptr %s12, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s6, ptr %s12, i32 2)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s14, ptr %shr, ptr %s6, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes ReturnInst
  %t5 = load i64, ptr %s14, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t5
}

define internal i64 @shllvm_f4(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 11)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 11, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 10
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_constant(ptr %s8, i32 3, i64 0)
  call void @shllvm_constant(ptr %s9, i32 3, i64 4607182418800017408)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s2, ptr %s0, i32 2)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s3, ptr %shr, ptr %s2, ptr %s8)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s4, ptr %s0, i32 2)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s5, ptr %shr, ptr %s4, ptr %s9)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 0, ptr %s3, ptr %s5)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s6, align 8
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
