; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [61 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 99, i8 111, i8 117, i8 110, i8 116, i8 101, i8 114, i8 0, i8 110, i8 101, i8 115, i8 116, i8 101, i8 100, i8 0, i8 114, i8 101, i8 99, i8 117, i8 114, i8 115, i8 105, i8 118, i8 101, i8 67, i8 108, i8 111, i8 115, i8 117, i8 114, i8 101, i8 0, i8 105, i8 110, i8 99, i8 0, i8 100, i8 101, i8 99, i8 0, i8 114, i8 101, i8 97, i8 100, i8 0, i8 0, i8 102, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [30 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 7, i32 3120126385, i32 15, i32 6, i32 132351545, i32 22, i32 16, i32 2450927680, i32 39, i32 3, i32 1541303569, i32 43, i32 3, i32 297796768, i32 47, i32 4, i32 726821588, i32 52, i32 0, i32 0, i32 53, i32 1, i32 105991, i32 55, i32 5, i32 2794059355]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [10 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 1, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 2, i32 1, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 3, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 4, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 5, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 6, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 7, i32 1, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 8, i32 1, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 7, i32 1, i32 0, i32 1 }
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
declare void @shllvm_env_resolve(ptr, ptr, ptr, i32)
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
  %t0 = call i64 @shllvm_frame_size(i32 127)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [6 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 127, i32 6, i32 %unit_index)
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
  %s109 = getelementptr i64, ptr %roots, i32 109
  %s110 = getelementptr i64, ptr %roots, i32 110
  %s111 = getelementptr i64, ptr %roots, i32 111
  %s112 = getelementptr i64, ptr %roots, i32 112
  %s113 = getelementptr i64, ptr %roots, i32 113
  %s114 = getelementptr i64, ptr %roots, i32 114
  %s115 = getelementptr i64, ptr %roots, i32 115
  %s116 = getelementptr i64, ptr %roots, i32 116
  %s117 = getelementptr i64, ptr %roots, i32 117
  %s118 = getelementptr i64, ptr %roots, i32 118
  %s119 = getelementptr i64, ptr %roots, i32 119
  %s120 = getelementptr i64, ptr %roots, i32 120
  %s121 = getelementptr i64, ptr %roots, i32 121
  %s122 = getelementptr i64, ptr %roots, i32 122
  %s123 = getelementptr i64, ptr %roots, i32 123
  %s124 = getelementptr i64, ptr %roots, i32 124
  %s125 = getelementptr i64, ptr %roots, i32 125
  %scratch = getelementptr i64, ptr %roots, i32 126
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s110, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_constant(ptr %s111, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s112, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s113, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_constant(ptr %s114, i32 3, i64 4630826316843712512)
  call void @shllvm_constant(ptr %s115, i32 2, i64 0)
  call void @shllvm_constant(ptr %s116, i32 3, i64 4636737291354636288)
  call void @shllvm_symbol(ptr %s117, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_symbol(ptr %s118, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s119, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_symbol(ptr %s120, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_constant(ptr %s121, i32 3, i64 4619567317775286272)
  call void @shllvm_constant(ptr %s122, i32 3, i64 4622382067542392832)
  call void @shllvm_constant(ptr %s123, i32 3, i64 4627448617123184640)
  call void @shllvm_constant(ptr %s124, i32 3, i64 4627730092099895296)
  call void @shllvm_constant(ptr %s125, i32 3, i64 4626322717216342016)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 3)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s111, align 8
  store i64 %t1, ptr %s2, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s2, i32 0)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s111, align 8
  store i64 %t2, ptr %s4, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s4, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 2)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s111, align 8
  store i64 %t3, ptr %s7, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s7, i32 2)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 3)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s10, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s11, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s11, i32 1, ptr %s10, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s13, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s14, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s14, i32 2, ptr %s13, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s16, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s17, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s17, i32 3, ptr %s16, i32 0, i32 0)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s111, align 8
  store i64 %t4, ptr %s20, align 8
  ; Hermes StoreStackInst
  %t5 = load i64, ptr %s20, align 8
  store i64 %t5, ptr %s19, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s22, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s23, ptr %shr, ptr %unit, ptr %s22, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s111, align 8
  store i64 %t6, ptr %s24, align 8
  ; Hermes LIRLoadConstInst
  %t7 = load i64, ptr %s111, align 8
  store i64 %t7, ptr %s25, align 8
  ; Hermes LIRLoadConstInst
  %t8 = load i64, ptr %s114, align 8
  store i64 %t8, ptr %s26, align 8
  ; Hermes CallInst
  %t9 = getelementptr i64, ptr %argv, i32 0
  %t10 = load i64, ptr %s26, align 8
  store i64 %t10, ptr %t9, align 8
  call void @shllvm_call(ptr %s27, ptr %shr, ptr %frame, ptr %s23, ptr %s25, ptr %s24, i32 1, ptr %argv)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s27, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s29, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s30, ptr %shr, ptr %unit, ptr %s29, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t11 = load i64, ptr %s111, align 8
  store i64 %t11, ptr %s31, align 8
  ; Hermes LIRLoadConstInst
  %t12 = load i64, ptr %s111, align 8
  store i64 %t12, ptr %s32, align 8
  ; Hermes LIRLoadConstInst
  %t13 = load i64, ptr %s116, align 8
  store i64 %t13, ptr %s33, align 8
  ; Hermes CallInst
  %t14 = getelementptr i64, ptr %argv, i32 0
  %t15 = load i64, ptr %s33, align 8
  store i64 %t15, ptr %t14, align 8
  call void @shllvm_call(ptr %s34, ptr %shr, ptr %frame, ptr %s30, ptr %s32, ptr %s31, i32 1, ptr %argv)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s34, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s36, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s37, ptr %shr, ptr %unit, ptr %s36, i32 9, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s38, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s39, ptr %shr, ptr %unit, ptr %s38, i32 4, i32 0)
  ; Hermes LIRLoadConstInst
  %t16 = load i64, ptr %s111, align 8
  store i64 %t16, ptr %s40, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s41, ptr %shr, ptr %frame, ptr %s39, ptr %s38, ptr %s40, i32 0, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s42, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s43, ptr %shr, ptr %unit, ptr %s42, i32 4, i32 0)
  ; Hermes LIRLoadConstInst
  %t17 = load i64, ptr %s111, align 8
  store i64 %t17, ptr %s44, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s45, ptr %shr, ptr %frame, ptr %s43, ptr %s42, ptr %s44, i32 0, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s46, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s47, ptr %shr, ptr %unit, ptr %s46, i32 5, i32 0)
  ; Hermes LIRLoadConstInst
  %t18 = load i64, ptr %s111, align 8
  store i64 %t18, ptr %s48, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s49, ptr %shr, ptr %frame, ptr %s47, ptr %s46, ptr %s48, i32 0, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s50, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s51, ptr %shr, ptr %unit, ptr %s50, i32 6, i32 0)
  ; Hermes LIRLoadConstInst
  %t19 = load i64, ptr %s111, align 8
  store i64 %t19, ptr %s52, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s53, ptr %shr, ptr %frame, ptr %s51, ptr %s50, ptr %s52, i32 0, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s54, ptr %s0, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s55, ptr %shr, ptr %unit, ptr %s54, i32 4, i32 0)
  ; Hermes LIRLoadConstInst
  %t20 = load i64, ptr %s111, align 8
  store i64 %t20, ptr %s56, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s57, ptr %shr, ptr %frame, ptr %s55, ptr %s54, ptr %s56, i32 0, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s58, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s59, ptr %shr, ptr %unit, ptr %s58, i32 6, i32 0)
  ; Hermes LIRLoadConstInst
  %t21 = load i64, ptr %s111, align 8
  store i64 %t21, ptr %s60, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s61, ptr %shr, ptr %frame, ptr %s59, ptr %s58, ptr %s60, i32 0, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t22 = load i64, ptr %s111, align 8
  store i64 %t22, ptr %s62, align 8
  ; Hermes LIRLoadConstInst
  %t23 = load i64, ptr %s111, align 8
  store i64 %t23, ptr %s63, align 8
  ; Hermes CallInst
  %t24 = getelementptr i64, ptr %argv, i32 0
  %t25 = load i64, ptr %s41, align 8
  store i64 %t25, ptr %t24, align 8
  %t26 = getelementptr i64, ptr %argv, i32 1
  %t27 = load i64, ptr %s45, align 8
  store i64 %t27, ptr %t26, align 8
  %t28 = getelementptr i64, ptr %argv, i32 2
  %t29 = load i64, ptr %s49, align 8
  store i64 %t29, ptr %t28, align 8
  %t30 = getelementptr i64, ptr %argv, i32 3
  %t31 = load i64, ptr %s53, align 8
  store i64 %t31, ptr %t30, align 8
  %t32 = getelementptr i64, ptr %argv, i32 4
  %t33 = load i64, ptr %s57, align 8
  store i64 %t33, ptr %t32, align 8
  %t34 = getelementptr i64, ptr %argv, i32 5
  %t35 = load i64, ptr %s61, align 8
  store i64 %t35, ptr %t34, align 8
  call void @shllvm_call(ptr %s64, ptr %shr, ptr %frame, ptr %s37, ptr %s63, ptr %s62, i32 6, ptr %argv)
  ; Hermes StoreStackInst
  %t36 = load i64, ptr %s64, align 8
  store i64 %t36, ptr %s19, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s66, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s67, ptr %shr, ptr %unit, ptr %s66, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t37 = load i64, ptr %s111, align 8
  store i64 %t37, ptr %s68, align 8
  ; Hermes LIRLoadConstInst
  %t38 = load i64, ptr %s111, align 8
  store i64 %t38, ptr %s69, align 8
  ; Hermes LIRLoadConstInst
  %t39 = load i64, ptr %s121, align 8
  store i64 %t39, ptr %s70, align 8
  ; Hermes CallInst
  %t40 = getelementptr i64, ptr %argv, i32 0
  %t41 = load i64, ptr %s70, align 8
  store i64 %t41, ptr %t40, align 8
  call void @shllvm_call(ptr %s71, ptr %shr, ptr %frame, ptr %s67, ptr %s69, ptr %s68, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t42 = load i64, ptr %s111, align 8
  store i64 %t42, ptr %s72, align 8
  ; Hermes LIRLoadConstInst
  %t43 = load i64, ptr %s111, align 8
  store i64 %t43, ptr %s73, align 8
  ; Hermes LIRLoadConstInst
  %t44 = load i64, ptr %s122, align 8
  store i64 %t44, ptr %s74, align 8
  ; Hermes CallInst
  %t45 = getelementptr i64, ptr %argv, i32 0
  %t46 = load i64, ptr %s74, align 8
  store i64 %t46, ptr %t45, align 8
  call void @shllvm_call(ptr %s75, ptr %shr, ptr %frame, ptr %s71, ptr %s73, ptr %s72, i32 1, ptr %argv)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s75, i32 2)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s77, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s78, ptr %shr, ptr %unit, ptr %s77, i32 9, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s79, ptr %s0, i32 2)
  ; Hermes LIRLoadConstInst
  %t47 = load i64, ptr %s111, align 8
  store i64 %t47, ptr %s80, align 8
  ; Hermes LIRLoadConstInst
  %t48 = load i64, ptr %s111, align 8
  store i64 %t48, ptr %s81, align 8
  ; Hermes LIRLoadConstInst
  %t49 = load i64, ptr %s123, align 8
  store i64 %t49, ptr %s82, align 8
  ; Hermes CallInst
  %t50 = getelementptr i64, ptr %argv, i32 0
  %t51 = load i64, ptr %s82, align 8
  store i64 %t51, ptr %t50, align 8
  call void @shllvm_call(ptr %s83, ptr %shr, ptr %frame, ptr %s79, ptr %s81, ptr %s80, i32 1, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s84, ptr %s0, i32 2)
  ; Hermes LIRLoadConstInst
  %t52 = load i64, ptr %s111, align 8
  store i64 %t52, ptr %s85, align 8
  ; Hermes LIRLoadConstInst
  %t53 = load i64, ptr %s111, align 8
  store i64 %t53, ptr %s86, align 8
  ; Hermes LIRLoadConstInst
  %t54 = load i64, ptr %s124, align 8
  store i64 %t54, ptr %s87, align 8
  ; Hermes CallInst
  %t55 = getelementptr i64, ptr %argv, i32 0
  %t56 = load i64, ptr %s87, align 8
  store i64 %t56, ptr %t55, align 8
  call void @shllvm_call(ptr %s88, ptr %shr, ptr %frame, ptr %s84, ptr %s86, ptr %s85, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t57 = load i64, ptr %s111, align 8
  store i64 %t57, ptr %s89, align 8
  ; Hermes LIRLoadConstInst
  %t58 = load i64, ptr %s111, align 8
  store i64 %t58, ptr %s90, align 8
  ; Hermes CallInst
  %t59 = getelementptr i64, ptr %argv, i32 0
  %t60 = load i64, ptr %s83, align 8
  store i64 %t60, ptr %t59, align 8
  %t61 = getelementptr i64, ptr %argv, i32 1
  %t62 = load i64, ptr %s88, align 8
  store i64 %t62, ptr %t61, align 8
  call void @shllvm_call(ptr %s91, ptr %shr, ptr %frame, ptr %s78, ptr %s90, ptr %s89, i32 2, ptr %argv)
  ; Hermes StoreStackInst
  %t63 = load i64, ptr %s91, align 8
  store i64 %t63, ptr %s19, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s93, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s94, ptr %shr, ptr %unit, ptr %s93, i32 9, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s95, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s96, ptr %shr, ptr %unit, ptr %s95, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t64 = load i64, ptr %s111, align 8
  store i64 %t64, ptr %s97, align 8
  ; Hermes LIRLoadConstInst
  %t65 = load i64, ptr %s111, align 8
  store i64 %t65, ptr %s98, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s99, ptr %shr, ptr %frame, ptr %s96, ptr %s98, ptr %s97, i32 0, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t66 = load i64, ptr %s111, align 8
  store i64 %t66, ptr %s100, align 8
  ; Hermes LIRLoadConstInst
  %t67 = load i64, ptr %s111, align 8
  store i64 %t67, ptr %s101, align 8
  ; Hermes LIRLoadConstInst
  %t68 = load i64, ptr %s125, align 8
  store i64 %t68, ptr %s102, align 8
  ; Hermes CallInst
  %t69 = getelementptr i64, ptr %argv, i32 0
  %t70 = load i64, ptr %s102, align 8
  store i64 %t70, ptr %t69, align 8
  call void @shllvm_call(ptr %s103, ptr %shr, ptr %frame, ptr %s99, ptr %s101, ptr %s100, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t71 = load i64, ptr %s111, align 8
  store i64 %t71, ptr %s104, align 8
  ; Hermes LIRLoadConstInst
  %t72 = load i64, ptr %s111, align 8
  store i64 %t72, ptr %s105, align 8
  ; Hermes CallInst
  %t73 = getelementptr i64, ptr %argv, i32 0
  %t74 = load i64, ptr %s103, align 8
  store i64 %t74, ptr %t73, align 8
  call void @shllvm_call(ptr %s106, ptr %shr, ptr %frame, ptr %s94, ptr %s105, ptr %s104, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t75 = load i64, ptr %s106, align 8
  store i64 %t75, ptr %s19, align 8
  ; Hermes LoadStackInst
  %t76 = load i64, ptr %s19, align 8
  store i64 %t76, ptr %s108, align 8
  ; Hermes ReturnInst
  %t77 = load i64, ptr %s108, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t77
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
  call void @shllvm_constant(ptr %s21, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s22, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_constant(ptr %s23, i32 2, i64 1)
  call void @shllvm_symbol(ptr %s24, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_symbol(ptr %s25, ptr %shr, ptr %unit, i32 6)
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
  %t1 = load i64, ptr %s21, align 8
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
  call void @shllvm_define(ptr %shr, ptr %s13, ptr %s22, ptr %s14, i32 1)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s16, ptr %shr, ptr %s3, ptr %unit, ptr @shllvm_f5, i32 5)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s13, ptr %s24, ptr %s16, i32 1)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s18, ptr %shr, ptr %s3, ptr %unit, ptr @shllvm_f6, i32 6)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s13, ptr %s25, ptr %s18, i32 1)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s13, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f2(ptr %shr) {
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
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s5, ptr %frame)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s5, i32 1)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s7, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s7, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s9, ptr %shr, ptr %s3, ptr %unit, ptr @shllvm_f7, i32 7)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s9, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f3(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 15)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 15, i32 0, i32 %unit_index)
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
  call void @shllvm_constant(ptr %s13, i32 0, i64 0)
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
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s5, ptr %frame)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s5, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s13, align 8
  store i64 %t1, ptr %s7, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s7, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s9, ptr %shr, ptr %s3, ptr %unit, ptr @shllvm_f8, i32 8)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s9, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s11, ptr %s3, i32 0)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s11, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f4(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s2, ptr %s0, i32 0)
  ; Hermes UnaryIncInst
  call void @shllvm_unary(ptr %s3, ptr %shr, i32 5, ptr %s2)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s3, i32 0)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s3, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f5(ptr %shr) {
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
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s2, ptr %s0, i32 0)
  ; Hermes UnaryDecInst
  call void @shllvm_unary(ptr %s3, ptr %shr, i32 6, ptr %s2)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s3, i32 0)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s3, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f6(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
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

define internal i64 @shllvm_f7(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
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
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s4, ptr %shr, ptr %s1, ptr %unit, ptr @shllvm_f9, i32 9)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s4, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f8(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_constant(ptr %s22, i32 3, i64 0)
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
  %t1 = load i64, ptr %s22, align 8
  store i64 %t1, ptr %s5, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 7, ptr %s4, ptr %s5)
  ; Hermes CondBranchInst
  %t2 = call i32 @shllvm_truthy(ptr %s6)
  %t3 = icmp ne i32 %t2, 0
  br i1 %t3, label %b2, label %b1
b1:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s8, ptr %s1, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s9, ptr %s0, i32 0)
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
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s16, ptr %shr, i32 0, ptr %s8, ptr %s15)
  ; Hermes BranchInst
  br label %edge0
b2:
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s22, align 8
  store i64 %t9, ptr %s18, align 8
  ; Hermes BranchInst
  br label %edge1
b3:
  ; Hermes PhiInst
  ; Hermes ReturnInst
  %t10 = load i64, ptr %s20, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t10
edge0:
  %t11 = load i64, ptr %s16, align 8
  store i64 %t11, ptr %s20, align 8
  br label %b3
edge1:
  %t12 = load i64, ptr %s18, align 8
  store i64 %t12, ptr %s20, align 8
  br label %b3
}

define internal i64 @shllvm_f9(ptr %shr) {
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
  call void @shllvm_constant(ptr %s11, i32 3, i64 4607182418800017408)
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
  ; Hermes LIRResolveScopeInst
  call void @shllvm_env_resolve(ptr %s4, ptr %shr, ptr %s0, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s5, ptr %s4, i32 0)
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
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 10, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 10, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
