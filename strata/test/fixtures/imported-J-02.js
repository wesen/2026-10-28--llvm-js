// Getters and setters: a thermometer that stores Celsius and validates what it is given.
function makeThermometer(celsius) {
  let reads = 0;
  return {
    get celsius() { reads = reads + 1; return celsius; },
    set celsius(v) {
      if (typeof v !== "number") throw new TypeError("not a number: " + v);
      if (v < -273.15) throw new RangeError("below absolute zero");
      celsius = v;
    },
    get fahrenheit() { return this.celsius * 9 / 5 + 32; },
    set fahrenheit(f) { this.celsius = (f - 32) * 5 / 9; },
    get reads() { return reads; },
  };
}

const t = makeThermometer(20);
print(t.fahrenheit);
t.fahrenheit = 212;
print(t.celsius);
try { t.celsius = -300; } catch (e) { print(e.name + ": " + e.message); }
try { t.celsius = "warm"; } catch (e) { print(e.name + ": " + e.message); }
print("reads " + t.reads);
