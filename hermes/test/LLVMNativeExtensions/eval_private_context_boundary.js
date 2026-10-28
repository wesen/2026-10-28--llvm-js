// SHLLVM_TEST: {"family":"eval","kind":"runtime-rejection","expected_error":"SyntaxError","rejection_reason":"Native eval descriptors do not yet carry the enclosing class private-name declarations.","c_oracle":"skip","c_oracle_reason":"The inherited C direct-eval path also lacks enclosing class lexical metadata."}
class PrivateContext {
  #value = 7;
  read() { return eval("this.#value"); }
}
new PrivateContext().read();
