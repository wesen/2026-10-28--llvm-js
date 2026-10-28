; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [71 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 110, i8 101, i8 115, i8 116, i8 101, i8 100, i8 0, i8 114, i8 101, i8 116, i8 117, i8 114, i8 110, i8 115, i8 0, i8 102, i8 0, i8 114, i8 117, i8 110, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 0, i8 110, i8 97, i8 109, i8 101, i8 0, i8 112, i8 114, i8 111, i8 116, i8 111, i8 116, i8 121, i8 112, i8 101, i8 0, i8 110, i8 111, i8 116, i8 68, i8 101, i8 102, i8 105, i8 110, i8 101, i8 100, i8 72, i8 101, i8 114, i8 101, i8 76, i8 76, i8 86, i8 77, i8 0, i8 110, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [33 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 6, i32 132351545, i32 14, i32 7, i32 152207403, i32 22, i32 1, i32 105991, i32 24, i32 3, i32 2129512166, i32 28, i32 5, i32 2794059355, i32 34, i32 0, i32 0, i32 35, i32 4, i32 3891058614, i32 40, i32 9, i32 2155634493, i32 50, i32 18, i32 1740255881, i32 69, i32 1, i32 114319]
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
declare void @shllvm_boolean(ptr, i32)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_catch_prepare(ptr, ptr, ptr, i32)
declare void @shllvm_catch_value(ptr, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_closure(ptr, ptr, ptr, ptr, ptr, i32)
declare void @shllvm_constant(ptr, i32, i64)
declare ptr @shllvm_create_unit(ptr, i32, ptr, ptr, ptr, i32, ptr, ptr, ptr)
declare void @shllvm_declare_global(ptr, ptr, i32)
declare void @shllvm_define(ptr, ptr, ptr, ptr, i32)
declare ptr @shllvm_enter(ptr, ptr, i32, i32, i32)
declare i64 @shllvm_frame_size(i32)
declare void @shllvm_get_id(ptr, ptr, ptr, ptr, i32, i32)
declare ptr @shllvm_get_unit(ptr, i32)
declare void @shllvm_global(ptr, ptr)
declare void @shllvm_leave(ptr, ptr, ptr)
declare void @shllvm_number(ptr, double)
declare void @shllvm_object(ptr, ptr)
declare void @shllvm_object_parent(ptr, ptr, ptr, ptr)
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

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 124)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [2 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 124, i32 2, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 123
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s107, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_symbol(ptr %s108, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s109, i32 4, i64 0)
  call void @shllvm_constant(ptr %s110, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s111, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_constant(ptr %s112, i32 3, i64 0)
  call void @shllvm_constant(ptr %s113, i32 2, i64 0)
  call void @shllvm_constant(ptr %s114, i32 3, i64 4613937818241073152)
  call void @shllvm_symbol(ptr %s115, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_constant(ptr %s116, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s117, i32 3, i64 4616189618054758400)
  call void @shllvm_symbol(ptr %s118, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s119, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_symbol(ptr %s120, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_constant(ptr %s121, i32 2, i64 1)
  call void @shllvm_symbol(ptr %s122, ptr %shr, ptr %unit, i32 9)
  %t1 = call i64 @shllvm_try_size()
  %try_storage = alloca i8, i64 %t1, align 16
  %try_state = alloca i32, align 4
  store volatile i32 0, ptr %try_state, align 4
  %t2 = call ptr @shllvm_try_begin(ptr %shr, ptr %try_storage)
  %t3 = call i32 @_setjmp(ptr %t2) returns_twice
  %t4 = icmp ne i32 %t3, 0
  br i1 %t4, label %catch.dispatch, label %b0
b0:
  ; Hermes AllocStackInst
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 2)
  ; Hermes LIRLoadConstInst
  %t5 = load volatile i64, ptr %s109, align 8
  store volatile i64 %t5, ptr %s3, align 8
  ; Hermes StoreStackInst
  %t6 = load volatile i64, ptr %s3, align 8
  store volatile i64 %t6, ptr %s0, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s5, ptr %shr)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s6, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s5, i32 1, ptr %s6, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s8, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s5, i32 2, ptr %s8, i32 0, i32 0)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t7 = load volatile i64, ptr %s110, align 8
  store volatile i64 %t7, ptr %s11, align 8
  ; Hermes StoreStackInst
  %t8 = load volatile i64, ptr %s11, align 8
  store volatile i64 %t8, ptr %s10, align 8
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s13, ptr %shr, ptr %unit, ptr %s5, i32 5, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s14, ptr %shr, ptr %unit, ptr %s5, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t9 = load volatile i64, ptr %s112, align 8
  store volatile i64 %t9, ptr %s15, align 8
  ; Hermes CallInst
  %t10 = getelementptr i64, ptr %argv, i32 0
  %t11 = load volatile i64, ptr %s15, align 8
  store volatile i64 %t11, ptr %t10, align 8
  call void @shllvm_call(ptr %s16, ptr %shr, ptr %frame, ptr %s14, ptr %s11, ptr %s11, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s17, ptr %shr, ptr %unit, ptr %s5, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t12 = load volatile i64, ptr %s114, align 8
  store volatile i64 %t12, ptr %s18, align 8
  ; Hermes CallInst
  %t13 = getelementptr i64, ptr %argv, i32 0
  %t14 = load volatile i64, ptr %s18, align 8
  store volatile i64 %t14, ptr %t13, align 8
  call void @shllvm_call(ptr %s19, ptr %shr, ptr %frame, ptr %s17, ptr %s11, ptr %s11, i32 1, ptr %argv)
  ; Hermes CallInst
  %t15 = getelementptr i64, ptr %argv, i32 0
  %t16 = load volatile i64, ptr %s16, align 8
  store volatile i64 %t16, ptr %t15, align 8
  %t17 = getelementptr i64, ptr %argv, i32 1
  %t18 = load volatile i64, ptr %s19, align 8
  store volatile i64 %t18, ptr %t17, align 8
  call void @shllvm_call(ptr %s20, ptr %shr, ptr %frame, ptr %s13, ptr %s11, ptr %s11, i32 2, ptr %argv)
  ; Hermes StoreStackInst
  %t19 = load volatile i64, ptr %s20, align 8
  store volatile i64 %t19, ptr %s10, align 8
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s22, ptr %shr, ptr %unit, ptr %s5, i32 5, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s23, ptr %shr, ptr %unit, ptr %s5, i32 2, i32 0)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s24, ptr %shr, ptr %frame, ptr %s23, ptr %s11, ptr %s11, i32 0, ptr %argv)
  ; Hermes CallInst
  %t20 = getelementptr i64, ptr %argv, i32 0
  %t21 = load volatile i64, ptr %s24, align 8
  store volatile i64 %t21, ptr %t20, align 8
  call void @shllvm_call(ptr %s25, ptr %shr, ptr %frame, ptr %s22, ptr %s11, ptr %s11, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t22 = load volatile i64, ptr %s25, align 8
  store volatile i64 %t22, ptr %s10, align 8
  ; Hermes LIRLoadConstInst
  %t23 = load volatile i64, ptr %s115, align 8
  store volatile i64 %t23, ptr %s27, align 8
  ; Hermes StoreStackInst
  %t24 = load volatile i64, ptr %s27, align 8
  store volatile i64 %t24, ptr %s0, align 8
  ; Hermes LIRLoadConstInst
  %t25 = load volatile i64, ptr %s116, align 8
  store volatile i64 %t25, ptr %s29, align 8
  ; Hermes LIRLoadConstInst
  %t26 = load volatile i64, ptr %s117, align 8
  store volatile i64 %t26, ptr %s30, align 8
  ; Hermes LIRLoadConstInst
  %t27 = load volatile i64, ptr %s118, align 8
  store volatile i64 %t27, ptr %s31, align 8
  ; Hermes BranchInst
  br label %edge0
b1:
  ; Hermes PhiInst
  ; Hermes TryStartInst
  store volatile i32 1, ptr %try_state, align 4
  br label %b5
b2:
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s35, ptr %shr, ptr %unit, ptr %s5, i32 5, i32 1)
  ; Hermes LoadStackInst
  %t28 = load volatile i64, ptr %s0, align 8
  store volatile i64 %t28, ptr %s36, align 8
  ; Hermes UnionNarrowTrustedInst
  %t29 = load volatile i64, ptr %s36, align 8
  store volatile i64 %t29, ptr %s37, align 8
  ; Hermes CallInst
  %t30 = getelementptr i64, ptr %argv, i32 0
  %t31 = load volatile i64, ptr %s37, align 8
  store volatile i64 %t31, ptr %t30, align 8
  call void @shllvm_call(ptr %s38, ptr %shr, ptr %frame, ptr %s35, ptr %s11, ptr %s11, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t32 = load volatile i64, ptr %s38, align 8
  store volatile i64 %t32, ptr %s10, align 8
  ; Hermes TryStartInst
  store volatile i32 2, ptr %try_state, align 4
  br label %b15
b3:
  ; Hermes FAddInst
  %t33 = load volatile i64, ptr %s33, align 8
  %t34 = bitcast i64 %t33 to double
  %t35 = load volatile i64, ptr %s29, align 8
  %t36 = bitcast i64 %t35 to double
  %t37 = fadd double %t34, %t36
  call void @shllvm_number(ptr %s41, double %t37)
  ; Hermes FLessThanInst
  %t38 = load volatile i64, ptr %s41, align 8
  %t39 = load volatile i64, ptr %s30, align 8
  %t40 = bitcast i64 %t38 to double
  %t41 = bitcast i64 %t39 to double
  %t42 = fcmp olt double %t40, %t41
  %t43 = zext i1 %t42 to i32
  call void @shllvm_boolean(ptr %s42, i32 %t43)
  ; Hermes CondBranchInst
  %t44 = call i32 @shllvm_truthy(ptr %s42)
  %t45 = icmp ne i32 %t44, 0
  br i1 %t45, label %edge1, label %b2
b4:
  ; Hermes CatchInst
  store volatile i32 0, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s44, ptr %shr)
  ; Hermes LoadStackInst
  %t46 = load volatile i64, ptr %s0, align 8
  store volatile i64 %t46, ptr %s45, align 8
  ; Hermes UnionNarrowTrustedInst
  %t47 = load volatile i64, ptr %s45, align 8
  store volatile i64 %t47, ptr %s46, align 8
  ; Hermes StringConcatInst
  %t48 = load volatile i64, ptr %s46, align 8
  store volatile i64 %t48, ptr %s47, align 8
  call void @shllvm_binary(ptr %s47, ptr %shr, i32 0, ptr %s47, ptr %s31)
  ; Hermes StoreStackInst
  %t49 = load volatile i64, ptr %s47, align 8
  store volatile i64 %t49, ptr %s0, align 8
  ; Hermes StoreStackInst
  %t50 = load volatile i64, ptr %s47, align 8
  store volatile i64 %t50, ptr %s10, align 8
  ; Hermes ThrowInst
  call void @shllvm_throw(ptr %shr, ptr %s44)
  unreachable
b5:
  ; Hermes FEqualInst
  %t51 = load volatile i64, ptr %s33, align 8
  %t52 = load volatile i64, ptr %s29, align 8
  %t53 = bitcast i64 %t51 to double
  %t54 = bitcast i64 %t52 to double
  %t55 = fcmp oeq double %t53, %t54
  %t56 = zext i1 %t55 to i32
  call void @shllvm_boolean(ptr %s51, i32 %t56)
  ; Hermes CondBranchInst
  %t57 = call i32 @shllvm_truthy(ptr %s51)
  %t58 = icmp ne i32 %t57, 0
  br i1 %t58, label %b6, label %b7
b6:
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b8
b7:
  ; Hermes FEqualInst
  %t59 = load volatile i64, ptr %s33, align 8
  %t60 = load volatile i64, ptr %s18, align 8
  %t61 = bitcast i64 %t59 to double
  %t62 = bitcast i64 %t60 to double
  %t63 = fcmp oeq double %t61, %t62
  %t64 = zext i1 %t63 to i32
  call void @shllvm_boolean(ptr %s54, i32 %t64)
  ; Hermes CondBranchInst
  %t65 = call i32 @shllvm_truthy(ptr %s54)
  %t66 = icmp ne i32 %t65, 0
  br i1 %t66, label %b9, label %b10
b8:
  ; Hermes LoadStackInst
  %t67 = load volatile i64, ptr %s0, align 8
  store volatile i64 %t67, ptr %s56, align 8
  ; Hermes UnionNarrowTrustedInst
  %t68 = load volatile i64, ptr %s56, align 8
  store volatile i64 %t68, ptr %s57, align 8
  ; Hermes StringConcatInst
  %t69 = load volatile i64, ptr %s57, align 8
  store volatile i64 %t69, ptr %s58, align 8
  call void @shllvm_binary(ptr %s58, ptr %shr, i32 0, ptr %s58, ptr %s31)
  ; Hermes StoreStackInst
  %t70 = load volatile i64, ptr %s58, align 8
  store volatile i64 %t70, ptr %s0, align 8
  ; Hermes StoreStackInst
  %t71 = load volatile i64, ptr %s58, align 8
  store volatile i64 %t71, ptr %s10, align 8
  ; Hermes BranchInst
  br label %b3
b9:
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b11
b10:
  ; Hermes LoadStackInst
  %t72 = load volatile i64, ptr %s0, align 8
  store volatile i64 %t72, ptr %s63, align 8
  ; Hermes UnionNarrowTrustedInst
  %t73 = load volatile i64, ptr %s63, align 8
  store volatile i64 %t73, ptr %s64, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s65, ptr %shr, i32 0, ptr %s64, ptr %s33)
  ; Hermes StoreStackInst
  %t74 = load volatile i64, ptr %s65, align 8
  store volatile i64 %t74, ptr %s0, align 8
  ; Hermes StoreStackInst
  %t75 = load volatile i64, ptr %s65, align 8
  store volatile i64 %t75, ptr %s10, align 8
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b12
b11:
  ; Hermes LoadStackInst
  %t76 = load volatile i64, ptr %s0, align 8
  store volatile i64 %t76, ptr %s69, align 8
  ; Hermes UnionNarrowTrustedInst
  %t77 = load volatile i64, ptr %s69, align 8
  store volatile i64 %t77, ptr %s70, align 8
  ; Hermes StringConcatInst
  %t78 = load volatile i64, ptr %s70, align 8
  store volatile i64 %t78, ptr %s71, align 8
  call void @shllvm_binary(ptr %s71, ptr %shr, i32 0, ptr %s71, ptr %s31)
  ; Hermes StoreStackInst
  %t79 = load volatile i64, ptr %s71, align 8
  store volatile i64 %t79, ptr %s0, align 8
  ; Hermes StoreStackInst
  %t80 = load volatile i64, ptr %s71, align 8
  store volatile i64 %t80, ptr %s10, align 8
  ; Hermes BranchInst
  br label %b2
b12:
  ; Hermes LoadStackInst
  %t81 = load volatile i64, ptr %s0, align 8
  store volatile i64 %t81, ptr %s75, align 8
  ; Hermes UnionNarrowTrustedInst
  %t82 = load volatile i64, ptr %s75, align 8
  store volatile i64 %t82, ptr %s76, align 8
  ; Hermes StringConcatInst
  %t83 = load volatile i64, ptr %s76, align 8
  store volatile i64 %t83, ptr %s77, align 8
  call void @shllvm_binary(ptr %s77, ptr %shr, i32 0, ptr %s77, ptr %s31)
  ; Hermes StoreStackInst
  %t84 = load volatile i64, ptr %s77, align 8
  store volatile i64 %t84, ptr %s0, align 8
  ; Hermes StoreStackInst
  %t85 = load volatile i64, ptr %s77, align 8
  store volatile i64 %t85, ptr %s10, align 8
  ; Hermes BranchInst
  br label %b3
b13:
  ; Hermes CatchInst
  store volatile i32 0, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s81, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s82, ptr %shr, ptr %unit, ptr %s5, i32 5, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s83, ptr %shr, ptr %unit, ptr %s81, i32 7, i32 0)
  ; Hermes CallInst
  %t86 = getelementptr i64, ptr %argv, i32 0
  %t87 = load volatile i64, ptr %s83, align 8
  store volatile i64 %t87, ptr %t86, align 8
  call void @shllvm_call(ptr %s84, ptr %shr, ptr %frame, ptr %s82, ptr %s11, ptr %s11, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t88 = load volatile i64, ptr %s84, align 8
  store volatile i64 %t88, ptr %s10, align 8
  ; Hermes BranchInst
  br label %b14
b14:
  ; Hermes TryStartInst
  store volatile i32 3, ptr %try_state, align 4
  br label %b18
b15:
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s88, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s89, ptr %shr, ptr %unit, ptr %s88, i32 8, i32 0)
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object_parent(ptr %s90, ptr %shr, ptr %unit, ptr %s89)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s91, ptr %shr, ptr %frame, ptr %s88, ptr %s90, ptr %s88, i32 0, ptr %argv)
  ; Hermes StoreStackInst
  %t89 = load volatile i64, ptr %s90, align 8
  store volatile i64 %t89, ptr %s10, align 8
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b14
b16:
  ; Hermes CatchInst
  store volatile i32 0, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s94, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s95, ptr %shr, ptr %unit, ptr %s5, i32 5, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s96, ptr %shr, ptr %unit, ptr %s94, i32 7, i32 0)
  ; Hermes CallInst
  %t90 = getelementptr i64, ptr %argv, i32 0
  %t91 = load volatile i64, ptr %s96, align 8
  store volatile i64 %t91, ptr %t90, align 8
  call void @shllvm_call(ptr %s97, ptr %shr, ptr %frame, ptr %s95, ptr %s11, ptr %s11, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t92 = load volatile i64, ptr %s97, align 8
  store volatile i64 %t92, ptr %s10, align 8
  ; Hermes BranchInst
  br label %b17
b17:
  ; Hermes LoadStackInst
  %t93 = load volatile i64, ptr %s10, align 8
  store volatile i64 %t93, ptr %s100, align 8
  ; Hermes ReturnInst
  %t94 = load volatile i64, ptr %s100, align 8
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t94
b18:
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s102, ptr %shr, ptr %unit, ptr %s5, i32 5, i32 1)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s103, ptr %shr, ptr %unit, ptr %s5, i32 9, i32 1)
  ; Hermes CallInst
  %t95 = getelementptr i64, ptr %argv, i32 0
  %t96 = load volatile i64, ptr %s103, align 8
  store volatile i64 %t96, ptr %t95, align 8
  call void @shllvm_call(ptr %s104, ptr %shr, ptr %frame, ptr %s102, ptr %s11, ptr %s11, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t97 = load volatile i64, ptr %s104, align 8
  store volatile i64 %t97, ptr %s10, align 8
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b17
catch.dispatch:
  %t98 = load volatile i32, ptr %try_state, align 4
  call void @shllvm_catch_prepare(ptr %shr, ptr %storage, ptr %frame, i32 2)
  switch i32 %t98, label %catch.rethrow [
    i32 1, label %b4
    i32 2, label %b13
    i32 3, label %b16
  ]
catch.rethrow:
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_rethrow(ptr %shr)
  unreachable
edge0:
  %t99 = load volatile i64, ptr %s15, align 8
  store volatile i64 %t99, ptr %s33, align 8
  br label %b1
edge1:
  %t100 = load volatile i64, ptr %s41, align 8
  store volatile i64 %t100, ptr %s33, align 8
  br label %b1
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 65)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 65, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 64
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s53, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s54, i32 3, i64 4625196817309499392)
  call void @shllvm_symbol(ptr %s55, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_symbol(ptr %s56, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_constant(ptr %s57, i32 0, i64 0)
  call void @shllvm_constant(ptr %s58, i32 2, i64 0)
  call void @shllvm_constant(ptr %s59, i32 3, i64 4616189618054758400)
  call void @shllvm_constant(ptr %s60, i32 3, i64 4611686018427387904)
  call void @shllvm_constant(ptr %s61, i32 1, i64 0)
  call void @shllvm_constant(ptr %s62, i32 3, i64 0)
  call void @shllvm_constant(ptr %s63, i32 3, i64 4620693217682128896)
  %t1 = call i64 @shllvm_try_size()
  %try_storage = alloca i8, i64 %t1, align 16
  %try_state = alloca i32, align 4
  store volatile i32 0, ptr %try_state, align 4
  %t2 = call ptr @shllvm_try_begin(ptr %shr, ptr %try_storage)
  %t3 = call i32 @_setjmp(ptr %t2) returns_twice
  %t4 = icmp ne i32 %t3, 0
  br i1 %t4, label %catch.dispatch, label %b0
b0:
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t5 = load volatile i64, ptr %s53, align 8
  store volatile i64 %t5, ptr %s1, align 8
  ; Hermes StoreStackInst
  %t6 = load volatile i64, ptr %s1, align 8
  store volatile i64 %t6, ptr %s0, align 8
  ; Hermes TryStartInst
  store volatile i32 1, ptr %try_state, align 4
  br label %b2
b1:
  ; Hermes CatchInst
  store volatile i32 0, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s4, ptr %shr)
  ; Hermes LoadStackInst
  %t7 = load volatile i64, ptr %s0, align 8
  store volatile i64 %t7, ptr %s5, align 8
  ; Hermes LIRLoadConstInst
  %t8 = load volatile i64, ptr %s54, align 8
  store volatile i64 %t8, ptr %s6, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s7, ptr %shr, i32 0, ptr %s5, ptr %s6)
  ; Hermes StoreStackInst
  %t9 = load volatile i64, ptr %s7, align 8
  store volatile i64 %t9, ptr %s0, align 8
  ; Hermes ThrowInst
  call void @shllvm_throw(ptr %shr, ptr %s4)
  unreachable
b2:
  ; Hermes TryStartInst
  store volatile i32 2, ptr %try_state, align 4
  br label %b5
b3:
  ; Hermes CatchInst
  store volatile i32 1, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s11, ptr %shr)
  ; Hermes LoadStackInst
  %t10 = load volatile i64, ptr %s0, align 8
  store volatile i64 %t10, ptr %s12, align 8
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s13, ptr %shr, ptr %unit, ptr %s11, i32 10, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s14, ptr %shr, ptr %unit, ptr %s11, i32 4, i32 0)
  ; Hermes LIRLoadConstInst
  %t11 = load volatile i64, ptr %s57, align 8
  store volatile i64 %t11, ptr %s15, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s16, ptr %shr, ptr %frame, ptr %s14, ptr %s11, ptr %s15, i32 0, ptr %argv)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s17, ptr %shr, i32 0, ptr %s13, ptr %s16)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s18, ptr %shr, i32 0, ptr %s12, ptr %s17)
  ; Hermes StoreStackInst
  %t12 = load volatile i64, ptr %s18, align 8
  store volatile i64 %t12, ptr %s0, align 8
  ; Hermes BranchInst
  br label %b4
b4:
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b11
b5:
  ; Hermes TryStartInst
  store volatile i32 3, ptr %try_state, align 4
  br label %b7
b6:
  ; Hermes CatchInst
  store volatile i32 2, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s23, ptr %shr)
  ; Hermes LoadStackInst
  %t13 = load volatile i64, ptr %s0, align 8
  store volatile i64 %t13, ptr %s24, align 8
  ; Hermes LIRLoadConstInst
  %t14 = load volatile i64, ptr %s59, align 8
  store volatile i64 %t14, ptr %s25, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s26, ptr %shr, i32 0, ptr %s24, ptr %s25)
  ; Hermes StoreStackInst
  %t15 = load volatile i64, ptr %s26, align 8
  store volatile i64 %t15, ptr %s0, align 8
  ; Hermes ThrowInst
  call void @shllvm_throw(ptr %shr, ptr %s23)
  unreachable
b7:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s29, ptr %frame, i32 1)
  ; Hermes LoadStackInst
  %t16 = load volatile i64, ptr %s0, align 8
  store volatile i64 %t16, ptr %s30, align 8
  ; Hermes LIRLoadConstInst
  %t17 = load volatile i64, ptr %s60, align 8
  store volatile i64 %t17, ptr %s31, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s32, ptr %shr, i32 0, ptr %s30, ptr %s31)
  ; Hermes StoreStackInst
  %t18 = load volatile i64, ptr %s32, align 8
  store volatile i64 %t18, ptr %s0, align 8
  ; Hermes CondBranchInst
  %t19 = call i32 @shllvm_truthy(ptr %s29)
  %t20 = icmp ne i32 %t19, 0
  br i1 %t20, label %b8, label %b9
b8:
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object(ptr %s35, ptr %shr)
  call void @shllvm_define(ptr %shr, ptr %s35, ptr %s55, ptr %s61, i32 1)
  call void @shllvm_define(ptr %shr, ptr %s35, ptr %s56, ptr %s61, i32 1)
  ; Hermes PrStoreInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s35, i32 10, ptr %s29, i32 1, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s37, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes PrStoreInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s35, i32 4, ptr %s37, i32 1, i32 0)
  ; Hermes ThrowInst
  call void @shllvm_throw(ptr %shr, ptr %s35)
  unreachable
b9:
  ; Hermes TryEndInst
  store volatile i32 2, ptr %try_state, align 4
  br label %b10
b10:
  ; Hermes LoadStackInst
  %t21 = load volatile i64, ptr %s0, align 8
  store volatile i64 %t21, ptr %s41, align 8
  ; Hermes LIRLoadConstInst
  %t22 = load volatile i64, ptr %s63, align 8
  store volatile i64 %t22, ptr %s42, align 8
  ; Hermes LIRLoadConstInst
  %t23 = load volatile i64, ptr %s59, align 8
  store volatile i64 %t23, ptr %s43, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s44, ptr %shr, i32 0, ptr %s41, ptr %s43)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s45, ptr %shr, i32 0, ptr %s44, ptr %s42)
  ; Hermes StoreStackInst
  %t24 = load volatile i64, ptr %s45, align 8
  store volatile i64 %t24, ptr %s0, align 8
  ; Hermes TryEndInst
  store volatile i32 1, ptr %try_state, align 4
  br label %b4
b11:
  ; Hermes LoadStackInst
  %t25 = load volatile i64, ptr %s0, align 8
  store volatile i64 %t25, ptr %s48, align 8
  ; Hermes LIRLoadConstInst
  %t26 = load volatile i64, ptr %s54, align 8
  store volatile i64 %t26, ptr %s49, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s50, ptr %shr, i32 0, ptr %s48, ptr %s49)
  ; Hermes StoreStackInst
  %t27 = load volatile i64, ptr %s50, align 8
  store volatile i64 %t27, ptr %s0, align 8
  ; Hermes ReturnInst
  %t28 = load volatile i64, ptr %s50, align 8
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t28
catch.dispatch:
  %t29 = load volatile i32, ptr %try_state, align 4
  call void @shllvm_catch_prepare(ptr %shr, ptr %storage, ptr %frame, i32 0)
  switch i32 %t29, label %catch.rethrow [
    i32 1, label %b1
    i32 2, label %b3
    i32 3, label %b6
  ]
catch.rethrow:
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_rethrow(ptr %shr)
  unreachable
}

define internal i64 @shllvm_f2(ptr %shr) {
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
  call void @shllvm_constant(ptr %s7, i32 3, i64 4631107791820423168)
  %t1 = call i64 @shllvm_try_size()
  %try_storage = alloca i8, i64 %t1, align 16
  %try_state = alloca i32, align 4
  store volatile i32 0, ptr %try_state, align 4
  %t2 = call ptr @shllvm_try_begin(ptr %shr, ptr %try_storage)
  %t3 = call i32 @_setjmp(ptr %t2) returns_twice
  %t4 = icmp ne i32 %t3, 0
  br i1 %t4, label %catch.dispatch, label %b0
b0:
  ; Hermes TryStartInst
  store volatile i32 1, ptr %try_state, align 4
  br label %b2
b1:
  ; Hermes CatchInst
  store volatile i32 0, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s1, ptr %shr)
  ; Hermes LIRLoadConstInst
  %t5 = load volatile i64, ptr %s7, align 8
  store volatile i64 %t5, ptr %s2, align 8
  ; Hermes ReturnInst
  %t6 = load volatile i64, ptr %s2, align 8
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t6
b2:
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b3
b3:
  ; Hermes LIRLoadConstInst
  %t7 = load volatile i64, ptr %s7, align 8
  store volatile i64 %t7, ptr %s5, align 8
  ; Hermes ReturnInst
  %t8 = load volatile i64, ptr %s5, align 8
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
  %t0 = call i64 @shllvm_frame_size(i32 4)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 4, i32 0, i32 %unit_index)
  %roots = call ptr @shllvm_roots(ptr %storage)
  %unit = call ptr @shllvm_get_unit(ptr %shr, i32 %unit_index)
  %s0 = getelementptr i64, ptr %roots, i32 0
  %s1 = getelementptr i64, ptr %roots, i32 1
  %s2 = getelementptr i64, ptr %roots, i32 2
  %scratch = getelementptr i64, ptr %roots, i32 3
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_constant(ptr %s2, i32 3, i64 4607182418800017408)
  br label %b0
b0:
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s2, align 8
  store i64 %t1, ptr %s0, align 8
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s0, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f4(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 4)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 4, i32 0, i32 %unit_index)
  %roots = call ptr @shllvm_roots(ptr %storage)
  %unit = call ptr @shllvm_get_unit(ptr %shr, i32 %unit_index)
  %s0 = getelementptr i64, ptr %roots, i32 0
  %s1 = getelementptr i64, ptr %roots, i32 1
  %s2 = getelementptr i64, ptr %roots, i32 2
  %scratch = getelementptr i64, ptr %roots, i32 3
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_constant(ptr %s2, i32 3, i64 4630826316843712512)
  br label %b0
b0:
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s2, align 8
  store i64 %t1, ptr %s0, align 8
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s0, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
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
