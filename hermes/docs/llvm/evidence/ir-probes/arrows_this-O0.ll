; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [45 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 115, i8 117, i8 109, i8 0, i8 109, i8 97, i8 107, i8 101, i8 0, i8 0, i8 118, i8 97, i8 108, i8 117, i8 101, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 99, i8 97, i8 108, i8 108, i8 0, i8 98, i8 97, i8 115, i8 101, i8 0, i8 97, i8 112, i8 112, i8 108, i8 121, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [27 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 3, i32 3122771808, i32 11, i32 4, i32 1101841612, i32 16, i32 0, i32 0, i32 17, i32 5, i32 3746588989, i32 23, i32 5, i32 2794059355, i32 29, i32 4, i32 2730800004, i32 34, i32 4, i32 2965116673, i32 39, i32 5, i32 3820442164]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [4 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 2, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 2, i32 1, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 3, i32 1, i32 0, i32 1 }
]

declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_array(ptr, ptr, i32)
declare void @shllvm_binary(ptr, ptr, i32, ptr, ptr)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_closure(ptr, ptr, ptr, ptr, ptr, i32)
declare void @shllvm_coerce_this(ptr, ptr, ptr)
declare void @shllvm_constant(ptr, i32, i64)
declare ptr @shllvm_create_unit(ptr, i32, ptr, ptr, ptr, i32, ptr, ptr, ptr)
declare void @shllvm_declare_global(ptr, ptr, i32)
declare void @shllvm_define(ptr, ptr, ptr, ptr, i32)
declare void @shllvm_define_index(ptr, ptr, i32, ptr)
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
declare void @shllvm_param(ptr, ptr, i32)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_set_id(ptr, ptr, ptr, i32, ptr, i32, i32)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 110)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [3 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 110, i32 3, i32 %unit_index)
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
  %s104 = getelementptr i64, ptr %roots, i32 104
  %s105 = getelementptr i64, ptr %roots, i32 105
  %s106 = getelementptr i64, ptr %roots, i32 106
  %s107 = getelementptr i64, ptr %roots, i32 107
  %s108 = getelementptr i64, ptr %roots, i32 108
  %scratch = getelementptr i64, ptr %roots, i32 109
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s87, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s88, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_constant(ptr %s89, i32 3, i64 4629137466983448576)
  call void @shllvm_symbol(ptr %s90, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_constant(ptr %s91, i32 2, i64 1)
  call void @shllvm_symbol(ptr %s92, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s93, i32 3, i64 4617315517961601024)
  call void @shllvm_constant(ptr %s94, i32 2, i64 0)
  call void @shllvm_symbol(ptr %s95, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_constant(ptr %s96, i32 3, i64 4619567317775286272)
  call void @shllvm_symbol(ptr %s97, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_constant(ptr %s98, i32 3, i64 4652007308841189376)
  call void @shllvm_constant(ptr %s99, i32 3, i64 4620693217682128896)
  call void @shllvm_constant(ptr %s100, i32 3, i64 4630826316843712512)
  call void @shllvm_constant(ptr %s101, i32 3, i64 4611686018427387904)
  call void @shllvm_constant(ptr %s102, i32 3, i64 4621819117588971520)
  call void @shllvm_symbol(ptr %s103, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_constant(ptr %s104, i32 3, i64 4622382067542392832)
  call void @shllvm_constant(ptr %s105, i32 3, i64 4626604192193052672)
  call void @shllvm_symbol(ptr %s106, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_constant(ptr %s107, i32 3, i64 4626322717216342016)
  call void @shllvm_constant(ptr %s108, i32 3, i64 4624633867356078080)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 3)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s87, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s1, i32 0)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s87, align 8
  store i64 %t2, ptr %s3, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s3, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s6, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s7, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s7, i32 1, ptr %s6, i32 0, i32 0)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s87, align 8
  store i64 %t3, ptr %s10, align 8
  ; Hermes StoreStackInst
  %t4 = load i64, ptr %s10, align 8
  store i64 %t4, ptr %s9, align 8
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s12, ptr %shr)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s12, i32 2)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s89, align 8
  store i64 %t5, ptr %s14, align 8
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s12, ptr %s90, ptr %s14, i32 1)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s16, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s12, ptr %s92, ptr %s16, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s12, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s19, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s20, ptr %shr, ptr %unit, ptr %s19, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s87, align 8
  store i64 %t6, ptr %s21, align 8
  ; Hermes LIRLoadConstInst
  %t7 = load i64, ptr %s93, align 8
  store i64 %t7, ptr %s22, align 8
  ; Hermes CallInst
  %t8 = getelementptr i64, ptr %argv, i32 0
  %t9 = load i64, ptr %s22, align 8
  store i64 %t9, ptr %t8, align 8
  call void @shllvm_call(ptr %s23, ptr %shr, ptr %frame, ptr %s20, ptr %s19, ptr %s21, i32 1, ptr %argv)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s23, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s25, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s26, ptr %shr, ptr %unit, ptr %s25, i32 5, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s27, ptr %s0, i32 1)
  ; Hermes LIRLoadConstInst
  %t10 = load i64, ptr %s87, align 8
  store i64 %t10, ptr %s28, align 8
  ; Hermes LIRLoadConstInst
  %t11 = load i64, ptr %s87, align 8
  store i64 %t11, ptr %s29, align 8
  ; Hermes LIRLoadConstInst
  %t12 = load i64, ptr %s96, align 8
  store i64 %t12, ptr %s30, align 8
  ; Hermes CallInst
  %t13 = getelementptr i64, ptr %argv, i32 0
  %t14 = load i64, ptr %s30, align 8
  store i64 %t14, ptr %t13, align 8
  call void @shllvm_call(ptr %s31, ptr %shr, ptr %frame, ptr %s27, ptr %s29, ptr %s28, i32 1, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s32, ptr %s0, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s33, ptr %shr, ptr %unit, ptr %s32, i32 6, i32 0)
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s34, ptr %shr)
  ; Hermes LIRLoadConstInst
  %t15 = load i64, ptr %s98, align 8
  store i64 %t15, ptr %s35, align 8
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s34, ptr %s90, ptr %s35, i32 1)
  ; Hermes LIRLoadConstInst
  %t16 = load i64, ptr %s87, align 8
  store i64 %t16, ptr %s37, align 8
  ; Hermes LIRLoadConstInst
  %t17 = load i64, ptr %s99, align 8
  store i64 %t17, ptr %s38, align 8
  ; Hermes CallInst
  %t18 = getelementptr i64, ptr %argv, i32 0
  %t19 = load i64, ptr %s34, align 8
  store i64 %t19, ptr %t18, align 8
  %t20 = getelementptr i64, ptr %argv, i32 1
  %t21 = load i64, ptr %s38, align 8
  store i64 %t21, ptr %t20, align 8
  call void @shllvm_call(ptr %s39, ptr %shr, ptr %frame, ptr %s33, ptr %s32, ptr %s37, i32 2, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t22 = load i64, ptr %s87, align 8
  store i64 %t22, ptr %s40, align 8
  ; Hermes LIRLoadConstInst
  %t23 = load i64, ptr %s87, align 8
  store i64 %t23, ptr %s41, align 8
  ; Hermes CallInst
  %t24 = getelementptr i64, ptr %argv, i32 0
  %t25 = load i64, ptr %s31, align 8
  store i64 %t25, ptr %t24, align 8
  %t26 = getelementptr i64, ptr %argv, i32 1
  %t27 = load i64, ptr %s39, align 8
  store i64 %t27, ptr %t26, align 8
  call void @shllvm_call(ptr %s42, ptr %shr, ptr %frame, ptr %s26, ptr %s41, ptr %s40, i32 2, ptr %argv)
  ; Hermes StoreStackInst
  %t28 = load i64, ptr %s42, align 8
  store i64 %t28, ptr %s9, align 8
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s44, ptr %s0, i32 0)
  ; Hermes LIRLoadConstInst
  %t29 = load i64, ptr %s100, align 8
  store i64 %t29, ptr %s45, align 8
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s44, i32 4, ptr %s45, i32 0, i32 0)
  ; Hermes LIRLoadConstInst
  %t30 = load i64, ptr %s100, align 8
  store i64 %t30, ptr %s47, align 8
  ; Hermes StoreStackInst
  %t31 = load i64, ptr %s47, align 8
  store i64 %t31, ptr %s9, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s49, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s50, ptr %shr, ptr %unit, ptr %s49, i32 5, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s51, ptr %s0, i32 1)
  ; Hermes LIRLoadConstInst
  %t32 = load i64, ptr %s87, align 8
  store i64 %t32, ptr %s52, align 8
  ; Hermes LIRLoadConstInst
  %t33 = load i64, ptr %s87, align 8
  store i64 %t33, ptr %s53, align 8
  ; Hermes LIRLoadConstInst
  %t34 = load i64, ptr %s101, align 8
  store i64 %t34, ptr %s54, align 8
  ; Hermes CallInst
  %t35 = getelementptr i64, ptr %argv, i32 0
  %t36 = load i64, ptr %s54, align 8
  store i64 %t36, ptr %t35, align 8
  call void @shllvm_call(ptr %s55, ptr %shr, ptr %frame, ptr %s51, ptr %s53, ptr %s52, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t37 = load i64, ptr %s87, align 8
  store i64 %t37, ptr %s56, align 8
  ; Hermes LIRLoadConstInst
  %t38 = load i64, ptr %s87, align 8
  store i64 %t38, ptr %s57, align 8
  ; Hermes CallInst
  %t39 = getelementptr i64, ptr %argv, i32 0
  %t40 = load i64, ptr %s55, align 8
  store i64 %t40, ptr %t39, align 8
  call void @shllvm_call(ptr %s58, ptr %shr, ptr %frame, ptr %s50, ptr %s57, ptr %s56, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t41 = load i64, ptr %s58, align 8
  store i64 %t41, ptr %s9, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s60, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s61, ptr %shr, ptr %unit, ptr %s60, i32 5, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s62, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s63, ptr %shr, ptr %unit, ptr %s62, i32 1, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s64, ptr %shr, ptr %unit, ptr %s63, i32 6, i32 0)
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s65, ptr %shr)
  ; Hermes LIRLoadConstInst
  %t42 = load i64, ptr %s102, align 8
  store i64 %t42, ptr %s66, align 8
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s65, ptr %s103, ptr %s66, i32 1)
  ; Hermes LIRLoadConstInst
  %t43 = load i64, ptr %s87, align 8
  store i64 %t43, ptr %s68, align 8
  ; Hermes LIRLoadConstInst
  %t44 = load i64, ptr %s104, align 8
  store i64 %t44, ptr %s69, align 8
  ; Hermes LIRLoadConstInst
  %t45 = load i64, ptr %s105, align 8
  store i64 %t45, ptr %s70, align 8
  ; Hermes CallInst
  %t46 = getelementptr i64, ptr %argv, i32 0
  %t47 = load i64, ptr %s65, align 8
  store i64 %t47, ptr %t46, align 8
  %t48 = getelementptr i64, ptr %argv, i32 1
  %t49 = load i64, ptr %s69, align 8
  store i64 %t49, ptr %t48, align 8
  %t50 = getelementptr i64, ptr %argv, i32 2
  %t51 = load i64, ptr %s70, align 8
  store i64 %t51, ptr %t50, align 8
  call void @shllvm_call(ptr %s71, ptr %shr, ptr %frame, ptr %s64, ptr %s63, ptr %s68, i32 3, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s72, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s73, ptr %shr, ptr %unit, ptr %s72, i32 1, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s74, ptr %shr, ptr %unit, ptr %s73, i32 8, i32 0)
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s75, ptr %shr)
  ; Hermes LIRLoadConstInst
  %t52 = load i64, ptr %s107, align 8
  store i64 %t52, ptr %s76, align 8
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s75, ptr %s103, ptr %s76, i32 1)
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s78, ptr %shr, i32 2)
  call void @shllvm_define_index(ptr %shr, ptr %s78, i32 0, ptr %s96)
  call void @shllvm_define_index(ptr %shr, ptr %s78, i32 1, ptr %s108)
  ; Hermes LIRLoadConstInst
  %t53 = load i64, ptr %s87, align 8
  store i64 %t53, ptr %s79, align 8
  ; Hermes CallInst
  %t54 = getelementptr i64, ptr %argv, i32 0
  %t55 = load i64, ptr %s75, align 8
  store i64 %t55, ptr %t54, align 8
  %t56 = getelementptr i64, ptr %argv, i32 1
  %t57 = load i64, ptr %s78, align 8
  store i64 %t57, ptr %t56, align 8
  call void @shllvm_call(ptr %s80, ptr %shr, ptr %frame, ptr %s74, ptr %s73, ptr %s79, i32 2, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t58 = load i64, ptr %s87, align 8
  store i64 %t58, ptr %s81, align 8
  ; Hermes LIRLoadConstInst
  %t59 = load i64, ptr %s87, align 8
  store i64 %t59, ptr %s82, align 8
  ; Hermes CallInst
  %t60 = getelementptr i64, ptr %argv, i32 0
  %t61 = load i64, ptr %s71, align 8
  store i64 %t61, ptr %t60, align 8
  %t62 = getelementptr i64, ptr %argv, i32 1
  %t63 = load i64, ptr %s80, align 8
  store i64 %t63, ptr %t62, align 8
  call void @shllvm_call(ptr %s83, ptr %shr, ptr %frame, ptr %s61, ptr %s82, ptr %s81, i32 2, ptr %argv)
  ; Hermes StoreStackInst
  %t64 = load i64, ptr %s83, align 8
  store i64 %t64, ptr %s9, align 8
  ; Hermes LoadStackInst
  %t65 = load i64, ptr %s9, align 8
  store i64 %t65, ptr %s85, align 8
  ; Hermes ReturnInst
  %t66 = load i64, ptr %s85, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t66
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 16)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 16, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 15
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s14, ptr %shr, ptr %unit, i32 7)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s2, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s3, ptr %shr, ptr %s2, i32 2)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s4, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s4, i32 0)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s6, ptr %frame, i32 2)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s6, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s8, ptr %shr, ptr %unit, ptr %s1, i32 7, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s9, ptr %s3, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s10, ptr %shr, i32 0, ptr %s8, ptr %s9)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s11, ptr %s3, i32 1)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s12, ptr %shr, i32 0, ptr %s10, ptr %s11)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s12, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f2(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 13)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 13, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 12
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_constant(ptr %s11, i32 0, i64 0)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s2, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s3, ptr %shr, ptr %s2, i32 3)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s1, i32 2)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s11, align 8
  store i64 %t1, ptr %s5, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s5, i32 1)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s7, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s7, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s9, ptr %shr, ptr %s3, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s9, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f3(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 13)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 13, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 12
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_symbol(ptr %s11, ptr %shr, ptr %unit, i32 4)
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
  call void @shllvm_env_load(ptr %s4, ptr %s0, i32 2)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s5, ptr %shr, ptr %unit, ptr %s4, i32 4, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s6, ptr %s0, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s7, ptr %shr, i32 0, ptr %s5, ptr %s6)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s8, ptr %s1, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s9, ptr %shr, i32 0, ptr %s7, ptr %s8)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s9, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 9, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 4, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
