// Plugin C uses a class, which is outside the subset: it never reaches the engine.
class Logger {
  log(event) { print("C saw " + event); }
}
hooks[hooks.length] = (event) => new Logger().log(event);
