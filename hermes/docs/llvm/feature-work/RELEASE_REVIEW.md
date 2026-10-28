# Documentation and release review

28 October 2026. Independent read-only review before the final extension gate.
The reviewed implementation was the completed build-9 state, with a narrow
nested-global-eval context correction still assigned for the next build.
This review does not substitute for a completed test matrix or PDF visual QA.

## Scope

Read `LANGUAGE_EXTENSIONS.md`, `ARCHITECTURE.md`, `REPORT_INTRO.md`,
`REPORT_VALIDATION.md`, `DRIVER.md`, `build_report.py`, and the release metadata
and packaging scripts. Compared the descriptions with the LLVM emitter's
slot allocation, feature cases, build configuration, source change inventory,
and the final-gate workflow.

## Findings sent to integration owner

1. `ARCHITECTURE.md` retained an old caution using private-field lowering as
   an example of an unestablished class feature. The new release implements
   that lowering. Replace the example with a reference to Chapter 7 and keep
   the targeted-coverage qualification. Also distinguish rejected internal
   typed-object/fixed-slot instructions from supported JavaScript private
   fields.
2. The PDF's first architecture figure drew the runtime-to-bridge arrow in
   the opposite direction from the call relationship. Generated code calls
   the prebuilt bridge, which calls the Hermes runtime. Reverse the arrow
   between the bridge and runtime boxes.
3. Optional source-guide improvement: the renderer suppresses local link
   targets, so bibliography entries whose labels omit filenames lose their
   precise source pointer in the PDF. Including the filename in those entry
   labels or prose would preserve the reading guide in both formats.

## Checks that were satisfactory

- Direct string eval is described as requiring a strict caller. The chapter
  and driver explicitly reject relying only on a strict directive inside a
  string supplied from a sloppy caller.
- Dynamic eval/Function strings compile to Hermes bytecode. The statically
  known program compiles directly to LLVM. The report does not claim a
  runtime LLVM JIT for arbitrary source strings.
- The shared C backend is identified as a second code-generation path using
  the patched frontend/runtime, rather than an independent runtime oracle.
  Its lexical-eval limitation is separated from successful comparisons.
- Runtime-boundary rejections, language errors, compiler rejections and
  positive execution contracts have separate counts in the report composer.
- The host runtime and RV32 integer-world lane have separate claims. The
  unchanged RV32 result is explicitly historical; physical hardware,
  complete ECMAScript/Test262, broad upstream testing and performance claims
  are not inferred from the targeted tests.
- The root-slot description matches the emitter: used results and constants
  retain slots; unused produced results use a separate discard root; scratch
  is distinct; the 1,024-slot limit includes argument storage and does not
  bound all native stack consumption.
- Sanitizer scope is qualified: compiler/runtime/bridge instrumentation,
  environment-specific disabled leak checking, and no claim that emitted
  LLVM bodies are fully ASan-instrumented.
- The package's explicit additions include the LLVM emitter/bridges,
  extension fixtures, extension harness and documentation. Modified tracked
  frontend, optimizer and VM files are selected automatically.
- The metadata script verifies the patch using an independent private Git
  index and checks tested input identities. The package script reads every
  ZIP member and compares its SHA-256, in addition to ZIP CRC checking.

## Remaining gates at the time of this review

Complete the final small eval correction and build, run the complete frozen
host matrix, inspect the generated report visually, then generate metadata
and package. The current review does not assert those future actions passed.
