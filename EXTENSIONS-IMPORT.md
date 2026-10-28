# ECMAScript extension release import

Imported on 2026-10-28 from
`~/Downloads/PicoCalc-LLVM-ECMAScript-Extensions-VERIFIED.zip`.
Archive SHA-256: `805b6dd6be63b94c22a8fa001d8f730238436ccdb36de85fea2ed1dad79b8a02`.

The archive contains 13,192 files; all 13,191 top-level manifest entries and
all ZIP CRCs passed verification. Relative to original release commit
`b1f3757493a2edbe449978cb0ebf0dd4101b705d`, it adds 141 files, changes 46, and
removes the two obsolete unsupported-eval/generator fixtures. The full inventory
is in `ttmp/2026-10-28/extensions-validation/import.json`. Packaged source and
historical evidence are retained exactly. `IMPORT.md` is the historical first
release's local-validation record.

## Fresh validation

The existing Clang/LLVM 18.1.3 Release configuration rebuilt successfully in
458 steps. Ninja's subsequent dry run reported no pending work. This local
build does not enable AddressSanitizer; packaged historical ASan evidence
remains separately qualified. Local Node is v24.18.0, Python 3.13.2, CMake
3.28.3, and Ninja 1.11.1.

The complete local gates passed:

- 22/22 core contracts, including 68 positive native comparisons.
- 53/53 extension contracts with 200 native and 50 real lli executions.
- 6/6 publication and 5/5 raw lexical-default checks.
- 654 extension-harness input fingerprints remained unchanged.

The extension totals include expected language errors and explicit unsupported
context rejections. Of 200 native executions, 176 compare positive output,
12 check language errors, and 12 check documented runtime boundaries. No case
filter, quick mode, JIT skip, or oracle-only mode was used. All four harness
exit statuses were zero. The unchanged RV32 source retains the prior local
24/24 result; host extension validation does not establish a dynamic device port.

Fresh JSON, logs, and the exact validation script are in
`ttmp/2026-10-28/extensions-validation/`. The two long-form report sources there
are `implementation-report.md` and `engineering-diary-report.md`; final copies
are published as separate new notes in the go-go-parc vault. The original vault
report is preserved unchanged.
