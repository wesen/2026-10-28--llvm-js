# Typed-array receiver conversion: specification-directed probe

## Expected behavior and source

The stable ECMA-262 operation
[TypedArray [[Set]]](https://tc39.es/ecma262/2026/multipage/ordinary-and-exotic-objects-behaviours.html)
specifies different paths for a receiver equal to the typed array and a
distinct receiver. For a distinct receiver and an invalid canonical numeric
index, assignment returns true before converting the supplied value. The
definition of
[CanonicalNumericIndexString](https://tc39.es/ecma262/2026/multipage/abstract-operations.html#sec-canonicalnumericindexstring)
recognizes `"-1"` as a numeric key, although it is not a valid element index.

The expected stdout for `typed-array-receiver-spec-probe.js` is:

```text
invalid true 0 false
symbol true
bigint true
valid true 17 1
```

## Observed reference limitation

Node v24.22.1 performs the value conversion on the invalid distinct-receiver
path. The observed output differs in the first three lines:

```text
invalid true 1 false
symbol TypeError
bigint TypeError
valid true 17 1
```

The main differential fixture still checks distinct receivers with values
whose conversion has no observable side effect. This separate program
preserves the discovered disagreement and uses the specification's explicit
algorithm as its expected result.

## Execution evidence

After coordinated build 4, all three Hermes execution routes produced the
four expected lines and exited successfully:

| Route | Optimization | Result |
|---|---|---|
| C emitter with shared updated runtime | Hermes O | Matches the specification |
| Direct native LLVM | Hermes O, LLVM O2 | Matches the specification |
| LLVM lli | Hermes O, LLVM O2 | Matches the specification |

Commands, complete output, source hashes and compiler/runtime binary hashes
are retained in `values-build4-probes.json`. This result concerns the
typed-array target with a distinct ordinary receiver. A separate subsequent
guard corrects the reverse direction, in which an ordinary target has a
typed-array receiver.

The probe was rerun after complete coordinated build 8 alongside that reverse-
receiver regression. Both programs passed C, native LLVM and lli. The final
evidence is `values-final-probes.json`; its before/after source and binary
hashes agree. The same record explicitly retains Node's nonmatching output
for the specification-directed probe.
