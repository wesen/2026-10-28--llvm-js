export const schema = 1;
export function step(state, event, arg) {
  while (event === 1) {
    state.score = (state.score + 1) | 0;
  }
  return 0;
}
