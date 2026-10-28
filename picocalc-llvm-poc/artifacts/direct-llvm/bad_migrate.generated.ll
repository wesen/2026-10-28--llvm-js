; Direct LLVM IR from the PicoCalc restricted JS/i32 frontend.
; C-compatible integer semantics, not general ECMAScript.
target datalayout = "e-m:e-p:32:32-i64:64-n32-S128"
target triple = "riscv32-unknown-elf"
%PicoState = type { i32, i32, i32, i32 }

define i32 @pico_world_migrate(ptr %state, i32 %version) {
entry:
  %v1 = getelementptr %PicoState, ptr %state, i32 0, i32 0
  store i32 3, ptr %v1, align 4
  %v2 = call i32 asm sideeffect "ecall", "={x10},{x17},{x10},~{memory}"(i32 2, i32 33)
  ret i32 0
}

define i32 @pico_world_step(ptr %state, i32 %event, i32 %arg) {
entry:
  %v1 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v2 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v3 = load i32, ptr %v2, align 4
  %v4 = add i32 %v3, 1000
  %v5 = or i32 %v4, 0
  store i32 %v5, ptr %v1, align 4
  ret i32 0
}
