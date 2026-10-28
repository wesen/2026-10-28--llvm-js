function record(label, result) {
  print(label, JSON.stringify(result));
}

function* sequence(start) {
  let n = start;
  const delta = yield n;
  try {
    n += delta;
    yield n;
    return n * 2;
  } finally {
    print("sequence-finally", n);
  }
}
const a = sequence(10);
record("first", a.next(999));
record("sent", a.next(5));
record("done", a.next());
record("after", a.next(3));

const b = sequence(20);
record("b-start", b.next());
record("b-return", b.return(99));
record("b-after", b.next());

function* catchThrow() {
  try {
    yield "ready";
  } catch (e) {
    yield "caught:" + e;
  } finally {
    print("caught-finally");
  }
  return "finished";
}
const c = catchThrow();
record("c-start", c.next());
record("c-throw", c.throw("boom"));
record("c-finish", c.next());
try { c.throw("late"); } catch (e) { print("completed-throw", e); }

let touched = false;
function* unstarted() { touched = true; yield 1; }
record("unstarted-return", unstarted().return(7));
try { unstarted().throw("early"); } catch (e) { print("unstarted-throw", e); }
print("unstarted-body", touched);

let reentrant;
function* recursiveResume() {
  try { reentrant.next(); } catch (e) { yield e.name; }
}
reentrant = recursiveResume();
record("reentrant", reentrant.next());
record("reentrant-done", reentrant.next());
