// SHLLVM_TEST: {"family":"eval","kind":"runtime-rejection","expected_diagnostic":"direct eval in a derived constructor is not supported","c_oracle":"skip","c_oracle_reason":"This fixture checks the LLVM string-eval context rejection after non-string passthrough.","expected_error":"SyntaxError","rejection_reason":"String evaluation still lacks derived-constructor caller context; non-string inputs are admitted."}
class EvalArrowBase {}
class EvalArrowDerived extends EvalArrowBase {
  constructor() {
    const read = () => eval("1 + 2");
    read();
    super();
  }
}
new EvalArrowDerived();
