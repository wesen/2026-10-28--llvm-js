---
Title: "Compiler framework redesign: seminar report"
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

# Compiler framework redesign: seminar report

## Abstract and recommendations

State the question, evidence, and design recommendation.

## Current system and constraints

Explain the native/dynamic paths, runtime ownership, supported profile, and historical evidence limits.

## Foundations

Define syntax, binding, interpretation, operational semantics, observations, continuations/SSA, lattice analyses, effects, capabilities, and preservation arguments only as needed. For each, show a derivation, code mapping, and limitation.

## Architecture alternatives

Compare custom CFG, MLIR, and Hermes extension on the same examples. Revisit state tokens, legality boundaries, ownership, roots, and exception behavior.

## Revised design

Present the smallest coherent API, diagrams, invariants, error states, source integration, and explicitly rejected or deferred features.

## Reusable components

Include two independent subsystem designs with two consumers each. Distinguish generic algorithms from language policy.

## Toward a custom system

Provide staged dependency replacement, formal-core scope, runtime requirements, and evidence gates. Distinguish owning semantics from replacing LLVM machine-code generation.

## Evaluation and limitations

Provide worked traces, counterexamples, claim ledger, alternative costs, and independent/self-review status. Separate derived results from executed tests.

## Future engineering proposal

List bounded implementation slices with acceptance criteria, not completed implementation claims.

## Bibliography and appendices

Record sections actually studied, versions, source navigation, decision records, and handback manifest.
