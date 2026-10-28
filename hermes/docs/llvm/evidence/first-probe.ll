; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [48 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 115, i8 117, i8 109, i8 0, i8 102, i8 97, i8 99, i8 116, i8 111, i8 114, i8 105, i8 97, i8 108, i8 0, i8 99, i8 111, i8 117, i8 110, i8 116, i8 101, i8 114, i8 0, i8 110, i8 101, i8 120, i8 116, i8 0, i8 99, i8 117, i8 114, i8 114, i8 101, i8 110, i8 116, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [21 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 3, i32 3122771808, i32 11, i32 9, i32 3907606197, i32 21, i32 7, i32 3120126385, i32 29, i32 4, i32 3324119240, i32 34, i32 7, i32 2348315831, i32 42, i32 5, i32 2794059355]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [6 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 1, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 2, i32 1, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 3, i32 1, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 4, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 5, i32 0, i32 0, i32 2 }
]

declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_binary(ptr, ptr, i32, ptr, ptr)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_closure(ptr, ptr, ptr, ptr, ptr, i32)
declare void @shllvm_coerce_this(ptr, ptr, ptr)
declare void @shllvm_constant(ptr, i32, i64)
declare ptr @shllvm_create_unit(ptr, i32, ptr, ptr, ptr, i32, ptr, ptr, ptr)
declare void @shllvm_declare_global(ptr, ptr, i32)
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
declare void @shllvm_new_target(ptr, ptr)
declare void @shllvm_object(ptr, ptr)
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
  %t0 = call i64 @shllvm_frame_size(i32 68)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [5 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 68, i32 5, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 67
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s57, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_symbol(ptr %s58, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s59, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_constant(ptr %s60, i32 0, i64 0)
  call void @shllvm_constant(ptr %s61, i32 3, i64 4621819117588971520)
  call void @shllvm_constant(ptr %s62, i32 2, i64 0)
  call void @shllvm_symbol(ptr %s63, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_constant(ptr %s64, i32 3, i64 4618441417868443648)
  call void @shllvm_symbol(ptr %s65, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s66, ptr %shr, ptr %unit, i32 5)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 2)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 3)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s60, align 8
  store i64 %t1, ptr %s4, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s4, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s6, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s7, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s7, i32 1, ptr %s6, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s9, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s10, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s10, i32 2, ptr %s9, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s12, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s13, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s13, i32 3, ptr %s12, i32 0, i32 0)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s60, align 8
  store i64 %t2, ptr %s16, align 8
  ; Hermes StoreStackInst
  %t3 = load i64, ptr %s16, align 8
  store i64 %t3, ptr %s15, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s18, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s19, ptr %shr, ptr %unit, ptr %s18, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s60, align 8
  store i64 %t4, ptr %s20, align 8
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s60, align 8
  store i64 %t5, ptr %s21, align 8
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s61, align 8
  store i64 %t6, ptr %s22, align 8
  ; Hermes CallInst
  %t7 = getelementptr i64, ptr %argv, i32 0
  %t8 = load i64, ptr %s22, align 8
  store i64 %t8, ptr %t7, align 8
  call void @shllvm_call(ptr %s23, ptr %shr, ptr %frame, ptr %s19, ptr %s21, ptr %s20, i32 1, ptr %argv)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s23, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s25, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s26, ptr %shr, ptr %unit, ptr %s25, i32 6, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s27, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s28, ptr %shr, ptr %unit, ptr %s27, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s60, align 8
  store i64 %t9, ptr %s29, align 8
  ; Hermes LIRLoadConstInst
  %t10 = load i64, ptr %s60, align 8
  store i64 %t10, ptr %s30, align 8
  ; Hermes LIRLoadConstInst
  %t11 = load i64, ptr %s61, align 8
  store i64 %t11, ptr %s31, align 8
  ; Hermes CallInst
  %t12 = getelementptr i64, ptr %argv, i32 0
  %t13 = load i64, ptr %s31, align 8
  store i64 %t13, ptr %t12, align 8
  call void @shllvm_call(ptr %s32, ptr %shr, ptr %frame, ptr %s28, ptr %s30, ptr %s29, i32 1, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s33, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s34, ptr %shr, ptr %unit, ptr %s33, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t14 = load i64, ptr %s60, align 8
  store i64 %t14, ptr %s35, align 8
  ; Hermes LIRLoadConstInst
  %t15 = load i64, ptr %s60, align 8
  store i64 %t15, ptr %s36, align 8
  ; Hermes LIRLoadConstInst
  %t16 = load i64, ptr %s64, align 8
  store i64 %t16, ptr %s37, align 8
  ; Hermes CallInst
  %t17 = getelementptr i64, ptr %argv, i32 0
  %t18 = load i64, ptr %s37, align 8
  store i64 %t18, ptr %t17, align 8
  call void @shllvm_call(ptr %s38, ptr %shr, ptr %frame, ptr %s34, ptr %s36, ptr %s35, i32 1, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s39, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s40, ptr %shr, ptr %unit, ptr %s39, i32 4, i32 0)
  ; Hermes LIRLoadConstInst
  %t19 = load i64, ptr %s60, align 8
  store i64 %t19, ptr %s41, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s42, ptr %shr, ptr %frame, ptr %s40, ptr %s39, ptr %s41, i32 0, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s43, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s44, ptr %shr, ptr %unit, ptr %s43, i32 4, i32 0)
  ; Hermes LIRLoadConstInst
  %t20 = load i64, ptr %s60, align 8
  store i64 %t20, ptr %s45, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s46, ptr %shr, ptr %frame, ptr %s44, ptr %s43, ptr %s45, i32 0, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s47, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s48, ptr %shr, ptr %unit, ptr %s47, i32 5, i32 0)
  ; Hermes LIRLoadConstInst
  %t21 = load i64, ptr %s60, align 8
  store i64 %t21, ptr %s49, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s50, ptr %shr, ptr %frame, ptr %s48, ptr %s47, ptr %s49, i32 0, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t22 = load i64, ptr %s60, align 8
  store i64 %t22, ptr %s51, align 8
  ; Hermes LIRLoadConstInst
  %t23 = load i64, ptr %s60, align 8
  store i64 %t23, ptr %s52, align 8
  ; Hermes CallInst
  %t24 = getelementptr i64, ptr %argv, i32 0
  %t25 = load i64, ptr %s32, align 8
  store i64 %t25, ptr %t24, align 8
  %t26 = getelementptr i64, ptr %argv, i32 1
  %t27 = load i64, ptr %s38, align 8
  store i64 %t27, ptr %t26, align 8
  %t28 = getelementptr i64, ptr %argv, i32 2
  %t29 = load i64, ptr %s42, align 8
  store i64 %t29, ptr %t28, align 8
  %t30 = getelementptr i64, ptr %argv, i32 3
  %t31 = load i64, ptr %s46, align 8
  store i64 %t31, ptr %t30, align 8
  %t32 = getelementptr i64, ptr %argv, i32 4
  %t33 = load i64, ptr %s50, align 8
  store i64 %t33, ptr %t32, align 8
  call void @shllvm_call(ptr %s53, ptr %shr, ptr %frame, ptr %s26, ptr %s52, ptr %s51, i32 5, ptr %argv)
  ; Hermes StoreStackInst
  %t34 = load i64, ptr %s53, align 8
  store i64 %t34, ptr %s15, align 8
  ; Hermes LoadStackInst
  %t35 = load i64, ptr %s15, align 8
  store i64 %t35, ptr %s55, align 8
  ; Hermes ReturnInst
  %t36 = load i64, ptr %s55, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t36
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 35)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 35, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 34
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s32, i32 0, i64 0)
  call void @shllvm_constant(ptr %s33, i32 3, i64 0)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 3)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s2, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s2, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s32, align 8
  store i64 %t1, ptr %s4, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s4, i32 1)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s33, align 8
  store i64 %t2, ptr %s6, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s6, i32 1)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s32, align 8
  store i64 %t3, ptr %s8, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s8, i32 2)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s33, align 8
  store i64 %t4, ptr %s10, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s10, i32 2)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s12, ptr %s1, i32 2)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s13, ptr %s1, i32 0)
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s14, ptr %shr, i32 9, ptr %s12, ptr %s13)
  ; Hermes CondBranchInst
  %t5 = call i32 @shllvm_truthy(ptr %s14)
  %t6 = icmp ne i32 %t5, 0
  br i1 %t6, label %b1, label %b2
b1:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s16, ptr %s1, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s17, ptr %s1, i32 2)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s18, ptr %shr, i32 0, ptr %s16, ptr %s17)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s18, i32 1)
  ; Hermes BranchInst
  br label %b4
b2:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s21, ptr %s1, i32 1)
  ; Hermes ReturnInst
  %t7 = load i64, ptr %s21, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t7
b3:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s23, ptr %s1, i32 2)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s24, ptr %s1, i32 0)
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s25, ptr %shr, i32 9, ptr %s23, ptr %s24)
  ; Hermes CondBranchInst
  %t8 = call i32 @shllvm_truthy(ptr %s25)
  %t9 = icmp ne i32 %t8, 0
  br i1 %t9, label %b1, label %b2
b4:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s27, ptr %s1, i32 2)
  ; Hermes AsNumericInst
  call void @shllvm_unary(ptr %s28, ptr %shr, i32 7, ptr %s27)
  ; Hermes UnaryIncInst
  call void @shllvm_unary(ptr %s29, ptr %shr, i32 5, ptr %s28)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s29, i32 2)
  ; Hermes BranchInst
  br label %b3
}

define internal i64 @shllvm_f2(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 28)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 28, i32 1, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 27
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s22, i32 3, i64 4611686018427387904)
  call void @shllvm_constant(ptr %s23, i32 3, i64 4607182418800017408)
  call void @shllvm_symbol(ptr %s24, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s25, i32 0, i64 0)
  call void @shllvm_constant(ptr %s26, i32 2, i64 0)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 1)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s2, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s2, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s4, ptr %s1, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s22, align 8
  store i64 %t1, ptr %s5, align 8
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 9, ptr %s4, ptr %s5)
  ; Hermes CondBranchInst
  %t2 = call i32 @shllvm_truthy(ptr %s6)
  %t3 = icmp ne i32 %t2, 0
  br i1 %t3, label %b1, label %b2
b1:
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s23, align 8
  store i64 %t4, ptr %s8, align 8
  ; Hermes ReturnInst
  %t5 = load i64, ptr %s8, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t5
b2:
  ; Hermes BranchInst
  br label %b3
b3:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s11, ptr %s1, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s12, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s13, ptr %shr, ptr %unit, ptr %s12, i32 2, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s14, ptr %s1, i32 0)
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s23, align 8
  store i64 %t6, ptr %s15, align 8
  ; Hermes BinarySubtractInst
  call void @shllvm_binary(ptr %s16, ptr %shr, i32 1, ptr %s14, ptr %s15)
  ; Hermes LIRLoadConstInst
  %t7 = load i64, ptr %s25, align 8
  store i64 %t7, ptr %s17, align 8
  ; Hermes LIRLoadConstInst
  %t8 = load i64, ptr %s25, align 8
  store i64 %t8, ptr %s18, align 8
  ; Hermes CallInst
  %t9 = getelementptr i64, ptr %argv, i32 0
  %t10 = load i64, ptr %s16, align 8
  store i64 %t10, ptr %t9, align 8
  call void @shllvm_call(ptr %s19, ptr %shr, ptr %frame, ptr %s13, ptr %s18, ptr %s17, i32 1, ptr %argv)
  ; Hermes BinaryMultiplyInst
  call void @shllvm_binary(ptr %s20, ptr %shr, i32 2, ptr %s11, ptr %s19)
  ; Hermes ReturnInst
  %t11 = load i64, ptr %s20, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t11
}

define internal i64 @shllvm_f3(ptr %shr) {
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
  call void @shllvm_constant(ptr %s19, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s20, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_constant(ptr %s21, i32 2, i64 1)
  call void @shllvm_symbol(ptr %s22, ptr %shr, ptr %unit, i32 5)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s2, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s3, ptr %shr, ptr %s2, i32 4)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s1, i32 3)
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s5, ptr %frame)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s5, i32 2)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s7, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s7, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s19, align 8
  store i64 %t1, ptr %s9, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s9, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s11, ptr %s3, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s11, i32 0)
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s13, ptr %shr)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s14, ptr %shr, ptr %s3, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s13, ptr %s20, ptr %s14, i32 1)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s16, ptr %shr, ptr %s3, ptr %unit, ptr @shllvm_f5, i32 5)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s13, ptr %s22, ptr %s16, i32 1)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s13, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f4(ptr %shr) {
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
  call void @shllvm_constant(ptr %s8, i32 3, i64 4607182418800017408)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s2, ptr %s0, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s8, align 8
  store i64 %t1, ptr %s3, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s4, ptr %shr, i32 0, ptr %s2, ptr %s3)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s4, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s6, ptr %s0, i32 0)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s6, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f5(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 5)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 5, i32 0, i32 %unit_index)
  %roots = call ptr @shllvm_roots(ptr %storage)
  %unit = call ptr @shllvm_get_unit(ptr %shr, i32 %unit_index)
  %s0 = getelementptr i64, ptr %roots, i32 0
  %s1 = getelementptr i64, ptr %roots, i32 1
  %s2 = getelementptr i64, ptr %roots, i32 2
  %s3 = getelementptr i64, ptr %roots, i32 3
  %scratch = getelementptr i64, ptr %roots, i32 4
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s2, ptr %s0, i32 0)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s2, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 7, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 6, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
