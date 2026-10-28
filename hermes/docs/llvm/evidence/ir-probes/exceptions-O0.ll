; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [61 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 110, i8 101, i8 115, i8 116, i8 101, i8 100, i8 0, i8 114, i8 101, i8 116, i8 117, i8 114, i8 110, i8 115, i8 0, i8 102, i8 0, i8 114, i8 117, i8 110, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 0, i8 110, i8 97, i8 109, i8 101, i8 0, i8 110, i8 111, i8 116, i8 68, i8 101, i8 102, i8 105, i8 110, i8 101, i8 100, i8 72, i8 101, i8 114, i8 101, i8 76, i8 76, i8 86, i8 77, i8 0, i8 110, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [30 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 6, i32 132351545, i32 14, i32 7, i32 152207403, i32 22, i32 1, i32 105991, i32 24, i32 3, i32 2129512166, i32 28, i32 5, i32 2794059355, i32 34, i32 0, i32 0, i32 35, i32 4, i32 3891058614, i32 40, i32 18, i32 1740255881, i32 59, i32 1, i32 114319]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [5 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 1, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 2, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 3, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 4, i32 0, i32 0, i32 1 }
]

declare i32 @_setjmp(ptr) returns_twice
declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_binary(ptr, ptr, i32, ptr, ptr)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_catch_prepare(ptr, ptr, ptr, i32)
declare void @shllvm_catch_value(ptr, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_closure(ptr, ptr, ptr, ptr, ptr, i32)
declare void @shllvm_coerce_this(ptr, ptr, ptr)
declare void @shllvm_constant(ptr, i32, i64)
declare void @shllvm_constructed_object(ptr, ptr, ptr)
declare void @shllvm_create_this(ptr, ptr, ptr, ptr)
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
declare void @shllvm_rethrow(ptr)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_set_id(ptr, ptr, ptr, i32, ptr, i32, i32)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)
declare void @shllvm_throw(ptr, ptr)
declare i32 @shllvm_truthy(ptr)
declare ptr @shllvm_try_begin(ptr, ptr)
declare void @shllvm_try_end(ptr, ptr)
declare i64 @shllvm_try_size()
declare void @shllvm_unary(ptr, ptr, i32, ptr)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 179)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [2 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 179, i32 2, i32 %unit_index)
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
  %s157 = getelementptr i64, ptr %roots, i32 157
  %s158 = getelementptr i64, ptr %roots, i32 158
  %s159 = getelementptr i64, ptr %roots, i32 159
  %s160 = getelementptr i64, ptr %roots, i32 160
  %s161 = getelementptr i64, ptr %roots, i32 161
  %s162 = getelementptr i64, ptr %roots, i32 162
  %s163 = getelementptr i64, ptr %roots, i32 163
  %s164 = getelementptr i64, ptr %roots, i32 164
  %s165 = getelementptr i64, ptr %roots, i32 165
  %s166 = getelementptr i64, ptr %roots, i32 166
  %s167 = getelementptr i64, ptr %roots, i32 167
  %s168 = getelementptr i64, ptr %roots, i32 168
  %s169 = getelementptr i64, ptr %roots, i32 169
  %s170 = getelementptr i64, ptr %roots, i32 170
  %s171 = getelementptr i64, ptr %roots, i32 171
  %s172 = getelementptr i64, ptr %roots, i32 172
  %s173 = getelementptr i64, ptr %roots, i32 173
  %s174 = getelementptr i64, ptr %roots, i32 174
  %s175 = getelementptr i64, ptr %roots, i32 175
  %s176 = getelementptr i64, ptr %roots, i32 176
  %s177 = getelementptr i64, ptr %roots, i32 177
  %scratch = getelementptr i64, ptr %roots, i32 178
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s165, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_symbol(ptr %s166, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s167, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s168, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_constant(ptr %s169, i32 3, i64 0)
  call void @shllvm_constant(ptr %s170, i32 2, i64 0)
  call void @shllvm_constant(ptr %s171, i32 3, i64 4613937818241073152)
  call void @shllvm_symbol(ptr %s172, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_constant(ptr %s173, i32 3, i64 4616189618054758400)
  call void @shllvm_symbol(ptr %s174, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_constant(ptr %s175, i32 3, i64 4607182418800017408)
  call void @shllvm_symbol(ptr %s176, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_symbol(ptr %s177, ptr %shr, ptr %unit, i32 8)
  %t1 = call i64 @shllvm_try_size()
  %try_storage = alloca i8, i64 %t1, align 16
  %try_state = alloca i32, align 4
  store volatile i32 0, ptr %try_state, align 4
  %t2 = call ptr @shllvm_try_begin(ptr %shr, ptr %try_storage)
  %t3 = call i32 @_setjmp(ptr %t2) returns_twice
  %t4 = icmp ne i32 %t3, 0
  br i1 %t4, label %catch.dispatch, label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s2, ptr %shr, ptr null, i32 7)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s1, i32 6)
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s4, ptr %frame)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s4, i32 5)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 2)
  ; Hermes LIRLoadConstInst
  %t5 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t5, ptr %s8, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s8, i32 2)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s10, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s11, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s11, i32 1, ptr %s10, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s13, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s14, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s14, i32 2, ptr %s13, i32 0, i32 0)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t6 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t6, ptr %s17, align 8
  ; Hermes StoreStackInst
  %t7 = load volatile i64, ptr %s17, align 8
  store volatile i64 %t7, ptr %s16, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s19, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s20, ptr %shr, ptr %unit, ptr %s19, i32 5, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s21, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s22, ptr %shr, ptr %unit, ptr %s21, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t8 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t8, ptr %s23, align 8
  ; Hermes LIRLoadConstInst
  %t9 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t9, ptr %s24, align 8
  ; Hermes LIRLoadConstInst
  %t10 = load volatile i64, ptr %s169, align 8
  store volatile i64 %t10, ptr %s25, align 8
  ; Hermes CallInst
  %t11 = getelementptr i64, ptr %argv, i32 0
  %t12 = load volatile i64, ptr %s25, align 8
  store volatile i64 %t12, ptr %t11, align 8
  call void @shllvm_call(ptr %s26, ptr %shr, ptr %frame, ptr %s22, ptr %s24, ptr %s23, i32 1, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s27, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s28, ptr %shr, ptr %unit, ptr %s27, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t13 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t13, ptr %s29, align 8
  ; Hermes LIRLoadConstInst
  %t14 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t14, ptr %s30, align 8
  ; Hermes LIRLoadConstInst
  %t15 = load volatile i64, ptr %s171, align 8
  store volatile i64 %t15, ptr %s31, align 8
  ; Hermes CallInst
  %t16 = getelementptr i64, ptr %argv, i32 0
  %t17 = load volatile i64, ptr %s31, align 8
  store volatile i64 %t17, ptr %t16, align 8
  call void @shllvm_call(ptr %s32, ptr %shr, ptr %frame, ptr %s28, ptr %s30, ptr %s29, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t18 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t18, ptr %s33, align 8
  ; Hermes LIRLoadConstInst
  %t19 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t19, ptr %s34, align 8
  ; Hermes CallInst
  %t20 = getelementptr i64, ptr %argv, i32 0
  %t21 = load volatile i64, ptr %s26, align 8
  store volatile i64 %t21, ptr %t20, align 8
  %t22 = getelementptr i64, ptr %argv, i32 1
  %t23 = load volatile i64, ptr %s32, align 8
  store volatile i64 %t23, ptr %t22, align 8
  call void @shllvm_call(ptr %s35, ptr %shr, ptr %frame, ptr %s20, ptr %s34, ptr %s33, i32 2, ptr %argv)
  ; Hermes StoreStackInst
  %t24 = load volatile i64, ptr %s35, align 8
  store volatile i64 %t24, ptr %s16, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s37, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s38, ptr %shr, ptr %unit, ptr %s37, i32 5, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s39, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s40, ptr %shr, ptr %unit, ptr %s39, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t25 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t25, ptr %s41, align 8
  ; Hermes LIRLoadConstInst
  %t26 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t26, ptr %s42, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s43, ptr %shr, ptr %frame, ptr %s40, ptr %s42, ptr %s41, i32 0, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t27 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t27, ptr %s44, align 8
  ; Hermes LIRLoadConstInst
  %t28 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t28, ptr %s45, align 8
  ; Hermes CallInst
  %t29 = getelementptr i64, ptr %argv, i32 0
  %t30 = load volatile i64, ptr %s43, align 8
  store volatile i64 %t30, ptr %t29, align 8
  call void @shllvm_call(ptr %s46, ptr %shr, ptr %frame, ptr %s38, ptr %s45, ptr %s44, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t31 = load volatile i64, ptr %s46, align 8
  store volatile i64 %t31, ptr %s16, align 8
  ; Hermes LIRLoadConstInst
  %t32 = load volatile i64, ptr %s172, align 8
  store volatile i64 %t32, ptr %s48, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s48, i32 2)
  ; Hermes LIRLoadConstInst
  %t33 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t33, ptr %s50, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s50, i32 3)
  ; Hermes LIRLoadConstInst
  %t34 = load volatile i64, ptr %s169, align 8
  store volatile i64 %t34, ptr %s52, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s52, i32 3)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s54, ptr %s2, i32 3)
  ; Hermes LIRLoadConstInst
  %t35 = load volatile i64, ptr %s173, align 8
  store volatile i64 %t35, ptr %s55, align 8
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s56, ptr %shr, i32 9, ptr %s54, ptr %s55)
  ; Hermes CondBranchInst
  %t36 = call i32 @shllvm_truthy(ptr %s56)
  %t37 = icmp ne i32 %t36, 0
  br i1 %t37, label %b1, label %b2
b1:
  ; Hermes TryStartInst
  store volatile i32 1, ptr %try_state, align 4
  br label %b7
b2:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s59, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s60, ptr %shr, ptr %unit, ptr %s59, i32 5, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s61, ptr %s2, i32 2)
  ; Hermes LIRLoadConstInst
  %t38 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t38, ptr %s62, align 8
  ; Hermes LIRLoadConstInst
  %t39 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t39, ptr %s63, align 8
  ; Hermes CallInst
  %t40 = getelementptr i64, ptr %argv, i32 0
  %t41 = load volatile i64, ptr %s61, align 8
  store volatile i64 %t41, ptr %t40, align 8
  call void @shllvm_call(ptr %s64, ptr %shr, ptr %frame, ptr %s60, ptr %s63, ptr %s62, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t42 = load volatile i64, ptr %s64, align 8
  store volatile i64 %t42, ptr %s16, align 8
  ; Hermes TryStartInst
  store volatile i32 2, ptr %try_state, align 4
  br label %b19
b3:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s67, ptr %s2, i32 3)
  ; Hermes LIRLoadConstInst
  %t43 = load volatile i64, ptr %s173, align 8
  store volatile i64 %t43, ptr %s68, align 8
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s69, ptr %shr, i32 9, ptr %s67, ptr %s68)
  ; Hermes CondBranchInst
  %t44 = call i32 @shllvm_truthy(ptr %s69)
  %t45 = icmp ne i32 %t44, 0
  br i1 %t45, label %b1, label %b2
b4:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s71, ptr %s2, i32 3)
  ; Hermes UnaryIncInst
  call void @shllvm_unary(ptr %s72, ptr %shr, i32 5, ptr %s71)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s72, i32 3)
  ; Hermes BranchInst
  br label %b3
b5:
  ; Hermes CatchInst
  store volatile i32 0, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s75, ptr %shr)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s76, ptr %s2, i32 2)
  ; Hermes LIRLoadConstInst
  %t46 = load volatile i64, ptr %s174, align 8
  store volatile i64 %t46, ptr %s77, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s78, ptr %shr, i32 0, ptr %s76, ptr %s77)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s78, i32 2)
  ; Hermes StoreStackInst
  %t47 = load volatile i64, ptr %s78, align 8
  store volatile i64 %t47, ptr %s16, align 8
  ; Hermes ThrowInst
  call void @shllvm_throw(ptr %shr, ptr %s75)
  unreachable
b6:
  ; Hermes BranchInst
  br label %b4
b7:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s83, ptr %s2, i32 3)
  ; Hermes LIRLoadConstInst
  %t48 = load volatile i64, ptr %s175, align 8
  store volatile i64 %t48, ptr %s84, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s85, ptr %shr, i32 7, ptr %s83, ptr %s84)
  ; Hermes CondBranchInst
  %t49 = call i32 @shllvm_truthy(ptr %s85)
  %t50 = icmp ne i32 %t49, 0
  br i1 %t50, label %b8, label %b9
b8:
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b11
b9:
  ; Hermes BranchInst
  br label %b10
b10:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s89, ptr %s2, i32 3)
  ; Hermes LIRLoadConstInst
  %t51 = load volatile i64, ptr %s171, align 8
  store volatile i64 %t51, ptr %s90, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s91, ptr %shr, i32 7, ptr %s89, ptr %s90)
  ; Hermes CondBranchInst
  %t52 = call i32 @shllvm_truthy(ptr %s91)
  %t53 = icmp ne i32 %t52, 0
  br i1 %t53, label %b12, label %b13
b11:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s93, ptr %s2, i32 2)
  ; Hermes LIRLoadConstInst
  %t54 = load volatile i64, ptr %s174, align 8
  store volatile i64 %t54, ptr %s94, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s95, ptr %shr, i32 0, ptr %s93, ptr %s94)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s95, i32 2)
  ; Hermes StoreStackInst
  %t55 = load volatile i64, ptr %s95, align 8
  store volatile i64 %t55, ptr %s16, align 8
  ; Hermes BranchInst
  br label %b4
b12:
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b15
b13:
  ; Hermes BranchInst
  br label %b14
b14:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s101, ptr %s2, i32 2)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s102, ptr %s2, i32 3)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s103, ptr %shr, i32 0, ptr %s101, ptr %s102)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s103, i32 2)
  ; Hermes StoreStackInst
  %t56 = load volatile i64, ptr %s103, align 8
  store volatile i64 %t56, ptr %s16, align 8
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b16
b15:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s107, ptr %s2, i32 2)
  ; Hermes LIRLoadConstInst
  %t57 = load volatile i64, ptr %s174, align 8
  store volatile i64 %t57, ptr %s108, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s109, ptr %shr, i32 0, ptr %s107, ptr %s108)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s109, i32 2)
  ; Hermes StoreStackInst
  %t58 = load volatile i64, ptr %s109, align 8
  store volatile i64 %t58, ptr %s16, align 8
  ; Hermes BranchInst
  br label %b2
b16:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s113, ptr %s2, i32 2)
  ; Hermes LIRLoadConstInst
  %t59 = load volatile i64, ptr %s174, align 8
  store volatile i64 %t59, ptr %s114, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s115, ptr %shr, i32 0, ptr %s113, ptr %s114)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s115, i32 2)
  ; Hermes StoreStackInst
  %t60 = load volatile i64, ptr %s115, align 8
  store volatile i64 %t60, ptr %s16, align 8
  ; Hermes BranchInst
  br label %b6
b17:
  ; Hermes CatchInst
  store volatile i32 0, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s119, ptr %shr)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s119, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s121, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s122, ptr %shr, ptr %unit, ptr %s121, i32 5, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s123, ptr %s2, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s124, ptr %shr, ptr %unit, ptr %s123, i32 7, i32 0)
  ; Hermes LIRLoadConstInst
  %t61 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t61, ptr %s125, align 8
  ; Hermes LIRLoadConstInst
  %t62 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t62, ptr %s126, align 8
  ; Hermes CallInst
  %t63 = getelementptr i64, ptr %argv, i32 0
  %t64 = load volatile i64, ptr %s124, align 8
  store volatile i64 %t64, ptr %t63, align 8
  call void @shllvm_call(ptr %s127, ptr %shr, ptr %frame, ptr %s122, ptr %s126, ptr %s125, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t65 = load volatile i64, ptr %s127, align 8
  store volatile i64 %t65, ptr %s16, align 8
  ; Hermes BranchInst
  br label %b18
b18:
  ; Hermes TryStartInst
  store volatile i32 3, ptr %try_state, align 4
  br label %b23
b19:
  ; Hermes LIRLoadConstInst
  %t66 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t66, ptr %s131, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s131, i32 4)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s133, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s133, i32 4)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s135, ptr %s2, i32 4)
  ; Hermes CreateThisInst
  call void @shllvm_create_this(ptr %s136, ptr %shr, ptr %s135, ptr %s135)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s137, ptr %shr, ptr %frame, ptr %s135, ptr %s136, ptr %s135, i32 0, ptr %argv)
  ; Hermes GetConstructedObjectInst
  call void @shllvm_constructed_object(ptr %s138, ptr %s136, ptr %s137)
  ; Hermes StoreStackInst
  %t67 = load volatile i64, ptr %s138, align 8
  store volatile i64 %t67, ptr %s16, align 8
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b20
b20:
  ; Hermes BranchInst
  br label %b18
b21:
  ; Hermes CatchInst
  store volatile i32 0, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s142, ptr %shr)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s142, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s144, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s145, ptr %shr, ptr %unit, ptr %s144, i32 5, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s146, ptr %s2, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s147, ptr %shr, ptr %unit, ptr %s146, i32 7, i32 0)
  ; Hermes LIRLoadConstInst
  %t68 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t68, ptr %s148, align 8
  ; Hermes LIRLoadConstInst
  %t69 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t69, ptr %s149, align 8
  ; Hermes CallInst
  %t70 = getelementptr i64, ptr %argv, i32 0
  %t71 = load volatile i64, ptr %s147, align 8
  store volatile i64 %t71, ptr %t70, align 8
  call void @shllvm_call(ptr %s150, ptr %shr, ptr %frame, ptr %s145, ptr %s149, ptr %s148, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t72 = load volatile i64, ptr %s150, align 8
  store volatile i64 %t72, ptr %s16, align 8
  ; Hermes BranchInst
  br label %b22
b22:
  ; Hermes LoadStackInst
  %t73 = load volatile i64, ptr %s16, align 8
  store volatile i64 %t73, ptr %s153, align 8
  ; Hermes ReturnInst
  %t74 = load volatile i64, ptr %s153, align 8
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t74
b23:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s155, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s156, ptr %shr, ptr %unit, ptr %s155, i32 5, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s157, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s158, ptr %shr, ptr %unit, ptr %s157, i32 8, i32 1)
  ; Hermes LIRLoadConstInst
  %t75 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t75, ptr %s159, align 8
  ; Hermes LIRLoadConstInst
  %t76 = load volatile i64, ptr %s167, align 8
  store volatile i64 %t76, ptr %s160, align 8
  ; Hermes CallInst
  %t77 = getelementptr i64, ptr %argv, i32 0
  %t78 = load volatile i64, ptr %s158, align 8
  store volatile i64 %t78, ptr %t77, align 8
  call void @shllvm_call(ptr %s161, ptr %shr, ptr %frame, ptr %s156, ptr %s160, ptr %s159, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t79 = load volatile i64, ptr %s161, align 8
  store volatile i64 %t79, ptr %s16, align 8
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b24
b24:
  ; Hermes BranchInst
  br label %b22
catch.dispatch:
  %t80 = load volatile i32, ptr %try_state, align 4
  call void @shllvm_catch_prepare(ptr %shr, ptr %storage, ptr %frame, i32 2)
  switch i32 %t80, label %catch.rethrow [
    i32 1, label %b5
    i32 2, label %b17
    i32 3, label %b21
  ]
catch.rethrow:
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_rethrow(ptr %shr)
  unreachable
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 85)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 85, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 84
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s74, i32 0, i64 0)
  call void @shllvm_constant(ptr %s75, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s76, i32 3, i64 4625196817309499392)
  call void @shllvm_symbol(ptr %s77, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_symbol(ptr %s78, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_constant(ptr %s79, i32 2, i64 0)
  call void @shllvm_constant(ptr %s80, i32 3, i64 4616189618054758400)
  call void @shllvm_constant(ptr %s81, i32 3, i64 4620693217682128896)
  call void @shllvm_constant(ptr %s82, i32 3, i64 4611686018427387904)
  call void @shllvm_constant(ptr %s83, i32 2, i64 1)
  %t1 = call i64 @shllvm_try_size()
  %try_storage = alloca i8, i64 %t1, align 16
  %try_state = alloca i32, align 4
  store volatile i32 0, ptr %try_state, align 4
  %t2 = call ptr @shllvm_try_begin(ptr %shr, ptr %try_storage)
  %t3 = call i32 @_setjmp(ptr %t2) returns_twice
  %t4 = icmp ne i32 %t3, 0
  br i1 %t4, label %catch.dispatch, label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s2, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s3, ptr %shr, ptr %s2, i32 5)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s1, i32 4)
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s5, ptr %frame)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s5, i32 3)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s7, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s7, i32 2)
  ; Hermes LIRLoadConstInst
  %t5 = load volatile i64, ptr %s74, align 8
  store volatile i64 %t5, ptr %s9, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s9, i32 1)
  ; Hermes LIRLoadConstInst
  %t6 = load volatile i64, ptr %s75, align 8
  store volatile i64 %t6, ptr %s11, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s11, i32 1)
  ; Hermes TryStartInst
  store volatile i32 1, ptr %try_state, align 4
  br label %b3
b1:
  ; Hermes CatchInst
  store volatile i32 0, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s14, ptr %shr)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s15, ptr %s3, i32 1)
  ; Hermes LIRLoadConstInst
  %t7 = load volatile i64, ptr %s76, align 8
  store volatile i64 %t7, ptr %s16, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s17, ptr %shr, i32 0, ptr %s15, ptr %s16)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s17, i32 1)
  ; Hermes ThrowInst
  call void @shllvm_throw(ptr %shr, ptr %s14)
  unreachable
b2:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s20, ptr %s3, i32 1)
  ; Hermes ReturnInst
  %t8 = load volatile i64, ptr %s20, align 8
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t8
b3:
  ; Hermes TryStartInst
  store volatile i32 2, ptr %try_state, align 4
  br label %b6
b4:
  ; Hermes CatchInst
  store volatile i32 1, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s23, ptr %shr)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s23, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s25, ptr %s3, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s26, ptr %s3, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s27, ptr %shr, ptr %unit, ptr %s26, i32 9, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s28, ptr %s3, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s29, ptr %shr, ptr %unit, ptr %s28, i32 4, i32 0)
  ; Hermes LIRLoadConstInst
  %t9 = load volatile i64, ptr %s74, align 8
  store volatile i64 %t9, ptr %s30, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s31, ptr %shr, ptr %frame, ptr %s29, ptr %s28, ptr %s30, i32 0, ptr %argv)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s32, ptr %shr, i32 0, ptr %s27, ptr %s31)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s33, ptr %shr, i32 0, ptr %s25, ptr %s32)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s33, i32 1)
  ; Hermes BranchInst
  br label %b5
b5:
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b15
b6:
  ; Hermes TryStartInst
  store volatile i32 3, ptr %try_state, align 4
  br label %b9
b7:
  ; Hermes CatchInst
  store volatile i32 2, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s38, ptr %shr)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s39, ptr %s3, i32 1)
  ; Hermes LIRLoadConstInst
  %t10 = load volatile i64, ptr %s80, align 8
  store volatile i64 %t10, ptr %s40, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s41, ptr %shr, i32 0, ptr %s39, ptr %s40)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s41, i32 1)
  ; Hermes ThrowInst
  call void @shllvm_throw(ptr %shr, ptr %s38)
  unreachable
b8:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s44, ptr %s3, i32 1)
  ; Hermes LIRLoadConstInst
  %t11 = load volatile i64, ptr %s81, align 8
  store volatile i64 %t11, ptr %s45, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s46, ptr %shr, i32 0, ptr %s44, ptr %s45)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s46, i32 1)
  ; Hermes TryEndInst
  store volatile i32 1, ptr %try_state, align 4
  br label %b14
b9:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s49, ptr %s3, i32 1)
  ; Hermes LIRLoadConstInst
  %t12 = load volatile i64, ptr %s82, align 8
  store volatile i64 %t12, ptr %s50, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s51, ptr %shr, i32 0, ptr %s49, ptr %s50)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s51, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s53, ptr %s3, i32 2)
  ; Hermes CondBranchInst
  %t13 = call i32 @shllvm_truthy(ptr %s53)
  %t14 = icmp ne i32 %t13, 0
  br i1 %t14, label %b10, label %b11
b10:
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s55, ptr %shr)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s56, ptr %s3, i32 2)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s55, ptr %s77, ptr %s56, i32 1)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s58, ptr %shr, ptr %s3, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s55, ptr %s78, ptr %s58, i32 1)
  ; Hermes ThrowInst
  call void @shllvm_throw(ptr %shr, ptr %s55)
  unreachable
b11:
  ; Hermes BranchInst
  br label %b12
b12:
  ; Hermes TryEndInst
  store volatile i32 2, ptr %try_state, align 4
  br label %b13
b13:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s63, ptr %s3, i32 1)
  ; Hermes LIRLoadConstInst
  %t15 = load volatile i64, ptr %s80, align 8
  store volatile i64 %t15, ptr %s64, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s65, ptr %shr, i32 0, ptr %s63, ptr %s64)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s65, i32 1)
  ; Hermes BranchInst
  br label %b8
b14:
  ; Hermes BranchInst
  br label %b5
b15:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s69, ptr %s3, i32 1)
  ; Hermes LIRLoadConstInst
  %t16 = load volatile i64, ptr %s76, align 8
  store volatile i64 %t16, ptr %s70, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s71, ptr %shr, i32 0, ptr %s69, ptr %s70)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s71, i32 1)
  ; Hermes BranchInst
  br label %b2
catch.dispatch:
  %t17 = load volatile i32, ptr %try_state, align 4
  call void @shllvm_catch_prepare(ptr %shr, ptr %storage, ptr %frame, i32 0)
  switch i32 %t17, label %catch.rethrow [
    i32 1, label %b1
    i32 2, label %b4
    i32 3, label %b7
  ]
catch.rethrow:
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_rethrow(ptr %shr)
  unreachable
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s9, i32 3, i64 4631107791820423168)
  %t1 = call i64 @shllvm_try_size()
  %try_storage = alloca i8, i64 %t1, align 16
  %try_state = alloca i32, align 4
  store volatile i32 0, ptr %try_state, align 4
  %t2 = call ptr @shllvm_try_begin(ptr %shr, ptr %try_storage)
  %t3 = call i32 @_setjmp(ptr %t2) returns_twice
  %t4 = icmp ne i32 %t3, 0
  br i1 %t4, label %catch.dispatch, label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 0)
  ; Hermes TryStartInst
  store volatile i32 1, ptr %try_state, align 4
  br label %b2
b1:
  ; Hermes CatchInst
  store volatile i32 0, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s3, ptr %shr)
  ; Hermes LIRLoadConstInst
  %t5 = load volatile i64, ptr %s9, align 8
  store volatile i64 %t5, ptr %s4, align 8
  ; Hermes ReturnInst
  %t6 = load volatile i64, ptr %s4, align 8
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t6
b2:
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b3
b3:
  ; Hermes LIRLoadConstInst
  %t7 = load volatile i64, ptr %s9, align 8
  store volatile i64 %t7, ptr %s7, align 8
  ; Hermes ReturnInst
  %t8 = load volatile i64, ptr %s7, align 8
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t8
catch.dispatch:
  %t9 = load volatile i32, ptr %try_state, align 4
  call void @shllvm_catch_prepare(ptr %shr, ptr %storage, ptr %frame, i32 0)
  switch i32 %t9, label %catch.rethrow [
    i32 1, label %b1
  ]
catch.rethrow:
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_rethrow(ptr %shr)
  unreachable
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

define internal i64 @shllvm_f4(ptr %shr) {
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
  call void @shllvm_constant(ptr %s4, i32 3, i64 4630826316843712512)
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
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 10, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 5, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
