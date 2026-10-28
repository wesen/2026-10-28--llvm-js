; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [66 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 103, i8 114, i8 101, i8 101, i8 116, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 119, i8 111, i8 114, i8 108, i8 100, i8 0, i8 108, i8 101, i8 110, i8 103, i8 116, i8 104, i8 0, i8 99, i8 104, i8 97, i8 114, i8 67, i8 111, i8 100, i8 101, i8 65, i8 116, i8 0, i8 97, i8 98, i8 99, i8 0, i8 115, i8 108, i8 105, i8 99, i8 101, i8 0, i8 97, i8 0, i8 98, i8 0, i8 104, i8 101, i8 108, i8 108, i8 111, i8 32, i8 0, i8 33, i8 0]
@shllvm_utf16 = private constant [8 x i16] [i16 55348, i16 56606, i16 0, i16 233, i16 0, i16 55357, i16 56832, i16 0]
@shllvm_strings = private constant [42 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 5, i32 486618146, i32 13, i32 5, i32 2794059355, i32 19, i32 5, i32 3688548067, i32 2147483648, i32 2, i32 3041246460, i32 25, i32 6, i32 363462486, i32 2147483651, i32 1, i32 240250, i32 32, i32 10, i32 360288817, i32 43, i32 3, i32 1486459893, i32 47, i32 5, i32 377550857, i32 53, i32 3, i32 1386057908, i32 2147483653, i32 2, i32 3136362617, i32 57, i32 6, i32 3748500907, i32 64, i32 1, i32 34353]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [2 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 1, i32 0, i32 2 }
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
declare void @shllvm_object(ptr, ptr)
declare void @shllvm_param(ptr, ptr, i32)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_set_id(ptr, ptr, ptr, i32, ptr, i32, i32)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 86)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [4 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 86, i32 4, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 85
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s69, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_constant(ptr %s70, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s71, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s72, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_constant(ptr %s73, i32 2, i64 0)
  call void @shllvm_symbol(ptr %s74, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s75, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_symbol(ptr %s76, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_symbol(ptr %s77, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_constant(ptr %s78, i32 3, i64 0)
  call void @shllvm_constant(ptr %s79, i32 3, i64 4607182418800017408)
  call void @shllvm_symbol(ptr %s80, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_symbol(ptr %s81, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_symbol(ptr %s82, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_symbol(ptr %s83, ptr %shr, ptr %unit, i32 11)
  call void @shllvm_constant(ptr %s84, i32 3, i64 4631107791820423168)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s70, align 8
  store i64 %t1, ptr %s2, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s2, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s4, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s5, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s5, i32 1, ptr %s4, i32 0, i32 0)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s70, align 8
  store i64 %t2, ptr %s8, align 8
  ; Hermes StoreStackInst
  %t3 = load i64, ptr %s8, align 8
  store i64 %t3, ptr %s7, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s10, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s11, ptr %shr, ptr %unit, ptr %s10, i32 2, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s12, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s13, ptr %shr, ptr %unit, ptr %s12, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s70, align 8
  store i64 %t4, ptr %s14, align 8
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s70, align 8
  store i64 %t5, ptr %s15, align 8
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s72, align 8
  store i64 %t6, ptr %s16, align 8
  ; Hermes CallInst
  %t7 = getelementptr i64, ptr %argv, i32 0
  %t8 = load i64, ptr %s16, align 8
  store i64 %t8, ptr %t7, align 8
  call void @shllvm_call(ptr %s17, ptr %shr, ptr %frame, ptr %s13, ptr %s15, ptr %s14, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s74, align 8
  store i64 %t9, ptr %s18, align 8
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s19, ptr %shr, ptr %unit, ptr %s18, i32 5, i32 0)
  ; Hermes LIRLoadConstInst
  %t10 = load i64, ptr %s76, align 8
  store i64 %t10, ptr %s20, align 8
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s21, ptr %shr, ptr %unit, ptr %s20, i32 7, i32 0)
  ; Hermes LIRLoadConstInst
  %t11 = load i64, ptr %s70, align 8
  store i64 %t11, ptr %s22, align 8
  ; Hermes LIRLoadConstInst
  %t12 = load i64, ptr %s76, align 8
  store i64 %t12, ptr %s23, align 8
  ; Hermes LIRLoadConstInst
  %t13 = load i64, ptr %s78, align 8
  store i64 %t13, ptr %s24, align 8
  ; Hermes CallInst
  %t14 = getelementptr i64, ptr %argv, i32 0
  %t15 = load i64, ptr %s24, align 8
  store i64 %t15, ptr %t14, align 8
  call void @shllvm_call(ptr %s25, ptr %shr, ptr %frame, ptr %s21, ptr %s23, ptr %s22, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t16 = load i64, ptr %s74, align 8
  store i64 %t16, ptr %s26, align 8
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s27, ptr %shr, ptr %unit, ptr %s26, i32 7, i32 0)
  ; Hermes LIRLoadConstInst
  %t17 = load i64, ptr %s70, align 8
  store i64 %t17, ptr %s28, align 8
  ; Hermes LIRLoadConstInst
  %t18 = load i64, ptr %s74, align 8
  store i64 %t18, ptr %s29, align 8
  ; Hermes LIRLoadConstInst
  %t19 = load i64, ptr %s79, align 8
  store i64 %t19, ptr %s30, align 8
  ; Hermes CallInst
  %t20 = getelementptr i64, ptr %argv, i32 0
  %t21 = load i64, ptr %s30, align 8
  store i64 %t21, ptr %t20, align 8
  call void @shllvm_call(ptr %s31, ptr %shr, ptr %frame, ptr %s27, ptr %s29, ptr %s28, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t22 = load i64, ptr %s70, align 8
  store i64 %t22, ptr %s32, align 8
  ; Hermes LIRLoadConstInst
  %t23 = load i64, ptr %s70, align 8
  store i64 %t23, ptr %s33, align 8
  ; Hermes CallInst
  %t24 = getelementptr i64, ptr %argv, i32 0
  %t25 = load i64, ptr %s17, align 8
  store i64 %t25, ptr %t24, align 8
  %t26 = getelementptr i64, ptr %argv, i32 1
  %t27 = load i64, ptr %s19, align 8
  store i64 %t27, ptr %t26, align 8
  %t28 = getelementptr i64, ptr %argv, i32 2
  %t29 = load i64, ptr %s25, align 8
  store i64 %t29, ptr %t28, align 8
  %t30 = getelementptr i64, ptr %argv, i32 3
  %t31 = load i64, ptr %s31, align 8
  store i64 %t31, ptr %t30, align 8
  call void @shllvm_call(ptr %s34, ptr %shr, ptr %frame, ptr %s11, ptr %s33, ptr %s32, i32 4, ptr %argv)
  ; Hermes StoreStackInst
  %t32 = load i64, ptr %s34, align 8
  store i64 %t32, ptr %s7, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s36, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s37, ptr %shr, ptr %unit, ptr %s36, i32 2, i32 1)
  ; Hermes LIRLoadConstInst
  %t33 = load i64, ptr %s80, align 8
  store i64 %t33, ptr %s38, align 8
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s39, ptr %shr, ptr %unit, ptr %s38, i32 9, i32 0)
  ; Hermes LIRLoadConstInst
  %t34 = load i64, ptr %s70, align 8
  store i64 %t34, ptr %s40, align 8
  ; Hermes LIRLoadConstInst
  %t35 = load i64, ptr %s80, align 8
  store i64 %t35, ptr %s41, align 8
  ; Hermes LIRLoadConstInst
  %t36 = load i64, ptr %s79, align 8
  store i64 %t36, ptr %s42, align 8
  ; Hermes CallInst
  %t37 = getelementptr i64, ptr %argv, i32 0
  %t38 = load i64, ptr %s42, align 8
  store i64 %t38, ptr %t37, align 8
  call void @shllvm_call(ptr %s43, ptr %shr, ptr %frame, ptr %s39, ptr %s41, ptr %s40, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t39 = load i64, ptr %s82, align 8
  store i64 %t39, ptr %s44, align 8
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s45, ptr %shr, ptr %unit, ptr %s44, i32 5, i32 0)
  ; Hermes LIRLoadConstInst
  %t40 = load i64, ptr %s83, align 8
  store i64 %t40, ptr %s46, align 8
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s47, ptr %shr, ptr %unit, ptr %s46, i32 5, i32 0)
  ; Hermes LIRLoadConstInst
  %t41 = load i64, ptr %s70, align 8
  store i64 %t41, ptr %s48, align 8
  ; Hermes LIRLoadConstInst
  %t42 = load i64, ptr %s70, align 8
  store i64 %t42, ptr %s49, align 8
  ; Hermes CallInst
  %t43 = getelementptr i64, ptr %argv, i32 0
  %t44 = load i64, ptr %s43, align 8
  store i64 %t44, ptr %t43, align 8
  %t45 = getelementptr i64, ptr %argv, i32 1
  %t46 = load i64, ptr %s45, align 8
  store i64 %t46, ptr %t45, align 8
  %t47 = getelementptr i64, ptr %argv, i32 2
  %t48 = load i64, ptr %s47, align 8
  store i64 %t48, ptr %t47, align 8
  call void @shllvm_call(ptr %s50, ptr %shr, ptr %frame, ptr %s37, ptr %s49, ptr %s48, i32 3, ptr %argv)
  ; Hermes StoreStackInst
  %t49 = load i64, ptr %s50, align 8
  store i64 %t49, ptr %s7, align 8
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s52, ptr %shr)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s52, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s54, ptr %s0, i32 0)
  ; Hermes LIRLoadConstInst
  %t50 = load i64, ptr %s84, align 8
  store i64 %t50, ptr %s55, align 8
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s54, i32 10, ptr %s55, i32 0, i32 0)
  ; Hermes LIRLoadConstInst
  %t51 = load i64, ptr %s84, align 8
  store i64 %t51, ptr %s57, align 8
  ; Hermes StoreStackInst
  %t52 = load i64, ptr %s57, align 8
  store i64 %t52, ptr %s7, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s59, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s60, ptr %shr, ptr %unit, ptr %s59, i32 2, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s61, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s62, ptr %shr, ptr %unit, ptr %s61, i32 10, i32 0)
  ; Hermes LIRLoadConstInst
  %t53 = load i64, ptr %s70, align 8
  store i64 %t53, ptr %s63, align 8
  ; Hermes LIRLoadConstInst
  %t54 = load i64, ptr %s70, align 8
  store i64 %t54, ptr %s64, align 8
  ; Hermes CallInst
  %t55 = getelementptr i64, ptr %argv, i32 0
  %t56 = load i64, ptr %s62, align 8
  store i64 %t56, ptr %t55, align 8
  call void @shllvm_call(ptr %s65, ptr %shr, ptr %frame, ptr %s60, ptr %s64, ptr %s63, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t57 = load i64, ptr %s65, align 8
  store i64 %t57, ptr %s7, align 8
  ; Hermes LoadStackInst
  %t58 = load i64, ptr %s7, align 8
  store i64 %t58, ptr %s67, align 8
  ; Hermes ReturnInst
  %t59 = load i64, ptr %s67, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t59
}

define internal i64 @shllvm_f1(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s10, ptr %shr, ptr %unit, i32 12)
  call void @shllvm_symbol(ptr %s11, ptr %shr, ptr %unit, i32 13)
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
  %t1 = load i64, ptr %s10, align 8
  store i64 %t1, ptr %s5, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 0, ptr %s5, ptr %s4)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s11, align 8
  store i64 %t2, ptr %s7, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s8, ptr %shr, i32 0, ptr %s6, ptr %s7)
  ; Hermes ReturnInst
  %t3 = load i64, ptr %s8, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t3
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 14, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 2, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
