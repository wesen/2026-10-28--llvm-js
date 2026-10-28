; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [36 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 118, i8 97, i8 108, i8 117, i8 101, i8 79, i8 102, i8 0, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 118, i8 97, i8 108, i8 117, i8 101, i8 61, i8 0, i8 52, i8 50, i8 0, i8 97, i8 0, i8 98, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [24 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 7, i32 4132478529, i32 15, i32 0, i32 0, i32 16, i32 5, i32 2794059355, i32 22, i32 6, i32 544573503, i32 29, i32 2, i32 54679048, i32 32, i32 1, i32 98928, i32 34, i32 1, i32 101955]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [4 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 1, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 2, i32 0, i32 0, i32 1 }
]

declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_binary(ptr, ptr, i32, ptr, ptr)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_closure(ptr, ptr, ptr, ptr, ptr, i32)
declare void @shllvm_coerce_this(ptr, ptr, ptr)
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
declare void @shllvm_new_target(ptr, ptr)
declare void @shllvm_object(ptr, ptr)
declare void @shllvm_param(ptr, ptr, i32)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)
declare void @shllvm_unary(ptr, ptr, i32, ptr)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 103)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [4 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 103, i32 4, i32 %unit_index)
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
  %s68 = getelementptr i64, ptr %roots, i32 68
  %s69 = getelementptr i64, ptr %roots, i32 69
  %s70 = getelementptr i64, ptr %roots, i32 70
  %s71 = getelementptr i64, ptr %roots, i32 71
  %s72 = getelementptr i64, ptr %roots, i32 72
  %s73 = getelementptr i64, ptr %roots, i32 73
  %s74 = getelementptr i64, ptr %roots, i32 74
  %s75 = getelementptr i64, ptr %roots, i32 75
  %s76 = getelementptr i64, ptr %roots, i32 76
  %s77 = getelementptr i64, ptr %roots, i32 77
  %s78 = getelementptr i64, ptr %roots, i32 78
  %s79 = getelementptr i64, ptr %roots, i32 79
  %s80 = getelementptr i64, ptr %roots, i32 80
  %s81 = getelementptr i64, ptr %roots, i32 81
  %s82 = getelementptr i64, ptr %roots, i32 82
  %s83 = getelementptr i64, ptr %roots, i32 83
  %s84 = getelementptr i64, ptr %roots, i32 84
  %s85 = getelementptr i64, ptr %roots, i32 85
  %s86 = getelementptr i64, ptr %roots, i32 86
  %s87 = getelementptr i64, ptr %roots, i32 87
  %s88 = getelementptr i64, ptr %roots, i32 88
  %s89 = getelementptr i64, ptr %roots, i32 89
  %s90 = getelementptr i64, ptr %roots, i32 90
  %s91 = getelementptr i64, ptr %roots, i32 91
  %s92 = getelementptr i64, ptr %roots, i32 92
  %s93 = getelementptr i64, ptr %roots, i32 93
  %s94 = getelementptr i64, ptr %roots, i32 94
  %s95 = getelementptr i64, ptr %roots, i32 95
  %s96 = getelementptr i64, ptr %roots, i32 96
  %s97 = getelementptr i64, ptr %roots, i32 97
  %s98 = getelementptr i64, ptr %roots, i32 98
  %s99 = getelementptr i64, ptr %roots, i32 99
  %s100 = getelementptr i64, ptr %roots, i32 100
  %s101 = getelementptr i64, ptr %roots, i32 101
  %scratch = getelementptr i64, ptr %roots, i32 102
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s88, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s89, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s90, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_constant(ptr %s91, i32 2, i64 1)
  call void @shllvm_symbol(ptr %s92, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s93, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_constant(ptr %s94, i32 2, i64 0)
  call void @shllvm_constant(ptr %s95, i32 1, i64 0)
  call void @shllvm_symbol(ptr %s96, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_constant(ptr %s97, i32 3, i64 4631107791820423168)
  call void @shllvm_constant(ptr %s98, i32 3, i64 18444492273895866368)
  call void @shllvm_constant(ptr %s99, i32 3, i64 18442240474082181120)
  call void @shllvm_constant(ptr %s100, i32 3, i64 4751297606873776128)
  call void @shllvm_constant(ptr %s101, i32 3, i64 4746794007244308480)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s2, ptr %shr, ptr null, i32 7)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s1, i32 4)
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s4, ptr %frame)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s4, i32 3)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s88, align 8
  store i64 %t1, ptr %s6, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s6, i32 2)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s88, align 8
  store i64 %t2, ptr %s8, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s8, i32 1)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s88, align 8
  store i64 %t3, ptr %s10, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s10, i32 0)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s88, align 8
  store i64 %t4, ptr %s13, align 8
  ; Hermes StoreStackInst
  %t5 = load i64, ptr %s13, align 8
  store i64 %t5, ptr %s12, align 8
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s89, align 8
  store i64 %t6, ptr %s15, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s15, i32 2)
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s17, ptr %shr)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s17, i32 5)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s19, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s17, ptr %s90, ptr %s19, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s17, i32 1)
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s22, ptr %shr)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s22, i32 6)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s24, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s22, ptr %s90, ptr %s24, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s22, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s27, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s28, ptr %shr, ptr %unit, ptr %s27, i32 3, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s29, ptr %s2, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s30, ptr %s2, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s31, ptr %shr, i32 0, ptr %s29, ptr %s30)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s32, ptr %s2, i32 2)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s33, ptr %s2, i32 1)
  ; Hermes LIRLoadConstInst
  %t7 = load i64, ptr %s93, align 8
  store i64 %t7, ptr %s34, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s35, ptr %shr, i32 0, ptr %s34, ptr %s33)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s36, ptr %s2, i32 0)
  ; Hermes AsNumberInst
  call void @shllvm_unary(ptr %s37, ptr %shr, i32 1, ptr %s36)
  ; Hermes LIRLoadConstInst
  %t8 = load i64, ptr %s88, align 8
  store i64 %t8, ptr %s38, align 8
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s88, align 8
  store i64 %t9, ptr %s39, align 8
  ; Hermes CallInst
  %t10 = getelementptr i64, ptr %argv, i32 0
  %t11 = load i64, ptr %s31, align 8
  store i64 %t11, ptr %t10, align 8
  %t12 = getelementptr i64, ptr %argv, i32 1
  %t13 = load i64, ptr %s32, align 8
  store i64 %t13, ptr %t12, align 8
  %t14 = getelementptr i64, ptr %argv, i32 2
  %t15 = load i64, ptr %s35, align 8
  store i64 %t15, ptr %t14, align 8
  %t16 = getelementptr i64, ptr %argv, i32 3
  %t17 = load i64, ptr %s37, align 8
  store i64 %t17, ptr %t16, align 8
  call void @shllvm_call(ptr %s40, ptr %shr, ptr %frame, ptr %s28, ptr %s39, ptr %s38, i32 4, ptr %argv)
  ; Hermes StoreStackInst
  %t18 = load i64, ptr %s40, align 8
  store i64 %t18, ptr %s12, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s42, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s43, ptr %shr, ptr %unit, ptr %s42, i32 3, i32 1)
  ; Hermes LIRLoadConstInst
  %t19 = load i64, ptr %s95, align 8
  store i64 %t19, ptr %s44, align 8
  ; Hermes LIRLoadConstInst
  %t20 = load i64, ptr %s88, align 8
  store i64 %t20, ptr %s45, align 8
  ; Hermes BinaryEqualInst
  call void @shllvm_binary(ptr %s46, ptr %shr, i32 5, ptr %s44, ptr %s45)
  ; Hermes LIRLoadConstInst
  %t21 = load i64, ptr %s95, align 8
  store i64 %t21, ptr %s47, align 8
  ; Hermes LIRLoadConstInst
  %t22 = load i64, ptr %s88, align 8
  store i64 %t22, ptr %s48, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s49, ptr %shr, i32 7, ptr %s47, ptr %s48)
  ; Hermes LIRLoadConstInst
  %t23 = load i64, ptr %s96, align 8
  store i64 %t23, ptr %s50, align 8
  ; Hermes LIRLoadConstInst
  %t24 = load i64, ptr %s97, align 8
  store i64 %t24, ptr %s51, align 8
  ; Hermes BinaryEqualInst
  call void @shllvm_binary(ptr %s52, ptr %shr, i32 5, ptr %s50, ptr %s51)
  ; Hermes LIRLoadConstInst
  %t25 = load i64, ptr %s96, align 8
  store i64 %t25, ptr %s53, align 8
  ; Hermes LIRLoadConstInst
  %t26 = load i64, ptr %s97, align 8
  store i64 %t26, ptr %s54, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s55, ptr %shr, i32 7, ptr %s53, ptr %s54)
  ; Hermes LIRLoadConstInst
  %t27 = load i64, ptr %s88, align 8
  store i64 %t27, ptr %s56, align 8
  ; Hermes LIRLoadConstInst
  %t28 = load i64, ptr %s88, align 8
  store i64 %t28, ptr %s57, align 8
  ; Hermes CallInst
  %t29 = getelementptr i64, ptr %argv, i32 0
  %t30 = load i64, ptr %s46, align 8
  store i64 %t30, ptr %t29, align 8
  %t31 = getelementptr i64, ptr %argv, i32 1
  %t32 = load i64, ptr %s49, align 8
  store i64 %t32, ptr %t31, align 8
  %t33 = getelementptr i64, ptr %argv, i32 2
  %t34 = load i64, ptr %s52, align 8
  store i64 %t34, ptr %t33, align 8
  %t35 = getelementptr i64, ptr %argv, i32 3
  %t36 = load i64, ptr %s55, align 8
  store i64 %t36, ptr %t35, align 8
  call void @shllvm_call(ptr %s58, ptr %shr, ptr %frame, ptr %s43, ptr %s57, ptr %s56, i32 4, ptr %argv)
  ; Hermes StoreStackInst
  %t37 = load i64, ptr %s58, align 8
  store i64 %t37, ptr %s12, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s60, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s61, ptr %shr, ptr %unit, ptr %s60, i32 3, i32 1)
  ; Hermes LIRLoadConstInst
  %t38 = load i64, ptr %s98, align 8
  store i64 %t38, ptr %s62, align 8
  ; Hermes LIRLoadConstInst
  %t39 = load i64, ptr %s98, align 8
  store i64 %t39, ptr %s63, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s64, ptr %shr, i32 7, ptr %s62, ptr %s63)
  ; Hermes LIRLoadConstInst
  %t40 = load i64, ptr %s88, align 8
  store i64 %t40, ptr %s65, align 8
  ; Hermes LIRLoadConstInst
  %t41 = load i64, ptr %s88, align 8
  store i64 %t41, ptr %s66, align 8
  ; Hermes LIRLoadConstInst
  %t42 = load i64, ptr %s99, align 8
  store i64 %t42, ptr %s67, align 8
  ; Hermes LIRLoadConstInst
  %t43 = load i64, ptr %s100, align 8
  store i64 %t43, ptr %s68, align 8
  ; Hermes LIRLoadConstInst
  %t44 = load i64, ptr %s101, align 8
  store i64 %t44, ptr %s69, align 8
  ; Hermes CallInst
  %t45 = getelementptr i64, ptr %argv, i32 0
  %t46 = load i64, ptr %s67, align 8
  store i64 %t46, ptr %t45, align 8
  %t47 = getelementptr i64, ptr %argv, i32 1
  %t48 = load i64, ptr %s64, align 8
  store i64 %t48, ptr %t47, align 8
  %t49 = getelementptr i64, ptr %argv, i32 2
  %t50 = load i64, ptr %s68, align 8
  store i64 %t50, ptr %t49, align 8
  %t51 = getelementptr i64, ptr %argv, i32 3
  %t52 = load i64, ptr %s69, align 8
  store i64 %t52, ptr %t51, align 8
  call void @shllvm_call(ptr %s70, ptr %shr, ptr %frame, ptr %s61, ptr %s66, ptr %s65, i32 4, ptr %argv)
  ; Hermes StoreStackInst
  %t53 = load i64, ptr %s70, align 8
  store i64 %t53, ptr %s12, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s72, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s73, ptr %shr, ptr %unit, ptr %s72, i32 3, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s74, ptr %s2, i32 1)
  ; Hermes TypeOfInst
  call void @shllvm_unary(ptr %s75, ptr %shr, i32 4, ptr %s74)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s76, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes TypeOfInst
  call void @shllvm_unary(ptr %s77, ptr %shr, i32 4, ptr %s76)
  ; Hermes LIRLoadConstInst
  %t54 = load i64, ptr %s88, align 8
  store i64 %t54, ptr %s78, align 8
  ; Hermes TypeOfInst
  call void @shllvm_unary(ptr %s79, ptr %shr, i32 4, ptr %s78)
  ; Hermes LIRLoadConstInst
  %t55 = load i64, ptr %s95, align 8
  store i64 %t55, ptr %s80, align 8
  ; Hermes TypeOfInst
  call void @shllvm_unary(ptr %s81, ptr %shr, i32 4, ptr %s80)
  ; Hermes LIRLoadConstInst
  %t56 = load i64, ptr %s88, align 8
  store i64 %t56, ptr %s82, align 8
  ; Hermes LIRLoadConstInst
  %t57 = load i64, ptr %s88, align 8
  store i64 %t57, ptr %s83, align 8
  ; Hermes CallInst
  %t58 = getelementptr i64, ptr %argv, i32 0
  %t59 = load i64, ptr %s75, align 8
  store i64 %t59, ptr %t58, align 8
  %t60 = getelementptr i64, ptr %argv, i32 1
  %t61 = load i64, ptr %s77, align 8
  store i64 %t61, ptr %t60, align 8
  %t62 = getelementptr i64, ptr %argv, i32 2
  %t63 = load i64, ptr %s79, align 8
  store i64 %t63, ptr %t62, align 8
  %t64 = getelementptr i64, ptr %argv, i32 3
  %t65 = load i64, ptr %s81, align 8
  store i64 %t65, ptr %t64, align 8
  call void @shllvm_call(ptr %s84, ptr %shr, ptr %frame, ptr %s73, ptr %s83, ptr %s82, i32 4, ptr %argv)
  ; Hermes StoreStackInst
  %t66 = load i64, ptr %s84, align 8
  store i64 %t66, ptr %s12, align 8
  ; Hermes LoadStackInst
  %t67 = load i64, ptr %s12, align 8
  store i64 %t67, ptr %s86, align 8
  ; Hermes ReturnInst
  %t68 = load i64, ptr %s86, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t68
}

define internal i64 @shllvm_f1(ptr %shr) {
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
  call void @shllvm_symbol(ptr %s8, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_constant(ptr %s9, i32 3, i64 4621819117588971520)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s2, ptr %s0, i32 2)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s8, align 8
  store i64 %t1, ptr %s3, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s4, ptr %shr, i32 0, ptr %s2, ptr %s3)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s4, i32 2)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s9, align 8
  store i64 %t2, ptr %s6, align 8
  ; Hermes ReturnInst
  %t3 = load i64, ptr %s6, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t3
}

define internal i64 @shllvm_f2(ptr %shr) {
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
  call void @shllvm_symbol(ptr %s8, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_constant(ptr %s9, i32 3, i64 4629700416936869888)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s2, ptr %s0, i32 2)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s8, align 8
  store i64 %t1, ptr %s3, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s4, ptr %shr, i32 0, ptr %s2, ptr %s3)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s4, i32 2)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s9, align 8
  store i64 %t2, ptr %s6, align 8
  ; Hermes ReturnInst
  %t3 = load i64, ptr %s6, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t3
}

define internal i64 @shllvm_f3(ptr %shr) {
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
  call void @shllvm_constant(ptr %s4, i32 3, i64 4607182418800017408)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s4, align 8
  store i64 %t1, ptr %s2, align 8
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s2, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 8, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 4, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
