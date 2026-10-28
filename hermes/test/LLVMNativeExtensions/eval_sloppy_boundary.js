// SHLLVM_TEST: {"family":"eval","kind":"runtime-rejection","expected_error":"SyntaxError","expected_diagnostic":"sloppy direct string eval is unsupported","rejection_reason":"Sloppy direct eval can inject new caller var bindings, which the native frontend cannot yet resolve dynamically.","c_oracle":"skip","c_oracle_reason":"The inherited C helper silently evaluates globally instead of injecting caller bindings."}
function needsDynamicBindings() {
  eval("var introduced = 3;");
  return introduced;
}
needsDynamicBindings();
