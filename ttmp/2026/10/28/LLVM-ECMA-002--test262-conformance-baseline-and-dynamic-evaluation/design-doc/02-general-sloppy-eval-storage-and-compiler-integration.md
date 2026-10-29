---
Title: General sloppy eval storage and compiler integration
Ticket: LLVM-ECMA-002
Status: active
Topics:
    - llvm
    - javascript
DocType: design-doc
Intent: long-term
Owners: []
RelatedFiles:
    - Path: repo://hermes/include/hermes/VM/Callable.h
      Note: Environment layout and mirror assertions
    - Path: repo://hermes/include/hermes/VM/sh_mirror.h
      Note: Native environment ABI layout
    - Path: repo://hermes/lib/IRGen/ESTreeIRGen-expr.cpp
      Note: Visible eval binding collection
    - Path: repo://hermes/lib/Sema/SemanticResolver.cpp
      Note: Disabled eval unresolver hook and declaration resolution
ExternalSources: []
Summary: ""
LastUpdated: 2026-10-28T20:15:31.37117208-04:00
WhatFor: ""
WhenToUse: ""
---

# General sloppy eval storage and compiler integration

## Status and problem

This is a proposed implementation design, based on source inspection after `20fd0f6`. Strict evaluated strings from sloppy callers are implemented and qualified. General non-strict direct eval remains rejected. The design below identifies concrete representation and compiler work required before removing that rejection; none of its proposed APIs exist yet.

The difficult case is a declaration introduced after native code has already been compiled. A closure can be created before evaluation and called afterward. Its identifier resolution must then observe the introduced local binding. An implementation that executes the string globally, or creates independent eval-local cells, cannot produce the required behavior.

```javascript
var value = 1;
function example() {
  const before = () => value;
  eval("var value = 2");
  return before();
}
// The intended result is 2; global value remains 1.
```

## Existing constraints in the source

`Environment` is declared in `hermes/include/hermes/VM/Callable.h`. It contains a parent pointer, a slot count, and trailing `GCHermesValue` slots. `EnvironmentBuildMeta` in `hermes/lib/VM/Callable.cpp` traces the parent and the slot array. The allocation size is fixed at creation. Therefore adding arbitrary bindings cannot mean extending the existing trailing array in place.

The native C interface mirrors this layout in `hermes/include/hermes/VM/sh_mirror.h`. Static assertions in Callable.h check total size and member offsets. `static_h.h` exposes slot access through the mirror. Any representation change must update the VM, tracing metadata, and native layout together and rebuild all generated consumers. A pointer inserted only in the C++ class would corrupt native accesses.

The current eval descriptors describe physical environment indices and nearest visible declarations. `ESTreeIRGen::genCallEvalExpr` deliberately filters shadowed names and private names, while the LLVM emitter serializes physical scopes. This is appropriate for strict eval references. It is insufficient for general declaration instantiation: lexical conflicts can depend on intervening semantic scopes which have been merged into one physical scope or omitted from the visible-name list.

The semantic resolver has a disabled `Unresolver::run` hook for non-strict eval. That pass can mark references as unresolved when eval may shadow an outer declaration. Enabling it is not the complete implementation. Its unresolved references still require a runtime lookup representation that reaches the correct dynamic local bindings. This is a compiler/runtime integration point, not a one-line conformance fix.

## Proposed environment representation

Add a traced, initially empty reference from an eval-capable environment to a binding table. The table represents declaration records, not arbitrary user-observable object properties. A record must distinguish an alias of a static slot from a newly allocated dynamic cell. Existing locals retain their original slots so native and bytecode closures continue to share identity.

```text
Environment
  parent ------------------------> outer Environment
  static slots ------------------> existing local values
  dynamic table -----------------> BindingTable
                                     name -> StaticSlotReference
                                     name -> DynamicCell

DynamicCell
  value
  initialized
  mutable
  deletable
```

This is a logical layout. A concrete C++ layout must be chosen after reviewing tracing, pointer compression, and memory overhead. A separate traced cell avoids storing raw movable pointers in an unmanaged map. The table can be allocated lazily, but all lookup paths must treat absence as an empty table. Metadata that maps a static slot to a name must not accidentally expose internal compiler slots.

Two implementation choices remain open. A dedicated GC cell can enforce binding semantics directly but requires allocation and metadata plumbing. A runtime-internal object can reuse traced property storage but must prevent prototypes, accessors, and user code from affecting binding operations. Neither choice should be implemented as a user-visible plain object whose ordinary property semantics are assumed to equal Environment Record semantics.

## Proposed semantic scope metadata

Extend eval-site metadata with a semantic scope chain, separate from physical environment traversal. Each semantic scope needs its kind, parent, variable-environment ownership, and relevant declarations. Each declaration needs its kind and its storage reference. A mapping from semantic declaration to physical slot remains useful even when several lexical scopes share one allocated environment.

```text
EvalSiteContext
  caller flags
  semantic scopes[]
    kind: function-body | parameter | block | catch | global
    parent index
    variable-environment owner
    declarations[]
      name
      declaration kind
      static environment depth and slot, or dynamic binding reference
```

This is a proposed format rather than a public ABI. The final representation must preserve enough information to reject conflicting declarations before executing side effects. A declaration's constness and TDZ flags alone do not encode whether it is a lexical declaration in an intervening block, a parameter, or a function-body var. Existing descriptors should be replaced or extended coherently within the pinned build; no compatibility adapter is required.

## Lookup and assignment lowering

Name resolution needs an explicit result object or IR representation that preserves the location found by lookup. Reads, writes, update expressions, compound assignments, calls, typeof, and delete consume that reference differently. Repeating lookup at each suboperation can introduce observable errors if evaluation changes the environment between operations.

```text
reference = ResolveBindingForEvalSensitiveCode(context, identifier)
old = GetBindingValue(reference)
rhs = EvaluateExpression()
PutBindingValue(reference, ApplyOperator(old, rhs))
```

The compiler should mark only references whose resolution can change because of eval. Inner lexical declarations with fixed resolution continue using direct slots. References that may be shadowed by a dynamic var search the appropriate variable environment before continuing outward. Function calls also need correct receiver handling; a binding reference is not interchangeable with an arbitrary property reference.

Native and bytecode execution must use the same binding operations. Introducing the runtime table only in the LLVM bridge would leave eval-created closures and nested eval inconsistent. The IR representation should expose side effects to optimization so a call to eval invalidates assumptions about dynamically resolvable names without unnecessarily disabling optimization of unrelated local computations.

## Declaration instantiation order

Declaration analysis precedes statement execution. For each candidate var/function declaration, the runtime checks the intervening lexical environments, selects the correct variable environment, reuses allowed existing bindings, and creates permitted new bindings. Function declarations and Annex B block-function behavior need a dedicated analysis pass rather than being treated as ordinary assignment statements.

```text
compile and validate source in caller context
collect declarations under the evaluated program's strictness rules
validate all declaration conflicts
prepare binding records in the selected variable environment
initialize function declarations according to ordering rules
execute evaluated statements
return the completion value
```

The sequence is schematic and must be checked against the pinned specification before implementation. Parameter defaults, catch parameters, global lexical declarations, and with-environments require separate cases. Strict evaluation continues to allocate its own declarations rather than mutating the caller's declaration set.

## Test sequence

Start with declaration-free mutation of an existing binding, then declaration of an existing var, then introduction of a previously absent var. After each case works, add closures created before eval, closures created by eval, and repeated eval calls. This ordering isolates storage identity from declaration lookup and lifetime issues.

Required adversarial cases include:

- A new local shadows an existing global without changing the global value.
- A closure created before declaration injection observes the new local afterward.
- A block lexical declaration prevents an invalid var declaration even when the block shares physical storage with other scopes.
- A parameter binding, default-parameter environment, and body var environment are distinguished.
- A lexical binding with the same spelling in an inner closure still wins over an outer dynamic declaration.
- Assignment, compound assignment, increment, typeof, delete, and calls use correct reference semantics.
- An eval-created closure and native closure mutate the same binding across forced collection.
- Failed declaration instantiation does not execute the evaluated statement body.
- A rebound eval identifier takes the ordinary-call path instead of invoking direct-eval machinery.

Run these first as narrow fixtures, then through the unchanged pinned eval family and the full optimization matrix. Retain a baseline before enabling the unresolver hook. The final review must inspect both generated LLVM and bytecode traces where the same name changes from global resolution to an injected local binding.

## Acceptance and remaining decisions

General sloppy eval is not complete until dynamic declaration injection, runtime lookup, nested bytecode use, declaration conflicts, and garbage-collection lifetime all pass their tests. Private names, super, and derived-constructor state remain separate context extensions. The baseline can identify their failures before they are implemented.

Before coding the representation, resolve the binding-table cell type, exact semantic scope serialization, and reference IR operations. Review the memory cost on the intended embedded target. The current work does not provide evidence that an unconditional environment-header expansion is acceptable on that target.
