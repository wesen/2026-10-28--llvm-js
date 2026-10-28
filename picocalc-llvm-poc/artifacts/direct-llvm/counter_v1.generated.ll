; Direct LLVM IR from the PicoCalc restricted JS/i32 frontend.
; C-compatible integer semantics, not general ECMAScript.
target datalayout = "e-m:e-p:32:32-i64:64-n32-S128"
target triple = "riscv32-unknown-elf"
%PicoState = type { i32, i32, i32, i32 }

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
  %v7 = add i32 %v6, %arg
  %v8 = or i32 %v7, 0
  store i32 %v8, ptr %v4, align 4
  %v9 = getelementptr %PicoState, ptr %state, i32 0, i32 2
  %v10 = getelementptr %PicoState, ptr %state, i32 0, i32 2
  %v11 = load i32, ptr %v10, align 4
  %v12 = add i32 %v11, 1
  %v13 = or i32 %v12, 0
  store i32 %v13, ptr %v9, align 4
  %v14 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v15 = load i32, ptr %v14, align 4
  %v16 = call i32 asm sideeffect "ecall", "={x10},{x17},{x10},~{memory}"(i32 1, i32 %v15)
  br label %if.end.3
if.end.3:
  %v17 = icmp eq i32 %event, 2
  %v18 = zext i1 %v17 to i32
  %v19 = icmp ne i32 %v18, 0
  br i1 %v19, label %if.yes.4, label %if.end.6
if.yes.4:
  %v20 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v21 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v22 = load i32, ptr %v21, align 4
  %v23 = mul i32 %v22, 2
  %v24 = or i32 %v23, 0
  store i32 %v24, ptr %v20, align 4
  %v25 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v26 = load i32, ptr %v25, align 4
  %v27 = call i32 asm sideeffect "ecall", "={x10},{x17},{x10},~{memory}"(i32 1, i32 %v26)
  br label %if.end.6
if.end.6:
  ret i32 0
}

define i32 @pico_world_migrate(ptr %state, i32 %version) {
entry:
  %p = getelementptr %PicoState, ptr %state, i32 0, i32 0
  store i32 1, ptr %p, align 4
  ret i32 0
}
