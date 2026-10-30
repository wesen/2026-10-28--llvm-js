// The host's dispatcher: call every registered hook, isolating failures.
function dispatch(event) {
  for (const h of hooks) {
    try {
      h(event);
    } catch (e) {
      print("a hook failed: " + e.message);
    }
  }
}

dispatch("open");
dispatch("save");
queueMicrotask(() => dispatch("close"));
