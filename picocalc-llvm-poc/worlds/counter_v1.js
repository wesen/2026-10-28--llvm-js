// Restricted JS i32 world. Host state and capability effects are separate.
export const schema = 1;
export function step(state, event, arg) {
  if (event === 1) {
    state.score = (state.score + arg) | 0;
    state.ticks = (state.ticks + 1) | 0;
    cap.emit(state.score);
  }
  if (event === 2) {
    state.score = (state.score * 2) | 0;
    cap.emit(state.score);
  }
  return 0;
}
