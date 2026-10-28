; Direct LLVM IR from the PicoCalc restricted JS/i32 frontend.
; C-compatible integer semantics, not general ECMAScript.
target datalayout = "e-m:e-p:32:32-i64:64-n32-S128"
target triple = "riscv32-unknown-elf"
%PicoState = type { i32, i32, i32, i32 }

define i32 @pico_world_migrate(ptr %state, i32 %version) {
entry:
  %v1 = icmp eq i32 %version, 1
  %v2 = zext i1 %v1 to i32
  %v3 = icmp ne i32 %v2, 0
  br i1 %v3, label %if.yes.1, label %if.end.3
if.yes.1:
  %v4 = getelementptr %PicoState, ptr %state, i32 0, i32 3
  store i32 42, ptr %v4, align 4
  %v5 = getelementptr %PicoState, ptr %state, i32 0, i32 0
  store i32 2, ptr %v5, align 4
  br label %if.end.3
if.end.3:
  ret i32 0
}

define i32 @pico_world_step(ptr %state, i32 %event, i32 %arg) {
entry:
  %v1 = icmp eq i32 %event, 1
  %v2 = zext i1 %v1 to i32
  %v3 = icmp ne i32 %v2, 0
  br i1 %v3, label %if.yes.1, label %if.end.3
if.yes.1:
  %v4 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v5 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v6 = load i32, ptr %v5, align 4
  %v7 = mul i32 %arg, 10
  %v8 = add i32 %v6, %v7
  %v9 = or i32 %v8, 0
  store i32 %v9, ptr %v4, align 4
  %v10 = getelementptr %PicoState, ptr %state, i32 0, i32 2
  %v11 = getelementptr %PicoState, ptr %state, i32 0, i32 2
  %v12 = load i32, ptr %v11, align 4
  %v13 = add i32 %v12, 1
  %v14 = or i32 %v13, 0
  store i32 %v14, ptr %v10, align 4
  %v15 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v16 = load i32, ptr %v15, align 4
  %v17 = call i32 asm sideeffect "ecall", "={x10},{x17},{x10},~{memory}"(i32 1, i32 %v16)
  br label %if.end.3
if.end.3:
  %v18 = icmp eq i32 %event, 2
  %v19 = zext i1 %v18 to i32
  %v20 = icmp ne i32 %v19, 0
  br i1 %v20, label %if.yes.4, label %if.end.6
if.yes.4:
  %v21 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v22 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v23 = load i32, ptr %v22, align 4
  %v24 = mul i32 %v23, 3
  %v25 = or i32 %v24, 0
  store i32 %v25, ptr %v21, align 4
  %v26 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v27 = load i32, ptr %v26, align 4
  %v28 = call i32 asm sideeffect "ecall", "={x10},{x17},{x10},~{memory}"(i32 1, i32 %v27)
  br label %if.end.6
if.end.6:
  ret i32 0
}
