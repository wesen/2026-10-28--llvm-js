// Plugin A creates the shared hook list and registers a hook that counts events.
hooks = [];
let count = 0;
hooks[hooks.length] = (event) => {
  count = count + 1;
  print("A saw " + event + " (" + count + ")");
};
print("plugin A loaded");
