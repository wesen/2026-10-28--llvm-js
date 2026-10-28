// Delegation, completion forwarding, iterator closing and ordinary iteration.
function record(label, result) { print(label, JSON.stringify(result)); }
function* child() { yield 3; return 4; }
function* combined() {
  yield* [1, 2];
  yield* "A\u{1f600}";
  const answer = yield* child();
  yield "child-return:" + answer;
  return 9;
}
const combinedIterator = combined();
for (;;) {
  const step = combinedIterator.next();
  record("combined", step);
  if (step.done) break;
}
let count = 0;
const delegate = {
  [Symbol.iterator]() { return this; },
  next(value) {
    print("delegate-next", count, value);
    return count++ === 0 ? { value: "ready", done: false }
                         : { value: value + 1, done: true };
  },
  return(value) { print("delegate-return", value); return {value: "cleanup", done: false}; }
};
function* forwarding() { return yield* delegate; }
const forward = forwarding();
record("forward-start", forward.next(999));
record("forward-return", forward.return(20));
record("forward-finish", forward.next(30));

let closes = 0;
function makeNoThrow() {
  return {
    [Symbol.iterator]() { return this; },
    next() { return {value: "open", done: false}; },
    return() { ++closes; return {done: true}; }
  };
}
function* noThrowDelegate() { yield* makeNoThrow(); }
const missing = noThrowDelegate();
record("missing-start", missing.next());
try { missing.throw("boom"); } catch (error) { print("missing-throw", error.name, closes); }
record("missing-done", missing.next());

function* closing(label) {
  try { yield 10; yield 20; }
  finally { print("closed", label); }
}
for (const value of closing("break")) { print("loop", value); break; }
try {
  for (const value of closing("throw")) { throw "loop-error:" + value; }
} catch (error) { print(error); }
const [first] = closing("destructure");
print("first", first);
print("spread", JSON.stringify([...closing("spread")]));
const protocol = closing("protocol");
print("self-iterator", protocol[Symbol.iterator]() === protocol);
try { protocol.next.call({}); } catch (error) { print("receiver", error.name); }
print("function-kind", typeof closing, typeof protocol.next);
