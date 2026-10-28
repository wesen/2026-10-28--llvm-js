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
  %v4 = call i32 asm sideeffect "ecall", "={x10},{x17},{x10},{x11},{x12},{x13},{x14},~{memory}"(i32 3, i32 0, i32 0, i32 320, i32 320, i32 65535)
  %v5 = call i32 asm sideeffect "ecall", "={x10},{x17},{x10},{x11},{x12},{x13},{x14},~{memory}"(i32 3, i32 0, i32 0, i32 320, i32 22, i32 63488)
  %v6 = call i32 asm sideeffect "ecall", "={x10},{x17},{x10},{x11},{x12},{x13},{x14},~{memory}"(i32 3, i32 8, i32 40, i32 180, i32 14, i32 31)
  %v7 = call i32 asm sideeffect "ecall", "={x10},{x17},{x10},{x11},{x12},{x13},{x14},~{memory}"(i32 3, i32 8, i32 65, i32 16, i32 16, i32 2016)
  %v8 = getelementptr %PicoState, ptr %state, i32 0, i32 2
  %v9 = getelementptr %PicoState, ptr %state, i32 0, i32 2
  %v10 = load i32, ptr %v9, align 4
  %v11 = add i32 %v10, 1
  %v12 = or i32 %v11, 0
  store i32 %v12, ptr %v8, align 4
  br label %if.end.3
if.end.3:
  %v13 = icmp eq i32 %event, 3
  %v14 = zext i1 %v13 to i32
  %v15 = icmp ne i32 %v14, 0
  br i1 %v15, label %if.yes.4, label %if.end.6
if.yes.4:
  %v16 = call i32 asm sideeffect "ecall", "={x10},{x17},{x10},{x11},{x12},{x13},{x14},~{memory}"(i32 3, i32 0, i32 0, i32 320, i32 320, i32 0)
  %v17 = call i32 asm sideeffect "ecall", "={x10},{x17},{x10},~{memory}"(i32 2, i32 99)
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
