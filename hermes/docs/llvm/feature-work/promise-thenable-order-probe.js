var events = [];
Promise.resolve({then: function (resolve) { events.push("then"); resolve(4); }})
  .then(function (value) { events.push("resolved:" + value); });
events.push("sync");
Promise.resolve().then(function () { events.push("tick"); });
Promise.resolve().then(function () {}).then(function () {}).then(function () {
  print(events.join("|"));
  print("fresh", Promise.resolve(0) !== Promise.resolve(0));
});
