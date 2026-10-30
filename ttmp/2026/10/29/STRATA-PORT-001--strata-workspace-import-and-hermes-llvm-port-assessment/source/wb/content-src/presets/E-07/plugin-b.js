// Plugin B registers a hook that refuses one kind of event.
hooks[hooks.length] = (event) => {
  if (event === "save") throw new Error("B cannot save");
  print("B saw " + event);
};
print("plugin B loaded");
