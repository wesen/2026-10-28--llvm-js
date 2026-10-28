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
declare void @shllvm_unary(ptr, ptr, i32, ptr)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 105)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [4 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 105, i32 4, i32 %unit_index)
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
  %s102 = getelementptr i64, ptr %roots, i32 102
  %s103 = getelementptr i64, ptr %roots, i32 103
  %scratch = getelementptr i64, ptr %roots, i32 104
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s92, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_symbol(ptr %s93, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s94, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s95, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s96, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_constant(ptr %s97, i32 3, i64 4626322717216342016)
  call void @shllvm_constant(ptr %s98, i32 2, i64 0)
  call void @shllvm_constant(ptr %s99, i32 3, i64 0)
  call void @shllvm_constant(ptr %s100, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s101, i32 2, i64 1)
  call void @shllvm_constant(ptr %s102, i32 3, i64 4611686018427387904)
  call void @shllvm_constant(ptr %s103, i32 3, i64 4631107791820423168)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 2)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s94, align 8
  store i64 %t1, ptr %s3, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s3, i32 0)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 3)
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
  %t2 = load i64, ptr %s94, align 8
  store i64 %t2, ptr %s16, align 8
  ; Hermes StoreStackInst
  %t3 = load i64, ptr %s16, align 8
  store i64 %t3, ptr %s15, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s18, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s19, ptr %shr, ptr %unit, ptr %s18, i32 4, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s20, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s21, ptr %shr, ptr %unit, ptr %s20, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s94, align 8
  store i64 %t4, ptr %s22, align 8
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s94, align 8
  store i64 %t5, ptr %s23, align 8
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s97, align 8
  store i64 %t6, ptr %s24, align 8
  ; Hermes CallInst
  %t7 = getelementptr i64, ptr %argv, i32 0
  %t8 = load i64, ptr %s24, align 8
  store i64 %t8, ptr %t7, align 8
  call void @shllvm_call(ptr %s25, ptr %shr, ptr %frame, ptr %s21, ptr %s23, ptr %s22, i32 1, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s26, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s27, ptr %shr, ptr %unit, ptr %s26, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s94, align 8
  store i64 %t9, ptr %s28, align 8
  ; Hermes LIRLoadConstInst
  %t10 = load i64, ptr %s94, align 8
  store i64 %t10, ptr %s29, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s30, ptr %shr, ptr %frame, ptr %s27, ptr %s29, ptr %s28, i32 0, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t11 = load i64, ptr %s94, align 8
  store i64 %t11, ptr %s31, align 8
  ; Hermes LIRLoadConstInst
  %t12 = load i64, ptr %s94, align 8
  store i64 %t12, ptr %s32, align 8
  ; Hermes CallInst
  %t13 = getelementptr i64, ptr %argv, i32 0
  %t14 = load i64, ptr %s25, align 8
  store i64 %t14, ptr %t13, align 8
  %t15 = getelementptr i64, ptr %argv, i32 1
  %t16 = load i64, ptr %s30, align 8
  store i64 %t16, ptr %t15, align 8
  call void @shllvm_call(ptr %s33, ptr %shr, ptr %frame, ptr %s19, ptr %s32, ptr %s31, i32 2, ptr %argv)
  ; Hermes StoreStackInst
  %t17 = load i64, ptr %s33, align 8
  store i64 %t17, ptr %s15, align 8
  ; Hermes LIRLoadConstInst
  %t18 = load i64, ptr %s99, align 8
  store i64 %t18, ptr %s35, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s35, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s37, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s38, ptr %shr, ptr %unit, ptr %s37, i32 4, i32 1)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t19 = load i64, ptr %s98, align 8
  store i64 %t19, ptr %s40, align 8
  ; Hermes StoreStackInst
  %t20 = load i64, ptr %s40, align 8
  store i64 %t20, ptr %s39, align 8
  ; Hermes LIRLoadConstInst
  %t21 = load i64, ptr %s98, align 8
  store i64 %t21, ptr %s42, align 8
  ; Hermes CondBranchInst
  %t22 = call i32 @shllvm_truthy(ptr %s42)
  %t23 = icmp ne i32 %t22, 0
  br i1 %t23, label %b1, label %b2
b1:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s44, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s45, ptr %shr, ptr %unit, ptr %s44, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t24 = load i64, ptr %s94, align 8
  store i64 %t24, ptr %s46, align 8
  ; Hermes LIRLoadConstInst
  %t25 = load i64, ptr %s94, align 8
  store i64 %t25, ptr %s47, align 8
  ; Hermes LIRLoadConstInst
  %t26 = load i64, ptr %s100, align 8
  store i64 %t26, ptr %s48, align 8
  ; Hermes CallInst
  %t27 = getelementptr i64, ptr %argv, i32 0
  %t28 = load i64, ptr %s48, align 8
  store i64 %t28, ptr %t27, align 8
  call void @shllvm_call(ptr %s49, ptr %shr, ptr %frame, ptr %s45, ptr %s47, ptr %s46, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t29 = load i64, ptr %s49, align 8
  store i64 %t29, ptr %s39, align 8
  ; Hermes BranchInst
  br label %b2
b2:
  ; Hermes LoadStackInst
  %t30 = load i64, ptr %s39, align 8
  store i64 %t30, ptr %s52, align 8
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t31 = load i64, ptr %s101, align 8
  store i64 %t31, ptr %s54, align 8
  ; Hermes StoreStackInst
  %t32 = load i64, ptr %s54, align 8
  store i64 %t32, ptr %s53, align 8
  ; Hermes LIRLoadConstInst
  %t33 = load i64, ptr %s101, align 8
  store i64 %t33, ptr %s56, align 8
  ; Hermes CondBranchInst
  %t34 = call i32 @shllvm_truthy(ptr %s56)
  %t35 = icmp ne i32 %t34, 0
  br i1 %t35, label %b4, label %b3
b3:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s58, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s59, ptr %shr, ptr %unit, ptr %s58, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t36 = load i64, ptr %s94, align 8
  store i64 %t36, ptr %s60, align 8
  ; Hermes LIRLoadConstInst
  %t37 = load i64, ptr %s94, align 8
  store i64 %t37, ptr %s61, align 8
  ; Hermes LIRLoadConstInst
  %t38 = load i64, ptr %s102, align 8
  store i64 %t38, ptr %s62, align 8
  ; Hermes CallInst
  %t39 = getelementptr i64, ptr %argv, i32 0
  %t40 = load i64, ptr %s62, align 8
  store i64 %t40, ptr %t39, align 8
  call void @shllvm_call(ptr %s63, ptr %shr, ptr %frame, ptr %s59, ptr %s61, ptr %s60, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t41 = load i64, ptr %s63, align 8
  store i64 %t41, ptr %s53, align 8
  ; Hermes BranchInst
  br label %b4
b4:
  ; Hermes LoadStackInst
  %t42 = load i64, ptr %s53, align 8
  store i64 %t42, ptr %s66, align 8
  ; Hermes AllocStackInst
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s68, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s69, ptr %shr, ptr %unit, ptr %s68, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t43 = load i64, ptr %s94, align 8
  store i64 %t43, ptr %s70, align 8
  ; Hermes LIRLoadConstInst
  %t44 = load i64, ptr %s94, align 8
  store i64 %t44, ptr %s71, align 8
  ; Hermes LIRLoadConstInst
  %t45 = load i64, ptr %s99, align 8
  store i64 %t45, ptr %s72, align 8
  ; Hermes CallInst
  %t46 = getelementptr i64, ptr %argv, i32 0
  %t47 = load i64, ptr %s72, align 8
  store i64 %t47, ptr %t46, align 8
  call void @shllvm_call(ptr %s73, ptr %shr, ptr %frame, ptr %s69, ptr %s71, ptr %s70, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t48 = load i64, ptr %s73, align 8
  store i64 %t48, ptr %s67, align 8
  ; Hermes CondBranchInst
  %t49 = call i32 @shllvm_truthy(ptr %s73)
  %t50 = icmp ne i32 %t49, 0
  br i1 %t50, label %b6, label %b5
b5:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s76, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s77, ptr %shr, ptr %unit, ptr %s76, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t51 = load i64, ptr %s94, align 8
  store i64 %t51, ptr %s78, align 8
  ; Hermes LIRLoadConstInst
  %t52 = load i64, ptr %s94, align 8
  store i64 %t52, ptr %s79, align 8
  ; Hermes LIRLoadConstInst
  %t53 = load i64, ptr %s103, align 8
  store i64 %t53, ptr %s80, align 8
  ; Hermes CallInst
  %t54 = getelementptr i64, ptr %argv, i32 0
  %t55 = load i64, ptr %s80, align 8
  store i64 %t55, ptr %t54, align 8
  call void @shllvm_call(ptr %s81, ptr %shr, ptr %frame, ptr %s77, ptr %s79, ptr %s78, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t56 = load i64, ptr %s81, align 8
  store i64 %t56, ptr %s67, align 8
  ; Hermes BranchInst
  br label %b6
b6:
  ; Hermes LoadStackInst
  %t57 = load i64, ptr %s67, align 8
  store i64 %t57, ptr %s84, align 8
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s85, ptr %s0, i32 0)
  ; Hermes LIRLoadConstInst
  %t58 = load i64, ptr %s94, align 8
  store i64 %t58, ptr %s86, align 8
  ; Hermes LIRLoadConstInst
  %t59 = load i64, ptr %s94, align 8
  store i64 %t59, ptr %s87, align 8
  ; Hermes CallInst
  %t60 = getelementptr i64, ptr %argv, i32 0
  %t61 = load i64, ptr %s52, align 8
  store i64 %t61, ptr %t60, align 8
  %t62 = getelementptr i64, ptr %argv, i32 1
  %t63 = load i64, ptr %s66, align 8
  store i64 %t63, ptr %t62, align 8
  %t64 = getelementptr i64, ptr %argv, i32 2
  %t65 = load i64, ptr %s84, align 8
  store i64 %t65, ptr %t64, align 8
  %t66 = getelementptr i64, ptr %argv, i32 3
  %t67 = load i64, ptr %s85, align 8
  store i64 %t67, ptr %t66, align 8
  call void @shllvm_call(ptr %s88, ptr %shr, ptr %frame, ptr %s38, ptr %s87, ptr %s86, i32 4, ptr %argv)
  ; Hermes StoreStackInst
  %t68 = load i64, ptr %s88, align 8
  store i64 %t68, ptr %s15, align 8
  ; Hermes LoadStackInst
  %t69 = load i64, ptr %s15, align 8
  store i64 %t69, ptr %s90, align 8
  ; Hermes ReturnInst
  %t70 = load i64, ptr %s90, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t70
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 45)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 45, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 44
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s41, i32 0, i64 0)
  call void @shllvm_constant(ptr %s42, i32 3, i64 0)
  call void @shllvm_constant(ptr %s43, i32 3, i64 4607182418800017408)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 5)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s2, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s2, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s41, align 8
  store i64 %t1, ptr %s4, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s4, i32 1)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s41, align 8
  store i64 %t2, ptr %s6, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s6, i32 2)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s42, align 8
  store i64 %t3, ptr %s8, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s8, i32 1)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s43, align 8
  store i64 %t4, ptr %s10, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s10, i32 2)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s41, align 8
  store i64 %t5, ptr %s12, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s12, i32 3)
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s42, align 8
  store i64 %t6, ptr %s14, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s14, i32 3)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s16, ptr %s1, i32 3)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s17, ptr %s1, i32 0)
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s18, ptr %shr, i32 9, ptr %s16, ptr %s17)
  ; Hermes CondBranchInst
  %t7 = call i32 @shllvm_truthy(ptr %s18)
  %t8 = icmp ne i32 %t7, 0
  br i1 %t8, label %b1, label %b2
b1:
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s41, align 8
  store i64 %t9, ptr %s20, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s20, i32 4)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s22, ptr %s1, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s22, i32 4)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s24, ptr %s1, i32 2)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s24, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s26, ptr %s1, i32 4)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s27, ptr %s1, i32 2)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s28, ptr %shr, i32 0, ptr %s26, ptr %s27)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s28, i32 2)
  ; Hermes BranchInst
  br label %b4
b2:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s31, ptr %s1, i32 1)
  ; Hermes ReturnInst
  %t10 = load i64, ptr %s31, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t10
b3:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s33, ptr %s1, i32 3)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s34, ptr %s1, i32 0)
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s35, ptr %shr, i32 9, ptr %s33, ptr %s34)
  ; Hermes CondBranchInst
  %t11 = call i32 @shllvm_truthy(ptr %s35)
  %t12 = icmp ne i32 %t11, 0
  br i1 %t12, label %b1, label %b2
b4:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s37, ptr %s1, i32 3)
  ; Hermes UnaryIncInst
  call void @shllvm_unary(ptr %s38, ptr %shr, i32 5, ptr %s37)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s38, i32 3)
  ; Hermes BranchInst
  br label %b3
}

define internal i64 @shllvm_f2(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 44)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 44, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 43
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s38, i32 0, i64 0)
  call void @shllvm_constant(ptr %s39, i32 3, i64 0)
  call void @shllvm_constant(ptr %s40, i32 2, i64 1)
  call void @shllvm_constant(ptr %s41, i32 3, i64 4611686018427387904)
  call void @shllvm_constant(ptr %s42, i32 3, i64 4622945017495814144)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 2)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s38, align 8
  store i64 %t1, ptr %s2, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s2, i32 0)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s38, align 8
  store i64 %t2, ptr %s4, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s4, i32 1)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s39, align 8
  store i64 %t3, ptr %s6, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s6, i32 0)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s39, align 8
  store i64 %t4, ptr %s8, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s8, i32 1)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s40, align 8
  store i64 %t5, ptr %s10, align 8
  ; Hermes CondBranchInst
  %t6 = call i32 @shllvm_truthy(ptr %s10)
  %t7 = icmp ne i32 %t6, 0
  br i1 %t7, label %b1, label %b2
b1:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s12, ptr %s1, i32 0)
  ; Hermes UnaryIncInst
  call void @shllvm_unary(ptr %s13, ptr %shr, i32 5, ptr %s12)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s13, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s15, ptr %s1, i32 0)
  ; Hermes LIRLoadConstInst
  %t8 = load i64, ptr %s41, align 8
  store i64 %t8, ptr %s16, align 8
  ; Hermes BinaryModuloInst
  call void @shllvm_binary(ptr %s17, ptr %shr, i32 4, ptr %s15, ptr %s16)
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s39, align 8
  store i64 %t9, ptr %s18, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s19, ptr %shr, i32 7, ptr %s17, ptr %s18)
  ; Hermes CondBranchInst
  %t10 = call i32 @shllvm_truthy(ptr %s19)
  %t11 = icmp ne i32 %t10, 0
  br i1 %t11, label %b4, label %b5
b2:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s21, ptr %s1, i32 1)
  ; Hermes ReturnInst
  %t12 = load i64, ptr %s21, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t12
b3:
  ; Hermes LIRLoadConstInst
  %t13 = load i64, ptr %s40, align 8
  store i64 %t13, ptr %s23, align 8
  ; Hermes CondBranchInst
  %t14 = call i32 @shllvm_truthy(ptr %s23)
  %t15 = icmp ne i32 %t14, 0
  br i1 %t15, label %b1, label %b2
b4:
  ; Hermes BranchInst
  br label %b3
b5:
  ; Hermes BranchInst
  br label %b6
b6:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s27, ptr %s1, i32 0)
  ; Hermes LIRLoadConstInst
  %t16 = load i64, ptr %s42, align 8
  store i64 %t16, ptr %s28, align 8
  ; Hermes BinaryGreaterThanInst
  call void @shllvm_binary(ptr %s29, ptr %shr, i32 11, ptr %s27, ptr %s28)
  ; Hermes CondBranchInst
  %t17 = call i32 @shllvm_truthy(ptr %s29)
  %t18 = icmp ne i32 %t17, 0
  br i1 %t18, label %b7, label %b8
b7:
  ; Hermes BranchInst
  br label %b2
b8:
  ; Hermes BranchInst
  br label %b9
b9:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s33, ptr %s1, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s34, ptr %s1, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s35, ptr %shr, i32 0, ptr %s33, ptr %s34)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s35, i32 1)
  ; Hermes BranchInst
  br label %b3
}

define internal i64 @shllvm_f3(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
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
  call void @shllvm_env_load(ptr %s4, ptr %s0, i32 0)
  ; Hermes UnaryIncInst
  call void @shllvm_unary(ptr %s5, ptr %shr, i32 5, ptr %s4)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s5, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s7, ptr %s1, i32 0)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s7, align 8
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
