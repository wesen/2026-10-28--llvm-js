// The running example: a small ledger.
function makeLedger(name) {
  let balance = 0;
  const log = [];
  return {
    name,
    deposit(amount) {
      if (typeof amount !== "number") throw new TypeError("amount must be a number");
      balance = balance + amount;
      log[log.length] = amount;
      return balance;
    },
    get balance() { return balance; },
    total() {
      let sum = 0;
      for (let i = 0; i < log.length; i++) sum = sum + log[i];
      return sum;
    },
  };
}

const ledger = makeLedger("main");
ledger.deposit(10);
ledger.deposit(32);
try {
  ledger.deposit("five");
} catch (e) {
  print("rejected: " + e.message);
}
print(ledger.name + " " + ledger.balance + " " + ledger.total());
queueMicrotask(() => print("audit " + ledger.total()));
