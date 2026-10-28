// SHLLVM_TEST: {"family":"eval","kind":"compile-error","expected_diagnostic":"direct eval in a derived constructor is not supported","c_oracle":"skip","c_oracle_reason":"This fixture checks the explicit LLVM compile boundary for pre-super constructor context."}
class EvalConstructorBase {}
class EvalConstructorDerived extends EvalConstructorBase {
  constructor() {
    eval("1 + 2");
    super();
  }
}
new EvalConstructorDerived();
