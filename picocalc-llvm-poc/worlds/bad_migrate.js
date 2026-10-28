export const schema = 3;
export function migrate(state, version) {
  state.schema = 3;
  cap.abort(33);
  return 0;
}
export function step(state, event, arg) {
  state.score = (state.score + 1000) | 0;
  return 0;
}
