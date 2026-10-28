; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [54 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 118, i8 97, i8 108, i8 117, i8 101, i8 0, i8 120, i8 0, i8 110, i8 101, i8 115, i8 116, i8 101, i8 100, i8 0, i8 111, i8 107, i8 0, i8 116, i8 97, i8 103, i8 0, i8 115, i8 101, i8 108, i8 102, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 101, i8 120, i8 116, i8 114, i8 97, i8 0, i8 109, i8 105, i8 115, i8 115, i8 105, i8 110, i8 103, i8 0]
@shllvm_utf16 = private constant [5 x i16] [i16 233, i16 0, i16 55348, i16 56606, i16 0]
@shllvm_strings = private constant [36 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 5, i32 3746588989, i32 13, i32 1, i32 124921, i32 15, i32 6, i32 132351545, i32 22, i32 2, i32 116811893, i32 25, i32 3, i32 4257416225, i32 29, i32 4, i32 995365215, i32 34, i32 5, i32 2794059355, i32 40, i32 5, i32 3915328114, i32 46, i32 7, i32 1729073391, i32 2147483648, i32 1, i32 240250, i32 2147483650, i32 2, i32 3041246460]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [1 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 }
]

declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_binary(ptr, ptr, i32, ptr, ptr)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_constant(ptr, i32, i64)
declare ptr @shllvm_create_unit(ptr, i32, ptr, ptr, ptr, i32, ptr, ptr, ptr)
declare void @shllvm_define(ptr, ptr, ptr, ptr, i32)
declare void @shllvm_delete(ptr, ptr, ptr, ptr, i32)
declare ptr @shllvm_enter(ptr, ptr, i32, i32, i32)
declare void @shllvm_env_create(ptr, ptr, ptr, i32)
declare void @shllvm_env_load(ptr, ptr, i32)
declare void @shllvm_env_store(ptr, ptr, ptr, i32)
declare i64 @shllvm_frame_size(i32)
declare void @shllvm_get(ptr, ptr, ptr, ptr)
declare void @shllvm_get_id(ptr, ptr, ptr, ptr, i32, i32)
declare ptr @shllvm_get_unit(ptr, i32)
declare void @shllvm_global(ptr, ptr)
declare void @shllvm_leave(ptr, ptr, ptr)
declare void @shllvm_object(ptr, ptr)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_set(ptr, ptr, ptr, ptr, i32)
declare void @shllvm_set_id(ptr, ptr, ptr, i32, ptr, i32, i32)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 126)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [4 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 126, i32 4, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 125
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s104, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s105, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_constant(ptr %s106, i32 3, i64 4613937818241073152)
  call void @shllvm_constant(ptr %s107, i32 2, i64 1)
  call void @shllvm_constant(ptr %s108, i32 3, i64 4619567317775286272)
  call void @shllvm_symbol(ptr %s109, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s110, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s111, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s112, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_constant(ptr %s113, i32 3, i64 4630685579355357184)
  call void @shllvm_constant(ptr %s114, i32 3, i64 4611686018427387904)
  call void @shllvm_symbol(ptr %s115, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_symbol(ptr %s116, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_constant(ptr %s117, i32 2, i64 0)
  call void @shllvm_constant(ptr %s118, i32 3, i64 4636666922610458624)
  call void @shllvm_symbol(ptr %s119, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_symbol(ptr %s120, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_constant(ptr %s121, i32 3, i64 4622382067542392832)
  call void @shllvm_symbol(ptr %s122, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_constant(ptr %s123, i32 3, i64 4629418941960159232)
  call void @shllvm_symbol(ptr %s124, ptr %shr, ptr %unit, i32 11)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 4)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s104, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s1, i32 0)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s104, align 8
  store i64 %t2, ptr %s3, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s3, i32 1)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s104, align 8
  store i64 %t3, ptr %s5, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s5, i32 2)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s104, align 8
  store i64 %t4, ptr %s7, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s7, i32 3)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s104, align 8
  store i64 %t5, ptr %s10, align 8
  ; Hermes StoreStackInst
  %t6 = load i64, ptr %s10, align 8
  store i64 %t6, ptr %s9, align 8
  ; Hermes LIRLoadConstInst
  %t7 = load i64, ptr %s105, align 8
  store i64 %t7, ptr %s12, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s12, i32 0)
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s14, ptr %shr)
  ; Hermes LIRLoadConstInst
  %t8 = load i64, ptr %s106, align 8
  store i64 %t8, ptr %s15, align 8
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s14, ptr %s105, ptr %s15, i32 1)
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s17, ptr %shr)
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s108, align 8
  store i64 %t9, ptr %s18, align 8
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s17, ptr %s109, ptr %s18, i32 1)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s14, ptr %s110, ptr %s17, i32 1)
  ; Hermes LIRLoadConstInst
  %t10 = load i64, ptr %s111, align 8
  store i64 %t10, ptr %s21, align 8
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s14, ptr %s112, ptr %s21, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s14, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s24, ptr %s0, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s24, i32 2)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s26, ptr %s0, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s27, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s28, ptr %shr, ptr %s26, ptr %s27)
  ; Hermes LIRLoadConstInst
  %t11 = load i64, ptr %s113, align 8
  store i64 %t11, ptr %s29, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s30, ptr %shr, i32 0, ptr %s28, ptr %s29)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set(ptr %shr, ptr %s26, ptr %s27, ptr %s30, i32 0)
  ; Hermes StoreStackInst
  %t12 = load i64, ptr %s30, align 8
  store i64 %t12, ptr %s9, align 8
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s33, ptr %s0, i32 2)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s34, ptr %shr, ptr %unit, ptr %s33, i32 3, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s35, ptr %shr, ptr %unit, ptr %s34, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t13 = load i64, ptr %s114, align 8
  store i64 %t13, ptr %s36, align 8
  ; Hermes BinaryMultiplyInst
  call void @shllvm_binary(ptr %s37, ptr %shr, i32 2, ptr %s35, ptr %s36)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s34, i32 2, ptr %s37, i32 0, i32 0)
  ; Hermes StoreStackInst
  %t14 = load i64, ptr %s37, align 8
  store i64 %t14, ptr %s9, align 8
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s40, ptr %s0, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s41, ptr %s0, i32 1)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s40, i32 6, ptr %s41, i32 0, i32 0)
  ; Hermes StoreStackInst
  %t15 = load i64, ptr %s41, align 8
  store i64 %t15, ptr %s9, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s44, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s45, ptr %shr, ptr %unit, ptr %s44, i32 7, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s46, ptr %s0, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s47, ptr %shr, ptr %unit, ptr %s46, i32 1, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s48, ptr %s0, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s49, ptr %shr, ptr %unit, ptr %s48, i32 3, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s50, ptr %shr, ptr %unit, ptr %s49, i32 2, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s51, ptr %s0, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s52, ptr %shr, ptr %unit, ptr %s51, i32 5, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s53, ptr %s0, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s54, ptr %shr, ptr %unit, ptr %s53, i32 6, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s55, ptr %s0, i32 2)
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s56, ptr %shr, i32 7, ptr %s54, ptr %s55)
  ; Hermes LIRLoadConstInst
  %t16 = load i64, ptr %s104, align 8
  store i64 %t16, ptr %s57, align 8
  ; Hermes LIRLoadConstInst
  %t17 = load i64, ptr %s104, align 8
  store i64 %t17, ptr %s58, align 8
  ; Hermes CallInst
  %t18 = getelementptr i64, ptr %argv, i32 0
  %t19 = load i64, ptr %s47, align 8
  store i64 %t19, ptr %t18, align 8
  %t20 = getelementptr i64, ptr %argv, i32 1
  %t21 = load i64, ptr %s50, align 8
  store i64 %t21, ptr %t20, align 8
  %t22 = getelementptr i64, ptr %argv, i32 2
  %t23 = load i64, ptr %s52, align 8
  store i64 %t23, ptr %t22, align 8
  %t24 = getelementptr i64, ptr %argv, i32 3
  %t25 = load i64, ptr %s56, align 8
  store i64 %t25, ptr %t24, align 8
  call void @shllvm_call(ptr %s59, ptr %shr, ptr %frame, ptr %s45, ptr %s58, ptr %s57, i32 4, ptr %argv)
  ; Hermes StoreStackInst
  %t26 = load i64, ptr %s59, align 8
  store i64 %t26, ptr %s9, align 8
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s61, ptr %s0, i32 1)
  ; Hermes LIRLoadConstInst
  %t27 = load i64, ptr %s118, align 8
  store i64 %t27, ptr %s62, align 8
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s61, i32 8, ptr %s62, i32 0, i32 0)
  ; Hermes LIRLoadConstInst
  %t28 = load i64, ptr %s118, align 8
  store i64 %t28, ptr %s64, align 8
  ; Hermes StoreStackInst
  %t29 = load i64, ptr %s64, align 8
  store i64 %t29, ptr %s9, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s66, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s67, ptr %shr, ptr %unit, ptr %s66, i32 7, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s68, ptr %s0, i32 1)
  ; Hermes LIRLoadConstInst
  %t30 = load i64, ptr %s119, align 8
  store i64 %t30, ptr %s69, align 8
  ; Hermes BinaryInInst
  call void @shllvm_binary(ptr %s70, ptr %shr, i32 19, ptr %s69, ptr %s68)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s71, ptr %s0, i32 1)
  ; Hermes LIRLoadConstInst
  %t31 = load i64, ptr %s119, align 8
  store i64 %t31, ptr %s72, align 8
  ; Hermes DeletePropertyLooseInst
  call void @shllvm_delete(ptr %s73, ptr %shr, ptr %s71, ptr %s72, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s74, ptr %s0, i32 1)
  ; Hermes LIRLoadConstInst
  %t32 = load i64, ptr %s119, align 8
  store i64 %t32, ptr %s75, align 8
  ; Hermes BinaryInInst
  call void @shllvm_binary(ptr %s76, ptr %shr, i32 19, ptr %s75, ptr %s74)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s77, ptr %s0, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s78, ptr %shr, ptr %unit, ptr %s77, i32 9, i32 0)
  ; Hermes LIRLoadConstInst
  %t33 = load i64, ptr %s104, align 8
  store i64 %t33, ptr %s79, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s80, ptr %shr, i32 7, ptr %s78, ptr %s79)
  ; Hermes LIRLoadConstInst
  %t34 = load i64, ptr %s104, align 8
  store i64 %t34, ptr %s81, align 8
  ; Hermes LIRLoadConstInst
  %t35 = load i64, ptr %s104, align 8
  store i64 %t35, ptr %s82, align 8
  ; Hermes CallInst
  %t36 = getelementptr i64, ptr %argv, i32 0
  %t37 = load i64, ptr %s70, align 8
  store i64 %t37, ptr %t36, align 8
  %t38 = getelementptr i64, ptr %argv, i32 1
  %t39 = load i64, ptr %s73, align 8
  store i64 %t39, ptr %t38, align 8
  %t40 = getelementptr i64, ptr %argv, i32 2
  %t41 = load i64, ptr %s76, align 8
  store i64 %t41, ptr %t40, align 8
  %t42 = getelementptr i64, ptr %argv, i32 3
  %t43 = load i64, ptr %s80, align 8
  store i64 %t43, ptr %t42, align 8
  call void @shllvm_call(ptr %s83, ptr %shr, ptr %frame, ptr %s67, ptr %s82, ptr %s81, i32 4, ptr %argv)
  ; Hermes StoreStackInst
  %t44 = load i64, ptr %s83, align 8
  store i64 %t44, ptr %s9, align 8
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s85, ptr %shr)
  ; Hermes LIRLoadConstInst
  %t45 = load i64, ptr %s121, align 8
  store i64 %t45, ptr %s86, align 8
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s85, ptr %s122, ptr %s86, i32 1)
  ; Hermes LIRLoadConstInst
  %t46 = load i64, ptr %s123, align 8
  store i64 %t46, ptr %s88, align 8
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s85, ptr %s124, ptr %s88, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s85, i32 3)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s91, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s92, ptr %shr, ptr %unit, ptr %s91, i32 7, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s93, ptr %s0, i32 3)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s94, ptr %shr, ptr %unit, ptr %s93, i32 10, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s95, ptr %s0, i32 3)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s96, ptr %shr, ptr %unit, ptr %s95, i32 11, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s97, ptr %shr, i32 0, ptr %s94, ptr %s96)
  ; Hermes LIRLoadConstInst
  %t47 = load i64, ptr %s104, align 8
  store i64 %t47, ptr %s98, align 8
  ; Hermes LIRLoadConstInst
  %t48 = load i64, ptr %s104, align 8
  store i64 %t48, ptr %s99, align 8
  ; Hermes CallInst
  %t49 = getelementptr i64, ptr %argv, i32 0
  %t50 = load i64, ptr %s97, align 8
  store i64 %t50, ptr %t49, align 8
  call void @shllvm_call(ptr %s100, ptr %shr, ptr %frame, ptr %s92, ptr %s99, ptr %s98, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t51 = load i64, ptr %s100, align 8
  store i64 %t51, ptr %s9, align 8
  ; Hermes LoadStackInst
  %t52 = load i64, ptr %s9, align 8
  store i64 %t52, ptr %s102, align 8
  ; Hermes ReturnInst
  %t53 = load i64, ptr %s102, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t53
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 12, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 1, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
