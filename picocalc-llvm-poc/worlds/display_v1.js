export const schema = 1;
export function step(state, event, arg) {
  if (event === 1) {
    cap.rect(0, 0, 320, 320, 65535);
    cap.rect(0, 0, 320, 22, 63488); // RGB565 red header
    cap.rect(8, 40, 180, 14, 31);    // RGB565 blue bar
    cap.rect(8, 65, 16, 16, 2016);  // RGB565 green cursor
    state.ticks = (state.ticks + 1) | 0;
  }
  if (event === 3) {
    cap.rect(0, 0, 320, 320, 0);
    cap.abort(99); // Failed transaction must leave the panel unchanged.
  }
  return 0;
}
