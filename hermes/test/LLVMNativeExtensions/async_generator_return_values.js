// SHLLVM_TEST: {"completion":"done: async_generator_return_values","family":"async-generators","hermes_flags":["-Xasync-generators"]}
async function* returning() {
  try {
    return Promise.reject(new Error("return expression"));
  } catch (error) {
    print("caught-return", error.name, error.message);
    return Promise.resolve(42);
  } finally {
    print("return-finally");
  }
}
async function* catching() {
  try { yield "ready"; }
  catch (error) {
    print("caught-argument", error.name, error.message);
    yield "recovered";
  } finally { print("argument-finally"); }
}
async function* neverStarted() {
  throw new Error("generator body must not start");
}
async function* contexts() {
  var arrow = () => { return 8; };
  var asyncArrow = async () => { return await Promise.resolve(9); };
  var factory = () => async function* () { return 10; };
  return arrow() + (await asyncArrow()) + (await factory()().next()).value;
}
async function* delegated() {
  yield* {
    [Symbol.asyncIterator]: function () { return this; },
    next: function () { return Promise.resolve({value: 1, done: false}); },
    return: function (value) {
      return Promise.resolve({value: Promise.resolve(value + 1), done: true});
    }
  };
}
async function main() {
  print("return-result", JSON.stringify(await returning().next()));
  var generator = catching();
  print("ready", JSON.stringify(await generator.next()));
  print("recovered", JSON.stringify(await generator.return(Promise.reject(new Error("return argument")))));
  print("after-recovery", JSON.stringify(await generator.next()));
  print("completed-return", JSON.stringify(await generator.return(Promise.resolve(99))));
  try { await generator.throw("late"); } catch (error) { print("completed-throw", error); }

  var getterGenerator = catching();
  await getterGenerator.next();
  var argument = Promise.resolve(7);
  Object.defineProperty(argument, "constructor", {
    get: function () { throw new SyntaxError("constructor getter"); }
  });
  print("getter-result", JSON.stringify(await getterGenerator.return(argument)));
  print("getter-done", JSON.stringify(await getterGenerator.next()));

  print("unstarted", JSON.stringify(await neverStarted().return(Promise.resolve(17))));
  try { await neverStarted().return(Promise.reject(new TypeError("unstarted return"))); }
  catch (error) { print("unstarted-rejection", error.name, error.message); }
  print("contexts", JSON.stringify(await contexts().next()));
  var defaultFactory = (generator = async function* () { yield 4; return 5; }) => generator;
  var fromDefault = defaultFactory()();
  print("default-parameter", JSON.stringify(await fromDefault.next()),
        JSON.stringify(await fromDefault.next()));

  var delegate = delegated();
  await delegate.next();
  var delegatedReturn = await delegate.return(10);
  print("delegate-return", delegatedReturn.done, delegatedReturn.value instanceof Promise, await delegatedReturn.value);

  var empty = (async function* () {})();
  var emptyResult = empty.next();
  print("empty", typeof empty[Symbol.asyncIterator], emptyResult instanceof Promise,
        JSON.stringify(await emptyResult));
}
main().then(function () { print("done: async_generator_return_values"); },
            function (error) { print("FAIL", error.name, error.message); });
