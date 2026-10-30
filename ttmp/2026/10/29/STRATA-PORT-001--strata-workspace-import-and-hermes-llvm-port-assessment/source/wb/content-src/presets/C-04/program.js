// A getter that prints and throws, read by code that ignores the result.
const settings = {
  get theme() {
    print("reading theme");
    throw new Error("no theme configured");
  },
};
function load() {
  const unused = settings.theme;   // the value is never used
  return "loaded";
}
try {
  print(load());
} catch (e) {
  print("caught: " + e.message);
}
