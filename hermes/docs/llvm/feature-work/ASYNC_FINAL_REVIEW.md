# Async implementation review before the final build

Reviewed 28 October 2026. This note separates observed executions from changes
that still require rebuilt validation.

## Retained partial evidence

`async-promise-final-pass.json` records eleven completed positive cases and
explicitly has `complete: false`. All recorded outcomes passed: 44 native
executions, eleven real `lli` executions, and 22 matched C executions. The
log agrees with the JSON case list. No failure is recorded. The two previously
oversized O0 programs, `async_generator_finally.js` and
`async_generator_return_values.js`, are included in the completed cases.

The interrupted file has no completed input-identity comparison and does not
establish a release result. It is kept unchanged as historical evidence.

## Concrete defect found and corrected in source

The AST visitors for function declarations and function expressions traversed
only their bodies. A nested async generator in a default-parameter expression
therefore escaped transformation. A targeted probe reproduced the defect for
defaults in four enclosing forms: ordinary declaration, ordinary expression,
async function, and async generator. Both frontend O0 and O with LLVM O2
produced caught TypeErrors; Node returned the expected Promise-valued iterator
results. An ordinary async-function default was a working control.

Evidence is in `async-parameter-traversal-build9.json` and
`traversal-probes/generator_in_parameters.js`. The authorized source correction
adds parameter-root traversal before parameters are moved into transformed
functions. It isolates parameter traversal from an enclosing async generator's
context and restores that context before body traversal. Existing lazy-body
handling remains unchanged. The permanent regression is
`test/LLVMNativeExtensions/async_parameter_expressions.js`; its Node execution
passes. The correction awaits the coordinated rebuild and final matrix.

## Architecture and documentation checks

The report appendix correctly distinguishes native state-machine execution,
managed generator environments, queued Promise reactions, and async-generator
request processing. Its return discussion matches the separate source-return
await and external-return argument await in the implementation. It also
correctly distinguishes the shared C/runtime comparison from the independent
Node comparison and avoids claiming full language conformance.

The GC-safe coding skill and its complete reference were read before reviewing
the new VM constructor-predicate wrapper. The wrapper borrows its argument
from the native call frame and calls the existing target-chain predicate;
the reviewed path does not allocate or invoke JavaScript.

The final report should mention that traversal includes await/yield operand
roots and function parameter defaults, with nested function contexts kept
separate. Final counts must come from the completed frozen full gate, not from
the partial focused file above.

## Final validation completed

The rebuilt implementation passed the complete frozen extension matrix in
`extension-final-validation.json`: 53/53 contracts, no skips, and unchanged
input hashes. Its async/async-generator/Promise families contain 24 passing
contracts: twenty positive programs, three expected runtime errors, and one
invalid-await compiler rejection. The 23 executable contracts passed 92 native
executions across frontend O0/O and LLVM O0/O2, 23 real `lli` executions, and
46 C comparisons, all matching Node's declared contracts. The rejection case
passed six compiler/driver publication checks across frontend O0/O.

The scope covers async values, errors, captures, GC and timers; async-generator
delegation, queues, return/finally and completed requests; and Promise
combinators, resolution, species, subclasses, thenables and expected errors.
In particular, both `async_nested_expressions.js` and
`async_parameter_expressions.js` pass all four native combinations, `lli`, and
both C configurations. The parameter-traversal defect is therefore verified
as corrected in the rebuilt compiler. The older partial run remains historical
evidence, and no full language-conformance claim follows from these tests.
