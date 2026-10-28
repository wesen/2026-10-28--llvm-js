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
declare void @shllvm_builtin_closure(ptr, ptr, i32)
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
  %t0 = call i64 @shllvm_frame_size(i32 76)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [3 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 76, i32 3, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 75
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s52, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_symbol(ptr %s53, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_constant(ptr %s54, i32 3, i64 4629137466983448576)
  call void @shllvm_symbol(ptr %s55, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s56, i32 1, i64 0)
  call void @shllvm_constant(ptr %s57, i32 3, i64 4607182418800017408)
  call void @shllvm_constant(ptr %s58, i32 2, i64 0)
  call void @shllvm_constant(ptr %s59, i32 3, i64 4617315517961601024)
  call void @shllvm_constant(ptr %s60, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s61, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_constant(ptr %s62, i32 3, i64 4619567317775286272)
  call void @shllvm_symbol(ptr %s63, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_constant(ptr %s64, i32 3, i64 4652007308841189376)
  call void @shllvm_constant(ptr %s65, i32 3, i64 4630826316843712512)
  call void @shllvm_constant(ptr %s66, i32 3, i64 4611686018427387904)
  call void @shllvm_symbol(ptr %s67, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_constant(ptr %s68, i32 3, i64 4621819117588971520)
  call void @shllvm_constant(ptr %s69, i32 3, i64 4620693217682128896)
  call void @shllvm_symbol(ptr %s70, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_constant(ptr %s71, i32 3, i64 4624633867356078080)
  call void @shllvm_constant(ptr %s72, i32 3, i64 4626322717216342016)
  call void @shllvm_constant(ptr %s73, i32 3, i64 4626604192193052672)
  call void @shllvm_constant(ptr %s74, i32 3, i64 4622382067542392832)
  br label %b0
b0:
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s1, ptr %shr)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s2, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s1, i32 1, ptr %s2, i32 0, i32 0)
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object(ptr %s4, ptr %shr)
  call void @shllvm_define(ptr %shr, ptr %s4, ptr %s53, ptr %s54, i32 1)
  call void @shllvm_define(ptr %shr, ptr %s4, ptr %s55, ptr %s56, i32 1)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s5, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes PrStoreInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s4, i32 2, ptr %s5, i32 1, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s7, ptr %shr, ptr %unit, ptr %s4, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s59, align 8
  store i64 %t1, ptr %s8, align 8
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s60, align 8
  store i64 %t2, ptr %s9, align 8
  ; Hermes CallInst
  %t3 = getelementptr i64, ptr %argv, i32 0
  %t4 = load i64, ptr %s8, align 8
  store i64 %t4, ptr %t3, align 8
  call void @shllvm_call(ptr %s10, ptr %shr, ptr %frame, ptr %s7, ptr %s4, ptr %s9, i32 1, ptr %argv)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s11, ptr %shr, ptr %unit, ptr %s1, i32 5, i32 1)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s62, align 8
  store i64 %t5, ptr %s12, align 8
  ; Hermes CallInst
  %t6 = getelementptr i64, ptr %argv, i32 0
  %t7 = load i64, ptr %s12, align 8
  store i64 %t7, ptr %t6, align 8
  call void @shllvm_call(ptr %s13, ptr %shr, ptr %frame, ptr %s10, ptr %s9, ptr %s9, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s14, ptr %shr, ptr %unit, ptr %s10, i32 6, i32 0)
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object(ptr %s15, ptr %shr)
  call void @shllvm_define(ptr %shr, ptr %s15, ptr %s53, ptr %s64, i32 1)
  ; Hermes BranchIfBuiltinInst
  call void @shllvm_builtin_closure(ptr %scratch, ptr %shr, i32 76)
  %t9 = load i64, ptr %s14, align 8
  %t8 = load i64, ptr %scratch, align 8
  %t10 = icmp eq i64 %t9, %t8
  br i1 %t10, label %b2, label %b3
b1:
  ; Hermes PhiInst
  ; Hermes CallInst
  %t11 = getelementptr i64, ptr %argv, i32 0
  %t12 = load i64, ptr %s13, align 8
  store i64 %t12, ptr %t11, align 8
  %t13 = getelementptr i64, ptr %argv, i32 1
  %t14 = load i64, ptr %s17, align 8
  store i64 %t14, ptr %t13, align 8
  call void @shllvm_call(ptr %s18, ptr %shr, ptr %frame, ptr %s11, ptr %s9, ptr %s9, i32 2, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t15 = load i64, ptr %s65, align 8
  store i64 %t15, ptr %s19, align 8
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s4, i32 4, ptr %s19, i32 0, i32 0)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s21, ptr %shr, ptr %unit, ptr %s1, i32 5, i32 1)
  ; Hermes LIRLoadConstInst
  %t16 = load i64, ptr %s66, align 8
  store i64 %t16, ptr %s22, align 8
  ; Hermes CallInst
  %t17 = getelementptr i64, ptr %argv, i32 0
  %t18 = load i64, ptr %s22, align 8
  store i64 %t18, ptr %t17, align 8
  call void @shllvm_call(ptr %s23, ptr %shr, ptr %frame, ptr %s10, ptr %s9, ptr %s9, i32 1, ptr %argv)
  ; Hermes CallInst
  %t19 = getelementptr i64, ptr %argv, i32 0
  %t20 = load i64, ptr %s23, align 8
  store i64 %t20, ptr %t19, align 8
  call void @shllvm_call(ptr %s24, ptr %shr, ptr %frame, ptr %s21, ptr %s9, ptr %s9, i32 1, ptr %argv)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s25, ptr %shr, ptr %unit, ptr %s1, i32 5, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s26, ptr %shr, ptr %unit, ptr %s1, i32 1, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s27, ptr %shr, ptr %unit, ptr %s26, i32 6, i32 0)
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object(ptr %s28, ptr %shr)
  call void @shllvm_define(ptr %shr, ptr %s28, ptr %s67, ptr %s68, i32 1)
  ; Hermes BranchIfBuiltinInst
  call void @shllvm_builtin_closure(ptr %scratch, ptr %shr, i32 76)
  %t22 = load i64, ptr %s27, align 8
  %t21 = load i64, ptr %scratch, align 8
  %t23 = icmp eq i64 %t22, %t21
  br i1 %t23, label %b5, label %b6
b2:
  ; Hermes LIRLoadConstInst
  %t24 = load i64, ptr %s69, align 8
  store i64 %t24, ptr %s30, align 8
  ; Hermes CallInst
  %t25 = getelementptr i64, ptr %argv, i32 0
  %t26 = load i64, ptr %s30, align 8
  store i64 %t26, ptr %t25, align 8
  call void @shllvm_call(ptr %s31, ptr %shr, ptr %frame, ptr %s10, ptr %s15, ptr %s9, i32 1, ptr %argv)
  ; Hermes BranchInst
  br label %edge0
b3:
  ; Hermes LIRLoadConstInst
  %t27 = load i64, ptr %s69, align 8
  store i64 %t27, ptr %s33, align 8
  ; Hermes CallInst
  %t28 = getelementptr i64, ptr %argv, i32 0
  %t29 = load i64, ptr %s15, align 8
  store i64 %t29, ptr %t28, align 8
  %t30 = getelementptr i64, ptr %argv, i32 1
  %t31 = load i64, ptr %s33, align 8
  store i64 %t31, ptr %t30, align 8
  call void @shllvm_call(ptr %s34, ptr %shr, ptr %frame, ptr %s14, ptr %s10, ptr %s9, i32 2, ptr %argv)
  ; Hermes BranchInst
  br label %edge1
b4:
  ; Hermes PhiInst
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s37, ptr %shr, ptr %unit, ptr %s1, i32 1, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s38, ptr %shr, ptr %unit, ptr %s37, i32 8, i32 0)
  ; Hermes AllocArrayInst
  call void @shllvm_array(ptr %s39, ptr %shr, i32 2)
  call void @shllvm_define_index(ptr %shr, ptr %s39, i32 0, ptr %s62)
  call void @shllvm_define_index(ptr %shr, ptr %s39, i32 1, ptr %s71)
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object(ptr %s40, ptr %shr)
  call void @shllvm_define(ptr %shr, ptr %s40, ptr %s67, ptr %s72, i32 1)
  ; Hermes CallInst
  %t32 = getelementptr i64, ptr %argv, i32 0
  %t33 = load i64, ptr %s40, align 8
  store i64 %t33, ptr %t32, align 8
  %t34 = getelementptr i64, ptr %argv, i32 1
  %t35 = load i64, ptr %s39, align 8
  store i64 %t35, ptr %t34, align 8
  call void @shllvm_call(ptr %s41, ptr %shr, ptr %frame, ptr %s38, ptr %s37, ptr %s9, i32 2, ptr %argv)
  ; Hermes CallInst
  %t36 = getelementptr i64, ptr %argv, i32 0
  %t37 = load i64, ptr %s36, align 8
  store i64 %t37, ptr %t36, align 8
  %t38 = getelementptr i64, ptr %argv, i32 1
  %t39 = load i64, ptr %s41, align 8
  store i64 %t39, ptr %t38, align 8
  call void @shllvm_call(ptr %s42, ptr %shr, ptr %frame, ptr %s25, ptr %s9, ptr %s9, i32 2, ptr %argv)
  ; Hermes ReturnInst
  %t40 = load i64, ptr %s42, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t40
b5:
  ; Hermes LIRLoadConstInst
  %t41 = load i64, ptr %s73, align 8
  store i64 %t41, ptr %s44, align 8
  ; Hermes LIRLoadConstInst
  %t42 = load i64, ptr %s74, align 8
  store i64 %t42, ptr %s45, align 8
  ; Hermes CallInst
  %t43 = getelementptr i64, ptr %argv, i32 0
  %t44 = load i64, ptr %s45, align 8
  store i64 %t44, ptr %t43, align 8
  %t45 = getelementptr i64, ptr %argv, i32 1
  %t46 = load i64, ptr %s44, align 8
  store i64 %t46, ptr %t45, align 8
  call void @shllvm_call(ptr %s46, ptr %shr, ptr %frame, ptr %s26, ptr %s28, ptr %s9, i32 2, ptr %argv)
  ; Hermes BranchInst
  br label %edge2
b6:
  ; Hermes LIRLoadConstInst
  %t47 = load i64, ptr %s73, align 8
  store i64 %t47, ptr %s48, align 8
  ; Hermes LIRLoadConstInst
  %t48 = load i64, ptr %s74, align 8
  store i64 %t48, ptr %s49, align 8
  ; Hermes CallInst
  %t49 = getelementptr i64, ptr %argv, i32 0
  %t50 = load i64, ptr %s28, align 8
  store i64 %t50, ptr %t49, align 8
  %t51 = getelementptr i64, ptr %argv, i32 1
  %t52 = load i64, ptr %s49, align 8
  store i64 %t52, ptr %t51, align 8
  %t53 = getelementptr i64, ptr %argv, i32 2
  %t54 = load i64, ptr %s48, align 8
  store i64 %t54, ptr %t53, align 8
  call void @shllvm_call(ptr %s50, ptr %shr, ptr %frame, ptr %s27, ptr %s26, ptr %s9, i32 3, ptr %argv)
  ; Hermes BranchInst
  br label %edge3
edge0:
  %t55 = load i64, ptr %s31, align 8
  store i64 %t55, ptr %s17, align 8
  br label %b1
edge1:
  %t56 = load i64, ptr %s34, align 8
  store i64 %t56, ptr %s17, align 8
  br label %b1
edge2:
  %t57 = load i64, ptr %s46, align 8
  store i64 %t57, ptr %s36, align 8
  br label %b4
edge3:
  %t58 = load i64, ptr %s50, align 8
  store i64 %t58, ptr %s36, align 8
  br label %b4
}

define internal i64 @shllvm_f1(ptr %shr) {
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
  call void @shllvm_symbol(ptr %s7, ptr %shr, ptr %unit, i32 7)
  br label %b0
b0:
  ; Hermes LIRGetThisNSInst
  call void @shllvm_param(ptr %scratch, ptr %frame, i32 0)
  call void @shllvm_coerce_this(ptr %s0, ptr %shr, ptr %scratch)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s1, ptr %shr, ptr %unit, ptr %s0, i32 7, i32 0)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s2, ptr %frame, i32 1)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s3, ptr %shr, i32 0, ptr %s1, ptr %s2)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s4, ptr %frame, i32 2)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s5, ptr %shr, i32 0, ptr %s3, ptr %s4)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s5, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f2(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 8)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 8, i32 0, i32 %unit_index)
  %roots = call ptr @shllvm_roots(ptr %storage)
  %unit = call ptr @shllvm_get_unit(ptr %shr, i32 %unit_index)
  %s0 = getelementptr i64, ptr %roots, i32 0
  %s1 = getelementptr i64, ptr %roots, i32 1
  %s2 = getelementptr i64, ptr %roots, i32 2
  %s3 = getelementptr i64, ptr %roots, i32 3
  %s4 = getelementptr i64, ptr %roots, i32 4
  %s5 = getelementptr i64, ptr %roots, i32 5
  %s6 = getelementptr i64, ptr %roots, i32 6
  %scratch = getelementptr i64, ptr %roots, i32 7
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 2)
  ; Hermes LIRGetThisNSInst
  call void @shllvm_param(ptr %scratch, ptr %frame, i32 0)
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %scratch)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s1, i32 1)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s3, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s3, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s5, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s5, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f3(ptr %shr) {
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
  call void @shllvm_symbol(ptr %s8, ptr %shr, ptr %unit, i32 4)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s1, ptr %s0, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s2, ptr %shr, ptr %unit, ptr %s1, i32 4, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s3, ptr %s0, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s4, ptr %shr, i32 0, ptr %s2, ptr %s3)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s5, ptr %frame, i32 1)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 0, ptr %s4, ptr %s5)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s6, align 8
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
