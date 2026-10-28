Promise.all([Promise.resolve(1)]).then(() => print("all"));
Promise.resolve().then(() => print("tick"));
