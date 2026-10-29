#include "hermes/LLVMJIT/Engine.h"
#include <chrono>
#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>
#include <sys/resource.h>
using namespace hermes::nativejit;
static bool report(const Result &r) {
  if (!r.ok) std::cerr << r.phase << ": " << r.message << '\n';
  return r.ok;
}
int main(int argc, char **argv) {
  SourceOptions options;
  bool collect = false, stats = false;
  std::string creator;
  std::vector<std::string> files;
  for (int i = 1; i < argc; ++i) {
    std::string arg = argv[i];
    if (arg == "-O") options.optimize = true;
    else if (arg == "--async-generators") options.asyncGenerators = true;
    else if (arg == "--gc-between") collect = true;
    else if (arg == "--stats") stats = true;
    else if (arg == "--ir" && i + 1 < argc) creator = argv[++i];
    else if (arg == "--help") {
      std::cout << "shllvm-jit [-O] [--async-generators] [--gc-between] [--stats] file.js...\n"
                   "shllvm-jit --ir sh_export_NAME file.ll\n"; return 0;
    } else if (!arg.empty() && arg[0] == '-') { std::cerr << "unknown option: " << arg << '\n'; return 2; }
    else files.push_back(arg);
  }
  if (files.empty() || (!creator.empty() && files.size() != 1)) {
    std::cerr << "provide source files, or one IR file with --ir CREATOR\n"; return 2;
  }
  std::string error;
  auto engine = Engine::create(error);
  if (!engine) { std::cerr << "initialize: " << error << '\n'; return 1; }
  for (const auto &file : files) {
    std::ifstream input(file, std::ios::binary);
    if (!input) { std::cerr << "cannot read " << file << '\n'; return 1; }
    std::ostringstream contents; contents << input.rdbuf();
    auto start = std::chrono::steady_clock::now();
    auto unit = creator.empty() ? engine->compile(contents.str(), file, options)
                                : engine->loadIR(contents.str(), creator);
    auto compiled = std::chrono::steady_clock::now();
    if (!report(unit) || !report(engine->execute(unit.unit))) return 1;
    auto executed = std::chrono::steady_clock::now();
    if (collect && !report(engine->collect())) return 1;
    struct rusage usage{};
    if (stats) getrusage(RUSAGE_SELF, &usage);
    if (stats) std::cerr << "stats " << file << " compile_ms="
      << std::chrono::duration<double,std::milli>(compiled-start).count()
      << " execute_ms=" << std::chrono::duration<double,std::milli>(executed-compiled).count()
      << " peak_rss_kib=" << usage.ru_maxrss
      << " retained_units=" << engine->unitCount() << '\n';
  }
  auto drained = engine->drain();
  if (!report(drained)) return drained.phase == "pending" ? 2 : 1;
  return report(engine->close()) ? 0 : 1;
}
