// Errors across calls: a throw three frames down, caught where it can be handled.
function readField(record, key) {
  const v = record[key];
  if (v === undefined) throw new Error("missing field " + key);
  return v;
}
function total(record) { return readField(record, "price") * readField(record, "qty"); }
function invoice(records) {
  let sum = 0, bad = 0;
  for (const r of records) {
    try {
      sum = sum + total(r);
    } catch (e) {
      bad = bad + 1;
      print("skipped: " + e.message);
    }
  }
  return { sum, bad };
}

const result = invoice([{ price: 3, qty: 2 }, { price: 5 }, { qty: 1, price: 10 }]);
print("sum " + result.sum + ", skipped " + result.bad);
total({});
