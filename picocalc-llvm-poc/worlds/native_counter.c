/* Freestanding C guest. All code is RV32; there is no libc, crt, or dynamic linker. */
#include "pico_abi.h"
__attribute__((noinline)) static int32_t multiply_three(int32_t n) {
    return n * 3;
}
int32_t pico_world_step(PicoState *state, uint32_t event, int32_t arg) {
    if (event == PICO_EVENT_ADD) {
        state->score += multiply_three(arg);
        state->ticks += 1;
        pico_cap_emit(state->score);
    }
    return 0;
}
int32_t pico_world_migrate(PicoState *state, uint32_t version) {
    (void) version;
    state->schema = 1;
    return 0;
}
