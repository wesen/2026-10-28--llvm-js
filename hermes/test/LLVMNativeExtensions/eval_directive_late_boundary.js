// SHLLVM_TEST: {"family":"eval","kind":"runtime-rejection","expected_error":"SyntaxError","expected_diagnostic":"sloppy direct string eval is unsupported","rejection_reason":"Non-strict eval still needs dynamic binding support; directive lookalikes must not bypass that boundary.","c_oracle":"skip","c_oracle_reason":"The C helper does not enforce the native lexical-eval boundary."}
// This is valid non-strict source in Node; the native boundary is explicit.
eval("0; \"use strict\"; 1");
