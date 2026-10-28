// Suspended finally clauses must retain pending return/throw completions.
function record(label, result) { print(label, JSON.stringify(result)); }
function* pending() {
  try { yield "start"; return "body-return"; }
  finally { yield "cleanup-1"; yield "cleanup-2"; }
}
const returned = pending();
record("return-start", returned.next());
record("return-cleanup", returned.return("forced-return"));
record("return-cleanup2", returned.next());
record("return-done", returned.next());
const thrown = pending();
record("throw-start", thrown.next());
record("throw-cleanup", thrown.throw("forced-throw"));
record("throw-cleanup2", thrown.next());
try { thrown.next(); } catch (error) { print("throw-final", error); }
record("throw-done", thrown.next());
function* nested() {
  try {
    try { yield "nested-start"; throw "inside"; }
    finally { yield "inner-finally"; }
  } catch (error) { yield "caught:" + error; }
  finally { yield "outer-finally"; }
  return "nested-done";
}
const nest = nested();
for (;;) {
  const step = nest.next();
  record("nested", step);
  if (step.done) break;
}
function* overrides() {
  try { yield 1; }
  finally { yield 2; return 3; }
}
const override = overrides();
record("override-start", override.next());
record("override-cleanup", override.throw("discarded"));
record("override-done", override.next());
