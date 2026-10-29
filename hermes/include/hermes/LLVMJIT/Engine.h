// Private baseline engine API. Code and values never outlive their engine.
#pragma once
#include <cstddef>
#include <memory>
#include <string>
namespace hermes { namespace nativejit {
struct Result {
  bool ok;
  std::string phase;
  std::string message;
  size_t unit = 0;
};
struct SourceOptions { bool optimize = false; bool asyncGenerators = false; };
// Request-scoped frontend; neither parses nor changes global CLI options.
Result compileSource(const std::string &source, const std::string &filename,
                     const std::string &unitName, SourceOptions options,
                     std::string &ir);
class Engine {
 public:
  static std::unique_ptr<Engine> create(std::string &error);
  ~Engine();
  Engine(const Engine &) = delete;
  Engine &operator=(const Engine &) = delete;
  Result compile(const std::string &source, const std::string &filename,
                 SourceOptions options = {});
  Result loadIR(const std::string &ir, const std::string &creator);
  Result execute(size_t unit);
  // Blocking: runs microtasks and waits for configured console timers/tasks.
  // Pending module entries return phase=pending, never successful completion.
  Result drain();
  Result collect();
  Result close();
  size_t unitCount() const;
 private:
  struct Impl;
  explicit Engine(std::unique_ptr<Impl> impl);
  std::unique_ptr<Impl> impl_;
};
}}
