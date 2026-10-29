---
Title: "Compiler framework design seminar: start here"
Ticket: LLVM-ENGINE-002
Status: active
Topics:
    - llvm
    - javascript
DocType: reference
Intent: long-term
Owners: []
RelatedFiles: []
ExternalSources: []
Summary: "Design research handoff material."
LastUpdated: 2026-10-29T15:30:00-04:00
WhatFor: "Guide design research and its returned evidence."
WhenToUse: "During the graduate seminar design assignment."
---

# Compiler framework design seminar: start here

Your assignment is to refine or replace our proposed design. Do not implement the new compiler. We want a graduate seminar research project that explains the foundations, challenges the architecture, identifies reusable components, and gives us a justified path toward a custom system.

## Read in this order

1. Read `documents/03-research-informed-redesign-and-graduate-seminar-handoff.md`. It is the current assignment and explains the scope, eight-week plan, readings, comparison examples, and return requirements.
2. Read `documents/01-engine-v2-architecture-and-intern-implementation-guide.md` and `documents/02-composable-compiler-language-grammar-effects-ownership-and-hermes-llvm-integration.md` as proposals to critique. Their implementation plans do not authorize implementation for this assignment.
3. Extract `source/current-code.tar.gz` into a separate directory. All source paths in the guides refer to its root. Follow the source-reading table in document 03.
4. Use the templates to maintain your evidence ledger, architecture decisions, subsystem designs, and final paper. Keep proposed APIs distinct from implemented APIs.

## What is included

The source archive contains the full tracked repository at commit `87d4658c4ed27aee42ddf4e023f9e9666ef3a2a1`, including source, licenses, tests, diaries, existing design documents, and historical validation evidence. The repository snapshot predates this handoff; the current assignment and its templates are supplied separately. No `.git` database, local build outputs, installed dependencies, or untracked workspace files are included. This is a source handoff, not a preconfigured build environment. Existing build instructions are under `hermes/docs/llvm/`.

The original project and bundled third-party licenses remain in the source archive. External readings are linked rather than redistributed. Check `MANIFEST.json` for payload hashes and `source/SOURCE.json` for revision and file inventory information. The manifest covers all payload files except itself. The ZIP's adjacent `.sha256` file verifies the archive as a whole.

## Verify and unpack

From the extracted package directory:

```sh
python3 VERIFY.py
mkdir code
tar -xzf source/current-code.tar.gz -C code
```

Verification checks the manifest and safe source paths; unpack only after verification succeeds. To reproduce the packet from the original repository, run the builder supplied under `tools/` with `--repo` and `--ticket` pointing to that repository and its LLVM-ENGINE-002 ticket. Reproduction requires the handoff documents and templates as well as the pinned source commit.

## What to return

Return a revised design, a 20–30 page seminar paper plus appendices, six decision records, two reusable subsystem API designs with two consumers each, a foundations chapter, a staged custom-system roadmap, worked examples and counterexamples, and a claim/evidence ledger. Explain which parts of the old proposals you removed and why. A recommendation to simplify or replace them is welcome.

The required result is design research. Existing baseline executions are optional supporting evidence. New engine code, a full JavaScript implementation, a new collector, and a production MLIR integration are outside this assignment. Illustrative pseudocode and hand-derived traces are expected; identify them as such.
