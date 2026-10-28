; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [55 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 0, i8 109, i8 97, i8 112, i8 0, i8 102, i8 105, i8 108, i8 116, i8 101, i8 114, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 106, i8 111, i8 105, i8 110, i8 0, i8 44, i8 0, i8 114, i8 101, i8 100, i8 117, i8 99, i8 101, i8 0, i8 112, i8 117, i8 115, i8 104, i8 0, i8 112, i8 111, i8 112, i8 0, i8 108, i8 101, i8 110, i8 103, i8 116, i8 104, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [33 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 0, i32 0, i32 8, i32 3, i32 1513730174, i32 12, i32 6, i32 1819577477, i32 19, i32 5, i32 2794059355, i32 25, i32 4, i32 2270132137, i32 30, i32 1, i32 45804, i32 32, i32 6, i32 229177066, i32 39, i32 4, i32 1059174534, i32 44, i32 3, i32 4256322194, i32 48, i32 6, i32 363462486]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [5 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 1, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 1, i32 1, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 1, i32 2, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 1, i32 0, i32 0, i32 1 }
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
declare void @shllvm_define_index(ptr, ptr, i32, ptr)
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
declare void @shllvm_symbol(ptr, ptr, ptr, i32)
declare i32 @shllvm_truthy(ptr)
declare void @shllvm_unary(ptr, ptr, i32, ptr)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 158)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [4 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 158, i32 4, i32 %unit_index)
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
  %s126 = getelementptr i64, ptr %roots, i32 126
  %s127 = getelementptr i64, ptr %roots, i32 127
  %s128 = getelementptr i64, ptr %roots, i32 128
  %s129 = getelementptr i64, ptr %roots, i32 129
  %s130 = getelementptr i64, ptr %roots, i32 130
  %s131 = getelementptr i64, ptr %roots, i32 131
  %s132 = getelementptr i64, ptr %roots, i32 132
  %s133 = getelementptr i64, ptr %roots, i32 133
  %s134 = getelementptr i64, ptr %roots, i32 134
  %s135 = getelementptr i64, ptr %roots, i32 135
  %s136 = getelementptr i64, ptr %roots, i32 136
  %s137 = getelementptr i64, ptr %roots, i32 137
  %s138 = getelementptr i64, ptr %roots, i32 138
  %s139 = getelementptr i64, ptr %roots, i32 139
  %s140 = getelementptr i64, ptr %roots, i32 140
  %s141 = getelementptr i64, ptr %roots, i32 141
  %s142 = getelementptr i64, ptr %roots, i32 142
  %s143 = getelementptr i64, ptr %roots, i32 143
  %s144 = getelementptr i64, ptr %roots, i32 144
  %s145 = getelementptr i64, ptr %roots, i32 145
  %s146 = getelementptr i64, ptr %roots, i32 146
  %s147 = getelementptr i64, ptr %roots, i32 147
  %s148 = getelementptr i64, ptr %roots, i32 148
  %s149 = getelementptr i64, ptr %roots, i32 149
  %s150 = getelementptr i64, ptr %roots, i32 150
  %s151 = getelementptr i64, ptr %roots, i32 151
  %s152 = getelementptr i64, ptr %roots, i32 152
  %s153 = getelementptr i64, ptr %roots, i32 153
  %s154 = getelementptr i64, ptr %roots, i32 154
  %s155 = getelementptr i64, ptr %roots, i32 155
  %s156 = getelementptr i64, ptr %roots, i32 156
  %scratch = getelementptr i64, ptr %roots, i32 157
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s138, i32 0, i64 0)
  call void @shllvm_constant(ptr %s139, i32 3, i64 4616189618054758400)
  call void @shllvm_constant(ptr %s140, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s141, i32 3, i64 4611686018427387904)
  call void @shllvm_constant(ptr %s142, i32 3, i64 4613937818241073152)
  call void @shllvm_symbol(ptr %s143, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s144, i32 2, i64 0)
  call void @shllvm_symbol(ptr %s145, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s146, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s147, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_symbol(ptr %s148, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_symbol(ptr %s149, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_constant(ptr %s150, i32 3, i64 0)
  call void @shllvm_symbol(ptr %s151, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_constant(ptr %s152, i32 3, i64 4617315517961601024)
  call void @shllvm_symbol(ptr %s153, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_symbol(ptr %s154, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_constant(ptr %s155, i32 3, i64 4619567317775286272)
  call void @shllvm_constant(ptr %s156, i32 3, i64 4621256167635550208)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s2, ptr %shr, ptr null, i32 8)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s1, i32 7)
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s4, ptr %frame)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s4, i32 6)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s138, align 8
  store i64 %t1, ptr %s6, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s6, i32 2)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s138, align 8
  store i64 %t2, ptr %s8, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s8, i32 3)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s138, align 8
  store i64 %t3, ptr %s10, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s10, i32 4)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s138, align 8
  store i64 %t4, ptr %s12, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s12, i32 5)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s138, align 8
  store i64 %t5, ptr %s14, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s14, i32 1)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s138, align 8
  store i64 %t6, ptr %s17, align 8
  ; Hermes StoreStackInst
  %t7 = load i64, ptr %s17, align 8
  store i64 %t7, ptr %s16, align 8
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s19, ptr %shr, i32 4)
  call void @shllvm_define_index(ptr %shr, ptr %s19, i32 0, ptr %s140)
  call void @shllvm_define_index(ptr %shr, ptr %s19, i32 1, ptr %s141)
  call void @shllvm_define_index(ptr %shr, ptr %s19, i32 2, ptr %s142)
  call void @shllvm_define_index(ptr %shr, ptr %s19, i32 3, ptr %s139)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s19, i32 2)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s21, ptr %s2, i32 2)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s22, ptr %shr, ptr %unit, ptr %s21, i32 2, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s23, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes LIRLoadConstInst
  %t8 = load i64, ptr %s138, align 8
  store i64 %t8, ptr %s24, align 8
  ; Hermes CallInst
  %t9 = getelementptr i64, ptr %argv, i32 0
  %t10 = load i64, ptr %s23, align 8
  store i64 %t10, ptr %t9, align 8
  call void @shllvm_call(ptr %s25, ptr %shr, ptr %frame, ptr %s22, ptr %s21, ptr %s24, i32 1, ptr %argv)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s25, i32 3)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s27, ptr %s2, i32 3)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s28, ptr %shr, ptr %unit, ptr %s27, i32 3, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s29, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes LIRLoadConstInst
  %t11 = load i64, ptr %s138, align 8
  store i64 %t11, ptr %s30, align 8
  ; Hermes CallInst
  %t12 = getelementptr i64, ptr %argv, i32 0
  %t13 = load i64, ptr %s29, align 8
  store i64 %t13, ptr %t12, align 8
  call void @shllvm_call(ptr %s31, ptr %shr, ptr %frame, ptr %s28, ptr %s27, ptr %s30, i32 1, ptr %argv)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s31, i32 4)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s33, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s34, ptr %shr, ptr %unit, ptr %s33, i32 4, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s35, ptr %s2, i32 3)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s36, ptr %shr, ptr %unit, ptr %s35, i32 5, i32 0)
  ; Hermes LIRLoadConstInst
  %t14 = load i64, ptr %s138, align 8
  store i64 %t14, ptr %s37, align 8
  ; Hermes LIRLoadConstInst
  %t15 = load i64, ptr %s148, align 8
  store i64 %t15, ptr %s38, align 8
  ; Hermes CallInst
  %t16 = getelementptr i64, ptr %argv, i32 0
  %t17 = load i64, ptr %s38, align 8
  store i64 %t17, ptr %t16, align 8
  call void @shllvm_call(ptr %s39, ptr %shr, ptr %frame, ptr %s36, ptr %s35, ptr %s37, i32 1, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s40, ptr %s2, i32 4)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s41, ptr %shr, ptr %unit, ptr %s40, i32 7, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s42, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes LIRLoadConstInst
  %t18 = load i64, ptr %s138, align 8
  store i64 %t18, ptr %s43, align 8
  ; Hermes LIRLoadConstInst
  %t19 = load i64, ptr %s150, align 8
  store i64 %t19, ptr %s44, align 8
  ; Hermes CallInst
  %t20 = getelementptr i64, ptr %argv, i32 0
  %t21 = load i64, ptr %s42, align 8
  store i64 %t21, ptr %t20, align 8
  %t22 = getelementptr i64, ptr %argv, i32 1
  %t23 = load i64, ptr %s44, align 8
  store i64 %t23, ptr %t22, align 8
  call void @shllvm_call(ptr %s45, ptr %shr, ptr %frame, ptr %s41, ptr %s40, ptr %s43, i32 2, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t24 = load i64, ptr %s138, align 8
  store i64 %t24, ptr %s46, align 8
  ; Hermes LIRLoadConstInst
  %t25 = load i64, ptr %s138, align 8
  store i64 %t25, ptr %s47, align 8
  ; Hermes CallInst
  %t26 = getelementptr i64, ptr %argv, i32 0
  %t27 = load i64, ptr %s39, align 8
  store i64 %t27, ptr %t26, align 8
  %t28 = getelementptr i64, ptr %argv, i32 1
  %t29 = load i64, ptr %s45, align 8
  store i64 %t29, ptr %t28, align 8
  call void @shllvm_call(ptr %s48, ptr %shr, ptr %frame, ptr %s34, ptr %s47, ptr %s46, i32 2, ptr %argv)
  ; Hermes StoreStackInst
  %t30 = load i64, ptr %s48, align 8
  store i64 %t30, ptr %s16, align 8
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s50, ptr %s2, i32 2)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s51, ptr %shr, ptr %unit, ptr %s50, i32 8, i32 0)
  ; Hermes LIRLoadConstInst
  %t31 = load i64, ptr %s138, align 8
  store i64 %t31, ptr %s52, align 8
  ; Hermes LIRLoadConstInst
  %t32 = load i64, ptr %s152, align 8
  store i64 %t32, ptr %s53, align 8
  ; Hermes CallInst
  %t33 = getelementptr i64, ptr %argv, i32 0
  %t34 = load i64, ptr %s53, align 8
  store i64 %t34, ptr %t33, align 8
  call void @shllvm_call(ptr %s54, ptr %shr, ptr %frame, ptr %s51, ptr %s50, ptr %s52, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t35 = load i64, ptr %s54, align 8
  store i64 %t35, ptr %s16, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s56, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s57, ptr %shr, ptr %unit, ptr %s56, i32 4, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s58, ptr %s2, i32 2)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s59, ptr %shr, ptr %unit, ptr %s58, i32 9, i32 0)
  ; Hermes LIRLoadConstInst
  %t36 = load i64, ptr %s138, align 8
  store i64 %t36, ptr %s60, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s61, ptr %shr, ptr %frame, ptr %s59, ptr %s58, ptr %s60, i32 0, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s62, ptr %s2, i32 2)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s63, ptr %shr, ptr %unit, ptr %s62, i32 10, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s64, ptr %s2, i32 2)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s65, ptr %shr, ptr %s64, ptr %s141)
  ; Hermes LIRLoadConstInst
  %t37 = load i64, ptr %s138, align 8
  store i64 %t37, ptr %s66, align 8
  ; Hermes LIRLoadConstInst
  %t38 = load i64, ptr %s138, align 8
  store i64 %t38, ptr %s67, align 8
  ; Hermes CallInst
  %t39 = getelementptr i64, ptr %argv, i32 0
  %t40 = load i64, ptr %s61, align 8
  store i64 %t40, ptr %t39, align 8
  %t41 = getelementptr i64, ptr %argv, i32 1
  %t42 = load i64, ptr %s63, align 8
  store i64 %t42, ptr %t41, align 8
  %t43 = getelementptr i64, ptr %argv, i32 2
  %t44 = load i64, ptr %s65, align 8
  store i64 %t44, ptr %t43, align 8
  call void @shllvm_call(ptr %s68, ptr %shr, ptr %frame, ptr %s57, ptr %s67, ptr %s66, i32 3, ptr %argv)
  ; Hermes StoreStackInst
  %t45 = load i64, ptr %s68, align 8
  store i64 %t45, ptr %s16, align 8
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s70, ptr %shr, i32 3)
  call void @shllvm_define_index(ptr %shr, ptr %s70, i32 0, ptr %s155)
  ; Hermes LIRLoadConstInst
  %t46 = load i64, ptr %s156, align 8
  store i64 %t46, ptr %s71, align 8
  ; Hermes DefineOwnInDenseArrayInst
  call void @shllvm_define_index(ptr %shr, ptr %s70, i32 2, ptr %s71)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s70, i32 5)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s74, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s75, ptr %shr, ptr %unit, ptr %s74, i32 4, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s76, ptr %s2, i32 5)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s77, ptr %shr, ptr %unit, ptr %s76, i32 10, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s78, ptr %s2, i32 5)
  ; Hermes LIRLoadConstInst
  %t47 = load i64, ptr %s140, align 8
  store i64 %t47, ptr %s79, align 8
  ; Hermes BinaryInInst
  call void @shllvm_binary(ptr %s80, ptr %shr, i32 19, ptr %s79, ptr %s78)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s81, ptr %s2, i32 5)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s82, ptr %shr, ptr %s81, ptr %s140)
  ; Hermes LIRLoadConstInst
  %t48 = load i64, ptr %s138, align 8
  store i64 %t48, ptr %s83, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s84, ptr %shr, i32 7, ptr %s82, ptr %s83)
  ; Hermes LIRLoadConstInst
  %t49 = load i64, ptr %s138, align 8
  store i64 %t49, ptr %s85, align 8
  ; Hermes LIRLoadConstInst
  %t50 = load i64, ptr %s138, align 8
  store i64 %t50, ptr %s86, align 8
  ; Hermes CallInst
  %t51 = getelementptr i64, ptr %argv, i32 0
  %t52 = load i64, ptr %s77, align 8
  store i64 %t52, ptr %t51, align 8
  %t53 = getelementptr i64, ptr %argv, i32 1
  %t54 = load i64, ptr %s80, align 8
  store i64 %t54, ptr %t53, align 8
  %t55 = getelementptr i64, ptr %argv, i32 2
  %t56 = load i64, ptr %s84, align 8
  store i64 %t56, ptr %t55, align 8
  call void @shllvm_call(ptr %s87, ptr %shr, ptr %frame, ptr %s75, ptr %s86, ptr %s85, i32 3, ptr %argv)
  ; Hermes StoreStackInst
  %t57 = load i64, ptr %s87, align 8
  store i64 %t57, ptr %s16, align 8
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s89, ptr %shr, i32 0)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s89, i32 1)
  ; Hermes LIRLoadConstInst
  %t58 = load i64, ptr %s138, align 8
  store i64 %t58, ptr %s91, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s91, i32 0)
  ; Hermes LIRLoadConstInst
  %t59 = load i64, ptr %s150, align 8
  store i64 %t59, ptr %s93, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s93, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s95, ptr %s2, i32 0)
  ; Hermes LIRLoadConstInst
  %t60 = load i64, ptr %s139, align 8
  store i64 %t60, ptr %s96, align 8
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s97, ptr %shr, i32 9, ptr %s95, ptr %s96)
  ; Hermes CondBranchInst
  %t61 = call i32 @shllvm_truthy(ptr %s97)
  %t62 = icmp ne i32 %t61, 0
  br i1 %t62, label %b1, label %b2
b1:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s99, ptr %s2, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s100, ptr %shr, ptr %unit, ptr %s99, i32 8, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s101, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes LIRLoadConstInst
  %t63 = load i64, ptr %s138, align 8
  store i64 %t63, ptr %s102, align 8
  ; Hermes CallInst
  %t64 = getelementptr i64, ptr %argv, i32 0
  %t65 = load i64, ptr %s101, align 8
  store i64 %t65, ptr %t64, align 8
  call void @shllvm_call(ptr %s103, ptr %shr, ptr %frame, ptr %s100, ptr %s99, ptr %s102, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t66 = load i64, ptr %s103, align 8
  store i64 %t66, ptr %s16, align 8
  ; Hermes BranchInst
  br label %b4
b2:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s106, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s107, ptr %shr, ptr %unit, ptr %s106, i32 4, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s108, ptr %s2, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s109, ptr %shr, ptr %s108, ptr %s150)
  ; Hermes LIRLoadConstInst
  %t67 = load i64, ptr %s138, align 8
  store i64 %t67, ptr %s110, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s111, ptr %shr, ptr %frame, ptr %s109, ptr %s108, ptr %s110, i32 0, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s112, ptr %s2, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s113, ptr %shr, ptr %s112, ptr %s140)
  ; Hermes LIRLoadConstInst
  %t68 = load i64, ptr %s138, align 8
  store i64 %t68, ptr %s114, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s115, ptr %shr, ptr %frame, ptr %s113, ptr %s112, ptr %s114, i32 0, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s116, ptr %s2, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s117, ptr %shr, ptr %s116, ptr %s141)
  ; Hermes LIRLoadConstInst
  %t69 = load i64, ptr %s138, align 8
  store i64 %t69, ptr %s118, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s119, ptr %shr, ptr %frame, ptr %s117, ptr %s116, ptr %s118, i32 0, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s120, ptr %s2, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s121, ptr %shr, ptr %s120, ptr %s142)
  ; Hermes LIRLoadConstInst
  %t70 = load i64, ptr %s138, align 8
  store i64 %t70, ptr %s122, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s123, ptr %shr, ptr %frame, ptr %s121, ptr %s120, ptr %s122, i32 0, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t71 = load i64, ptr %s138, align 8
  store i64 %t71, ptr %s124, align 8
  ; Hermes LIRLoadConstInst
  %t72 = load i64, ptr %s138, align 8
  store i64 %t72, ptr %s125, align 8
  ; Hermes CallInst
  %t73 = getelementptr i64, ptr %argv, i32 0
  %t74 = load i64, ptr %s111, align 8
  store i64 %t74, ptr %t73, align 8
  %t75 = getelementptr i64, ptr %argv, i32 1
  %t76 = load i64, ptr %s115, align 8
  store i64 %t76, ptr %t75, align 8
  %t77 = getelementptr i64, ptr %argv, i32 2
  %t78 = load i64, ptr %s119, align 8
  store i64 %t78, ptr %t77, align 8
  %t79 = getelementptr i64, ptr %argv, i32 3
  %t80 = load i64, ptr %s123, align 8
  store i64 %t80, ptr %t79, align 8
  call void @shllvm_call(ptr %s126, ptr %shr, ptr %frame, ptr %s107, ptr %s125, ptr %s124, i32 4, ptr %argv)
  ; Hermes StoreStackInst
  %t81 = load i64, ptr %s126, align 8
  store i64 %t81, ptr %s16, align 8
  ; Hermes LoadStackInst
  %t82 = load i64, ptr %s16, align 8
  store i64 %t82, ptr %s128, align 8
  ; Hermes ReturnInst
  %t83 = load i64, ptr %s128, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t83
b3:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s130, ptr %s2, i32 0)
  ; Hermes LIRLoadConstInst
  %t84 = load i64, ptr %s139, align 8
  store i64 %t84, ptr %s131, align 8
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s132, ptr %shr, i32 9, ptr %s130, ptr %s131)
  ; Hermes CondBranchInst
  %t85 = call i32 @shllvm_truthy(ptr %s132)
  %t86 = icmp ne i32 %t85, 0
  br i1 %t86, label %b1, label %b2
b4:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s134, ptr %s2, i32 0)
  ; Hermes UnaryIncInst
  call void @shllvm_unary(ptr %s135, ptr %shr, i32 5, ptr %s134)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s135, i32 0)
  ; Hermes BranchInst
  br label %b3
}

define internal i64 @shllvm_f1(ptr %shr) {
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

define internal i64 @shllvm_f2(ptr %shr) {
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
  call void @shllvm_constant(ptr %s8, i32 3, i64 4613937818241073152)
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
  ; Hermes BinaryGreaterThanInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 11, ptr %s4, ptr %s5)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s6, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f3(ptr %shr) {
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
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s8, ptr %shr, i32 0, ptr %s6, ptr %s7)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s8, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f4(ptr %shr) {
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

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 11, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 5, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
