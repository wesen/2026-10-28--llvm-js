// SHLLVM_TEST: {"family":"eval","kind":"runtime-rejection","expected_error":"SyntaxError","rejection_reason":"Native eval descriptors do not yet carry the enclosing method home object for super resolution.","c_oracle":"skip","c_oracle_reason":"The inherited C direct-eval path also lacks the method home object."}
class EvalBase {
  value() { return 8; }
}
class EvalDerived extends EvalBase {
  value() { return eval("super.value()"); }
}
new EvalDerived().value();
