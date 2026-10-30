// show reads limit, which is declared with let further down.
function show() {
  print("limit is " + limit);
}

try {
  show();                       // too early: limit is not initialised yet
} catch (e) {
  print(e.name + ": " + e.message);
}

let limit = 10;
show();                         // now it is
