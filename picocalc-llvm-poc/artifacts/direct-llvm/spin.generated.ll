; Direct LLVM IR from the PicoCalc restricted JS/i32 frontend.
; C-compatible integer semantics, not general ECMAScript.
target datalayout = "e-m:e-p:32:32-i64:64-n32-S128"
target triple = "riscv32-unknown-elf"
%PicoState = type { i32, i32, i32, i32 }

define i32 @pico_world_step(ptr %state, i32 %event, i32 %arg) {
entry:
  br label %while.test.1
while.test.1:
  %v1 = icmp eq i32 %event, 1
  %v2 = zext i1 %v1 to i32
  %v3 = icmp ne i32 %v2, 0
  br i1 %v3, label %while.body.2, label %while.end.3
while.body.2:
  %v4 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v5 = getelementptr %PicoState, ptr %state, i32 0, i32 1
  %v6 = load i32, ptr %v5, align 4
  %v7 = add i32 %v6, 1
  %v8 = or i32 %v7, 0
  store i32 %v8, ptr %v4, align 4
  br label %while.test.1
while.end.3:
  ret i32 0
}

define i32 @pico_world_migrate(ptr %state, i32 %version) {
entry:
  %p = getelementptr %PicoState, ptr %state, i32 0, i32 0
  store i32 1, ptr %p, align 4
  ret i32 0
}
