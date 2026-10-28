; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [97 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 103, i8 101, i8 116, i8 32, i8 120, i8 0, i8 115, i8 101, i8 116, i8 32, i8 120, i8 0, i8 97, i8 100, i8 100, i8 0, i8 0, i8 95, i8 120, i8 0, i8 120, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 79, i8 98, i8 106, i8 101, i8 99, i8 116, i8 0, i8 100, i8 101, i8 102, i8 105, i8 110, i8 101, i8 80, i8 114, i8 111, i8 112, i8 101, i8 114, i8 116, i8 121, i8 0, i8 104, i8 105, i8 100, i8 100, i8 101, i8 110, i8 0, i8 118, i8 97, i8 108, i8 117, i8 101, i8 0, i8 101, i8 110, i8 117, i8 109, i8 101, i8 114, i8 97, i8 98, i8 108, i8 101, i8 0, i8 107, i8 101, i8 121, i8 115, i8 0, i8 106, i8 111, i8 105, i8 110, i8 0, i8 44, i8 0, i8 103, i8 0, i8 115, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [54 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 5, i32 2747000965, i32 13, i32 5, i32 2024248979, i32 19, i32 3, i32 1492819387, i32 23, i32 0, i32 0, i32 24, i32 2, i32 100514414, i32 27, i32 1, i32 124921, i32 29, i32 5, i32 2794059355, i32 35, i32 6, i32 2518018554, i32 42, i32 14, i32 4185130826, i32 57, i32 6, i32 388824345, i32 64, i32 5, i32 3746588989, i32 70, i32 10, i32 3747843760, i32 81, i32 4, i32 2536968949, i32 86, i32 4, i32 2270132137, i32 91, i32 1, i32 45804, i32 93, i32 1, i32 104982, i32 95, i32 1, i32 117570]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [4 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 2, i32 1, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 3, i32 1, i32 0, i32 1 }
]

declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_binary(ptr, ptr, i32, ptr, ptr)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
declare void @shllvm_check_invocation(ptr, ptr, i32)
declare void @shllvm_closure(ptr, ptr, ptr, ptr, ptr, i32)
declare void @shllvm_coerce_this(ptr, ptr, ptr)
declare void @shllvm_constant(ptr, i32, i64)
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
  %t0 = call i64 @shllvm_frame_size(i32 54)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [3 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 54, i32 3, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 53
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s34, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s35, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_constant(ptr %s36, i32 3, i64 4621819117588971520)
  call void @shllvm_symbol(ptr %s37, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_constant(ptr %s38, i32 2, i64 1)
  call void @shllvm_symbol(ptr %s39, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s40, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_constant(ptr %s41, i32 3, i64 4629700416936869888)
  call void @shllvm_constant(ptr %s42, i32 0, i64 0)
  call void @shllvm_constant(ptr %s43, i32 2, i64 0)
  call void @shllvm_symbol(ptr %s44, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_symbol(ptr %s45, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_symbol(ptr %s46, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_symbol(ptr %s47, ptr %shr, ptr %unit, i32 11)
  call void @shllvm_constant(ptr %s48, i32 3, i64 4620693217682128896)
  call void @shllvm_symbol(ptr %s49, ptr %shr, ptr %unit, i32 12)
  call void @shllvm_symbol(ptr %s50, ptr %shr, ptr %unit, i32 13)
  call void @shllvm_symbol(ptr %s51, ptr %shr, ptr %unit, i32 14)
  call void @shllvm_symbol(ptr %s52, ptr %shr, ptr %unit, i32 15)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s34, align 8
  store i64 %t1, ptr %s1, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s1, i32 0)
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object(ptr %s3, ptr %shr)
  call void @shllvm_define(ptr %shr, ptr %s3, ptr %s35, ptr %s36, i32 1)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s37, align 8
  store i64 %t2, ptr %s4, align 8
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s5, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s6, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes DefineOwnGetterSetterInst
  call void @shllvm_define_accessor(ptr %shr, ptr %s3, ptr %s4, ptr %s6, ptr %s5, i32 1)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s8, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s3, ptr %s39, ptr %s8, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s10, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s11, ptr %shr, ptr %unit, ptr %s10, i32 7, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s12, ptr %shr, ptr %unit, ptr %s3, i32 3, i32 0)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s41, align 8
  store i64 %t3, ptr %s13, align 8
  ; Hermes LIRLoadConstInst
  %t4 = load i64, ptr %s42, align 8
  store i64 %t4, ptr %s14, align 8
  ; Hermes CallInst
  %t5 = getelementptr i64, ptr %argv, i32 0
  %t6 = load i64, ptr %s13, align 8
  store i64 %t6, ptr %t5, align 8
  call void @shllvm_call(ptr %s15, ptr %shr, ptr %frame, ptr %s12, ptr %s3, ptr %s14, i32 1, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s16, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s17, ptr %shr, ptr %unit, ptr %s3, i32 5, i32 0)
  ; Hermes CallInst
  %t7 = getelementptr i64, ptr %argv, i32 0
  %t8 = load i64, ptr %s15, align 8
  store i64 %t8, ptr %t7, align 8
  %t9 = getelementptr i64, ptr %argv, i32 1
  %t10 = load i64, ptr %s16, align 8
  store i64 %t10, ptr %t9, align 8
  %t11 = getelementptr i64, ptr %argv, i32 2
  %t12 = load i64, ptr %s17, align 8
  store i64 %t12, ptr %t11, align 8
  call void @shllvm_call(ptr %s18, ptr %shr, ptr %frame, ptr %s11, ptr %s14, ptr %s14, i32 3, ptr %argv)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s19, ptr %shr, ptr %unit, ptr %s10, i32 8, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s20, ptr %shr, ptr %unit, ptr %s19, i32 9, i32 0)
  ; Hermes LIRLoadConstInst
  %t13 = load i64, ptr %s46, align 8
  store i64 %t13, ptr %s21, align 8
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object(ptr %s22, ptr %shr)
  call void @shllvm_define(ptr %shr, ptr %s22, ptr %s47, ptr %s48, i32 1)
  call void @shllvm_define(ptr %shr, ptr %s22, ptr %s49, ptr %s43, i32 1)
  ; Hermes CallInst
  %t14 = getelementptr i64, ptr %argv, i32 0
  %t15 = load i64, ptr %s3, align 8
  store i64 %t15, ptr %t14, align 8
  %t16 = getelementptr i64, ptr %argv, i32 1
  %t17 = load i64, ptr %s21, align 8
  store i64 %t17, ptr %t16, align 8
  %t18 = getelementptr i64, ptr %argv, i32 2
  %t19 = load i64, ptr %s22, align 8
  store i64 %t19, ptr %t18, align 8
  call void @shllvm_call(ptr %s23, ptr %shr, ptr %frame, ptr %s20, ptr %s19, ptr %s14, i32 3, ptr %argv)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s24, ptr %shr, ptr %unit, ptr %s10, i32 7, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s25, ptr %shr, ptr %unit, ptr %s3, i32 10, i32 0)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s26, ptr %shr, ptr %unit, ptr %s10, i32 8, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s27, ptr %shr, ptr %unit, ptr %s26, i32 13, i32 0)
  ; Hermes CallInst
  %t20 = getelementptr i64, ptr %argv, i32 0
  %t21 = load i64, ptr %s3, align 8
  store i64 %t21, ptr %t20, align 8
  call void @shllvm_call(ptr %s28, ptr %shr, ptr %frame, ptr %s27, ptr %s26, ptr %s14, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s29, ptr %shr, ptr %unit, ptr %s28, i32 14, i32 0)
  ; Hermes LIRLoadConstInst
  %t22 = load i64, ptr %s52, align 8
  store i64 %t22, ptr %s30, align 8
  ; Hermes CallInst
  %t23 = getelementptr i64, ptr %argv, i32 0
  %t24 = load i64, ptr %s30, align 8
  store i64 %t24, ptr %t23, align 8
  call void @shllvm_call(ptr %s31, ptr %shr, ptr %frame, ptr %s29, ptr %s28, ptr %s14, i32 1, ptr %argv)
  ; Hermes CallInst
  %t25 = getelementptr i64, ptr %argv, i32 0
  %t26 = load i64, ptr %s25, align 8
  store i64 %t26, ptr %t25, align 8
  %t27 = getelementptr i64, ptr %argv, i32 1
  %t28 = load i64, ptr %s31, align 8
  store i64 %t28, ptr %t27, align 8
  call void @shllvm_call(ptr %s32, ptr %shr, ptr %frame, ptr %s24, ptr %s14, ptr %s14, i32 2, ptr %argv)
  ; Hermes ReturnInst
  %t29 = load i64, ptr %s32, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t29
}

define internal i64 @shllvm_f1(ptr %shr) {
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
  call void @shllvm_symbol(ptr %s8, ptr %shr, ptr %unit, i32 16)
  call void @shllvm_symbol(ptr %s9, ptr %shr, ptr %unit, i32 5)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s1, ptr %s0, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s8, align 8
  store i64 %t1, ptr %s2, align 8
  ; Hermes StringConcatInst
  %t2 = load i64, ptr %s1, align 8
  store i64 %t2, ptr %s3, align 8
  call void @shllvm_binary(ptr %s3, ptr %shr, i32 0, ptr %s3, ptr %s2)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s3, i32 0)
  ; Hermes LIRGetThisNSInst
  call void @shllvm_param(ptr %scratch, ptr %frame, i32 0)
  call void @shllvm_coerce_this(ptr %s5, ptr %shr, ptr %scratch)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s6, ptr %shr, ptr %unit, ptr %s5, i32 5, i32 0)
  ; Hermes ReturnInst
  %t3 = load i64, ptr %s6, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t3
}

define internal i64 @shllvm_f2(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 14)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 14, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 13
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s10, ptr %shr, ptr %unit, i32 17)
  call void @shllvm_symbol(ptr %s11, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_constant(ptr %s12, i32 0, i64 0)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s1, ptr %s0, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s10, align 8
  store i64 %t1, ptr %s2, align 8
  ; Hermes StringConcatInst
  %t2 = load i64, ptr %s1, align 8
  store i64 %t2, ptr %s3, align 8
  call void @shllvm_binary(ptr %s3, ptr %shr, i32 0, ptr %s3, ptr %s2)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s3, i32 0)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s5, ptr %frame, i32 1)
  ; Hermes LIRGetThisNSInst
  call void @shllvm_param(ptr %scratch, ptr %frame, i32 0)
  call void @shllvm_coerce_this(ptr %s6, ptr %shr, ptr %scratch)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s6, i32 5, ptr %s5, i32 0, i32 0)
  ; Hermes LIRLoadConstInst
  %t3 = load i64, ptr %s12, align 8
  store i64 %t3, ptr %s8, align 8
  ; Hermes ReturnInst
  %t4 = load i64, ptr %s8, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t4
}

define internal i64 @shllvm_f3(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 1)
  call void @shllvm_symbol(ptr %s7, ptr %shr, ptr %unit, i32 6)
  br label %b0
b0:
  ; Hermes LIRGetThisNSInst
  call void @shllvm_param(ptr %scratch, ptr %frame, i32 0)
  call void @shllvm_coerce_this(ptr %s0, ptr %shr, ptr %scratch)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s1, ptr %shr, ptr %unit, ptr %s0, i32 6, i32 0)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s2, ptr %frame, i32 1)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s3, ptr %shr, i32 0, ptr %s1, ptr %s2)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s0, i32 6, ptr %s3, i32 0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s5, ptr %shr, ptr %unit, ptr %s0, i32 6, i32 0)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s5, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 18, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 4, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
