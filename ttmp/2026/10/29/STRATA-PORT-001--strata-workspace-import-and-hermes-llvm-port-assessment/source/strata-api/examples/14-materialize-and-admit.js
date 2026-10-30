// 14 · Materialization, artifacts and admission
//
// Model: g.compile produces an artifact: relocatable, not yet in memory, and
// a pure value like everything else compile returns. It carries its ABI,
// target, required strategies, immutable function descriptors and exact
// constants; never live pointers or engine-local ids. Two effects consume it:
// `await engine.admit(artifact)` checks it against the engine and then
// materializes it (LLVM ORC in process), and `await g.emit(pipeline, src)`
// writes an object file (LLVM AOT). Admission refuses a mismatch before any
// native code runs.
//
// Notice: the JIT and AOT artifacts are equal modulo object format; a
// strategy conflict inside a pipeline is caught by check(), while admission
// catches an artifact built for a different engine.

import { g } from 'strata'

const src = g.source.text(`
export const big = 12345678901234567890n
export const snowman = '\\u2603'
export function f(o, cb) { cb(); return o.value }`, { name: 'lib.mjs' })

const jit = g.pipeline().materialize(g.llvm.orc({ target: g.target.host64 }))
const aot = g.pipeline().materialize(g.llvm.aot({ target: g.target.linuxX64, output: 'lib.o' }))

// Pure: no memory is mapped and no file is written.
const art = g.compile(jit, src).artifact
art.describe()
// → { abi: 'strata-abi/1', target: 'x86_64-linux-gnu', state: 'relocatable',
//     requires: { roots: 'stackReuse', exceptions: 'setjmp', calls: 'hermesNative', runtime: 'hermes@f837b9d' },
//     functions: 3, descriptors: [{ name: 'f', rootSlots: 2, fixedSlots: 2, argumentSlots: 1, frame: '5 slots',
//                                   source: 'lib.mjs:4:8' }, …],
//     constants: { bigint: [{ bytes: '0xab54a98ceb1f0ad2', sign: '+' }], utf16: [[0x2603]] },
//     modules: [{ key: 'lib.mjs', exports: ['big', 'snowman', 'f'] }] }
// f's rooted values: o (live across cb()) and cb (borrowed by the call); its only call passes no
// arguments besides this, so the outgoing argument frame is max(1, 0) = 1 slot.

// What an artifact must not contain is checked, not hoped for.
art.audit()
// → { livePointers: 0, engineIds: 0, processGlobalIndices: 0, ok: true }

// The boundary to LLVM is textual IR at first (Hermes builds against llvh; text keeps the type systems apart).
// The shape follows today's emitter: one ptr %shr parameter, a frame from shllvm_enter, runtime wrappers.
g.compile(jit, src).ir('L4', { format: 'llvm', fn: 'f' })
// → define internal i64 @f(ptr %shr) {
//   entry:
//     call void @_sh_check_native_stack_overflow(ptr %shr)
//     %storage = alloca i8, i64 %size, align 16
//     %argv = alloca [1 x i64], align 8
//     %frame = call ptr @shllvm_enter(ptr %shr, ptr %storage, i32 4, i32 1, i32 %unit_index)
//     …
//     call void @shllvm_call(ptr %out, ptr %shr, ptr %frame, ptr %cb, ptr %this, ptr %nt, i32 0, ptr %argv)
//     …
//     call void @shllvm_get(ptr %out2, ptr %shr, ptr %o, ptr %key)
//     …

// AOT writes a file: an effect, so it is awaited.
const written = await g.emit(aot, src)
written                                        // → { path: 'lib.o', bytes: 18432, artifact: { … } }
g.artifact.diff(art, written.artifact)
// → { abi: 'equal', descriptors: 'equal', constants: 'equal', code: 'equal modulo object format (ELF vs ORC buffer)' }

// A pipeline whose strategies and providers conflict never produces an artifact.
jit.exceptions('landingPads').check()
// → { ok: false, diagnostics: [
//      { slot: 'exceptions', conflict: 'hermes.* providers lower throwing helpers with nonlocalThrow' },
//      { slot: 'exceptions', conflict: 'no declared compatible pair landingPads × stackReuse' }] }

// Admission checks the artifact against the engine, then materializes it.
const engine = await g.engine({ strategies: { roots: 'stackReuse', exceptions: 'setjmp' } })
const code = await engine.admit(art)
code                                           // → CodeId(engine#1, 1)

// A valid artifact built for different strategies is refused: arena × setjmp is a declared pair (example 12),
// but this engine runs stackReuse.
const arenaArt = g.compile(jit.roots('arena'), src).artifact
await engine.admit(arenaArt).catch(e => e)
// → AdmissionError { reason: 'strategy mismatch', field: 'roots', artifact: 'arena', engine: 'stackReuse', ranCode: false }

const wrongTarget = g.compile(g.pipeline().materialize(g.llvm.aot({ target: g.target.riscv32 })), src).artifact
await engine.admit(wrongTarget).catch(e => e)
// → AdmissionError { reason: 'target mismatch', artifact: 'riscv32-unknown-elf', engine: 'x86_64-linux-gnu', ranCode: false }

// Refused artifacts were never materialized, so nothing leaks.
engine.metrics().code
// → { admittedUnits: 1, codeBytes: 2048, rejectedArtifacts: 2, materializedOnRejection: 0 }
await engine.close()
