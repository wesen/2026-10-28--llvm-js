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

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 91)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [5 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 91, i32 5, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 90
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s76, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_symbol(ptr %s77, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s78, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s79, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_constant(ptr %s80, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s81, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_symbol(ptr %s82, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_constant(ptr %s83, i32 3, i64 4620693217682128896)
  call void @shllvm_constant(ptr %s84, i32 2, i64 0)
  call void @shllvm_constant(ptr %s85, i32 3, i64 4622945017495814144)
  call void @shllvm_constant(ptr %s86, i32 3, i64 4623507967449235456)
  call void @shllvm_constant(ptr %s87, i32 3, i64 4626604192193052672)
  call void @shllvm_constant(ptr %s88, i32 3, i64 4626041242239631360)
  call void @shllvm_constant(ptr %s89, i32 3, i64 4627167142146473984)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s2, ptr %shr, ptr null, i32 3)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s1, i32 2)
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s4, ptr %frame)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s4, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 2)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 3)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 4)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s80, align 8
  store i64 %t1, ptr %s10, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s10, i32 0)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 5)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s13, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s14, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s14, i32 1, ptr %s13, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s16, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s17, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s17, i32 2, ptr %s16, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s19, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s20, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s20, i32 3, ptr %s19, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s22, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s23, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s23, i32 4, ptr %s22, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s25, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f5, i32 5)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s26, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s26, i32 5, ptr %s25, i32 0, i32 0)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s80, align 8
  store i64 %t2, ptr %s29, align 8
  ; Hermes StoreStackInst
  %t3 = load i64, ptr %s29, align 8
  store i64 %t3, ptr %s28, align 8
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s31, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f6, i32 6)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s31, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s33, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s34, ptr %shr, ptr %unit, ptr %s33, i32 8, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s35, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s36, ptr %shr, ptr %unit, ptr %s35, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s80, align 8
  store i64 %t4, ptr %s37, align 8
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s80, align 8
  store i64 %t5, ptr %s38, align 8
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s83, align 8
  store i64 %t6, ptr %s39, align 8
  ; Hermes CallInst
  %t7 = getelementptr i64, ptr %argv, i32 0
  %t8 = load i64, ptr %s39, align 8
  store i64 %t8, ptr %t7, align 8
  call void @shllvm_call(ptr %s40, ptr %shr, ptr %frame, ptr %s36, ptr %s38, ptr %s37, i32 1, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s41, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s42, ptr %shr, ptr %unit, ptr %s41, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s80, align 8
  store i64 %t9, ptr %s43, align 8
  ; Hermes LIRLoadConstInst
  %t10 = load i64, ptr %s80, align 8
  store i64 %t10, ptr %s44, align 8
  ; Hermes LIRLoadConstInst
  %t11 = load i64, ptr %s85, align 8
  store i64 %t11, ptr %s45, align 8
  ; Hermes CallInst
  %t12 = getelementptr i64, ptr %argv, i32 0
  %t13 = load i64, ptr %s45, align 8
  store i64 %t13, ptr %t12, align 8
  call void @shllvm_call(ptr %s46, ptr %shr, ptr %frame, ptr %s42, ptr %s44, ptr %s43, i32 1, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s47, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s48, ptr %shr, ptr %unit, ptr %s47, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t14 = load i64, ptr %s80, align 8
  store i64 %t14, ptr %s49, align 8
  ; Hermes LIRLoadConstInst
  %t15 = load i64, ptr %s80, align 8
  store i64 %t15, ptr %s50, align 8
  ; Hermes LIRLoadConstInst
  %t16 = load i64, ptr %s86, align 8
  store i64 %t16, ptr %s51, align 8
  ; Hermes CallInst
  %t17 = getelementptr i64, ptr %argv, i32 0
  %t18 = load i64, ptr %s51, align 8
  store i64 %t18, ptr %t17, align 8
  call void @shllvm_call(ptr %s52, ptr %shr, ptr %frame, ptr %s48, ptr %s50, ptr %s49, i32 1, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s53, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s54, ptr %shr, ptr %unit, ptr %s53, i32 4, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s55, ptr %s2, i32 0)
  ; Hermes LIRLoadConstInst
  %t19 = load i64, ptr %s80, align 8
  store i64 %t19, ptr %s56, align 8
  ; Hermes LIRLoadConstInst
  %t20 = load i64, ptr %s80, align 8
  store i64 %t20, ptr %s57, align 8
  ; Hermes LIRLoadConstInst
  %t21 = load i64, ptr %s87, align 8
  store i64 %t21, ptr %s58, align 8
  ; Hermes CallInst
  %t22 = getelementptr i64, ptr %argv, i32 0
  %t23 = load i64, ptr %s55, align 8
  store i64 %t23, ptr %t22, align 8
  %t24 = getelementptr i64, ptr %argv, i32 1
  %t25 = load i64, ptr %s58, align 8
  store i64 %t25, ptr %t24, align 8
  call void @shllvm_call(ptr %s59, ptr %shr, ptr %frame, ptr %s54, ptr %s57, ptr %s56, i32 2, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s60, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s61, ptr %shr, ptr %unit, ptr %s60, i32 5, i32 0)
  ; Hermes LIRLoadConstInst
  %t26 = load i64, ptr %s80, align 8
  store i64 %t26, ptr %s62, align 8
  ; Hermes LIRLoadConstInst
  %t27 = load i64, ptr %s80, align 8
  store i64 %t27, ptr %s63, align 8
  ; Hermes LIRLoadConstInst
  %t28 = load i64, ptr %s88, align 8
  store i64 %t28, ptr %s64, align 8
  ; Hermes CallInst
  %t29 = getelementptr i64, ptr %argv, i32 0
  %t30 = load i64, ptr %s64, align 8
  store i64 %t30, ptr %t29, align 8
  call void @shllvm_call(ptr %s65, ptr %shr, ptr %frame, ptr %s61, ptr %s63, ptr %s62, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t31 = load i64, ptr %s80, align 8
  store i64 %t31, ptr %s66, align 8
  ; Hermes LIRLoadConstInst
  %t32 = load i64, ptr %s80, align 8
  store i64 %t32, ptr %s67, align 8
  ; Hermes LIRLoadConstInst
  %t33 = load i64, ptr %s89, align 8
  store i64 %t33, ptr %s68, align 8
  ; Hermes CallInst
  %t34 = getelementptr i64, ptr %argv, i32 0
  %t35 = load i64, ptr %s68, align 8
  store i64 %t35, ptr %t34, align 8
  call void @shllvm_call(ptr %s69, ptr %shr, ptr %frame, ptr %s65, ptr %s67, ptr %s66, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t36 = load i64, ptr %s80, align 8
  store i64 %t36, ptr %s70, align 8
  ; Hermes LIRLoadConstInst
  %t37 = load i64, ptr %s80, align 8
  store i64 %t37, ptr %s71, align 8
  ; Hermes CallInst
  %t38 = getelementptr i64, ptr %argv, i32 0
  %t39 = load i64, ptr %s40, align 8
  store i64 %t39, ptr %t38, align 8
  %t40 = getelementptr i64, ptr %argv, i32 1
  %t41 = load i64, ptr %s46, align 8
  store i64 %t41, ptr %t40, align 8
  %t42 = getelementptr i64, ptr %argv, i32 2
  %t43 = load i64, ptr %s52, align 8
  store i64 %t43, ptr %t42, align 8
  %t44 = getelementptr i64, ptr %argv, i32 3
  %t45 = load i64, ptr %s59, align 8
  store i64 %t45, ptr %t44, align 8
  %t46 = getelementptr i64, ptr %argv, i32 4
  %t47 = load i64, ptr %s69, align 8
  store i64 %t47, ptr %t46, align 8
  call void @shllvm_call(ptr %s72, ptr %shr, ptr %frame, ptr %s34, ptr %s71, ptr %s70, i32 5, ptr %argv)
  ; Hermes StoreStackInst
  %t48 = load i64, ptr %s72, align 8
  store i64 %t48, ptr %s28, align 8
  ; Hermes LoadStackInst
  %t49 = load i64, ptr %s28, align 8
  store i64 %t49, ptr %s74, align 8
  ; Hermes ReturnInst
  %t50 = load i64, ptr %s74, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t50
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 27)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 27, i32 1, i32 %unit_index)
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
  call void @shllvm_constant(ptr %s22, i32 3, i64 4607182418800017408)
  call void @shllvm_symbol(ptr %s23, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_constant(ptr %s24, i32 0, i64 0)
  call void @shllvm_constant(ptr %s25, i32 2, i64 0)
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
  ; Hermes BinaryLessThanOrEqualInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 10, ptr %s4, ptr %s5)
  ; Hermes CondBranchInst
  %t2 = call i32 @shllvm_truthy(ptr %s6)
  %t3 = icmp ne i32 %t2, 0
  br i1 %t3, label %b1, label %b2
b1:
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s22, align 8
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
  call void @shllvm_get_id(ptr %s13, ptr %shr, ptr %unit, ptr %s12, i32 1, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s14, ptr %s1, i32 0)
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s22, align 8
  store i64 %t6, ptr %s15, align 8
  ; Hermes BinarySubtractInst
  call void @shllvm_binary(ptr %s16, ptr %shr, i32 1, ptr %s14, ptr %s15)
  ; Hermes LIRLoadConstInst
  %t7 = load i64, ptr %s24, align 8
  store i64 %t7, ptr %s17, align 8
  ; Hermes LIRLoadConstInst
  %t8 = load i64, ptr %s24, align 8
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
  call void @shllvm_constant(ptr %s21, i32 3, i64 0)
  call void @shllvm_symbol(ptr %s22, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_constant(ptr %s23, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s24, i32 0, i64 0)
  call void @shllvm_constant(ptr %s25, i32 2, i64 0)
  call void @shllvm_constant(ptr %s26, i32 2, i64 1)
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
  %t1 = load i64, ptr %s21, align 8
  store i64 %t1, ptr %s5, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 7, ptr %s4, ptr %s5)
  ; Hermes CondBranchInst
  %t2 = call i32 @shllvm_truthy(ptr %s6)
  %t3 = icmp ne i32 %t2, 0
  br i1 %t3, label %b2, label %b1
b1:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s8, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s9, ptr %shr, ptr %unit, ptr %s8, i32 3, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s10, ptr %s1, i32 0)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s23, align 8
  store i64 %t4, ptr %s11, align 8
  ; Hermes BinarySubtractInst
  call void @shllvm_binary(ptr %s12, ptr %shr, i32 1, ptr %s10, ptr %s11)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s24, align 8
  store i64 %t5, ptr %s13, align 8
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s24, align 8
  store i64 %t6, ptr %s14, align 8
  ; Hermes CallInst
  %t7 = getelementptr i64, ptr %argv, i32 0
  %t8 = load i64, ptr %s12, align 8
  store i64 %t8, ptr %t7, align 8
  call void @shllvm_call(ptr %s15, ptr %shr, ptr %frame, ptr %s9, ptr %s14, ptr %s13, i32 1, ptr %argv)
  ; Hermes BranchInst
  br label %edge0
b2:
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s26, align 8
  store i64 %t9, ptr %s17, align 8
  ; Hermes BranchInst
  br label %edge1
b3:
  ; Hermes PhiInst
  ; Hermes ReturnInst
  %t10 = load i64, ptr %s19, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t10
edge0:
  %t11 = load i64, ptr %s15, align 8
  store i64 %t11, ptr %s19, align 8
  br label %b3
edge1:
  %t12 = load i64, ptr %s17, align 8
  store i64 %t12, ptr %s19, align 8
  br label %b3
}

define internal i64 @shllvm_f3(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 27)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 27, i32 1, i32 %unit_index)
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
  call void @shllvm_constant(ptr %s21, i32 3, i64 0)
  call void @shllvm_symbol(ptr %s22, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s23, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s24, i32 0, i64 0)
  call void @shllvm_constant(ptr %s25, i32 2, i64 0)
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
  %t1 = load i64, ptr %s21, align 8
  store i64 %t1, ptr %s5, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 7, ptr %s4, ptr %s5)
  ; Hermes CondBranchInst
  %t2 = call i32 @shllvm_truthy(ptr %s6)
  %t3 = icmp ne i32 %t2, 0
  br i1 %t3, label %b2, label %b1
b1:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s8, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s9, ptr %shr, ptr %unit, ptr %s8, i32 2, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s10, ptr %s1, i32 0)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s23, align 8
  store i64 %t4, ptr %s11, align 8
  ; Hermes BinarySubtractInst
  call void @shllvm_binary(ptr %s12, ptr %shr, i32 1, ptr %s10, ptr %s11)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s24, align 8
  store i64 %t5, ptr %s13, align 8
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s24, align 8
  store i64 %t6, ptr %s14, align 8
  ; Hermes CallInst
  %t7 = getelementptr i64, ptr %argv, i32 0
  %t8 = load i64, ptr %s12, align 8
  store i64 %t8, ptr %t7, align 8
  call void @shllvm_call(ptr %s15, ptr %shr, ptr %frame, ptr %s9, ptr %s14, ptr %s13, i32 1, ptr %argv)
  ; Hermes BranchInst
  br label %edge0
b2:
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s25, align 8
  store i64 %t9, ptr %s17, align 8
  ; Hermes BranchInst
  br label %edge1
b3:
  ; Hermes PhiInst
  ; Hermes ReturnInst
  %t10 = load i64, ptr %s19, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t10
edge0:
  %t11 = load i64, ptr %s15, align 8
  store i64 %t11, ptr %s19, align 8
  br label %b3
edge1:
  %t12 = load i64, ptr %s17, align 8
  store i64 %t12, ptr %s19, align 8
  br label %b3
}

define internal i64 @shllvm_f4(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 15)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 15, i32 1, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 14
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s12, i32 0, i64 0)
  call void @shllvm_constant(ptr %s13, i32 2, i64 0)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 2)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s2, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s2, i32 0)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s4, ptr %frame, i32 2)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s4, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s6, ptr %s1, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s7, ptr %s1, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s12, align 8
  store i64 %t1, ptr %s8, align 8
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s12, align 8
  store i64 %t2, ptr %s9, align 8
  ; Hermes CallInst
  %t3 = getelementptr i64, ptr %argv, i32 0
  %t4 = load i64, ptr %s7, align 8
  store i64 %t4, ptr %t3, align 8
  call void @shllvm_call(ptr %s10, ptr %shr, ptr %frame, ptr %s6, ptr %s9, ptr %s8, i32 1, ptr %argv)
  ; Hermes ReturnInst
  %t5 = load i64, ptr %s10, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t5
}

define internal i64 @shllvm_f5(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 8)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 8, i32 0, i32 %unit_index)
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
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 2)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s2, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s2, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s4, ptr %shr, ptr %s1, ptr %unit, ptr @shllvm_f7, i32 7)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s1, ptr %s4, i32 1)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s4, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f6(ptr %shr) {
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
  call void @shllvm_constant(ptr %s8, i32 3, i64 4611686018427387904)
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
  %t1 = load i64, ptr %s8, align 8
  store i64 %t1, ptr %s5, align 8
  ; Hermes BinaryMultiplyInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 2, ptr %s4, ptr %s5)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s6, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f7(ptr %shr) {
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
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s5, ptr %s1, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 0, ptr %s4, ptr %s5)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s6, align 8
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
