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

define internal i64 @shllvm_f0(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 108)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [3 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 108, i32 3, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 107
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s94, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_constant(ptr %s95, i32 0, i64 0)
  call void @shllvm_symbol(ptr %s96, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s97, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_symbol(ptr %s98, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s99, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_symbol(ptr %s100, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_constant(ptr %s101, i32 3, i64 4626041242239631360)
  call void @shllvm_constant(ptr %s102, i32 3, i64 4627167142146473984)
  call void @shllvm_constant(ptr %s103, i32 2, i64 0)
  call void @shllvm_symbol(ptr %s104, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_symbol(ptr %s105, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_symbol(ptr %s106, ptr %shr, ptr %unit, i32 10)
  br label %b0
b0:
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s0, ptr %shr, ptr null, i32 1)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 1)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s95, align 8
  store i64 %t1, ptr %s2, align 8
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s2, i32 0)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 2)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 3)
  ; Hermes DeclareGlobalVarInst
  call void @shllvm_declare_global(ptr %shr, ptr %unit, i32 4)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s7, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f1, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s8, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s8, i32 1, ptr %s7, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s10, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f2, i32 2)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s11, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s11, i32 2, ptr %s10, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s13, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f3, i32 3)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s14, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s14, i32 3, ptr %s13, i32 0, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s16, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f4, i32 4)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s17, ptr %shr)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s17, i32 4, ptr %s16, i32 0, i32 0)
  ; Hermes AllocStackInst
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s95, align 8
  store i64 %t2, ptr %s20, align 8
  ; Hermes StoreStackInst
  %t3 = load i64, ptr %s20, align 8
  store i64 %t3, ptr %s19, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s22, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s23, ptr %shr, ptr %unit, ptr %s22, i32 1, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s24, ptr %shr, ptr %unit, ptr %s23, i32 6, i32 0)
  ; Hermes CreateFunctionInst
  call void @shllvm_closure(ptr %s25, ptr %shr, ptr %s0, ptr %unit, ptr @shllvm_f5, i32 5)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s24, i32 7, ptr %s25, i32 0, i32 0)
  ; Hermes StoreStackInst
  %t4 = load i64, ptr %s25, align 8
  store i64 %t4, ptr %s19, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s28, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s29, ptr %shr, ptr %unit, ptr %s28, i32 1, i32 0)
  ; Hermes CreateThisInst
  call void @shllvm_create_this(ptr %s30, ptr %shr, ptr %s29, ptr %s29)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s101, align 8
  store i64 %t5, ptr %s31, align 8
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s102, align 8
  store i64 %t6, ptr %s32, align 8
  ; Hermes CallInst
  %t7 = getelementptr i64, ptr %argv, i32 0
  %t8 = load i64, ptr %s31, align 8
  store i64 %t8, ptr %t7, align 8
  %t9 = getelementptr i64, ptr %argv, i32 1
  %t10 = load i64, ptr %s32, align 8
  store i64 %t10, ptr %t9, align 8
  call void @shllvm_call(ptr %s33, ptr %shr, ptr %frame, ptr %s29, ptr %s30, ptr %s29, i32 2, ptr %argv)
  ; Hermes GetConstructedObjectInst
  call void @shllvm_constructed_object(ptr %s34, ptr %s30, ptr %s33)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s0, ptr %s34, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s36, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s37, ptr %shr, ptr %unit, ptr %s36, i32 8, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s38, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s39, ptr %shr, ptr %unit, ptr %s38, i32 7, i32 0)
  ; Hermes LIRLoadConstInst
  %t11 = load i64, ptr %s95, align 8
  store i64 %t11, ptr %s40, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s41, ptr %shr, ptr %frame, ptr %s39, ptr %s38, ptr %s40, i32 0, ptr %argv)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s42, ptr %s0, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s43, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s44, ptr %shr, ptr %unit, ptr %s43, i32 1, i32 0)
  ; Hermes BinaryInstanceOfInst
  call void @shllvm_binary(ptr %s45, ptr %shr, i32 20, ptr %s42, ptr %s44)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s46, ptr %s0, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s47, ptr %shr, ptr %unit, ptr %s46, i32 9, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s48, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s49, ptr %shr, ptr %unit, ptr %s48, i32 1, i32 0)
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s50, ptr %shr, i32 7, ptr %s47, ptr %s49)
  ; Hermes LIRLoadConstInst
  %t12 = load i64, ptr %s95, align 8
  store i64 %t12, ptr %s51, align 8
  ; Hermes LIRLoadConstInst
  %t13 = load i64, ptr %s95, align 8
  store i64 %t13, ptr %s52, align 8
  ; Hermes CallInst
  %t14 = getelementptr i64, ptr %argv, i32 0
  %t15 = load i64, ptr %s41, align 8
  store i64 %t15, ptr %t14, align 8
  %t16 = getelementptr i64, ptr %argv, i32 1
  %t17 = load i64, ptr %s45, align 8
  store i64 %t17, ptr %t16, align 8
  %t18 = getelementptr i64, ptr %argv, i32 2
  %t19 = load i64, ptr %s50, align 8
  store i64 %t19, ptr %t18, align 8
  call void @shllvm_call(ptr %s53, ptr %shr, ptr %frame, ptr %s37, ptr %s52, ptr %s51, i32 3, ptr %argv)
  ; Hermes StoreStackInst
  %t20 = load i64, ptr %s53, align 8
  store i64 %t20, ptr %s19, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s55, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s56, ptr %shr, ptr %unit, ptr %s55, i32 8, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s57, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s58, ptr %shr, ptr %unit, ptr %s57, i32 2, i32 0)
  ; Hermes CreateThisInst
  call void @shllvm_create_this(ptr %s59, ptr %shr, ptr %s58, ptr %s58)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s60, ptr %shr, ptr %frame, ptr %s58, ptr %s59, ptr %s58, i32 0, ptr %argv)
  ; Hermes GetConstructedObjectInst
  call void @shllvm_constructed_object(ptr %s61, ptr %s59, ptr %s60)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s62, ptr %shr, ptr %unit, ptr %s61, i32 10, i32 0)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s63, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s64, ptr %shr, ptr %unit, ptr %s63, i32 3, i32 0)
  ; Hermes CreateThisInst
  call void @shllvm_create_this(ptr %s65, ptr %shr, ptr %s64, ptr %s64)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s66, ptr %shr, ptr %frame, ptr %s64, ptr %s65, ptr %s64, i32 0, ptr %argv)
  ; Hermes GetConstructedObjectInst
  call void @shllvm_constructed_object(ptr %s67, ptr %s65, ptr %s66)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s68, ptr %shr, ptr %unit, ptr %s67, i32 10, i32 0)
  ; Hermes LIRLoadConstInst
  %t21 = load i64, ptr %s95, align 8
  store i64 %t21, ptr %s69, align 8
  ; Hermes LIRLoadConstInst
  %t22 = load i64, ptr %s95, align 8
  store i64 %t22, ptr %s70, align 8
  ; Hermes CallInst
  %t23 = getelementptr i64, ptr %argv, i32 0
  %t24 = load i64, ptr %s62, align 8
  store i64 %t24, ptr %t23, align 8
  %t25 = getelementptr i64, ptr %argv, i32 1
  %t26 = load i64, ptr %s68, align 8
  store i64 %t26, ptr %t25, align 8
  call void @shllvm_call(ptr %s71, ptr %shr, ptr %frame, ptr %s56, ptr %s70, ptr %s69, i32 2, ptr %argv)
  ; Hermes StoreStackInst
  %t27 = load i64, ptr %s71, align 8
  store i64 %t27, ptr %s19, align 8
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s73, ptr %shr)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s74, ptr %shr, ptr %unit, ptr %s73, i32 8, i32 1)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s75, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s76, ptr %shr, ptr %unit, ptr %s75, i32 4, i32 0)
  ; Hermes LIRLoadConstInst
  %t28 = load i64, ptr %s95, align 8
  store i64 %t28, ptr %s77, align 8
  ; Hermes LIRLoadConstInst
  %t29 = load i64, ptr %s95, align 8
  store i64 %t29, ptr %s78, align 8
  ; Hermes CallInst
  call void @shllvm_call(ptr %s79, ptr %shr, ptr %frame, ptr %s76, ptr %s78, ptr %s77, i32 0, ptr %argv)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s80, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s81, ptr %shr, ptr %unit, ptr %s80, i32 4, i32 0)
  ; Hermes CreateThisInst
  call void @shllvm_create_this(ptr %s82, ptr %shr, ptr %s81, ptr %s81)
  ; Hermes CallInst
  call void @shllvm_call(ptr %s83, ptr %shr, ptr %frame, ptr %s81, ptr %s82, ptr %s81, i32 0, ptr %argv)
  ; Hermes GetConstructedObjectInst
  call void @shllvm_constructed_object(ptr %s84, ptr %s82, ptr %s83)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s85, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s86, ptr %shr, ptr %unit, ptr %s85, i32 4, i32 0)
  ; Hermes BinaryInstanceOfInst
  call void @shllvm_binary(ptr %s87, ptr %shr, i32 20, ptr %s84, ptr %s86)
  ; Hermes LIRLoadConstInst
  %t30 = load i64, ptr %s95, align 8
  store i64 %t30, ptr %s88, align 8
  ; Hermes LIRLoadConstInst
  %t31 = load i64, ptr %s95, align 8
  store i64 %t31, ptr %s89, align 8
  ; Hermes CallInst
  %t32 = getelementptr i64, ptr %argv, i32 0
  %t33 = load i64, ptr %s79, align 8
  store i64 %t33, ptr %t32, align 8
  %t34 = getelementptr i64, ptr %argv, i32 1
  %t35 = load i64, ptr %s87, align 8
  store i64 %t35, ptr %t34, align 8
  call void @shllvm_call(ptr %s90, ptr %shr, ptr %frame, ptr %s74, ptr %s89, ptr %s88, i32 2, ptr %argv)
  ; Hermes StoreStackInst
  %t36 = load i64, ptr %s90, align 8
  store i64 %t36, ptr %s19, align 8
  ; Hermes LoadStackInst
  %t37 = load i64, ptr %s19, align 8
  store i64 %t37, ptr %s92, align 8
  ; Hermes ReturnInst
  %t38 = load i64, ptr %s92, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t38
}

define internal i64 @shllvm_f1(ptr %shr) {
entry:
  call void @_sh_check_native_stack_overflow(ptr %shr)
  %t0 = call i64 @shllvm_frame_size(i32 18)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [1 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 18, i32 0, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 17
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s14, ptr %shr, ptr %unit, i32 11)
  call void @shllvm_symbol(ptr %s15, ptr %shr, ptr %unit, i32 12)
  call void @shllvm_constant(ptr %s16, i32 0, i64 0)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s2, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s3, ptr %shr, ptr %s2, i32 2)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s4, ptr %frame, i32 1)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s4, i32 0)
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s6, ptr %frame, i32 2)
  ; Hermes StoreFrameInst
  call void @shllvm_env_store(ptr %shr, ptr %s3, ptr %s6, i32 1)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s8, ptr %s3, i32 0)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s1, i32 11, ptr %s8, i32 0, i32 0)
  ; Hermes LoadFrameInst
  call void @shllvm_env_load(ptr %s10, ptr %s3, i32 1)
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s1, i32 12, ptr %s10, i32 0, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s16, align 8
  store i64 %t1, ptr %s12, align 8
  ; Hermes ReturnInst
  %t2 = load i64, ptr %s12, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t2
}

define internal i64 @shllvm_f2(ptr %shr) {
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s10, i32 2, i64 1)
  call void @shllvm_symbol(ptr %s11, ptr %shr, ptr %unit, i32 13)
  call void @shllvm_constant(ptr %s12, i32 3, i64 4631107791820423168)
  call void @shllvm_symbol(ptr %s13, ptr %shr, ptr %unit, i32 10)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s2, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s3, ptr %shr, ptr %s2, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s10, align 8
  store i64 %t1, ptr %s4, align 8
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s1, i32 13, ptr %s4, i32 0, i32 0)
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s6, ptr %shr)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s12, align 8
  store i64 %t2, ptr %s7, align 8
  ; Hermes DefineOwnPropertyInst
  call void @shllvm_define(ptr %shr, ptr %s6, ptr %s13, ptr %s7, i32 1)
  ; Hermes ReturnInst
  %t3 = load i64, ptr %s6, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t3
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
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_constant(ptr %s8, i32 3, i64 4630967054332067840)
  call void @shllvm_symbol(ptr %s9, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_constant(ptr %s10, i32 3, i64 4636666922610458624)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s2, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s3, ptr %shr, ptr %s2, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s8, align 8
  store i64 %t1, ptr %s4, align 8
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s1, i32 10, ptr %s4, i32 0, i32 0)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s10, align 8
  store i64 %t2, ptr %s6, align 8
  ; Hermes ReturnInst
  %t3 = load i64, ptr %s6, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t3
}

define internal i64 @shllvm_f4(ptr %shr) {
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
  call void @shllvm_symbol(ptr %s7, ptr %shr, ptr %unit, i32 4)
  br label %b0
b0:
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s0, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s1, ptr %shr, ptr %s0, i32 0)
  ; Hermes GetNewTargetInst
  call void @shllvm_new_target(ptr %s2, ptr %frame)
  ; Hermes LIRGetGlobalObjectInst
  call void @shllvm_global(ptr %s3, ptr %shr)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s4, ptr %shr, ptr %unit, ptr %s3, i32 4, i32 0)
  ; Hermes BinaryStrictlyEqualInst
  call void @shllvm_binary(ptr %s5, ptr %shr, i32 7, ptr %s2, ptr %s4)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s5, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t1
}

define internal i64 @shllvm_f5(ptr %shr) {
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
  call void @shllvm_symbol(ptr %s8, ptr %shr, ptr %unit, i32 11)
  call void @shllvm_symbol(ptr %s9, ptr %shr, ptr %unit, i32 12)
  br label %b0
b0:
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s0, ptr %frame, i32 0)
  ; Hermes CoerceThisNSInst
  call void @shllvm_coerce_this(ptr %s1, ptr %shr, ptr %s0)
  ; Hermes GetParentScopeInst
  call void @shllvm_env_from_frame(ptr %s2, ptr %shr, ptr %frame)
  ; Hermes CreateScopeInst
  call void @shllvm_env_create(ptr %s3, ptr %shr, ptr %s2, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s4, ptr %shr, ptr %unit, ptr %s1, i32 11, i32 0)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s5, ptr %shr, ptr %unit, ptr %s1, i32 12, i32 0)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s6, ptr %shr, i32 0, ptr %s4, ptr %s5)
  ; Hermes ReturnInst
  %t1 = load i64, ptr %s6, align 8
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
