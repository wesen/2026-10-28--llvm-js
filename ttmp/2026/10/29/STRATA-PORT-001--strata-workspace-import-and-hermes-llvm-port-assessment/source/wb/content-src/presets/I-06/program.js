// Every kind of variable: a parameter, var, let, const, a function declaration, a captured let.
function account(owner) {
  var opened = true;
  let balance = 0;
  const limit = 100;
  function canPay(x) { return balance + limit >= x; }
  const pay = x => {
    if (!canPay(x)) throw new RangeError(owner + " cannot pay " + x);
    balance = balance - x;
    return balance;
  };
  return { owner, opened, pay };
}

const a = account("ada");
print(a.pay(30), a.pay(50));
