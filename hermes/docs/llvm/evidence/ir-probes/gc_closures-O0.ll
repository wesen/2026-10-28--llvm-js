; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [106 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 109, i8 97, i8 107, i8 101, i8 0, i8 0, i8 105, i8 0, i8 103, i8 97, i8 114, i8 98, i8 97, i8 103, i8 101, i8 45, i8 0, i8 116, i8 101, i8 120, i8 116, i8 0, i8 108, i8 105, i8 115, i8 116, i8 0, i8 115, i8 101, i8 108, i8 102, i8 0, i8 103, i8 99, i8 0, i8 102, i8 117, i8 110, i8 99, i8 116, i8 105, i8 111, i8 110, i8 0, i8 112, i8 117, i8 115, i8 104, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 110, i8 0, i8 119, i8 111, i8 114, i8 100, i8 115, i8 0, i8 106, i8 111, i8 105, i8 110, i8 0, i8 32, i8 0, i8 109, i8 97, i8 112, i8 0, i8 44, i8 0, i8 97, i8 108, i8 105, i8 118, i8 101, i8 0, i8 97, i8 102, i8 116, i8 101, i8 114, i8 0, i8 99, i8 111, i8 108, i8 108, i8 101, i8 99, i8 116, i8 105, i8 111, i8 110, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [63 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 4, i32 1101841612, i32 12, i32 0, i32 0, i32 13, i32 1, i32 107256, i32 15, i32 8, i32 412089714, i32 24, i32 4, i32 280487688, i32 29, i32 4, i32 1676513445, i32 34, i32 4, i32 995365215, i32 39, i32 2, i32 108188544, i32 42, i32 8, i32 126745432, i32 51, i32 4, i32 1059174534, i32 56, i32 5, i32 2794059355, i32 62, i32 1, i32 114319, i32 64, i32 5, i32 3696541289, i32 70, i32 4, i32 2270132137, i32 75, i32 1, i32 33312, i32 77, i32 3, i32 1513730174, i32 81, i32 1, i32 45804, i32 83, i32 5, i32 3901130879, i32 89, i32 5, i32 1699682491, i32 95, i32 10, i32 2083827680]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [5 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 2, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 2, i32 1, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 2, i32 0, i32 0, i32 1 }
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
  %t0 = call i64 @shllvm_frame_size(i32 153)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [3 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 153, i32 3, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 152
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s127, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_constant(ptr %s128, i32 0, i64 0)
  call void @shllvm_constant(ptr %s129, i32 2, i64 0)
  call void @shllvm_constant(ptr %s130, i32 3, i64 0)
  call void @shllvm_constant(ptr %s131, i32 3, i64 4677104761256804352)
  call void @shllvm_symbol(ptr %s132, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_constant(ptr %s133, i32 2, i64 1)
  call void @shllvm_symbol(ptr %s134, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s135, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_constant(ptr %s136, i32 3, i64 4613937818241073152)
  call void @shllvm_constant(ptr %s137, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s138, i32 3, i64 4611686018427387904)
  call void @shllvm_symbol(ptr %s139, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_symbol(ptr %s140, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_constant(ptr %s141, i32 3, i64 4662219572839972864)
  call void @shllvm_symbol(ptr %s142, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_symbol(ptr %s143, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_symbol(ptr %s144, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_symbol(ptr %s145, ptr %shr, ptr %unit, i32 11)
  call void @shllvm_symbol(ptr %s146, ptr %shr, ptr %unit, i32 12)
  call void @shllvm_symbol(ptr %s147, ptr %shr, ptr %unit, i32 13)
  call void @shllvm_symbol(ptr %s148, ptr %shr, ptr %unit, i32 14)
  call void @shllvm_symbol(ptr %s149, ptr %shr, ptr %unit, i32 15)
  call void @shllvm_symbol(ptr %s150, ptr %shr, ptr %unit, i32 16)
  call void @shllvm_symbol(ptr %s151, ptr %shr, ptr %unit, i32 17)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s2, ptr %shr, ptr null, i32 6)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s1, i32 5)
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s4, ptr %frame)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s4, i32 4)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s128, align 8
  store i64 %t1, ptr %s7, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s7, i32 2)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s128, align 8
  store i64 %t2, ptr %s9, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s9, i32 3)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s11, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s12, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s12, i32 1, ptr %s11, i32 0, i32 0)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s128, align 8
  store i64 %t3, ptr %s15, align 8
  ; Hermes StoreStackInst
  %t4 = load i64, ptr %s15, align 8
  store i64 %t4, ptr %s14, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s17, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s18, ptr %shr, ptr %unit, ptr %s17, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s128, align 8
  store i64 %t5, ptr %s19, align 8
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s128, align 8
  store i64 %t6, ptr %s20, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s21, ptr %shr, ptr %frame, ptr %s18, ptr %s20, ptr %s19, i32 0, ptr %argv)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s21, i32 2)
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s23, ptr %shr, i32 0)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s23, i32 3)
  ; Hermes LIRLoadConstInst
  %t7 = load i64, ptr %s128, align 8
  store i64 %t7, ptr %s25, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s25, i32 1)
  ; Hermes LIRLoadConstInst
  %t8 = load i64, ptr %s130, align 8
  store i64 %t8, ptr %s27, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s27, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s29, ptr %s2, i32 1)
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s131, align 8
  store i64 %t9, ptr %s30, align 8
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s31, ptr %shr, i32 9, ptr %s29, ptr %s30)
  ; Hermes CondBranchInst
  %t10 = call i32 @shllvm_truthy(ptr %s31)
  %t11 = icmp ne i32 %t10, 0
  br i1 %t11, label %b1, label %b2
b1:
  ; Hermes LIRLoadConstInst
  %t12 = load i64, ptr %s128, align 8
  store i64 %t12, ptr %s33, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s33, i32 0)
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s35, ptr %shr)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s36, ptr %s2, i32 1)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s35, ptr %s132, ptr %s36, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s38, ptr %s2, i32 1)
  ; Hermes LIRLoadConstInst
  %t13 = load i64, ptr %s134, align 8
  store i64 %t13, ptr %s39, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s40, ptr %shr, i32 0, ptr %s39, ptr %s38)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s35, ptr %s135, ptr %s40, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s42, ptr %s2, i32 1)
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s43, ptr %shr, i32 3)
  ; Hermes DefineOwnInDenseArrayInst
  call void @shllvm_define_index(ptr %shr, ptr %s43, i32 0, ptr %s42)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s45, ptr %s2, i32 1)
  ; Hermes LIRLoadConstInst
  %t14 = load i64, ptr %s137, align 8
  store i64 %t14, ptr %s46, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s47, ptr %shr, i32 0, ptr %s45, ptr %s46)
  ; Hermes DefineOwnInDenseArrayInst
  call void @shllvm_define_index(ptr %shr, ptr %s43, i32 1, ptr %s47)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s49, ptr %s2, i32 1)
  ; Hermes LIRLoadConstInst
  %t15 = load i64, ptr %s138, align 8
  store i64 %t15, ptr %s50, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s51, ptr %shr, i32 0, ptr %s49, ptr %s50)
  ; Hermes DefineOwnInDenseArrayInst
  call void @shllvm_define_index(ptr %shr, ptr %s43, i32 2, ptr %s51)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s35, ptr %s139, ptr %s43, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s35, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s55, ptr %s2, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s56, ptr %s2, i32 0)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s55, i32 7, ptr %s56, i32 0, i32 0)
  ; Hermes StoreStackInst
  %t16 = load i64, ptr %s56, align 8
  store i64 %t16, ptr %s14, align 8
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s59, ptr %s2, i32 1)
  ; Hermes LIRLoadConstInst
  %t17 = load i64, ptr %s141, align 8
  store i64 %t17, ptr %s60, align 8
  ; Hermes BinaryModuloInst
  call void @shllvm_binary(ptr %s61, ptr %shr, i32 4, ptr %s59, ptr %s60)
  ; Hermes LIRLoadConstInst
  %t18 = load i64, ptr %s130, align 8
  store i64 %t18, ptr %s62, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s63, ptr %shr, i32 7, ptr %s61, ptr %s62)
  ; Hermes CondBranchInst
  %t19 = call i32 @shllvm_truthy(ptr %s63)
  %t20 = icmp ne i32 %t19, 0
  br i1 %t20, label %b5, label %b6
b2:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s65, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s66, ptr %shr, ptr %unit, ptr %s65, i32 8, i32 0)
  ; Hermes TypeOfInst
  call void @shllvm_unary(ptr %s67, ptr %shr, i32 4, ptr %s66)
  ; Hermes LIRLoadConstInst
  %t21 = load i64, ptr %s143, align 8
  store i64 %t21, ptr %s68, align 8
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s69, ptr %shr, i32 7, ptr %s67, ptr %s68)
  ; Hermes CondBranchInst
  %t22 = call i32 @shllvm_truthy(ptr %s69)
  %t23 = icmp ne i32 %t22, 0
  br i1 %t23, label %b8, label %b9
b3:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s71, ptr %s2, i32 1)
  ; Hermes LIRLoadConstInst
  %t24 = load i64, ptr %s131, align 8
  store i64 %t24, ptr %s72, align 8
  ; Hermes BinaryLessThanInst
  call void @shllvm_binary(ptr %s73, ptr %shr, i32 9, ptr %s71, ptr %s72)
  ; Hermes CondBranchInst
  %t25 = call i32 @shllvm_truthy(ptr %s73)
  %t26 = icmp ne i32 %t25, 0
  br i1 %t26, label %b1, label %b2
b4:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s75, ptr %s2, i32 1)
  ; Hermes UnaryIncInst
  call void @shllvm_unary(ptr %s76, ptr %shr, i32 5, ptr %s75)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s2, ptr %s76, i32 1)
  ; Hermes BranchInst
  br label %b3
b5:
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s79, ptr %s2, i32 3)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s80, ptr %shr, ptr %unit, ptr %s79, i32 10, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s81, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes LIRLoadConstInst
  %t27 = load i64, ptr %s128, align 8
  store i64 %t27, ptr %s82, align 8
  ; Hermes CallInst
  %t28 = getelementptr i64, ptr %argv, i32 0
  %t29 = load i64, ptr %s81, align 8
  store i64 %t29, ptr %t28, align 8
  call void @shllvm_call(ptr %s83, ptr %shr, ptr %frame, ptr %s80, ptr %s79, ptr %s82, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t30 = load i64, ptr %s83, align 8
  store i64 %t30, ptr %s14, align 8
  ; Hermes BranchInst
  br label %b7
b6:
  ; Hermes BranchInst
  br label %b7
b7:
  ; Hermes BranchInst
  br label %b4
b8:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s88, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s89, ptr %shr, ptr %unit, ptr %s88, i32 8, i32 1)
  ; Hermes LIRLoadConstInst
  %t31 = load i64, ptr %s128, align 8
  store i64 %t31, ptr %s90, align 8
  ; Hermes LIRLoadConstInst
  %t32 = load i64, ptr %s128, align 8
  store i64 %t32, ptr %s91, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s92, ptr %shr, ptr %frame, ptr %s89, ptr %s91, ptr %s90, i32 0, ptr %argv)
  ; Hermes StoreStackInst
  %t33 = load i64, ptr %s92, align 8
  store i64 %t33, ptr %s14, align 8
  ; Hermes BranchInst
  br label %b10
b9:
  ; Hermes BranchInst
  br label %b10
b10:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s96, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s97, ptr %shr, ptr %unit, ptr %s96, i32 11, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s98, ptr %s2, i32 2)
  ; Hermes LIRLoadConstInst
  %t34 = load i64, ptr %s128, align 8
  store i64 %t34, ptr %s99, align 8
  ; Hermes LIRLoadConstInst
  %t35 = load i64, ptr %s128, align 8
  store i64 %t35, ptr %s100, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s101, ptr %shr, ptr %frame, ptr %s98, ptr %s100, ptr %s99, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s102, ptr %shr, ptr %unit, ptr %s101, i32 12, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s103, ptr %s2, i32 2)
  ; Hermes LIRLoadConstInst
  %t36 = load i64, ptr %s128, align 8
  store i64 %t36, ptr %s104, align 8
  ; Hermes LIRLoadConstInst
  %t37 = load i64, ptr %s128, align 8
  store i64 %t37, ptr %s105, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s106, ptr %shr, ptr %frame, ptr %s103, ptr %s105, ptr %s104, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s107, ptr %shr, ptr %unit, ptr %s106, i32 13, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s108, ptr %shr, ptr %unit, ptr %s107, i32 14, i32 0)
  ; Hermes LIRLoadConstInst
  %t38 = load i64, ptr %s128, align 8
  store i64 %t38, ptr %s109, align 8
  ; Hermes LIRLoadConstInst
  %t39 = load i64, ptr %s149, align 8
  store i64 %t39, ptr %s110, align 8
  ; Hermes CallInst
  %t40 = getelementptr i64, ptr %argv, i32 0
  %t41 = load i64, ptr %s110, align 8
  store i64 %t41, ptr %t40, align 8
  call void @shllvm_call(ptr %s111, ptr %shr, ptr %frame, ptr %s108, ptr %s107, ptr %s109, i32 1, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s112, ptr %s2, i32 3)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s113, ptr %shr, ptr %unit, ptr %s112, i32 16, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s114, ptr %shr, ptr %s2, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes LIRLoadConstInst
  %t42 = load i64, ptr %s128, align 8
  store i64 %t42, ptr %s115, align 8
  ; Hermes CallInst
  %t43 = getelementptr i64, ptr %argv, i32 0
  %t44 = load i64, ptr %s114, align 8
  store i64 %t44, ptr %t43, align 8
  call void @shllvm_call(ptr %s116, ptr %shr, ptr %frame, ptr %s113, ptr %s112, ptr %s115, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s117, ptr %shr, ptr %unit, ptr %s116, i32 14, i32 0)
  ; Hermes LIRLoadConstInst
  %t45 = load i64, ptr %s128, align 8
  store i64 %t45, ptr %s118, align 8
  ; Hermes LIRLoadConstInst
  %t46 = load i64, ptr %s151, align 8
  store i64 %t46, ptr %s119, align 8
  ; Hermes CallInst
  %t47 = getelementptr i64, ptr %argv, i32 0
  %t48 = load i64, ptr %s119, align 8
  store i64 %t48, ptr %t47, align 8
  call void @shllvm_call(ptr %s120, ptr %shr, ptr %frame, ptr %s117, ptr %s116, ptr %s118, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t49 = load i64, ptr %s128, align 8
  store i64 %t49, ptr %s121, align 8
  ; Hermes LIRLoadConstInst
  %t50 = load i64, ptr %s128, align 8
  store i64 %t50, ptr %s122, align 8
  ; Hermes CallInst
  %t51 = getelementptr i64, ptr %argv, i32 0
  %t52 = load i64, ptr %s102, align 8
  store i64 %t52, ptr %t51, align 8
  %t53 = getelementptr i64, ptr %argv, i32 1
  %t54 = load i64, ptr %s111, align 8
  store i64 %t54, ptr %t53, align 8
  %t55 = getelementptr i64, ptr %argv, i32 2
  %t56 = load i64, ptr %s120, align 8
  store i64 %t56, ptr %t55, align 8
  call void @shllvm_call(ptr %s123, ptr %shr, ptr %frame, ptr %s97, ptr %s122, ptr %s121, i32 3, ptr %argv)
  ; Hermes StoreStackInst
  %t57 = load i64, ptr %s123, align 8
  store i64 %t57, ptr %s14, align 8
  ; Hermes LoadStackInst
  %t58 = load i64, ptr %s14, align 8
  store i64 %t58, ptr %s125, align 8
  ; Hermes ReturnInst
  %t59 = load i64, ptr %s125, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t59
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
  call void @shllvm_constant(ptr %s17, i32 0, i64 0)
  call void @shllvm_constant(ptr %s18, i32 3, i64 4607182418800017408)
  call void @shllvm_symbol(ptr %s19, ptr %shr, ptr %unit, i32 12)
  call void @shllvm_constant(ptr %s20, i32 2, i64 1)
  call void @shllvm_constant(ptr %s21, i32 3, i64 4613937818241073152)
  call void @shllvm_symbol(ptr %s22, ptr %shr, ptr %unit, i32 18)
  call void @shllvm_symbol(ptr %s23, ptr %shr, ptr %unit, i32 19)
  call void @shllvm_symbol(ptr %s24, ptr %shr, ptr %unit, i32 20)
  call void @shllvm_symbol(ptr %s25, ptr %shr, ptr %unit, i32 13)
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
  %t1 = load i64, ptr %s17, align 8
  store i64 %t1, ptr %s7, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s7, i32 0)
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s9, ptr %shr)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s18, align 8
  store i64 %t2, ptr %s10, align 8
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s9, ptr %s19, ptr %s10, i32 1)
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s12, ptr %shr, i32 3)
  call void @shllvm_define_index(ptr %shr, ptr %s12, i32 0, ptr %s22)
  call void @shllvm_define_index(ptr %shr, ptr %s12, i32 1, ptr %s23)
  call void @shllvm_define_index(ptr %shr, ptr %s12, i32 2, ptr %s24)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s9, ptr %s25, ptr %s12, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s9, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s15, ptr %shr, ptr %s3, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes ReturnInst
  %t3 = load i64, ptr %s15, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t3
}

define internal i64 @shllvm_f2(ptr %shr) {
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
  call void @shllvm_symbol(ptr %s5, ptr %shr, ptr %unit, i32 3)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s2, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s3, ptr %shr, ptr %unit, ptr %s2, i32 3, i32 0)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s3, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f3(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_constant(ptr %s9, i32 0, i64 0)
  call void @shllvm_constant(ptr %s10, i32 2, i64 0)
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
  %t1 = load i64, ptr %s9, align 8
  store i64 %t1, ptr %s5, align 8
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s9, align 8
  store i64 %t2, ptr %s6, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s7, ptr %shr, ptr %frame, ptr %s4, ptr %s6, ptr %s5, i32 0, ptr %argv)
  ; Hermes ReturnInst
  %t3 = load i64, ptr %s7, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t3
}

define internal i64 @shllvm_f4(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_symbol(ptr %s9, ptr %shr, ptr %unit, i32 12)
  call void @shllvm_constant(ptr %s10, i32 3, i64 4607182418800017408)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s2, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s3, ptr %shr, ptr %unit, ptr %s2, i32 12, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s10, align 8
  store i64 %t1, ptr %s4, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s5, ptr %shr, i32 0, ptr %s3, ptr %s4)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s2, i32 12, ptr %s5, i32 0, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s7, ptr %s0, i32 0)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s7, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 21, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 5, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
