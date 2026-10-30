# Appendix A: Core IR reference

This appendix lists everything the verifier and the interpreter accept: the text form of core IR, the types, every operation of the five standard sets with its contract, the variants used for narrowing, and the verifier's rules. The operation tables were generated from the engine (`g.opsets`, `g.ops`, `g.perm` and each operation's lowering) by a script run against engine version 0.1.0, and the rules were read from the verifier's source; if the engine and this page disagree, the engine is right and this page is out of date. [Chapter 3](lab:book?ch=3) explains the IR, [Chapter 6](lab:book?ch=6) the contracts and [Chapter 7](lab:book?ch=7) the permissions.

## A.1 The text form

The parser reads what the printer writes, plus comments after `;` or `//`. One construct per line:

```text
module      := function+
function    := "fn" name "(" params? ")" ( "->" type )? "{" block+ "}"
params      := param ( "," param )*
param       := name ":" type
type        := kind ( "|" kind )*
block       := label ( "(" params? ")" )? exit? ":" line* terminator
exit        := "throws" "unwind" | "throws" "to" label ( "(" operands ")" )?
line        := ( value "=" )? call
call        := opname ( "[" attr ( "," attr )* "]" )? "(" ( "@" callee ( "," )? )? operands? ")"
terminator  := "jump" edge
             | "branch" operand "," edge "," edge
             | "return" operand?
             | "throw" operand
             | "unreachable"
             | "invoke" call "normal" edge "throw" edge
edge        := label ( "(" operands ")" )?
operand     := value | number | string | "true" | "false" | "null" | "undefined"
number      := decimal | "-0" | "NaN" | "Infinity" | "-Infinity"
```

The first block is the entry, entered with no arguments, so it should declare no parameters. A value name is defined once in a function, by a function parameter, a block parameter or an operation's result. Numbers are doubles, strings are JSON strings. Attributes: `@callee` names a function of the module (`js.closure`, `core.call`); a bracketed attribute gives a kind (`js.new_error[TypeError]`, `completion.is[return]`).

**Implicit parameters.** Three kinds of edge pass a value the edge itself defines, as the target's first parameter before any explicit arguments: the normal edge of an `invoke` whose operation has a result (the result), the throw edge of an `invoke` (the thrown value), and a block's `throws to H(args)` exit (the thrown value, then `args`, evaluated at the head of the protected block).

**Exceptional exits.** A block's header says where a throw inside it goes: `throws to H(args)` to a handler block, `throws unwind` to the caller. A block with neither may not contain an operation that may throw; the verifier reports `may-throw-without-exit`. The frontend writes `throws unwind` on every block outside a `try`, so this matters only for IR written by hand or with `g.fn`.

## A.2 Types

A type is a set of kinds. The ten kinds are `undefined`, `null`, `boolean`, `int32`, `double`, `string`, `object`, `function`, `cell` and `completion`. Named unions:

| name | kinds |
|---|---|
| `number` | int32, double |
| `any` | every JavaScript value: undefined, null, boolean, number, string, object, function |
| `top` | any, cell, completion |
| `bottom` | none |
| `propertyKey` | number, string |

The type of a union prints as its kinds joined by `|`, with `number` used for int32 and double together: `number|string`. A type is **managed** if it can hold a heap reference: object, function, cell or completion (the type's `managed` flag). The root planner of [Chapter 13](lab:book?ch=13) is more cautious: it gives a root slot to any value whose type may also be a string, since a real runtime allocates strings on the collected heap.

## A.3 Operations

Each table gives the operands and results (`…` marks a variadic operation), the behaviour and obligations from the contract, the permissions `g.perm` derives with no facts (allowed outright, or allowed under a condition the rewrite must check), and the lowering the L2 pass binds: an inline instruction, a runtime helper (with its operation code where the helper serves several operations) or a direct call. "none" in the permission columns means every permission is refused.

### A.3.1 core

26 operations: numbers, 32-bit integers, booleans, direct calls and printing. This is the profile the WebAssembly backend accepts.

| operation | operands → results | behaviour | obligations | allowed | conditional | lowered to |
|---|---|---|---|---|---|---|
| `num.add` | number, number → number | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline fadd` |
| `num.sub` | number, number → number | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline fsub` |
| `num.mul` | number, number → number | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline fmul` |
| `num.div` | number, number → number | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline fdiv` |
| `num.mod` | number, number → number | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline frem` |
| `num.neg` | number → number | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline fneg` |
| `num.lt` | number, number → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline fcmp olt` |
| `num.le` | number, number → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline fcmp ole` |
| `num.gt` | number, number → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline fcmp ogt` |
| `num.ge` | number, number → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline fcmp oge` |
| `num.eq` | number, number → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline fcmp oeq` |
| `num.ne` | number, number → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline fcmp une` |
| `i32.add` | int32, int32 → int32 | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline add i32` |
| `i32.sub` | int32, int32 → int32 | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline sub i32` |
| `i32.mul` | int32, int32 → int32 | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline mul i32` |
| `i32.lt` | int32, int32 → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline icmp slt` |
| `i32.eq` | int32, int32 → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline icmp eq` |
| `bool.not` | boolean → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline xor i1` |
| `bool.and` | boolean, boolean → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline and i1` |
| `bool.or` | boolean, boolean → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline or i1` |
| `core.copy` | top → top | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline copy` |
| `core.ref_eq` | any, any → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `inline icmp eq i64` |
| `core.is_number` | any → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `shllvm_typeof_is` |
| `core.is_int32` | any → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `shllvm_typeof_is` |
| `core.call` [callee] | … → the callee's declared result | callsUser | mayCollect, nonlocalThrow | none | none | `direct call` |
| `host.print` | … → none | host(print) | mayCollect | none | none | `shllvm_builtin (print)` |

### A.3.2 js.value

16 operations on JavaScript values. The arithmetic and comparisons may call `valueOf` or `toString` and so carry `callsUser`; strict equality, negation, truthiness and `typeof` are pure.

| operation | operands → results | behaviour | obligations | allowed | conditional | lowered to |
|---|---|---|---|---|---|---|
| `js.add` | any, any → any | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_binary (add)` |
| `js.sub` | any, any → number | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_binary (sub)` |
| `js.mul` | any, any → number | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_binary (mul)` |
| `js.div` | any, any → number | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_binary (div)` |
| `js.mod` | any, any → number | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_binary (mod)` |
| `js.neg` | any → number | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_unary (neg)` |
| `js.lt` | any, any → boolean | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_binary (lt)` |
| `js.le` | any, any → boolean | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_binary (le)` |
| `js.gt` | any, any → boolean | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_binary (gt)` |
| `js.ge` | any, any → boolean | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_binary (ge)` |
| `js.strict_eq` | any, any → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `shllvm_binary (strict_eq)` |
| `js.strict_ne` | any, any → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `shllvm_binary (strict_ne)` |
| `js.not` | any → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `shllvm_truthy` |
| `js.truthy` | any → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `shllvm_truthy` |
| `js.typeof` | any → string | none | none | erase, merge, move, duplicate, hoist, speculate | none | `shllvm_unary (typeof)` |
| `str.concat` | string, string → string | fresh | mayCollect | move, speculate | erase | `shllvm_binary (add)` |

### A.3.3 js.object

9 operations that make objects and read or write their properties.

| operation | operands → results | behaviour | obligations | allowed | conditional | lowered to |
|---|---|---|---|---|---|---|
| `obj.new` | none → object | fresh | mayCollect | move, speculate | erase | `shllvm_object` |
| `arr.new` | … → object | fresh | mayCollect | move, speculate | erase | `shllvm_array` |
| `js.define` | object, string, any → none | reads+writes(heap) | mayCollect, writeBarrier | none | move | `shllvm_define` |
| `js.define_getter` | object, string, function → none | reads+writes(heap) | mayCollect, writeBarrier | none | move | `shllvm_define_accessor` |
| `js.define_setter` | object, string, function → none | reads+writes(heap) | mayCollect, writeBarrier | none | move | `shllvm_define_accessor` |
| `js.get` | any, number\|string → any | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_get` |
| `js.put` | any, number\|string, any → none | callsUser | mayCollect, nonlocalThrow, writeBarrier | none | none | `shllvm_set` |
| `js.get_own_data` | object, number\|string → any | reads(heap) | none | erase, duplicate | merge, move, hoist, speculate | `shllvm_get_id` |
| `js.new_error` [kind] | any → object | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_constructed_object` |

### A.3.4 js.function

10 operations for closures, calls, cells and globals.

| operation | operands → results | behaviour | obligations | allowed | conditional | lowered to |
|---|---|---|---|---|---|---|
| `js.closure` [callee] | … → function | fresh | mayCollect | move, speculate | erase | `shllvm_closure` |
| `js.call` | … → any | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_call` |
| `js.call_method` | … → any | callsUser | mayCollect, nonlocalThrow | none | none | `shllvm_call` |
| `cell.new` | … → cell | fresh | mayCollect | move, speculate | erase | `shllvm_env_create` |
| `cell.load` | cell → any | reads(cells) | none | erase, duplicate | merge, move, hoist, speculate | `shllvm_env_load` |
| `cell.load_checked` | cell → any | reads(cells), throws | nonlocalThrow | none | move | `shllvm_check_tdz` |
| `cell.store` | cell, any → none | reads+writes(cells) | writeBarrier | none | move | `shllvm_env_store` |
| `js.global_get` | string → any | reads(globals), throws | nonlocalThrow | none | move | `shllvm_global` |
| `js.global_put` | string, any → none | reads+writes(globals) | writeBarrier | none | move | `shllvm_declare_global` |
| `js.type_error` | string → none | fresh, throws | mayCollect, nonlocalThrow | none | move | `shllvm_throw_type_error` |

### A.3.5 js.control

8 operations for jobs, timers, promises and the completion records of `try`/`finally`.

| operation | operands → results | behaviour | obligations | allowed | conditional | lowered to |
|---|---|---|---|---|---|---|
| `job.enqueue` | … → none | reads+writes(jobs) | mayCollect | none | move | `shllvm_builtin (queueMicrotask)` |
| `timer.set` | function, number → none | reads+writes(timers) | mayCollect | none | move | `shllvm_builtin (setTimeout)` |
| `promise.resolve` | any → object | reads+writes(jobs), fresh | mayCollect | none | move | `shllvm_builtin (Promise.resolve)` |
| `completion.normal` | none → completion | fresh | mayCollect | move, speculate | erase | `shllvm_object` |
| `completion.return` | any → completion | fresh | mayCollect | move, speculate | erase | `shllvm_object` |
| `completion.throw` | any → completion | fresh | mayCollect | move, speculate | erase | `shllvm_object` |
| `completion.is` [kind] | completion → boolean | none | none | erase, merge, move, duplicate, hoist, speculate | none | `shllvm_get_id` |
| `completion.value` | completion → any | none | none | erase, merge, move, duplicate, hoist, speculate | none | `shllvm_get_id` |


### A.3.6 Variants

A general operation narrows to a variant when type facts show its operands are in the variant's domain (`g.op.narrow(name, types)`, used by the `narrow-by-facts` rewrite of [Chapter 10](lab:book?ch=10)). Variants found by asking the engine with number, int32, boolean and string operands:

| general | numbers | int32 (or boolean, for unary) | strings |
|---|---|---|---|
| `js.add` | `num.add` | `num.add` | `str.concat` |
| `js.sub` | `num.sub` | `num.sub` | (none) |
| `js.mul` | `num.mul` | `num.mul` | (none) |
| `js.div` | `num.div` | `num.div` | (none) |
| `js.mod` | `num.mod` | `num.mod` | (none) |
| `js.neg` | `num.neg` | (none) | (none) |
| `js.lt` | `num.lt` | `num.lt` | (none) |
| `js.le` | `num.le` | `num.le` | (none) |
| `js.gt` | `num.gt` | `num.gt` | (none) |
| `js.ge` | `num.ge` | `num.ge` | (none) |
| `js.strict_eq` | `num.eq` | `num.eq` | (none) |
| `js.strict_ne` | `num.ne` | `num.ne` | (none) |
| `js.not` | (none) | `bool.not` | (none) |
| `js.truthy` | (none) | `core.copy` | (none) |

Integer operands narrow to the double operation, not to `i32.*`: the 32-bit operations wrap and the JavaScript ones do not, so `i32.add` is not a variant of `js.add` (the law `variant(i32.add of num.add)` fails on its second sample, [Chapter 19](lab:book?ch=19)).

## A.4 The verifier's rules

`g.verify(fn or module)` returns `{ ok, diagnostics }`; `ok` is false if any diagnostic is an error. Each diagnostic names its rule and the function, block or operation it concerns.

| rule | severity | checks |
|---|---|---|
| `entry` | error | the function has at least one block |
| `block-name` | error | no two blocks have the same name |
| `single-definition` | error | every value is defined once: function parameter, block parameter or result |
| `terminator` | error | every block ends in a terminator, and nothing follows it (the parser also refuses text after a terminator) |
| `unknown-block` | error | every edge and every `throws to` names a block of the function |
| `unknown-op` | error | every operation is registered (standard or added with `g.opset(…).register()`) |
| `arity` | error | a non-variadic operation has exactly its declared number of operands |
| `may-throw-without-exit` | error | an operation that may throw is in an `invoke` or a block with an exceptional exit |
| `unknown-callee` | error | `@callee` names a function of the module (checked when verifying a module) |
| `edge-arity` | error | an edge passes as many arguments as the target has parameters, less its implicit ones |
| `edge-type` | error | each argument's static type is contained in the parameter's type |
| `undefined-value` | error | every value used is defined somewhere |
| `dominance` | error | every use is dominated by its definition: a block parameter must belong to a block that dominates the use, a result must be defined earlier in the same block or in a block that dominates the use's block, and a value passed to a `throws to` exit must be defined before the block's head; for a result defined in another block, the message gives a path from the entry that reaches the use without passing the definition |
| `unreachable` | warning | every block is reachable from the entry |
| `stale-fact` | error | only when called with facts: a fact refers to code a rewrite changed |

The operations that may throw, so the ones `may-throw-without-exit` applies to, are `core.call`, the ten `js.*` arithmetic and comparison operations, `js.get`, `js.put`, `js.call`, `js.call_method`, `cell.load_checked`, `js.global_get`, `js.new_error` and `js.type_error`. Of the 69 standard operations, 32 may collect and are therefore safepoints in the sense of [Chapter 13](lab:book?ch=13).
