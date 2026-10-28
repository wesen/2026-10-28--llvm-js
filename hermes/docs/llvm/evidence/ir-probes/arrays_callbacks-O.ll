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
declare void @shllvm_boolean(ptr, i32)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_closure(ptr, ptr, ptr, ptr, ptr, i32)
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
declare void @shllvm_number(ptr, double)
declare void @shllvm_param(ptr, ptr, i32)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)
declare i32 @shllvm_truthy(ptr)

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 81)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [4 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 81, i32 4, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 80
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s61, i32 3, i64 4616189618054758400)
  call void @shllvm_constant(ptr %s62, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s63, i32 3, i64 4611686018427387904)
  call void @shllvm_constant(ptr %s64, i32 3, i64 4613937818241073152)
  call void @shllvm_symbol(ptr %s65, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s66, i32 0, i64 0)
  call void @shllvm_constant(ptr %s67, i32 2, i64 0)
  call void @shllvm_symbol(ptr %s68, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s69, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s70, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_symbol(ptr %s71, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_symbol(ptr %s72, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_constant(ptr %s73, i32 3, i64 0)
  call void @shllvm_symbol(ptr %s74, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_constant(ptr %s75, i32 3, i64 4617315517961601024)
  call void @shllvm_symbol(ptr %s76, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_symbol(ptr %s77, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_constant(ptr %s78, i32 3, i64 4619567317775286272)
  call void @shllvm_constant(ptr %s79, i32 3, i64 4621256167635550208)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s1, ptr %shr, i32 4)
  call void @shllvm_define_index(ptr %shr, ptr %s1, i32 0, ptr %s62)
  call void @shllvm_define_index(ptr %shr, ptr %s1, i32 1, ptr %s63)
  call void @shllvm_define_index(ptr %shr, ptr %s1, i32 2, ptr %s64)
  call void @shllvm_define_index(ptr %shr, ptr %s1, i32 3, ptr %s61)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s2, ptr %shr, ptr %unit, ptr %s1, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s66, align 8
  store i64 %t1, ptr %s3, align 8
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s4, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes CallInst
  %t2 = getelementptr i64, ptr %argv, i32 0
  %t3 = load i64, ptr %s4, align 8
  store i64 %t3, ptr %t2, align 8
  call void @shllvm_call(ptr %s5, ptr %shr, ptr %frame, ptr %s2, ptr %s1, ptr %s3, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s6, ptr %shr, ptr %unit, ptr %s5, i32 3, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s7, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes CallInst
  %t4 = getelementptr i64, ptr %argv, i32 0
  %t5 = load i64, ptr %s7, align 8
  store i64 %t5, ptr %t4, align 8
  call void @shllvm_call(ptr %s8, ptr %shr, ptr %frame, ptr %s6, ptr %s5, ptr %s3, i32 1, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s9, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s10, ptr %shr, ptr %unit, ptr %s9, i32 4, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s11, ptr %shr, ptr %unit, ptr %s5, i32 5, i32 0)
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s71, align 8
  store i64 %t6, ptr %s12, align 8
  ; Hermes CallInst
  %t7 = getelementptr i64, ptr %argv, i32 0
  %t8 = load i64, ptr %s12, align 8
  store i64 %t8, ptr %t7, align 8
  call void @shllvm_call(ptr %s13, ptr %shr, ptr %frame, ptr %s11, ptr %s5, ptr %s3, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s14, ptr %shr, ptr %unit, ptr %s8, i32 7, i32 0)
  ; Hermes LIRLoadConstInst
  %t9 = load i64, ptr %s73, align 8
  store i64 %t9, ptr %s15, align 8
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s16, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes CallInst
  %t10 = getelementptr i64, ptr %argv, i32 0
  %t11 = load i64, ptr %s16, align 8
  store i64 %t11, ptr %t10, align 8
  %t12 = getelementptr i64, ptr %argv, i32 1
  %t13 = load i64, ptr %s15, align 8
  store i64 %t13, ptr %t12, align 8
  call void @shllvm_call(ptr %s17, ptr %shr, ptr %frame, ptr %s14, ptr %s8, ptr %s3, i32 2, ptr %argv)
  ; Hermes CallInst
  %t14 = getelementptr i64, ptr %argv, i32 0
  %t15 = load i64, ptr %s13, align 8
  store i64 %t15, ptr %t14, align 8
  %t16 = getelementptr i64, ptr %argv, i32 1
  %t17 = load i64, ptr %s17, align 8
  store i64 %t17, ptr %t16, align 8
  call void @shllvm_call(ptr %s18, ptr %shr, ptr %frame, ptr %s10, ptr %s3, ptr %s3, i32 2, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s19, ptr %shr, ptr %unit, ptr %s1, i32 8, i32 0)
  ; Hermes LIRLoadConstInst
  %t18 = load i64, ptr %s75, align 8
  store i64 %t18, ptr %s20, align 8
  ; Hermes CallInst
  %t19 = getelementptr i64, ptr %argv, i32 0
  %t20 = load i64, ptr %s20, align 8
  store i64 %t20, ptr %t19, align 8
  call void @shllvm_call(ptr %s21, ptr %shr, ptr %frame, ptr %s19, ptr %s1, ptr %s3, i32 1, ptr %argv)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s22, ptr %shr, ptr %unit, ptr %s9, i32 4, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s23, ptr %shr, ptr %unit, ptr %s1, i32 9, i32 0)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s24, ptr %shr, ptr %frame, ptr %s23, ptr %s1, ptr %s3, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s25, ptr %shr, ptr %unit, ptr %s1, i32 10, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s26, ptr %shr, ptr %s1, ptr %s63)
  ; Hermes CallInst
  %t21 = getelementptr i64, ptr %argv, i32 0
  %t22 = load i64, ptr %s24, align 8
  store i64 %t22, ptr %t21, align 8
  %t23 = getelementptr i64, ptr %argv, i32 1
  %t24 = load i64, ptr %s25, align 8
  store i64 %t24, ptr %t23, align 8
  %t25 = getelementptr i64, ptr %argv, i32 2
  %t26 = load i64, ptr %s26, align 8
  store i64 %t26, ptr %t25, align 8
  call void @shllvm_call(ptr %s27, ptr %shr, ptr %frame, ptr %s22, ptr %s3, ptr %s3, i32 3, ptr %argv)
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s28, ptr %shr, i32 3)
  call void @shllvm_define_index(ptr %shr, ptr %s28, i32 0, ptr %s78)
  ; Hermes LIRLoadConstInst
  %t27 = load i64, ptr %s79, align 8
  store i64 %t27, ptr %s29, align 8
  ; Hermes DefineOwnInDenseArrayInst
  call void @shllvm_define_index(ptr %shr, ptr %s28, i32 2, ptr %s29)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s31, ptr %shr, ptr %unit, ptr %s9, i32 4, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s32, ptr %shr, ptr %unit, ptr %s28, i32 10, i32 0)
  ; Hermes LIRLoadConstInst
  %t28 = load i64, ptr %s62, align 8
  store i64 %t28, ptr %s33, align 8
  ; Hermes BinaryInInst
  call void @shllvm_binary(ptr %s34, ptr %shr, i32 19, ptr %s33, ptr %s28)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s35, ptr %shr, ptr %s28, ptr %s62)
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s36, ptr %shr, i32 7, ptr %s35, ptr %s3)
  ; Hermes CallInst
  %t29 = getelementptr i64, ptr %argv, i32 0
  %t30 = load i64, ptr %s32, align 8
  store i64 %t30, ptr %t29, align 8
  %t31 = getelementptr i64, ptr %argv, i32 1
  %t32 = load i64, ptr %s34, align 8
  store i64 %t32, ptr %t31, align 8
  %t33 = getelementptr i64, ptr %argv, i32 2
  %t34 = load i64, ptr %s36, align 8
  store i64 %t34, ptr %t33, align 8
  call void @shllvm_call(ptr %s37, ptr %shr, ptr %frame, ptr %s31, ptr %s3, ptr %s3, i32 3, ptr %argv)
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s38, ptr %shr, i32 0)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s15, i32 0)
  ; Hermes LIRLoadConstInst
  %t35 = load i64, ptr %s61, align 8
  store i64 %t35, ptr %s40, align 8
  ; Hermes BranchInst
  br label %edge0
b1:
  ; Hermes PhiInst
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s43, ptr %shr, ptr %unit, ptr %s38, i32 8, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s44, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes CallInst
  %t36 = getelementptr i64, ptr %argv, i32 0
  %t37 = load i64, ptr %s44, align 8
  store i64 %t37, ptr %t36, align 8
  call void @shllvm_call(ptr %s45, ptr %shr, ptr %frame, ptr %s43, ptr %s38, ptr %s3, i32 1, ptr %argv)
  ; Hermes FAddInst
  %t38 = load i64, ptr %s42, align 8
  %t39 = bitcast i64 %t38 to double
  %t40 = load i64, ptr %s33, align 8
  %t41 = bitcast i64 %t40 to double
  %t42 = fadd double %t39, %t41
  call void @shllvm_number(ptr %s46, double %t42)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s46, i32 0)
  ; Hermes FLessThanInst
  %t43 = load i64, ptr %s46, align 8
  %t44 = load i64, ptr %s40, align 8
  %t45 = bitcast i64 %t43 to double
  %t46 = bitcast i64 %t44 to double
  %t47 = fcmp olt double %t45, %t46
  %t48 = zext i1 %t47 to i32
  call void @shllvm_boolean(ptr %s48, i32 %t48)
  ; Hermes CondBranchInst
  %t49 = call i32 @shllvm_truthy(ptr %s48)
  %t50 = icmp ne i32 %t49, 0
  br i1 %t50, label %edge1, label %b2
b2:
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s50, ptr %shr, ptr %unit, ptr %s9, i32 4, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s51, ptr %shr, ptr %s38, ptr %s73)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s52, ptr %shr, ptr %frame, ptr %s51, ptr %s38, ptr %s3, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s53, ptr %shr, ptr %s38, ptr %s62)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s54, ptr %shr, ptr %frame, ptr %s53, ptr %s38, ptr %s3, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s55, ptr %shr, ptr %s38, ptr %s63)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s56, ptr %shr, ptr %frame, ptr %s55, ptr %s38, ptr %s3, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get(ptr %s57, ptr %shr, ptr %s38, ptr %s64)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s58, ptr %shr, ptr %frame, ptr %s57, ptr %s38, ptr %s3, i32 0, ptr %argv)
  ; Hermes CallInst
  %t51 = getelementptr i64, ptr %argv, i32 0
  %t52 = load i64, ptr %s52, align 8
  store i64 %t52, ptr %t51, align 8
  %t53 = getelementptr i64, ptr %argv, i32 1
  %t54 = load i64, ptr %s54, align 8
  store i64 %t54, ptr %t53, align 8
  %t55 = getelementptr i64, ptr %argv, i32 2
  %t56 = load i64, ptr %s56, align 8
  store i64 %t56, ptr %t55, align 8
  %t57 = getelementptr i64, ptr %argv, i32 3
  %t58 = load i64, ptr %s58, align 8
  store i64 %t58, ptr %t57, align 8
  call void @shllvm_call(ptr %s59, ptr %shr, ptr %frame, ptr %s50, ptr %s3, ptr %s3, i32 4, ptr %argv)
  ; Hermes ReturnInst
  %t59 = load i64, ptr %s59, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t59
edge0:
  %t60 = load i64, ptr %s15, align 8
  store i64 %t60, ptr %s42, align 8
  br label %b1
edge1:
  %t61 = load i64, ptr %s46, align 8
  store i64 %t61, ptr %s42, align 8
  br label %b1
}

define internal i64 @shllvm_f1(ptr %shr) {
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
  call void @shllvm_constant(ptr %s4, i32 3, i64 4611686018427387904)
  br label %b0
b0:
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s4, align 8
  store i64 %t1, ptr %s0, align 8
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s1, ptr %frame, i32 1)
  ; Hermes BinaryMultiplyInst
  call void @shllvm_binary(ptr %s2, ptr %shr, i32 2, ptr %s1, ptr %s0)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s2, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
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
  call void @shllvm_constant(ptr %s4, i32 3, i64 4613937818241073152)
  br label %b0
b0:
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s4, align 8
  store i64 %t1, ptr %s0, align 8
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s1, ptr %frame, i32 1)
  ; Hermes BinaryGreaterThanInst
  call void @shllvm_binary(ptr %s2, ptr %shr, i32 11, ptr %s1, ptr %s0)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s2, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f3(ptr %shr) {
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
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 2)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s1, ptr %frame, i32 1)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s2, ptr %shr, i32 0, ptr %s1, ptr %s0)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s2, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
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
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s1, ptr %s0, i32 0)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s1, align 8
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
