// Persistent application host: manifest lines are "expected-outcome filename".
#include "hermes/LLVMJIT/Engine.h"
#include <chrono>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
using namespace hermes::nativejit;
int main(int argc, char **argv) {
  if (argc < 2 || argc > 3 || (argc == 3 && std::string(argv[2]) != "-O")) {
    std::cerr << "usage: shllvm-app-host manifest [-O]\n"; return 2;
  }
  std::ifstream manifest(argv[1]);
  if (!manifest) { std::cerr << "cannot open manifest\n"; return 2; }
  std::string error;
  auto engine = Engine::create(error);
  if (!engine) { std::cerr << error << '\n'; return 1; }
  size_t submissions = 0, compileErrors = 0, executionErrors = 0;
  double compileMs = 0, executeMs = 0;
  std::string line;
  while (std::getline(manifest, line)) {
    auto split = line.find(' ');
    if (split == std::string::npos) { std::cerr << "invalid manifest line\n"; return 2; }
    auto expected = line.substr(0, split), filename = line.substr(split + 1);
    if (expected != "ok" && expected != "parse-error" && expected != "execute-error") {
      std::cerr << "invalid expected outcome\n"; return 2;
    }
    std::ifstream input(filename);
    if (!input) { std::cerr << "cannot open " << filename << '\n'; return 2; }
    std::stringstream source; source << input.rdbuf();
    auto start = std::chrono::steady_clock::now();
    auto compiled = engine->compile(source.str(), filename, {argc == 3, false});
    auto loaded = std::chrono::steady_clock::now();
    compileMs += std::chrono::duration<double, std::milli>(loaded-start).count();
    ++submissions;
    if (expected == "parse-error") {
      if (compiled.ok || compiled.phase != "parse") {
        std::cerr << "expected parse error: " << filename << ' ' << compiled.phase << '\n'; return 1;
      }
      ++compileErrors;
      continue;
    }
    if (!compiled.ok) { std::cerr << compiled.phase << ": " << compiled.message << '\n'; return 1; }
    auto result = engine->execute(compiled.unit);
    executeMs += std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now()-loaded).count();
    if (expected == "execute-error") {
      if (result.ok || result.phase != "execute") { std::cerr << "expected initializer failure\n"; return 1; }
      ++executionErrors;
    } else if (!result.ok) { std::cerr << result.message << '\n'; return 1; }
    // Collect before any later submission or job can use the published values.
    if (!engine->collect().ok) return 1;
  }
  auto drained = engine->drain();
  if (!drained.ok) { std::cerr << drained.phase << ": " << drained.message << '\n'; return 1; }
  std::cerr << "host-stats {\"submissions\":" << submissions
            << ",\"units\":" << engine->unitCount()
            << ",\"parseErrors\":" << compileErrors
            << ",\"executionErrors\":" << executionErrors
            << ",\"compile_ms\":" << compileMs << ",\"execute_ms\":" << executeMs << "}\n";
  return engine->close().ok ? 0 : 1;
}
