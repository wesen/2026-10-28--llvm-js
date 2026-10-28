export const schema = 1;
export function step(state, event, arg) {
  state.score = (state.score + arg) | 0;
  cap.emit(state.score);
  cap.abort(66); // Should rollback *both* state and pending emit.
  return 0;
}
