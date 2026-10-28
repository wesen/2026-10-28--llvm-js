// New behavior, schema migration and retained state.
export const schema = 2;
export function migrate(state, version) {
  if (version === 1) {
    state.flags = 42;
    state.schema = 2;
  }
  return 0;
}
export function step(state, event, arg) {
  if (event === 1) {
    state.score = (state.score + arg * 10) | 0;
    state.ticks = (state.ticks + 1) | 0;
    cap.emit(state.score);
  }
  if (event === 2) {
    state.score = (state.score * 3) | 0;
    cap.emit(state.score);
  }
  return 0;
}
