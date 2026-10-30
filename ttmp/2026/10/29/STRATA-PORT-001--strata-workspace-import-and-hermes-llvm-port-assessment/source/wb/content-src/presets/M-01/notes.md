# Laws as tests

On the screen is the engine checking itself. `main.js` runs twelve **laws**: properties the engine's parts are supposed to have, each checked on hundreds or thousands of sampled inputs. Eleven hold. One, the associativity of `num.add`, fails, and it is meant to: floating-point addition is not associative, and the sampler finds a case in its first sample. The [Laws view](lab:show?view=laws) lists every law with its sample count and, for the failure, the counterexample.

> **Try it.** [Run main.js](lab:build) and open the failing law, [associative(num.add)](lab:law?name=associative%28num.add%29). The counterexample is `a = 1`, `b = 0.1`, `c = -10000000000000000`: `(a + b) + c` is `-9999999999999998`, `a + (b + c)` is `-10000000000000000`.

## What a law is

A law is a function that draws inputs, checks a property on each and returns `{ name, ok, samples, counterexample? }`. It is not a proof: 2,000 samples that pass say the property held on 2,000 inputs. It is much stronger than an example, because the inputs include the cases a person would not think to write: `-0`, `NaN`, `2³¹`, empty sets, the top of a lattice. And when it fails, it fails with an input that can be replayed.

## The laws on the screen

| law | what it protects |
|---|---|
| `lattice(types)`, `lattice(powerset)`, `lattice(interval)` | join is commutative, associative and idempotent, and the order agrees with join; the solver's termination argument depends on it |
| `join(fx)` | behaviours form a semilattice with `none` at the bottom and `unknown` at the top, so the behaviour of a block is the join of its operations' |
| `antitone(perm)` | more behaviour never grants a permission; a rewrite that is safe for a large behaviour is safe for a smaller one |
| `monotone(liveness)` | the liveness transfer function is monotone, which is what makes the fixed point exist and the worklist stop |
| `roundTrip(text and JSON)` | printing IR and parsing it back gives the same function, so IR can be stored and diffed |
| `idempotent(rewrites)` | the canonical rewrites reach a fixed point: running them twice changes nothing more |
| `variant(num.add of js.add)` | the narrowed operation computes what the general one does on numbers |
| `commutative(num.add)`, `associative(num.add)` | the algebra an operation declares (or should not declare) |
| `vectorSpace(slots)` | quantities with units add and scale |

Each row is a promise another part of the engine relies on. If `antitone` failed, the rewrite pass could erase an operation that throws; if `monotone(liveness)` failed, the solver could loop forever or stop at a wrong answer; if `roundTrip` failed, an IR file would not mean what it says.

## A failure that teaches

`associative(num.add)` is in the list to show what a counterexample looks like and why algebra matters to a compiler. Reassociating `(a + b) + c` into `a + (b + c)` is a classic optimisation for integers, and `i32.add` declares it; for doubles it changes results, so `num.add` declares only commutativity, and a rewrite that wants to reassociate must check `laws.associative` first. The law makes that rule executable: if someone adds `associative: true` to `num.add`, [g.law.declared](lab:ask?q=What%20does%20g.law.declared%20check%2C%20and%20what%20would%20it%20report%20for%20the%20core%20set%3F) on the core set reports the counterexample.

> **Try it.** Replace the last but one law with `g.law.declared(g.opsets.core)` and rerun: every law the core set declares holds, including the associativity of `i32.add`, because 32-bit wrapping addition really is associative.

## Laws as a test suite

The twelve laws run in about half a second. That makes them cheap enough to run after every engine change, which is how they are meant to be used: a law that fails after a change says exactly which promise broke, with an input to start debugging from. [M-02](lab:preset?id=M-02) adds laws over whole programs, and [M-07](lab:preset?id=M-07) puts them next to the other checks of a release.

> **Exercise.** Write a law of your own: sample pairs of types from `g.t.all()` and check that `a.meet(b).le(a)` always holds. Return it with `g.laws([...])` next to the others as `{ name, ok, samples }`.

## Where next

[Chapter 19](lab:book?ch=19) covers laws, generators and shrinking, and the doc on [property testing](lab:doc?id=property-testing) explains the method. [A-01](lab:preset?id=A-01) looks at the lattices themselves.
