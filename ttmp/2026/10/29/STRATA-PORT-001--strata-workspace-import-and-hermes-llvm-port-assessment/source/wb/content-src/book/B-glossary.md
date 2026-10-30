# Appendix B: Glossary

Every term the book defines in bold, with a short definition in the book's sense and the chapter that defines it. Where a term is used before its defining chapter (a root slot appears in Chapter 1 and is developed in Chapters 9 and 13), the entry names the chapter that gives the full definition. Terms are in alphabetical order; symbols and numbers come first.

**1-minimal.** Of a shrunk counterexample: removing any single item (a statement) makes the failure disappear. [Chapter 19](lab:book?ch=19).

**action.** What a rewrite does when its side condition holds: erase the operation, replace its result with an operand, or replace the operation with another. [Chapter 10](lab:book?ch=10).

**admission.** The check an engine makes before any of a program's code runs: the program compiled without errors and its artifact's requirements match the engine's. A refused program leaves the domain unchanged. [Chapter 18](lab:book?ch=18).

**adopt.** What a derived promise does when its handler returns a promise: it settles when that promise settles, with its value, instead of settling with the promise object. [Chapter 17](lab:book?ch=17).

**alphabet.** The set of labels a labelled transition system mentions; in a product, a machine takes part only in labels of its own alphabet. [Chapter 18](lab:book?ch=18).

**analysis pass.** A pass that adds facts without changing the program; it is correct when the facts are true. [Chapter 11](lab:book?ch=11).

**antitone.** Of a function between ordered sets: a larger input gives a smaller (or equal) output. The derivation of permissions is antitone in the behaviour: more behaviour never grants a permission. [Chapter 7](lab:book?ch=7).

**artifact.** A compiled program's relocatable description, including what it requires of the runtime (root strategy, exception strategy); admission reads it. [Chapter 18](lab:book?ch=18).

**assumption.** A parameter type set with `.assume(...)`, used by the facts as if proved; recorded as an unchecked decision, the thing a JIT would guard and deoptimise on. [Chapter 15](lab:book?ch=15).

**behaviour.** The part of an operation's contract that says what it may do: the resources it may read or write, and whether it may allocate, throw, diverge, run user code or talk to the host. Behaviours form a join-semilattice. [Chapter 1](lab:book?ch=1); developed in [Chapter 6](lab:book?ch=6).

**block.** A straight run of operations ending in one terminator, with its own typed parameters. A function's body is a list of blocks. [Chapter 1](lab:book?ch=1); developed in [Chapter 3](lab:book?ch=3).

**block parameter.** A typed value a block receives on entry, supplied by each edge into it; core IR uses block parameters instead of phi nodes. [Chapter 3](lab:book?ch=3).

**blocker.** A part of a behaviour that makes an operation observable (it may throw, diverge, write, run user code or talk to the host); blockers are what refuse permissions. [Chapter 7](lab:book?ch=7).

**borrow.** A safepoint borrows its managed operands: its helper reads them after it may have collected, so they must be rooted for the duration of the call even if nothing needs them afterwards. [Chapter 9](lab:book?ch=9); developed in [Chapter 13](lab:book?ch=13).

**branch simplification.** The rewrite that replaces a branch on a literal condition with a jump to the side it always takes. [Chapter 10](lab:book?ch=10).

**canonical form.** The output of an idempotent rewrite set: programs with the same canonical form can be treated as the same, and later passes may assume the easy simplifications are done. [Chapter 10](lab:book?ch=10).

**canonicalised NaN.** Under NaN-boxing, every NaN a program produces is rewritten to the single pattern `0x7FF8000000000000` before it is stored, so that other NaN patterns can carry tags. [Chapter 12](lab:book?ch=12).

**captured.** Of a variable: read or written by a function other than the one that declares it, so its storage must outlive a call and be shared; captured variables stay cells. [Chapter 4](lab:book?ch=4).

**cell.** A small heap box holding one variable (`cell.new`, `cell.load`, `cell.store`). The frontend gives every variable a cell; promotion turns the uncaptured ones into SSA values. [Chapter 1](lab:book?ch=1).

**collect.** Of an operation: it may allocate and so may run the garbage collector. An operation that may collect is a safepoint. [Chapter 1](lab:book?ch=1).

**compiler.** A program that translates a program from the language a person wrote into one a machine runs, preserving what the program does. [Chapter 1](lab:book?ch=1).

**completion record.** An object (`completion.normal`, `completion.return`, `completion.throw`) recording how a protected region ended, so that one block can run a `finally` body and then continue the right way. [Chapter 5](lab:book?ch=5).

**condition.** A permission that is neither granted nor refused but granted if something else holds, stated as a sentence the rewrite must check, such as "if nothing writes cells between them". [Chapter 7](lab:book?ch=7).

**constant folding.** The rewrite that replaces an operation on literal operands with its result, when no user code can run. [Chapter 10](lab:book?ch=10).

**contract.** What an operation may do (its behaviour) and what lowering owes it (its obligations). Every permission is derived from the contract. [Preface](lab:book?ch=P); developed in [Chapter 6](lab:book?ch=6).

**control-flow graph.** The directed graph whose nodes are a function's blocks and whose edges are the targets their terminators name. [Chapter 3](lab:book?ch=3).

**corpus.** The list of sources a design point is measured on. [Chapter 20](lab:book?ch=20).

**correct.** Of a design point: every lowered run on the corpus equals the interpreter's run of the same program under `observe.equal`. [Chapter 20](lab:book?ch=20).

**decision.** An entry in a program's log recording that a rewrite, promotion or assumption fired or was refused, with the reason. In Part IX also a decision record (`g.decision`) with options, evidence, a counterexample sought, a choice and what would overturn it. [Chapter 1](lab:book?ch=1); records in [Chapter 21](lab:book?ch=21).

**declaration.** A name introduced into a scope by `var`, `let`, `const`, a function, a parameter or a catch clause, with a record the frontend uses to decide where it lives. [Chapter 4](lab:book?ch=4).

**derived promise.** The new pending promise that `then` returns, settled by the reaction's result. [Chapter 17](lab:book?ch=17).

**design.** A product of parameters together with a rule turning each point into a pipeline. [Chapter 20](lab:book?ch=20).

**differential testing.** Running the same input through several implementations that should agree and comparing everything they observe, without stating why they should agree. [Chapter 19](lab:book?ch=19).

**direct binding.** A lowering of an operation to a call of another compiled function whose name is known (`core.call(@sq, n)` to `call i64 @sq`). [Chapter 12](lab:book?ch=12).

**dispatch loop.** The Wasm backend's construction for any control-flow graph: a variable holds the number of the next block and one `br_table` at the top of a loop jumps to it. [Chapter 15](lab:book?ch=15).

**dominance frontier.** The blocks $y$ such that $x$ dominates a predecessor of $y$ but does not strictly dominate $y$: where a definition in $x$ stops being the only one that reaches. [Chapter 4](lab:book?ch=4).

**dominate.** Block $a$ dominates block $b$ when every path from the entry to $b$ passes through $a$; a use must be dominated by its definition. (In [Chapter 20](lab:book?ch=20), a design point dominates another if it is at least as good on every metric and better on one.) [Chapter 3](lab:book?ch=3).

**dominator tree.** The tree formed by linking every block except the entry to its immediate dominator. [Chapter 3](lab:book?ch=3).

**duplicate.** The permission to evaluate an operation twice where it ran once. [Chapter 7](lab:book?ch=7).

**edge.** A target named by a terminator, with the arguments it passes to the target's parameters. [Chapter 3](lab:book?ch=3).

**engine.** An object owning one execution domain, with the operations admit, evaluate, run jobs, look and close. [Chapter 18](lab:book?ch=18).

**environment.** The part of an interpreter frame that maps each SSA value to what it holds. [Chapter 2](lab:book?ch=2).

**erase.** The permission to delete an operation whose result is unused. [Chapter 7](lab:book?ch=7).

**exceptional edge.** The edge from a protected block to its handler, taken when an operation in the block throws. [Chapter 5](lab:book?ch=5).

**execution domain.** A heap, job queues, globals and the admitted code, owned together by one engine; code in the domain can share objects, and nothing outside can reach them. [Chapter 18](lab:book?ch=18).

**factorial study.** An experiment that varies every factor (here strategies and programs) and measures every combination. [Chapter 20](lab:book?ch=20).

**fact.** A statement about a program point computed by an analysis: a value is live, a value has a type, an operation may collect. [Chapter 9](lab:book?ch=9).

**feasibility.** Whether a design point is a working compiler at all (admitted and correct); infeasible points rank after every feasible one whatever the objective. [Chapter 20](lab:book?ch=20).

**fixed point.** A solution $x$ of $F(x) = x$; an analysis computes the least fixed point of its equations. [Chapter 8](lab:book?ch=8).

**frame.** The interpreter's record of one active call: the function, its environment and the operation it is at. [Chapter 2](lab:book?ch=2).

**function.** In core IR, a name, typed parameters, a result type and a list of blocks, the first being the entry. [Chapter 3](lab:book?ch=3).

**generator.** A function that builds inputs for laws from a seed: `g.gen.coreIR` for numeric IR, `g.gen.js` for JavaScript statements. [Chapter 19](lab:book?ch=19).

**handler.** The block a protected block's exceptional edge leads to. [Chapter 5](lab:book?ch=5).

**head.** The start of a block, before its first operation; the arguments of a block-level exceptional exit are evaluated there. [Chapter 5](lab:book?ch=5).

**height.** Of a lattice: the length of its longest strictly rising chain; finite height guarantees that iteration terminates. [Chapter 8](lab:book?ch=8).

**helper.** A runtime function compiled code calls to perform an operation, with names in the shape of the Hermes LLVM backend (`shllvm_get`, `shllvm_call`). [Chapter 1](lab:book?ch=1).

**hoist.** The permission to move an operation out of a loop. [Chapter 7](lab:book?ch=7).

**idempotent.** Of a rewrite set: running it again on its own output changes nothing. [Chapter 10](lab:book?ch=10).

**immediate dominator.** The closest block, other than $b$, among those that dominate $b$. [Chapter 3](lab:book?ch=3).

**inline binding.** A lowering of an operation to an instruction the backend writes directly (`num.add` to `fadd`). [Chapter 12](lab:book?ch=12).

**intermediate representation (IR).** One of the forms a compiler rewrites a program into between source and machine code, chosen to make the next decision easy to state and check. [Chapter 1](lab:book?ch=1).

**invariant.** A predicate on the states of a product of machines that must hold in every reachable state. [Chapter 18](lab:book?ch=18).

**iterated dominance frontier.** The closure of the dominance frontier under its own new definitions: the blocks that need a parameter for a promoted variable. [Chapter 4](lab:book?ch=4).

**job.** A function and its arguments waiting in a queue, run later and to completion. [Chapter 17](lab:book?ch=17).

**job order.** The order in which jobs' effects appear; an observation of the `js-async` profile. [Chapter 17](lab:book?ch=17).

**join.** The least upper bound of two elements; for behaviours, the union of resources and the logical or of the flags. [Chapter 6](lab:book?ch=6); in general in [Chapter 8](lab:book?ch=8).

**join-semilattice.** A partial order in which every pair has a join and there is a least element; in this book "lattice" means this. [Chapter 6](lab:book?ch=6); [Chapter 8](lab:book?ch=8).

**L3 executor.** The machine that runs a lowered program with its root plan and a simulated moving collector (`run({ mode: 'plan' })`). [Chapter 13](lab:book?ch=13).

**label.** The name of the event that causes a transition in a labelled transition system. [Chapter 18](lab:book?ch=18).

**labelled transition system (LTS).** A set of states, an initial state and labelled transitions between states. [Chapter 18](lab:book?ch=18).

**lambda strategy.** A function given for a strategy slot; it receives the input and a context whose `ctx.default()` runs the strategy it wraps. [Chapter 11](lab:book?ch=11).

**landing pads.** The exception strategy in which each throwing call names an unwind destination recorded in tables a runtime unwinder reads, so the normal path costs nothing. [Chapter 14](lab:book?ch=14).

**lattice.** See join-semilattice. [Chapter 8](lab:book?ch=8).

**law.** A property packaged with a way to draw inputs and a report `{ name, ok, samples, counterexample }`. [Chapter 19](lab:book?ch=19).

**layout.** The only conversion from slots to bytes: it knows the size of a slot on a target (8 B on a 64-bit host). [Chapter 12](lab:book?ch=12).

**LEB128.** The variable-length integer encoding WebAssembly uses: seven bits per byte, low bits first, the top bit set while more bytes follow. [Chapter 15](lab:book?ch=15).

**level.** The workbench's name for each form of a program: L0 source, L1 core IR, L2 bound to implementations, L3 with the root plan, then LLVM text. [Chapter 1](lab:book?ch=1).

**live across.** Of a value and a safepoint: the code reads the value after the safepoint returns. The live-across sets are computed from liveness. [Chapter 9](lab:book?ch=9); [Chapter 13](lab:book?ch=13).

**liveness.** A value is live at a point if some path from that point reads it before anything else could; a backward analysis. [Chapter 8](lab:book?ch=8); developed in [Chapter 9](lab:book?ch=9).

**lowering pass.** A pass that changes the level; it is correct when the lowered program, run by its own machine, shows only behaviours of its input. [Chapter 11](lab:book?ch=11).

**managed.** Of a type: it can hold a heap reference (object, function, cell, completion). [Appendix A](lab:book?ch=A).

**managed frame.** The runtime's notion of the current JavaScript frame, updated by call helpers and restored by unwinding. [Chapter 14](lab:book?ch=14).

**merge.** The permission to replace a second evaluation of an operation with the first one's result. [Chapter 7](lab:book?ch=7).

**metric.** A function of a compiled program and its run, with a direction (smaller or larger is better) and a unit. [Chapter 20](lab:book?ch=20).

**missing.** Of a value at a safepoint: required but without a slot, or sharing its slot with another required value; the plan checker reports it as an error. [Chapter 13](lab:book?ch=13).

**monotone.** Of a function between ordered sets: $x \sqsubseteq y$ implies $F(x) \sqsubseteq F(y)$. [Chapter 8](lab:book?ch=8).

**move.** The permission to reorder an operation with its neighbours. [Chapter 7](lab:book?ch=7).

**moving collector.** A garbage collector that copies every object reachable from the roots into fresh memory and treats the old memory as free. [Chapter 13](lab:book?ch=13).

**NaN-boxing.** Storing every value in one 64-bit word by using the spare bit patterns of NaN doubles for tags and pointers. [Chapter 12](lab:book?ch=12).

**narrowing.** The rewrite that replaces an operation by its variant when the facts show the operands are in the variant's domain. [Chapter 10](lab:book?ch=10).

**not admitted.** Of a design point: some program in the corpus failed to compile under its pipeline. [Chapter 20](lab:book?ch=20).

**object identity.** The number the interpreter gives each object it allocates; observations compare identities up to a renaming. [Chapter 2](lab:book?ch=2).

**objective.** A rule that turns rows of metrics into an order (or, for the Pareto objective, a set). [Chapter 20](lab:book?ch=20).

**obligation.** A requirement an operation places on lowering, such as roots for a collection it may trigger or a way to unwind an exception it may throw. [Chapter 1](lab:book?ch=1); developed in [Chapter 6](lab:book?ch=6).

**observation.** One of the things a run is compared on: printed values in order, the outcome, the thrown value, object identity and, for programs with jobs, job order. [Chapter 2](lab:book?ch=2).

**operation.** One step inside a block: a name from an operation set, operands and at most one result. [Chapter 3](lab:book?ch=3).

**oracle.** A slow, simple implementation whose output a fast one must match on every test program. [Chapter 21](lab:book?ch=21).

**outcome.** How a run ends: normal, throw, diverge, or an engine error. [Chapter 2](lab:book?ch=2).

**parallel copy.** Moving all of an edge's arguments into the target's parameters at once, as SSA destruction requires. [Chapter 15](lab:book?ch=15).

**parameter (of a design).** A finite list of values or a stepped range, one coordinate of a design. [Chapter 20](lab:book?ch=20).

**Pareto frontier.** The set of feasible design points that no other feasible point dominates. [Chapter 20](lab:book?ch=20).

**partial order.** A relation $\sqsubseteq$ that is reflexive, antisymmetric and transitive. [Chapter 8](lab:book?ch=8).

**pass.** One stage of a compiler: a named step from one level to the same or the next that declares what it needs and provides and records what it did. [Chapter 1](lab:book?ch=1); developed in [Chapter 11](lab:book?ch=11).

**permission.** One of six questions a rewrite asks of an operation (erase, merge, move, duplicate, hoist, speculate), answered true, false or a condition, derived from its behaviour. [Chapter 7](lab:book?ch=7).

**phi node.** The classic SSA construct at the top of a merge block that selects a value by predecessor; core IR uses block parameters instead. [Chapter 3](lab:book?ch=3).

**pipeline.** An immutable value that resolves every choice of a compilation (rewrites, strategies, checks, passes) and can check that its passes fit together before compiling anything. [Chapter 11](lab:book?ch=11).

**plan.** The result of lowering's root planning for one function: which value sits in which root slot, what each safepoint requires and roots, and the frame's size. [Chapter 13](lab:book?ch=13).

**point.** One value per parameter of a design; one pipeline. [Chapter 20](lab:book?ch=20).

**preset.** A folder of files (a `main.js`, usually a `program.js`, and notes) that loads into every view of the workbench at once. [Preface](lab:book?ch=P).

**products (of a pass).** Names of facts or properties (`core-ir`, `verified`, `liveness`) a pass needs, gives or kills; a pipeline checks them. [Chapter 11](lab:book?ch=11).

**profile.** The operation sets a program may use and the observations a correctness claim about it preserves: `core`, `js-sync`, `js-async`. [Chapter 2](lab:book?ch=2).

**Program.** The object `g.compile` returns, which every view reads. [Chapter 1](lab:book?ch=1).

**promise.** An object with a state (pending, fulfilled, rejected), a value once settled, and a list of reactions. [Chapter 17](lab:book?ch=17).

**property.** A statement that should hold for every input of some kind. [Chapter 19](lab:book?ch=19).

**protected block.** A block with an exceptional successor (`throws to H`). [Chapter 5](lab:book?ch=5).

**provider.** Whoever implements an operation set's runtime helpers: Hermes or the workbench's reference. [Chapter 6](lab:book?ch=6).

**quantity.** A number carrying a unit (`slots(3)`, `bytes(24)`), so that counts of different things cannot be mixed by mistake. [Chapter 12](lab:book?ch=12).

**quiet.** Of an operation: it has no blocker; it always returns, never throws, writes nothing a program can read and says nothing to the host. [Chapter 7](lab:book?ch=7).

**reaction.** A handler waiting on a promise, run as a job when the promise settles. [Chapter 17](lab:book?ch=17).

**reference interpreter.** The interpreter for core IR written to be read, not to be fast; it is the specification. [Chapter 2](lab:book?ch=2).

**refinement.** A program $P'$ refines $P$ if every behaviour $P'$ can show is one $P$ can show; the correctness criterion for rewrites, passes and lowering. [Chapter 10](lab:book?ch=10).

**representation.** The rule saying how a value of a given type is stored in machine words: tagged, `f64`, `i32` or `bool`. [Chapter 12](lab:book?ch=12).

**required.** The set a plan must root at a safepoint: the managed values live across it plus its managed operands. [Chapter 9](lab:book?ch=9).

**resource.** A part of the state an operation may read or write: `heap`, `cells`, `jobs`, `timers`, `globals`, `engine`. [Chapter 6](lab:book?ch=6).

**retained.** Of an admitted unit: its code stays installed until the engine closes, because a failed initialiser may already have published it. [Chapter 18](lab:book?ch=18).

**rewrite.** A match, a side condition and an action; every attempt is logged with its reason. [Chapter 10](lab:book?ch=10).

**root chain.** The runtime's list of frames whose root slots the collector scans. [Chapter 14](lab:book?ch=14).

**root slot.** A frame slot the collector knows to scan and update when it moves an object. [Chapter 1](lab:book?ch=1); developed in [Chapter 9](lab:book?ch=9) and [Chapter 13](lab:book?ch=13).

**root strategy.** The rule that assigns root slots to required values: `distinct`, `stackReuse`, `arena`, `none`, or a lambda. [Chapter 13](lab:book?ch=13).

**roots.** The starting points a moving collector copies from: root slots, globals, queues. [Chapter 13](lab:book?ch=13).

**run to completion.** The discipline that a job, once started, runs until it returns before any other job starts. [Chapter 17](lab:book?ch=17).

**safepoint.** An operation that may collect; at a safepoint every needed reference must be rooted. [Chapter 1](lab:book?ch=1); developed in [Chapter 9](lab:book?ch=9).

**SameValue.** The comparison of `Object.is`: it distinguishes $-0$ from $0$ and treats `NaN` as equal to itself. [Chapter 2](lab:book?ch=2).

**scope.** A region of the source in which declarations are visible: a function body, a block, a `for` head, a `catch` clause. [Chapter 4](lab:book?ch=4).

**shrinking.** Searching for a smaller input that still fails, here by deleting statements one at a time. [Chapter 19](lab:book?ch=19); first used in [Chapter 10](lab:book?ch=10).

**side condition.** The check a rewrite makes before it acts, returning `{ ok, because }`. [Chapter 10](lab:book?ch=10).

**slippage.** The drift of a shrunk counterexample from the original failure to a different one. [Chapter 19](lab:book?ch=19).

**specification.** The reference interpreter in its role as the definition of what every compiled program must do. [Chapter 2](lab:book?ch=2).

**speculate.** The permission to evaluate an operation on a path where it would not have run. [Chapter 7](lab:book?ch=7).

**Stage.** The workbench view that draws one function's control-flow graph as a technical drawing. [Preface](lab:book?ch=P).

**static single assignment (SSA).** The form in which every value has exactly one definition in the text of a function. [Chapter 3](lab:book?ch=3).

**status returns.** The exception strategy in which every throwing helper returns a status the compiled code tests after the call. [Chapter 14](lab:book?ch=14).

**step.** One executed operation or terminator, counted and recorded by the interpreter. [Chapter 2](lab:book?ch=2).

**step function.** The few lines of JavaScript that define what one operation does; the interpreter and the laws call it. [Chapter 2](lab:book?ch=2).

**store-to-load forwarding.** The rewrite that replaces a `cell.load` with the value stored earlier in the same block, if nothing in between may write cells. [Chapter 10](lab:book?ch=10).

**strategy.** A value filling one of a pipeline's slots (`roots`, `exceptions`, `representation`): nothing, parameters, a named library strategy or a lambda. [Chapter 11](lab:book?ch=11).

**string table.** The module's list of constant strings; `shllvm_constant(out, shr, index)` materialises entry `index`. [Chapter 16](lab:book?ch=16).

**strongly connected components.** The groups of nodes of a directed graph that reach each other; iteration is needed only inside them. [Chapter 8](lab:book?ch=8).

**synchronised product.** The LTS whose states are tuples of machine states and whose transitions move every machine that knows the label together. [Chapter 18](lab:book?ch=18).

**temporal dead zone.** The interval in which a `let` or `const` variable exists but may not be read because its declaration has not run. [Chapter 2](lab:book?ch=2).

**terminator.** The last element of a block, saying where control goes next: jump, branch, return, throw, unreachable or invoke. [Chapter 1](lab:book?ch=1).

**trace.** The list of notes each pass leaves when it runs, with its level and time. [Chapter 1](lab:book?ch=1).

**transforming pass.** A pass that changes the program at the same level; it is correct when its result refines its input. [Chapter 11](lab:book?ch=11).

**try state.** A 32-bit variable recording which handler a `setjmp` landing should dispatch to. [Chapter 14](lab:book?ch=14).

**unboxed.** Of a representation: the word holds a raw double or boolean, which the compiler has proved is all it will ever hold. [Chapter 12](lab:book?ch=12).

**unreachable-block removal.** The rewrite that deletes blocks with no path from the entry. [Chapter 10](lab:book?ch=10).

**unwinding.** Getting an exception from where it is thrown to its handler: transferring control, delivering the value and restoring the catching frame's state, including the collector's view of frames and roots. [Chapter 14](lab:book?ch=14).

**upper bound.** An element above both of two given elements in a partial order. [Chapter 8](lab:book?ch=8).

**variant.** An operation with a smaller behaviour that gives the same result as a general one whenever the operands have certain types (`num.add` for `js.add` on numbers). [Chapter 7](lab:book?ch=7).

**virtual clock.** The machine's notion of time for timers, which moves only when a timer fires. [Chapter 17](lab:book?ch=17).

**widening.** An operator that, after a few iterations, jumps a still-growing value to the next of a fixed set of thresholds so that iteration on an infinite lattice terminates. [Chapter 8](lab:book?ch=8).

**worklist.** The solver's queue of blocks whose inputs may have changed. [Chapter 8](lab:book?ch=8).

**write barrier.** Work a collector needs on stores into objects it has already scanned or promoted; recorded as an obligation in the workbench but not checked. [Chapter 21](lab:book?ch=21).
