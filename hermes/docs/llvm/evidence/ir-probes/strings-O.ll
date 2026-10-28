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
  %t0 = call i64 @shllvm_frame_size(i32 52)
  %storage = alloca i8, i64 %t0, align 16
  %argv = alloca [4 x i64], align 8
  %unit_index = load i32, ptr @shllvm_unit_index, align 4
  %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 52, i32 4, i32 %unit_index)
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
  %scratch = getelementptr i64, ptr %roots, i32 51
  call void @shllvm_check_invocation(ptr %shr, ptr %frame, i32 0)
  call void @shllvm_symbol(ptr %s35, ptr %shr, ptr %unit, i32 1)
  call void @shllvm_symbol(ptr %s36, ptr %shr, ptr %unit, i32 2)
  call void @shllvm_symbol(ptr %s37, ptr %shr, ptr %unit, i32 3)
  call void @shllvm_constant(ptr %s38, i32 0, i64 0)
  call void @shllvm_constant(ptr %s39, i32 2, i64 0)
  call void @shllvm_symbol(ptr %s40, ptr %shr, ptr %unit, i32 4)
  call void @shllvm_symbol(ptr %s41, ptr %shr, ptr %unit, i32 5)
  call void @shllvm_symbol(ptr %s42, ptr %shr, ptr %unit, i32 6)
  call void @shllvm_symbol(ptr %s43, ptr %shr, ptr %unit, i32 7)
  call void @shllvm_constant(ptr %s44, i32 3, i64 0)
  call void @shllvm_constant(ptr %s45, i32 3, i64 4607182418800017408)
  call void @shllvm_symbol(ptr %s46, ptr %shr, ptr %unit, i32 8)
  call void @shllvm_symbol(ptr %s47, ptr %shr, ptr %unit, i32 9)
  call void @shllvm_symbol(ptr %s48, ptr %shr, ptr %unit, i32 10)
  call void @shllvm_symbol(ptr %s49, ptr %shr, ptr %unit, i32 11)
  call void @shllvm_constant(ptr %s50, i32 3, i64 4631107791820423168)
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
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s4, ptr %shr, ptr %unit, ptr %s1, i32 2, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s5, ptr %shr, ptr %unit, ptr %s1, i32 1, i32 0)
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s37, align 8
  store i64 %t1, ptr %s6, align 8
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s38, align 8
  store i64 %t2, ptr %s7, align 8
  ; Hermes CallInst
  %t3 = getelementptr i64, ptr %argv, i32 0
  %t4 = load i64, ptr %s6, align 8
  store i64 %t4, ptr %t3, align 8
  call void @shllvm_call(ptr %s8, ptr %shr, ptr %frame, ptr %s5, ptr %s7, ptr %s7, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t5 = load i64, ptr %s40, align 8
  store i64 %t5, ptr %s9, align 8
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s10, ptr %shr, ptr %unit, ptr %s9, i32 5, i32 0)
  ; Hermes LIRLoadConstInst
  %t6 = load i64, ptr %s42, align 8
  store i64 %t6, ptr %s11, align 8
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s12, ptr %shr, ptr %unit, ptr %s11, i32 7, i32 0)
  ; Hermes LIRLoadConstInst
  %t7 = load i64, ptr %s44, align 8
  store i64 %t7, ptr %s13, align 8
  ; Hermes CallInst
  %t8 = getelementptr i64, ptr %argv, i32 0
  %t9 = load i64, ptr %s13, align 8
  store i64 %t9, ptr %t8, align 8
  call void @shllvm_call(ptr %s14, ptr %shr, ptr %frame, ptr %s12, ptr %s11, ptr %s7, i32 1, ptr %argv)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s15, ptr %shr, ptr %unit, ptr %s9, i32 7, i32 0)
  ; Hermes LIRLoadConstInst
  %t10 = load i64, ptr %s45, align 8
  store i64 %t10, ptr %s16, align 8
  ; Hermes CallInst
  %t11 = getelementptr i64, ptr %argv, i32 0
  %t12 = load i64, ptr %s16, align 8
  store i64 %t12, ptr %t11, align 8
  call void @shllvm_call(ptr %s17, ptr %shr, ptr %frame, ptr %s15, ptr %s9, ptr %s7, i32 1, ptr %argv)
  ; Hermes CallInst
  %t13 = getelementptr i64, ptr %argv, i32 0
  %t14 = load i64, ptr %s8, align 8
  store i64 %t14, ptr %t13, align 8
  %t15 = getelementptr i64, ptr %argv, i32 1
  %t16 = load i64, ptr %s10, align 8
  store i64 %t16, ptr %t15, align 8
  %t17 = getelementptr i64, ptr %argv, i32 2
  %t18 = load i64, ptr %s14, align 8
  store i64 %t18, ptr %t17, align 8
  %t19 = getelementptr i64, ptr %argv, i32 3
  %t20 = load i64, ptr %s17, align 8
  store i64 %t20, ptr %t19, align 8
  call void @shllvm_call(ptr %s18, ptr %shr, ptr %frame, ptr %s4, ptr %s7, ptr %s7, i32 4, ptr %argv)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s19, ptr %shr, ptr %unit, ptr %s1, i32 2, i32 1)
  ; Hermes LIRLoadConstInst
  %t21 = load i64, ptr %s46, align 8
  store i64 %t21, ptr %s20, align 8
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s21, ptr %shr, ptr %unit, ptr %s20, i32 9, i32 0)
  ; Hermes CallInst
  %t22 = getelementptr i64, ptr %argv, i32 0
  %t23 = load i64, ptr %s16, align 8
  store i64 %t23, ptr %t22, align 8
  call void @shllvm_call(ptr %s22, ptr %shr, ptr %frame, ptr %s21, ptr %s20, ptr %s7, i32 1, ptr %argv)
  ; Hermes LIRLoadConstInst
  %t24 = load i64, ptr %s48, align 8
  store i64 %t24, ptr %s23, align 8
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s24, ptr %shr, ptr %unit, ptr %s23, i32 5, i32 0)
  ; Hermes LIRLoadConstInst
  %t25 = load i64, ptr %s49, align 8
  store i64 %t25, ptr %s25, align 8
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s26, ptr %shr, ptr %unit, ptr %s25, i32 5, i32 0)
  ; Hermes CallInst
  %t26 = getelementptr i64, ptr %argv, i32 0
  %t27 = load i64, ptr %s22, align 8
  store i64 %t27, ptr %t26, align 8
  %t28 = getelementptr i64, ptr %argv, i32 1
  %t29 = load i64, ptr %s24, align 8
  store i64 %t29, ptr %t28, align 8
  %t30 = getelementptr i64, ptr %argv, i32 2
  %t31 = load i64, ptr %s26, align 8
  store i64 %t31, ptr %t30, align 8
  call void @shllvm_call(ptr %s27, ptr %shr, ptr %frame, ptr %s19, ptr %s7, ptr %s7, i32 3, ptr %argv)
  ; Hermes AllocObjectLiteralInst
  call void @shllvm_object(ptr %s28, ptr %shr)
  ; Hermes LIRLoadConstInst
  %t32 = load i64, ptr %s50, align 8
  store i64 %t32, ptr %s29, align 8
  ; Hermes StorePropertyLooseInst
  call void @shllvm_set_id(ptr %shr, ptr %unit, ptr %s28, i32 10, ptr %s29, i32 0, i32 0)
  ; Hermes TryLoadGlobalPropertyInst
  call void @shllvm_get_id(ptr %s31, ptr %shr, ptr %unit, ptr %s1, i32 2, i32 1)
  ; Hermes LoadPropertyInst
  call void @shllvm_get_id(ptr %s32, ptr %shr, ptr %unit, ptr %s28, i32 10, i32 0)
  ; Hermes CallInst
  %t33 = getelementptr i64, ptr %argv, i32 0
  %t34 = load i64, ptr %s32, align 8
  store i64 %t34, ptr %t33, align 8
  call void @shllvm_call(ptr %s33, ptr %shr, ptr %frame, ptr %s31, ptr %s7, ptr %s7, i32 1, ptr %argv)
  ; Hermes ReturnInst
  %t35 = load i64, ptr %s33, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t35
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
  call void @shllvm_symbol(ptr %s6, ptr %shr, ptr %unit, i32 12)
  call void @shllvm_symbol(ptr %s7, ptr %shr, ptr %unit, i32 13)
  br label %b0
b0:
  ; Hermes LIRLoadConstInst
  %t1 = load i64, ptr %s6, align 8
  store i64 %t1, ptr %s0, align 8
  ; Hermes LoadParamInst
  call void @shllvm_param(ptr %s1, ptr %frame, i32 1)
  ; Hermes BinaryAddInst
  call void @shllvm_binary(ptr %s2, ptr %shr, i32 0, ptr %s0, ptr %s1)
  ; Hermes LIRLoadConstInst
  %t2 = load i64, ptr %s7, align 8
  store i64 %t2, ptr %s3, align 8
  ; Hermes StringConcatInst
  %t3 = load i64, ptr %s2, align 8
  store i64 %t3, ptr %s4, align 8
  call void @shllvm_binary(ptr %s4, ptr %shr, i32 0, ptr %s4, ptr %s3)
  ; Hermes ReturnInst
  %t4 = load i64, ptr %s4, align 8
  call void @shllvm_leave(ptr %shr, ptr %storage, ptr %frame)
  ret i64 %t4
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
