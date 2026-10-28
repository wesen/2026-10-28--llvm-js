; Direct Static Hermes IR -> LLVM IR. No generated C frontend stage.
; Runtime bridge ABI v1; opaque pointers; host native callback ABI.
source_filename = "hermes-direct-llvm"

@shllvm_ascii = private constant [91 x i8] [i8 103, i8 108, i8 111, i8 98, i8 97, i8 108, i8 0, i8 80, i8 111, i8 105, i8 110, i8 116, i8 0, i8 70, i8 97, i8 99, i8 116, i8 111, i8 114, i8 121, i8 0, i8 80, i8 114, i8 105, i8 109, i8 105, i8 116, i8 105, i8 118, i8 101, i8 0, i8 105, i8 110, i8 115, i8 112, i8 101, i8 99, i8 116, i8 0, i8 0, i8 112, i8 114, i8 111, i8 116, i8 111, i8 116, i8 121, i8 112, i8 101, i8 0, i8 115, i8 117, i8 109, i8 0, i8 112, i8 114, i8 105, i8 110, i8 116, i8 0, i8 99, i8 111, i8 110, i8 115, i8 116, i8 114, i8 117, i8 99, i8 116, i8 111, i8 114, i8 0, i8 97, i8 110, i8 115, i8 119, i8 101, i8 114, i8 0, i8 120, i8 0, i8 121, i8 0, i8 105, i8 103, i8 110, i8 111, i8 114, i8 101, i8 100, i8 0]
@shllvm_utf16 = private constant [1 x i16] [i16 0]
@shllvm_strings = private constant [42 x i32] [i32 0, i32 6, i32 615793799, i32 7, i32 5, i32 1448770811, i32 13, i32 7, i32 4095277028, i32 21, i32 9, i32 3608259045, i32 31, i32 7, i32 57933841, i32 39, i32 0, i32 0, i32 40, i32 9, i32 2155634493, i32 50, i32 3, i32 3122771808, i32 54, i32 5, i32 2794059355, i32 60, i32 11, i32 2127663999, i32 72, i32 6, i32 1915305844, i32 79, i32 1, i32 124921, i32 81, i32 1, i32 123880, i32 83, i32 7, i32 2138543470]
@shllvm_unit_index = internal global i32 0, align 4
@shllvm_unit_name = private constant [12 x i8] c"llvm_module\00"
%SHLLVMFunctionInfo = type { i32, i32, i32, i32 }
@shllvm_functions = private constant [6 x %SHLLVMFunctionInfo] [
  %SHLLVMFunctionInfo { i32 0, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 1, i32 2, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 2, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 3, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 4, i32 0, i32 0, i32 2 },
  %SHLLVMFunctionInfo { i32 5, i32 0, i32 0, i32 2 }
]

declare void @_sh_check_native_stack_overflow(ptr)
declare void @shllvm_binary(ptr, ptr, i32, ptr, ptr)
declare void @shllvm_call(ptr, ptr, ptr, ptr, ptr, ptr, i32, ptr)
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

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 70)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [3 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 70, i32 3, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 69
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s56, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_symbol(ptr %s57, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s58, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s59, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s60, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_symbol(ptr %s61, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_constant(ptr %s62, i32 3, i64 4627167142146473984)
  call void @shllvm_constant(ptr %s63, i32 3, i64 4626041242239631360)
  call void @shllvm_constant(ptr %s64, i32 2, i64 0)
  call void @shllvm_symbol(ptr %s65, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_constant(ptr %s66, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s67, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_symbol(ptr %s68, ptr %shr, ptr %unit, i32 10)
  br label %b0
b0:
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 2)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 3)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 4)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s4, ptr %shr)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s5, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s4, i32 1, ptr %s5, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s7, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s4, i32 2, ptr %s7, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s9, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s4, i32 3, ptr %s9, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s11, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s4, i32 4, ptr %s11, i32 0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s13, ptr %shr, ptr %unit, ptr %s4, i32 1, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s14, ptr %shr, ptr %unit, ptr %s13, i32 6, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s15, ptr %shr, ptr null, ptr %unit, ptr @shllvm_f5, i32 5)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s14, i32 7, ptr %s15, i32 0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s17, ptr %shr, ptr %unit, ptr %s4, i32 1, i32 0)
  ; Hermes CreateThisInst
  call void @shllvm_create_this(ptr %s18, ptr %shr, ptr %s17, ptr %s17)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s62, align 8
  store i64 %t1, ptr %s19, align 8
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s63, align 8
  store i64 %t2, ptr %s20, align 8
  ; Hermes CallInst
  %t3 = getelementptr i64, ptr %argv, i32 0
  %t4 = load i64, ptr %s20, align 8
  store i64 %t4, ptr %t3, align 8
  %t5 = getelementptr i64, ptr %argv, i32 1
  %t6 = load i64, ptr %s19, align 8
  store i64 %t6, ptr %t5, align 8
  call void @shllvm_call(ptr %s21, ptr %shr, ptr %frame, ptr %s17, ptr %s18, ptr %s17, i32 2, ptr %argv)
  ; Hermes GetConstructedObjectInst
  call void @shllvm_constructed_object(ptr %s22, ptr %s18, ptr %s21)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s23, ptr %shr, ptr %unit, ptr %s4, i32 8, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s24, ptr %shr, ptr %unit, ptr %s22, i32 7, i32 0)
  ; Hermes LIRLoadConstInst
  %t7 = load i64, ptr %s66, align 8
  store i64 %t7, ptr %s25, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s26, ptr %shr, ptr %frame, ptr %s24, ptr %s22, ptr %s25, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s27, ptr %shr, ptr %unit, ptr %s4, i32 1, i32 0)
  ; Hermes BinaryInstanceOfInst
  call void @shllvm_binary(ptr %s28, ptr %shr, i32 20, ptr %s22, ptr %s27)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s29, ptr %shr, ptr %unit, ptr %s22, i32 9, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s30, ptr %shr, ptr %unit, ptr %s4, i32 1, i32 0)
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s31, ptr %shr, i32 7, ptr %s29, ptr %s30)
  ; Hermes CallInst
  %t8 = getelementptr i64, ptr %argv, i32 0
  %t9 = load i64, ptr %s26, align 8
  store i64 %t9, ptr %t8, align 8
  %t10 = getelementptr i64, ptr %argv, i32 1
  %t11 = load i64, ptr %s28, align 8
  store i64 %t11, ptr %t10, align 8
  %t12 = getelementptr i64, ptr %argv, i32 2
  %t13 = load i64, ptr %s31, align 8
  store i64 %t13, ptr %t12, align 8
  call void @shllvm_call(ptr %s32, ptr %shr, ptr %frame, ptr %s23, ptr %s25, ptr %s25, i32 3, ptr %argv)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s33, ptr %shr, ptr %unit, ptr %s4, i32 8, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s34, ptr %shr, ptr %unit, ptr %s4, i32 2, i32 0)
  ; Hermes CreateThisInst
  call void @shllvm_create_this(ptr %s35, ptr %shr, ptr %s34, ptr %s34)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s36, ptr %shr, ptr %frame, ptr %s34, ptr %s35, ptr %s34, i32 0, ptr %argv)
  ; Hermes GetConstructedObjectInst
  call void @shllvm_constructed_object(ptr %s37, ptr %s35, ptr %s36)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s38, ptr %shr, ptr %unit, ptr %s37, i32 10, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s39, ptr %shr, ptr %unit, ptr %s4, i32 3, i32 0)
  ; Hermes CreateThisInst
  call void @shllvm_create_this(ptr %s40, ptr %shr, ptr %s39, ptr %s39)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s41, ptr %shr, ptr %frame, ptr %s39, ptr %s40, ptr %s39, i32 0, ptr %argv)
  ; Hermes GetConstructedObjectInst
  call void @shllvm_constructed_object(ptr %s42, ptr %s40, ptr %s41)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s43, ptr %shr, ptr %unit, ptr %s42, i32 10, i32 0)
  ; Hermes CallInst
  %t14 = getelementptr i64, ptr %argv, i32 0
  %t15 = load i64, ptr %s38, align 8
  store i64 %t15, ptr %t14, align 8
  %t16 = getelementptr i64, ptr %argv, i32 1
  %t17 = load i64, ptr %s43, align 8
  store i64 %t17, ptr %t16, align 8
  call void @shllvm_call(ptr %s44, ptr %shr, ptr %frame, ptr %s33, ptr %s25, ptr %s25, i32 2, ptr %argv)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s45, ptr %shr, ptr %unit, ptr %s4, i32 8, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s46, ptr %shr, ptr %unit, ptr %s4, i32 4, i32 0)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s47, ptr %shr, ptr %frame, ptr %s46, ptr %s25, ptr %s25, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s48, ptr %shr, ptr %unit, ptr %s4, i32 4, i32 0)
  ; Hermes CreateThisInst
  call void @shllvm_create_this(ptr %s49, ptr %shr, ptr %s48, ptr %s48)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s50, ptr %shr, ptr %frame, ptr %s48, ptr %s49, ptr %s48, i32 0, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s51, ptr %shr, ptr %unit, ptr %s4, i32 4, i32 0)
  ; Hermes GetConstructedObjectInst
  call void @shllvm_constructed_object(ptr %s52, ptr %s49, ptr %s50)
  ; Hermes BinaryInstanceOfInst
  call void @shllvm_binary(ptr %s53, ptr %shr, i32 20, ptr %s52, ptr %s51)
  ; Hermes CallInst
  %t18 = getelementptr i64, ptr %argv, i32 0
  %t19 = load i64, ptr %s47, align 8
  store i64 %t19, ptr %t18, align 8
  %t20 = getelementptr i64, ptr %argv, i32 1
  %t21 = load i64, ptr %s53, align 8
  store i64 %t21, ptr %t20, align 8
  call void @shllvm_call(ptr %s54, ptr %shr, ptr %frame, ptr %s45, ptr %s25, ptr %s25, i32 2, ptr %argv)
  ; Hermes ReturnInst
  %t22 = load i64, ptr %s54, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t22
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
  call void @shllvm_symbol(ptr %s7, ptr %shr, ptr %unit, i32 11)
  call void @shllvm_symbol(ptr %s8, ptr %shr, ptr %unit, i32 12)
  call void @shllvm_constant(ptr %s9, i32 0, i64 0)
  br label %b0
b0:
  ; Hermes LIRGetThisNSInst
  call void @shllvm_param(ptr %scratch, ptr %frame, i32 0)
  call void @shllvm_coerce_this(ptr %s0, ptr %shr, ptr %scratch)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s1, ptr %frame, i32 1)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s0, i32 11, ptr %s1, i32 0, i32 0)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s3, ptr %frame, i32 2)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s0, i32 12, ptr %s3, i32 0, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s9, align 8
  store i64 %t1, ptr %s5, align 8
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s5, align 8
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s5, i32 2, i64 1)
  call void @shllvm_symbol(ptr %s6, ptr %shr, ptr %unit, i32 13)
  call void @shllvm_symbol(ptr %s7, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_constant(ptr %s8, i32 3, i64 4631107791820423168)
  br label %b0
b0:
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s5, align 8
  store i64 %t1, ptr %s0, align 8
  ; Hermes LIRGetThisNSInst
  call void @shllvm_param(ptr %scratch, ptr %frame, i32 0)
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %scratch)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s1, i32 13, ptr %s0, i32 0, i32 0)
  ; Hermes LIRAllocObjectFromBufferInst
  call void @shllvm_object(ptr %s3, ptr %shr)
  call void @shllvm_define(ptr %shr, ptr %s3, ptr %s7, ptr %s8, i32 1)
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s3, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s5, i32 3, i64 4630967054332067840)
  call void @shllvm_symbol(ptr %s6, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_constant(ptr %s7, i32 3, i64 4636666922610458624)
  br label %b0
b0:
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s5, align 8
  store i64 %t1, ptr %s0, align 8
  ; Hermes LIRGetThisNSInst
  call void @shllvm_param(ptr %scratch, ptr %frame, i32 0)
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %scratch)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s1, i32 10, ptr %s0, i32 0, i32 0)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s7, align 8
  store i64 %t2, ptr %s3, align 8
  ; Hermes ReturnInst
  %t3 = load i64, ptr %s3, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t3
}

define internal i64 @shllvm_f4(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s5, ptr %shr, ptr %unit, i32 4)
  br label %b0
b0:
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s0, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s1, ptr %shr, ptr %unit, ptr %s0, i32 4, i32 0)
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s2, ptr %frame)
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s3, ptr %shr, i32 7, ptr %s2, ptr %s1)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s3, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f5(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s5, ptr %shr, ptr %unit, i32 11)
  call void @shllvm_symbol(ptr %s6, ptr %shr, ptr %unit, i32 12)
  br label %b0
b0:
  ; Hermes LIRGetThisNSInst
  call void @shllvm_param(ptr %scratch, ptr %frame, i32 0)
  call void @shllvm_coerce_this(ptr %s0, ptr %shr, ptr %scratch)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s1, ptr %shr, ptr %unit, ptr %s0, i32 11, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s2, ptr %shr, ptr %unit, ptr %s0, i32 12, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s3, ptr %shr, i32 0, ptr %s1, ptr %s2)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s3, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define ptr @sh_export_this_unit() {
entry:
  %unit = call ptr @shllvm_create_unit(ptr @shllvm_unit_index, i32 14, ptr @shllvm_ascii, ptr @shllvm_utf16, ptr @shllvm_strings, i32 6, ptr @shllvm_functions, ptr @shllvm_f0, ptr @shllvm_unit_name)
  ret ptr %unit
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %status = call i32 @shllvm_run(i32 %argc, ptr %argv, ptr @sh_export_this_unit)
  ret i32 %status
}
