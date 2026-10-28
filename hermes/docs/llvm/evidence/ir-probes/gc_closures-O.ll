; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [97 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 109, i8 97, i8 107, i8 101, i8 0, i8 0, i8 103, i8 97, i8 114, i8 98, i8 97, i8 103, i8 101, i8 45, i8 0, i8 105, i8 0, i8 116, i8 101, i8 120, i8 116, i8 0, i8 108, i8 105, i8 115, i8 116, i8 0, i8 115, i8 101, i8 108, i8 102, i8 0, i8 103, i8 99, i8 0, i8 112, i8 117, i8 115, i8 104, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 110, i8 0, i8 119, i8 111, i8 114, i8 100, i8 115, i8 0, i8 106, i8 111, i8 105, i8 110, i8 0, i8 32, i8 0, i8 109, i8 97, i8 112, i8 0, i8 44, i8 0, i8 97, i8 108, i8 105, i8 118, i8 101, i8 0, i8 97, i8 102, i8 116, i8 101, i8 114, i8 0, i8 99, i8 111, i8 108, i8 108, i8 101, i8 99, i8 116, i8 105, i8 111, i8 110, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [60 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 4, i32 1101841612, i32 12, i32 0, i32 0, i32 13, i32 8, i32 412089714, i32 22, i32 1, i32 107256, i32 24, i32 4, i32 280487688, i32 29, i32 4, i32 1676513445, i32 34, i32 4, i32 995365215, i32 39, i32 2, i32 108188544, i32 42, i32 4, i32 1059174534, i32 47, i32 5, i32 2794059355, i32 53, i32 1, i32 114319, i32 55, i32 5, i32 3696541289, i32 61, i32 4, i32 2270132137, i32 66, i32 1, i32 33312, i32 68, i32 3, i32 1513730174, i32 72, i32 1, i32 45804, i32 74, i32 5, i32 3901130879, i32 80, i32 5, i32 1699682491, i32 86, i32 10, i32 2083827680]
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
declare void @shllvm_boolean(ptr, i32)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_closure(ptr, ptr, ptr, ptr, ptr, i32)
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
declare void @shllvm_number(ptr, double)
declare void @shllvm_object(ptr, ptr)
declare void @shllvm_param(ptr, ptr, i32)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_set_id(ptr, ptr, ptr, i32, ptr, i32, i32)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)
declare i32 @shllvm_truthy(ptr)
declare void @shllvm_typeof_is(ptr, ptr, i32)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 86)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [3 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 86, i32 3, i32 %unit_index)
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
  call void @shllvm_symbol(ptr %s61, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_constant(ptr %s62, i32 0, i64 0)
  call void @shllvm_constant(ptr %s63, i32 2, i64 0)
  call void @shllvm_constant(ptr %s64, i32 3, i64 0)
  call void @shllvm_constant(ptr %s65, i32 3, i64 4677104761256804352)
  call void @shllvm_symbol(ptr %s66, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_constant(ptr %s67, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s68, i32 3, i64 4611686018427387904)
  call void @shllvm_constant(ptr %s69, i32 3, i64 4662219572839972864)
  call void @shllvm_symbol(ptr %s70, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_constant(ptr %s71, i32 1, i64 0)
  call void @shllvm_symbol(ptr %s72, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_symbol(ptr %s73, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_constant(ptr %s74, i32 3, i64 4613937818241073152)
  call void @shllvm_symbol(ptr %s75, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_symbol(ptr %s76, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_symbol(ptr %s77, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_symbol(ptr %s78, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_symbol(ptr %s79, ptr %shr, ptr %unit, i32 11)
  call void @shllvm_symbol(ptr %s80, ptr %shr, ptr %unit, i32 12)
  call void @shllvm_symbol(ptr %s81, ptr %shr, ptr %unit, i32 13)
  call void @shllvm_symbol(ptr %s82, ptr %shr, ptr %unit, i32 14)
  call void @shllvm_symbol(ptr %s83, ptr %shr, ptr %unit, i32 15)
  call void @shllvm_symbol(ptr %s84, ptr %shr, ptr %unit, i32 16)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s2, ptr %shr)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s3, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s2, i32 1, ptr %s3, i32 0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s5, ptr %shr, ptr %unit, ptr %s2, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s62, align 8
  store i64 %t1, ptr %s6, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s7, ptr %shr, ptr %frame, ptr %s5, ptr %s6, ptr %s6, i32 0, ptr %argv)
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s8, ptr %shr, i32 0)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s64, align 8
  store i64 %t2, ptr %s9, align 8
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s65, align 8
  store i64 %t3, ptr %s10, align 8
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s66, align 8
  store i64 %t4, ptr %s11, align 8
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s67, align 8
  store i64 %t5, ptr %s12, align 8
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s68, align 8
  store i64 %t6, ptr %s13, align 8
  ; Hermes LIRLoadConstInst
  %t7 = load i64, ptr %s69, align 8
  store i64 %t7, ptr %s14, align 8
  ; Hermes BranchInst
  br label %edge0
b1:
  ; Hermes PhiInst
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object(ptr %s17, ptr %shr)
  call void @shllvm_define(ptr %shr, ptr %s17, ptr %s70, ptr %s71, i32 1)
  call void @shllvm_define(ptr %shr, ptr %s17, ptr %s72, ptr %s71, i32 1)
  call void @shllvm_define(ptr %shr, ptr %s17, ptr %s73, ptr %s71, i32 1)
  ; Hermes PrStoreInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s17, i32 4, ptr %s16, i32 1, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s19, ptr %shr, i32 0, ptr %s11, ptr %s16)
  ; Hermes PrStoreInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s17, i32 5, ptr %s19, i32 1, i32 0)
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s21, ptr %shr, i32 3)
  ; Hermes DefineOwnInDenseArrayInst
  call void @shllvm_define_index(ptr %shr, ptr %s21, i32 0, ptr %s16)
  ; Hermes FAddInst
  %t8 = load i64, ptr %s16, align 8
  %t9 = bitcast i64 %t8 to double
  %t10 = load i64, ptr %s12, align 8
  %t11 = bitcast i64 %t10 to double
  %t12 = fadd double %t9, %t11
  call void @shllvm_number(ptr %s23, double %t12)
  ; Hermes DefineOwnInDenseArrayInst
  call void @shllvm_define_index(ptr %shr, ptr %s21, i32 1, ptr %s23)
  ; Hermes FAddInst
  %t13 = load i64, ptr %s16, align 8
  %t14 = bitcast i64 %t13 to double
  %t15 = load i64, ptr %s13, align 8
  %t16 = bitcast i64 %t15 to double
  %t17 = fadd double %t14, %t16
  call void @shllvm_number(ptr %s25, double %t17)
  ; Hermes DefineOwnInDenseArrayInst
  call void @shllvm_define_index(ptr %shr, ptr %s21, i32 2, ptr %s25)
  ; Hermes PrStoreInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s17, i32 6, ptr %s21, i32 1, i32 0)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s17, i32 0)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s17, i32 7, ptr %s17, i32 0, i32 0)
  ; Hermes FModuloInst
  %t18 = load i64, ptr %s16, align 8
  %t19 = bitcast i64 %t18 to double
  %t20 = load i64, ptr %s14, align 8
  %t21 = bitcast i64 %t20 to double
  %t22 = frem double %t19, %t21
  call void @shllvm_number(ptr %s30, double %t22)
  ; Hermes FEqualInst
  %t23 = load i64, ptr %s30, align 8
  %t24 = load i64, ptr %s9, align 8
  %t25 = bitcast i64 %t23 to double
  %t26 = bitcast i64 %t24 to double
  %t27 = fcmp oeq double %t25, %t26
  %t28 = zext i1 %t27 to i32
  call void @shllvm_boolean(ptr %s31, i32 %t28)
  ; Hermes CondBranchInst
  %t29 = call i32 @shllvm_truthy(ptr %s31)
  %t30 = icmp ne i32 %t29, 0
  br i1 %t30, label %b4, label %b3
b2:
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s33, ptr %shr, ptr %unit, ptr %s2, i32 8, i32 0)
  ; Hermes TypeOfIsInst
  call void @shllvm_typeof_is(ptr %s34, ptr %s33, i32 128)
  ; Hermes CondBranchInst
  %t31 = call i32 @shllvm_truthy(ptr %s34)
  %t32 = icmp ne i32 %t31, 0
  br i1 %t32, label %b5, label %b6
b3:
  ; Hermes FLessThanInst
  %t33 = load i64, ptr %s23, align 8
  %t34 = load i64, ptr %s10, align 8
  %t35 = bitcast i64 %t33 to double
  %t36 = bitcast i64 %t34 to double
  %t37 = fcmp olt double %t35, %t36
  %t38 = zext i1 %t37 to i32
  call void @shllvm_boolean(ptr %s36, i32 %t38)
  ; Hermes CondBranchInst
  %t39 = call i32 @shllvm_truthy(ptr %s36)
  %t40 = icmp ne i32 %t39, 0
  br i1 %t40, label %edge1, label %b2
b4:
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s38, ptr %shr, ptr %unit, ptr %s8, i32 9, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s39, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes CallInst
  %t41 = getelementptr i64, ptr %argv, i32 0
  %t42 = load i64, ptr %s39, align 8
  store i64 %t42, ptr %t41, align 8
  call void @shllvm_call(ptr %s40, ptr %shr, ptr %frame, ptr %s38, ptr %s8, ptr %s6, i32 1, ptr %argv)
  ; Hermes BranchInst
  br label %b3
b5:
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s42, ptr %shr, ptr %unit, ptr %s2, i32 8, i32 1)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s43, ptr %shr, ptr %frame, ptr %s42, ptr %s6, ptr %s6, i32 0, ptr %argv)
  ; Hermes BranchInst
  br label %b6
b6:
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s45, ptr %shr, ptr %unit, ptr %s2, i32 10, i32 1)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s46, ptr %shr, ptr %frame, ptr %s7, ptr %s6, ptr %s6, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s47, ptr %shr, ptr %unit, ptr %s46, i32 11, i32 0)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s48, ptr %shr, ptr %frame, ptr %s7, ptr %s6, ptr %s6, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s49, ptr %shr, ptr %unit, ptr %s48, i32 12, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s50, ptr %shr, ptr %unit, ptr %s49, i32 13, i32 0)
  ; Hermes LIRLoadConstInst
  %t43 = load i64, ptr %s82, align 8
  store i64 %t43, ptr %s51, align 8
  ; Hermes CallInst
  %t44 = getelementptr i64, ptr %argv, i32 0
  %t45 = load i64, ptr %s51, align 8
  store i64 %t45, ptr %t44, align 8
  call void @shllvm_call(ptr %s52, ptr %shr, ptr %frame, ptr %s50, ptr %s49, ptr %s6, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s53, ptr %shr, ptr %unit, ptr %s8, i32 15, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s54, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes CallInst
  %t46 = getelementptr i64, ptr %argv, i32 0
  %t47 = load i64, ptr %s54, align 8
  store i64 %t47, ptr %t46, align 8
  call void @shllvm_call(ptr %s55, ptr %shr, ptr %frame, ptr %s53, ptr %s8, ptr %s6, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s56, ptr %shr, ptr %unit, ptr %s55, i32 13, i32 0)
  ; Hermes LIRLoadConstInst
  %t48 = load i64, ptr %s84, align 8
  store i64 %t48, ptr %s57, align 8
  ; Hermes CallInst
  %t49 = getelementptr i64, ptr %argv, i32 0
  %t50 = load i64, ptr %s57, align 8
  store i64 %t50, ptr %t49, align 8
  call void @shllvm_call(ptr %s58, ptr %shr, ptr %frame, ptr %s56, ptr %s55, ptr %s6, i32 1, ptr %argv)
  ; Hermes CallInst
  %t51 = getelementptr i64, ptr %argv, i32 0
  %t52 = load i64, ptr %s47, align 8
  store i64 %t52, ptr %t51, align 8
  %t53 = getelementptr i64, ptr %argv, i32 1
  %t54 = load i64, ptr %s52, align 8
  store i64 %t54, ptr %t53, align 8
  %t55 = getelementptr i64, ptr %argv, i32 2
  %t56 = load i64, ptr %s58, align 8
  store i64 %t56, ptr %t55, align 8
  call void @shllvm_call(ptr %s59, ptr %shr, ptr %frame, ptr %s45, ptr %s6, ptr %s6, i32 3, ptr %argv)
  ; Hermes ReturnInst
  %t57 = load i64, ptr %s59, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t57
edge0:
  %t58 = load i64, ptr %s9, align 8
  store i64 %t58, ptr %s16, align 8
  br label %b1
edge1:
  %t59 = load i64, ptr %s23, align 8
  store i64 %t59, ptr %s16, align 8
  br label %b1
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 17)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 17, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 16
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s7, ptr %shr, ptr %unit, i32 11)
  call void @shllvm_constant(ptr %s8, i32 3, i64 4607182418800017408)
  call void @shllvm_symbol(ptr %s9, ptr %shr, ptr %unit, i32 12)
  call void @shllvm_constant(ptr %s10, i32 1, i64 0)
  call void @shllvm_constant(ptr %s11, i32 3, i64 4613937818241073152)
  call void @shllvm_symbol(ptr %s12, ptr %shr, ptr %unit, i32 17)
  call void @shllvm_symbol(ptr %s13, ptr %shr, ptr %unit, i32 18)
  call void @shllvm_symbol(ptr %s14, ptr %shr, ptr %unit, i32 19)
  call void @shllvm_constant(ptr %s15, i32 2, i64 0)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object(ptr %s1, ptr %shr)
  call void @shllvm_define(ptr %shr, ptr %s1, ptr %s7, ptr %s8, i32 1)
  call void @shllvm_define(ptr %shr, ptr %s1, ptr %s9, ptr %s10, i32 1)
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s2, ptr %shr, i32 3)
  call void @shllvm_define_index(ptr %shr, ptr %s2, i32 0, ptr %s12)
  call void @shllvm_define_index(ptr %shr, ptr %s2, i32 1, ptr %s13)
  call void @shllvm_define_index(ptr %shr, ptr %s2, i32 2, ptr %s14)
  ; Hermes PrStoreInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s1, i32 12, ptr %s2, i32 1, i32 0)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s1, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s5, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s5, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f2(ptr %shr) {
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
  call void @shllvm_symbol(ptr %s4, ptr %shr, ptr %unit, i32 4)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s1, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s2, ptr %shr, ptr %unit, ptr %s1, i32 4, i32 0)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s2, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f3(ptr %shr) {
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
  call void @shllvm_constant(ptr %s4, i32 0, i64 0)
  call void @shllvm_constant(ptr %s5, i32 2, i64 0)
  br label %b0
b0:
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s4, align 8
  store i64 %t1, ptr %s0, align 8
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s1, ptr %frame, i32 1)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s2, ptr %shr, ptr %frame, ptr %s1, ptr %s0, ptr %s0, i32 0, ptr %argv)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s2, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f4(ptr %shr) {
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
  call void @shllvm_symbol(ptr %s7, ptr %shr, ptr %unit, i32 11)
  call void @shllvm_constant(ptr %s8, i32 3, i64 4607182418800017408)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s1, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s2, ptr %shr, ptr %unit, ptr %s1, i32 11, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s8, align 8
  store i64 %t1, ptr %s3, align 8
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s4, ptr %shr, i32 0, ptr %s2, ptr %s3)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s1, i32 11, ptr %s4, i32 0, i32 0)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s1, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 20, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 5, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
