; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [92 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 66, i8 97, i8 115, i8 101, i8 0, i8 97, i8 110, i8 115, i8 119, i8 101, i8 114, i8 0, i8 103, i8 101, i8 116, i8 32, i8 118, i8 97, i8 108, i8 117, i8 101, i8 0, i8 108, i8 97, i8 98, i8 101, i8 108, i8 0, i8 68, i8 101, i8 114, i8 105, i8 118, i8 101, i8 100, i8 0, i8 99, i8 97, i8 112, i8 116, i8 117, i8 114, i8 101, i8 0, i8 0, i8 118, i8 97, i8 108, i8 117, i8 101, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 110, i8 97, i8 109, i8 101, i8 0, i8 112, i8 114, i8 111, i8 116, i8 111, i8 116, i8 121, i8 112, i8 101, i8 0, i8 120, i8 0, i8 98, i8 97, i8 115, i8 101, i8 0, i8 100, i8 101, i8 108, i8 116, i8 97, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [45 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 4, i32 2816260886, i32 12, i32 6, i32 1915305844, i32 19, i32 9, i32 207255882, i32 29, i32 5, i32 464014579, i32 35, i32 7, i32 1879956715, i32 43, i32 7, i32 2573446312, i32 51, i32 0, i32 0, i32 52, i32 5, i32 3746588989, i32 58, i32 5, i32 2794059355, i32 64, i32 4, i32 3891058614, i32 69, i32 9, i32 2155634493, i32 79, i32 1, i32 124921, i32 81, i32 4, i32 2965116673, i32 86, i32 5, i32 2784234399]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [9 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 1, i32 0, i32 0 },
  %SHLLVMFunctionInfo { i32 2, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 3, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 4, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 5, i32 2, i32 0, i32 0 },
  %SHLLVMFunctionInfo { i32 2, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 6, i32 0, i32 0, i32 1 },
  %SHLLVMFunctionInfo { i32 7, i32 1, i32 0, i32 1 }
]

declare i32 @_setjmp(ptr) returns_twice
declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_binary(ptr, ptr, i32, ptr, ptr)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_catch_prepare(ptr, ptr, ptr, i32)
declare void @shllvm_catch_value(ptr, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_check_this_initialized(ptr, ptr)
declare void @shllvm_class(ptr, ptr, ptr, ptr, ptr, i32, ptr, ptr)
declare void @shllvm_closure(ptr, ptr, ptr, ptr, ptr, i32)
declare void @shllvm_constant(ptr, i32, i64)
declare void @shllvm_constructed_object(ptr, ptr, ptr)
declare void @shllvm_create_this(ptr, ptr, ptr, ptr)
declare ptr @shllvm_create_unit(ptr, i32, ptr, ptr, ptr, i32, ptr, ptr, ptr)
declare void @shllvm_define(ptr, ptr, ptr, ptr, i32)
declare void @shllvm_define_accessor(ptr, ptr, ptr, ptr, ptr, i32)
declare ptr @shllvm_enter(ptr, ptr, i32, i32, i32)
declare void @shllvm_env_create(ptr, ptr, ptr, i32)
declare void @shllvm_env_from_frame(ptr, ptr, ptr)
declare void @shllvm_env_load(ptr, ptr, i32)
declare void @shllvm_env_store(ptr, ptr, ptr, i32)
declare i64 @shllvm_frame_size(i32)
declare void @shllvm_get_id(ptr, ptr, ptr, ptr, i32, i32)
declare void @shllvm_get_parent(ptr, ptr, ptr)
declare void @shllvm_get_receiver(ptr, ptr, ptr, ptr, ptr)
declare ptr @shllvm_get_unit(ptr, i32)
declare void @shllvm_global(ptr, ptr)
declare void @shllvm_leave(ptr, ptr, ptr)
declare void @shllvm_new_target(ptr, ptr)
declare void @shllvm_object_parent(ptr, ptr, ptr, ptr)
declare void @shllvm_param(ptr, ptr, i32)
declare void @shllvm_rethrow(ptr)
declare ptr @shllvm_roots(ptr)
declare i32 @shllvm_run(i32, ptr, ptr)
declare void @shllvm_set_id(ptr, ptr, ptr, i32, ptr, i32, i32)
declare void @shllvm_symbol(ptr, ptr, ptr, i32)
declare ptr @shllvm_try_begin(ptr, ptr)
declare void @shllvm_try_end(ptr, ptr)
declare i64 @shllvm_try_size()

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 71)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [6 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 71, i32 6, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 70
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s57, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s58, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s59, i32 2, i64 0)
  call void @shllvm_symbol(ptr %s60, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_symbol(ptr %s61, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s62, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_constant(ptr %s63, i32 3, i64 4617315517961601024)
  call void @shllvm_constant(ptr %s64, i32 3, i64 4629137466983448576)
  call void @shllvm_constant(ptr %s65, i32 2, i64 1)
  call void @shllvm_symbol(ptr %s66, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_constant(ptr %s67, i32 3, i64 4619567317775286272)
  call void @shllvm_symbol(ptr %s68, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_constant(ptr %s69, i32 3, i64 4607182418800017408)
  %t1 = call i64 @shllvm_try_size()
  %try_storage = alloca i8, i64 %t1, align 16
  %try_state = alloca i32, align 4
  store volatile i32 0, ptr %try_state, align 4
  %t2 = call ptr @shllvm_try_begin(ptr %shr, ptr %try_storage)
  %t3 = call i32 @_setjmp(ptr %t2) returns_twice
  %t4 = icmp ne i32 %t3, 0
  br i1 %t4, label %catch.dispatch, label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 2)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t5 = load volatile i64, ptr %s57, align 8
  store volatile i64 %t5, ptr %s2, align 8
  ; Hermes StoreStackInst
  %t6 = load volatile i64, ptr %s2, align 8
  store volatile i64 %t6, ptr %s1, align 8
  ; Hermes AllocStackInst
  ; Hermes CreateClassInst
  call void @shllvm_class(ptr %s5, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f1, i32 1, ptr %s4, ptr null)
  ; Hermes LoadStackInst
  %t7 = load volatile i64, ptr %s4, align 8
  store volatile i64 %t7, ptr %s6, align 8
  ; Hermes LIRLoadConstInst
  %t8 = load volatile i64, ptr %s58, align 8
  store volatile i64 %t8, ptr %s7, align 8
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s8, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s6, ptr %s7, ptr %s8, i32 0)
  ; Hermes LIRLoadConstInst
  %t9 = load volatile i64, ptr %s60, align 8
  store volatile i64 %t9, ptr %s10, align 8
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s11, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes DefineOwnGetterSetterInst
  call void @shllvm_define_accessor(ptr %shr, ptr %s6, ptr %s10, ptr %s11, ptr %s2, i32 0)
  ; Hermes LIRLoadConstInst
  %t10 = load volatile i64, ptr %s61, align 8
  store volatile i64 %t10, ptr %s13, align 8
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s14, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s5, ptr %s13, ptr %s14, i32 0)
  ; Hermes AllocStackInst
  ; Hermes CreateClassInst
  call void @shllvm_class(ptr %s17, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f5, i32 5, ptr %s16, ptr %s5)
  ; Hermes LoadStackInst
  %t11 = load volatile i64, ptr %s16, align 8
  store volatile i64 %t11, ptr %s18, align 8
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s19, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f6, i32 6)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s18, ptr %s7, ptr %s19, i32 0)
  ; Hermes LIRLoadConstInst
  %t12 = load volatile i64, ptr %s62, align 8
  store volatile i64 %t12, ptr %s21, align 8
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s22, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f7, i32 7)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s18, ptr %s21, ptr %s22, i32 0)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s17, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s18, i32 0)
  ; Hermes LIRLoadConstInst
  %t13 = load volatile i64, ptr %s63, align 8
  store volatile i64 %t13, ptr %s26, align 8
  ; Hermes LIRLoadConstInst
  %t14 = load volatile i64, ptr %s64, align 8
  store volatile i64 %t14, ptr %s27, align 8
  ; Hermes CallInst
  %t15 = getelementptr i64, ptr %argv, i32 0
  %t16 = load volatile i64, ptr %s27, align 8
  store volatile i64 %t16, ptr %t15, align 8
  %t17 = getelementptr i64, ptr %argv, i32 1
  %t18 = load volatile i64, ptr %s26, align 8
  store volatile i64 %t18, ptr %t17, align 8
  call void @shllvm_call(ptr %s28, ptr %shr, ptr %frame, ptr %s17, ptr %s2, ptr %s17, i32 2, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s29, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s30, ptr %shr, ptr %unit, ptr %s29, i32 9, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s31, ptr %shr, ptr %unit, ptr %s28, i32 2, i32 0)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s32, ptr %shr, ptr %frame, ptr %s31, ptr %s28, ptr %s2, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s33, ptr %shr, ptr %unit, ptr %s28, i32 8, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s34, ptr %shr, ptr %unit, ptr %s28, i32 6, i32 0)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s35, ptr %shr, ptr %frame, ptr %s34, ptr %s28, ptr %s2, i32 0, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t19 = load volatile i64, ptr %s67, align 8
  store volatile i64 %t19, ptr %s36, align 8
  ; Hermes CallInst
  %t20 = getelementptr i64, ptr %argv, i32 0
  %t21 = load volatile i64, ptr %s36, align 8
  store volatile i64 %t21, ptr %t20, align 8
  call void @shllvm_call(ptr %s37, ptr %shr, ptr %frame, ptr %s35, ptr %s2, ptr %s2, i32 1, ptr %argv)
  ; Hermes BinaryInstanceOfInst
  call void @shllvm_binary(ptr %s38, ptr %shr, i32 20, ptr %s28, ptr %s17)
  ; Hermes BinaryInstanceOfInst
  call void @shllvm_binary(ptr %s39, ptr %shr, i32 20, ptr %s28, ptr %s5)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s40, ptr %shr, ptr %unit, ptr %s17, i32 4, i32 0)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s41, ptr %shr, ptr %frame, ptr %s40, ptr %s17, ptr %s2, i32 0, ptr %argv)
  ; Hermes CallInst
  %t22 = getelementptr i64, ptr %argv, i32 0
  %t23 = load volatile i64, ptr %s32, align 8
  store volatile i64 %t23, ptr %t22, align 8
  %t24 = getelementptr i64, ptr %argv, i32 1
  %t25 = load volatile i64, ptr %s33, align 8
  store volatile i64 %t25, ptr %t24, align 8
  %t26 = getelementptr i64, ptr %argv, i32 2
  %t27 = load volatile i64, ptr %s37, align 8
  store volatile i64 %t27, ptr %t26, align 8
  %t28 = getelementptr i64, ptr %argv, i32 3
  %t29 = load volatile i64, ptr %s38, align 8
  store volatile i64 %t29, ptr %t28, align 8
  %t30 = getelementptr i64, ptr %argv, i32 4
  %t31 = load volatile i64, ptr %s39, align 8
  store volatile i64 %t31, ptr %t30, align 8
  %t32 = getelementptr i64, ptr %argv, i32 5
  %t33 = load volatile i64, ptr %s41, align 8
  store volatile i64 %t33, ptr %t32, align 8
  call void @shllvm_call(ptr %s42, ptr %shr, ptr %frame, ptr %s30, ptr %s2, ptr %s2, i32 6, ptr %argv)
  ; Hermes StoreStackInst
  %t34 = load volatile i64, ptr %s42, align 8
  store volatile i64 %t34, ptr %s1, align 8
  ; Hermes TryStartInst
  store volatile i32 1, ptr %try_state, align 4
  br label %b3
b1:
  ; Hermes CatchInst
  store volatile i32 0, ptr %try_state, align 4
  call void @shllvm_catch_value(ptr %s45, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s46, ptr %shr, ptr %unit, ptr %s29, i32 9, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s47, ptr %shr, ptr %unit, ptr %s45, i32 10, i32 0)
  ; Hermes CallInst
  %t35 = getelementptr i64, ptr %argv, i32 0
  %t36 = load volatile i64, ptr %s47, align 8
  store volatile i64 %t36, ptr %t35, align 8
  call void @shllvm_call(ptr %s48, ptr %shr, ptr %frame, ptr %s46, ptr %s2, ptr %s2, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t37 = load volatile i64, ptr %s48, align 8
  store volatile i64 %t37, ptr %s1, align 8
  ; Hermes BranchInst
  br label %b2
b2:
  ; Hermes LoadStackInst
  %t38 = load volatile i64, ptr %s1, align 8
  store volatile i64 %t38, ptr %s51, align 8
  ; Hermes ReturnInst
  %t39 = load volatile i64, ptr %s51, align 8
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t39
b3:
  ; Hermes LIRLoadConstInst
  %t40 = load volatile i64, ptr %s69, align 8
  store volatile i64 %t40, ptr %s53, align 8
  ; Hermes CallInst
  %t41 = getelementptr i64, ptr %argv, i32 0
  %t42 = load volatile i64, ptr %s53, align 8
  store volatile i64 %t42, ptr %t41, align 8
  call void @shllvm_call(ptr %s54, ptr %shr, ptr %frame, ptr %s5, ptr %s2, ptr %s2, i32 1, ptr %argv)
  ; Hermes StoreStackInst
  %t43 = load volatile i64, ptr %s54, align 8
  store volatile i64 %t43, ptr %s1, align 8
  ; Hermes TryEndInst
  store volatile i32 0, ptr %try_state, align 4
  br label %b2
catch.dispatch:
  %t44 = load volatile i32, ptr %try_state, align 4
  call void @shllvm_catch_prepare(ptr %shr, ptr %storage, ptr %frame, i32 6)
  switch i32 %t44, label %catch.rethrow [
    i32 1, label %b1
  ]
catch.rethrow:
  call void @shllvm_try_end(ptr %shr, ptr %try_storage)
  call void @shllvm_rethrow(ptr %shr)
  unreachable
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 2)
  call void @shllvm_symbol(ptr %s6, ptr %shr, ptr %unit, i32 11)
  call void @shllvm_symbol(ptr %s7, ptr %shr, ptr %unit, i32 12)
  br label %b0
b0:
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s0, ptr %frame)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s1, ptr %shr, ptr %unit, ptr %s0, i32 11, i32 0)
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object_parent(ptr %s2, ptr %shr, ptr %unit, ptr %s1)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s3, ptr %frame, i32 1)
  ; Hermes StorePropertyStrictInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s2, i32 12, ptr %s3, i32 1, i32 0)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s2, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f2(ptr %shr) {
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
  call void @shllvm_symbol(ptr %s3, ptr %shr, ptr %unit, i32 12)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s1, ptr %shr, ptr %unit, ptr %s0, i32 12, i32 0)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s1, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
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
  call void @shllvm_symbol(ptr %s3, ptr %shr, ptr %unit, i32 12)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s1, ptr %shr, ptr %unit, ptr %s0, i32 12, i32 0)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s1, align 8
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
  call void @shllvm_symbol(ptr %s2, ptr %shr, ptr %unit, i32 13)
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

define internal i64 @shllvm_f5(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 17)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 17, i32 1, i32 %unit_index)
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 2)
  call void @shllvm_constant(ptr %s13, i32 2, i64 0)
  call void @shllvm_constant(ptr %s14, i32 4, i64 0)
  call void @shllvm_symbol(ptr %s15, ptr %shr, ptr %unit, i32 14)
  br label %b0
b0:
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s0, ptr %frame)
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s1, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s2, ptr %s1, i32 1)
  ; Hermes LoadParentNoTrapsInst
  call void @shllvm_get_parent(ptr %s3, ptr %shr, ptr %s2)
  ; Hermes CreateThisInst
  call void @shllvm_create_this(ptr %s4, ptr %shr, ptr %s3, ptr %s0)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s5, ptr %frame, i32 1)
  ; Hermes CallInst
  %t1 = getelementptr i64, ptr %argv, i32 0
  %t2 = load i64, ptr %s5, align 8
  store i64 %t2, ptr %t1, align 8
  call void @shllvm_call(ptr %s6, ptr %shr, ptr %frame, ptr %s3, ptr %s4, ptr %s0, i32 1, ptr %argv)
  ; Hermes GetConstructedObjectInst
  call void @shllvm_constructed_object(ptr %s7, ptr %s4, ptr %s6)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s14, align 8
  store i64 %t3, ptr %s8, align 8
  ; Hermes ThrowIfThisInitializedInst
  call void @shllvm_check_this_initialized(ptr %shr, ptr %s8)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s10, ptr %frame, i32 2)
  ; Hermes StorePropertyStrictInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s7, i32 14, ptr %s10, i32 1, i32 0)
  ; Hermes ReturnInst
  %t4 = load i64, ptr %s7, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t4
}

define internal i64 @shllvm_f6(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_symbol(ptr %s10, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s11, i32 0, i64 0)
  call void @shllvm_constant(ptr %s12, i32 2, i64 0)
  call void @shllvm_symbol(ptr %s13, ptr %shr, ptr %unit, i32 14)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s1, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s2, ptr %s1, i32 0)
  ; Hermes LoadParentNoTrapsInst
  call void @shllvm_get_parent(ptr %s3, ptr %shr, ptr %s2)
  ; Hermes LoadPropertyWithReceiverInst
  call void @shllvm_get_receiver(ptr %s4, ptr %shr, ptr %s3, ptr %s10, ptr %s0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s11, align 8
  store i64 %t1, ptr %s5, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s6, ptr %shr, ptr %frame, ptr %s4, ptr %s0, ptr %s5, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s7, ptr %shr, ptr %unit, ptr %s0, i32 14, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s8, ptr %shr, i32 0, ptr %s6, ptr %s7)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s8, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f7(ptr %shr) {
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
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s1, ptr %frame, i32 0)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s1, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s3, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f8, i32 8)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s3, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f8(ptr %shr) {
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
  call void @shllvm_symbol(ptr %s8, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_constant(ptr %s9, i32 0, i64 0)
  call void @shllvm_constant(ptr %s10, i32 2, i64 0)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s1, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s2, ptr %shr, ptr %unit, ptr %s1, i32 2, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s9, align 8
  store i64 %t1, ptr %s3, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s4, ptr %shr, ptr %frame, ptr %s2, ptr %s1, ptr %s3, i32 0, ptr %argv)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s5, ptr %frame, i32 1)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 0, ptr %s4, ptr %s5)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s6, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 15, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 9, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
