#ifndef PICO_JIT_ABI_H
#define PICO_JIT_ABI_H
/* Shared target ABI. Freestanding RV32I code: no libc, dynamic loader or sysroot. */
#include <stdint.h>
#define PICO_ABI_VERSION 1
#define PICO_STATE_ADDR 0x30000000u
#define PICO_STACK_BASE 0x80000000u
#define PICO_STACK_SIZE 8192u
#define PICO_EVENT_ADD 1u
#define PICO_EVENT_DOUBLE 2u
#define PICO_EVENT_FAULT 3u
#define PICO_EVENT_TICK 4u
#define PICO_CAP_EMIT 1u
#define PICO_CAP_ABORT 2u
#define PICO_CAP_RECT 3u
#define PICO_PANEL_WIDTH 320u
#define PICO_PANEL_HEIGHT 320u

typedef struct PicoState {
    uint32_t schema;
    int32_t score;
    int32_t ticks;
    int32_t flags;
} PicoState;

#ifdef __riscv
/* Only host effects through ecall; no libc imports. a0=argument, a7=service ID. */
static inline int32_t pico_cap_emit(int32_t value) {
    register int32_t a0 __asm__("a0") = value;
    register int32_t a7 __asm__("a7") = PICO_CAP_EMIT;
    __asm__ volatile("ecall" : "+r"(a0) : "r"(a7) : "memory");
    return a0;
}
static inline int32_t pico_cap_rect(int32_t x, int32_t y, int32_t w, int32_t h, int32_t rgb565) {
    register int32_t a0 __asm__("a0") = x;
    register int32_t a1 __asm__("a1") = y;
    register int32_t a2 __asm__("a2") = w;
    register int32_t a3 __asm__("a3") = h;
    register int32_t a4 __asm__("a4") = rgb565;
    register int32_t a7 __asm__("a7") = PICO_CAP_RECT;
    __asm__ volatile("ecall" : "+r"(a0) : "r"(a1), "r"(a2), "r"(a3), "r"(a4), "r"(a7) : "memory");
    return a0;
}
static inline int32_t pico_cap_abort(int32_t code) {
    register int32_t a0 __asm__("a0") = code;
    register int32_t a7 __asm__("a7") = PICO_CAP_ABORT;
    __asm__ volatile("ecall" : "+r"(a0) : "r"(a7) : "memory");
    return a0;
}
#else
/* Declared only to make ABI documentation portable. Host does not link guest code. */
int32_t pico_cap_emit(int32_t value);
int32_t pico_cap_abort(int32_t code);
int32_t pico_cap_rect(int32_t x, int32_t y, int32_t w, int32_t h, int32_t rgb565);
#endif
#endif
