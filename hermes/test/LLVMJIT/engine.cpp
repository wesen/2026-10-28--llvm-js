#include "hermes/LLVMJIT/Engine.h"
#include <iostream>
#include <thread>
#include <cstdlib>
using namespace hermes::nativejit;
static void require(bool condition, const std::string &why) {
  if (!condition) { std::cerr << "FAIL " << why << '\n'; std::exit(1); }
}
static Result run(Engine &engine, const std::string &source, bool optimize = false) {
  auto unit = engine.compile(source, "engine-test.js", {optimize, true});
  require(unit.ok, unit.phase + ": " + unit.message);
  return engine.execute(unit.unit);
}
int main() {
  std::string error;
  for (int cycle = 0; cycle != 3; ++cycle) {
    auto e = Engine::create(error); require(bool(e), error);
    require(run(*e, "globalThis.shared={n:1};globalThis.inc=()=>++shared.n;").ok, "unit A");
    require(e->collect().ok, "collection");
    require(run(*e, "if(inc()!==2||shared.n!==2)throw Error('state');", true).ok, "unit B");
    auto bad = e->compile("let = ;", "broken-name.js");
    require(!bad.ok && bad.message.find("broken-name.js") != std::string::npos, "parse filename");
    require(!run(*e, "globalThis.escaped=()=>shared.n;throw Error('expected-initializer');").ok, "throw");
    require(e->collect().ok, "GC after throw");
    require(run(*e, "if(escaped()!==2)throw Error('escaped');").ok, "escaped after failure");
    for (int i=0;i!=12;++i) require(run(*e,"shared.n++;",i%2).ok,"many units");
    require(e->collect().ok, "GC after unit-table growth");
    require(run(*e, "if(shared.n!==14)throw Error('many');").ok, "unit table growth");
    require(run(*e, "globalThis.jobs=0;Promise.resolve().then(()=>jobs++);setTimeout(()=>jobs++,1);").ok,"schedule");
    require(e->drain().ok, "drain");
    require(run(*e, "if(jobs!==2)throw Error('jobs');").ok, "job effects");
    auto loaded = e->compile("shared.n++;", "once.js"); require(loaded.ok,"load once");
    require(e->execute(loaded.unit).ok && !e->execute(loaded.unit).ok,"execute once");
    require(!e->loadIR("invalid IR", "none").ok,"IR parse error");
    auto wrong=e->loadIR("target triple = \"aarch64-unknown-linux-gnu\"\ndefine ptr @creator(){ret ptr null}","creator");
    require(!wrong.ok && wrong.phase=="target", "target rejection");
    auto abi=e->loadIR("define i32 @creator(){ret i32 0}","creator");
    require(!abi.ok && abi.phase=="entry", "creator ABI");
    auto duplicateIR = std::string("define ptr @duplicate_creator(){ret ptr null}");
    require(e->loadIR(duplicateIR,"duplicate_creator").ok,"first duplicate creator");
    require(!e->loadIR(duplicateIR,"duplicate_creator").ok,"duplicate creator rejected");
    auto layout=e->loadIR("target datalayout = \"e-p:32:32\"\ndefine ptr @creator(){ret ptr null}","creator");
    require(!layout.ok && layout.phase=="target","layout rejection");
    auto missing=e->loadIR("declare ptr @missing_jit_test_symbol()\ndefine ptr @broken_creator(){%x=call ptr @missing_jit_test_symbol()\nret ptr %x}","broken_creator");
    require(!missing.ok && missing.phase=="llvm-link", "symbol failure");
    require(run(*e,"shared.n++;").ok,"recovery after link failure");
    Result threadResult{};
    std::thread t([&]{threadResult=e->collect();});t.join();
    require(!threadResult.ok && threadResult.phase=="state","thread guard");
    require(e->close().ok && e->close().ok && !e->collect().ok,"close state");
  }
  // Two simultaneously alive, distinct engines must not share runtime state.
  auto a=Engine::create(error), b=Engine::create(error);require(a&&b,"two engines");
  require(run(*a,"globalThis.identity=17;").ok,"engine a");
  require(run(*b,"if(typeof identity!=='undefined')throw Error('isolation');").ok,"engine b");
  a->close();require(run(*b,"globalThis.identity=9;").ok,"independent teardown");
  std::cout << "engine-lifecycle-ok\n";
}
