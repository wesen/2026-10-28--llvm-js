// 05 · Operation sets and providers
//
// Model: operations are grouped into named, versioned operation sets
// (core, js.value, js.object, js.function, js.control, js.module, js.dynamic).
// A provider implements an operation set: it lowers each operation to
// runtime calls or instructions, and may supply reference steps. Hermes is
// the first provider for every JavaScript set. A provider is admitted only if
// it covers its set and satisfies every contract (Law 2).
//
// Notice: op-set union is a monoid over disjoint names; an opaque escape is
// legal but costs every permission; a Hermes inventory turns existing
// instructions into reviewable contract skeletons.

import { g } from 'strata'

const { t, fx, ob } = g

// Build a small set from operations defined like those in example 04.
const jsObject = g.opset('js.object', { version: '0.1.0' }).ops(
  g.op('js.get').operands(t.any, t.propertyKey).results(t.any)
    .behaviour(fx.callsUser.join(fx.throws)).obligations(ob.mayCollect.join(ob.nonlocalThrow).join(ob.borrows(0, 1))),
  g.op('js.put').operands(t.any, t.propertyKey, t.any)
    .behaviour(fx.callsUser.join(fx.throws))
    .obligations(ob.mayCollect.join(ob.nonlocalThrow).join(ob.writeBarrier).join(ob.borrows(0, 1, 2))),
  g.op('obj.new').results(t.object).behaviour(fx.fresh).obligations(ob.mayCollect),
  g.op('obj.literal').attrs({ shape: 'literal' }).results(t.object).behaviour(fx.fresh).obligations(ob.mayCollect),
)

// The standard sets ship with the library.
const { core, jsValue, jsFunction, jsControl, jsModule, jsDynamic } = g.opsets
const js = g.opset.union(jsValue, jsObject, jsFunction, jsControl, jsModule, jsDynamic)
js.size                                        // → 143 operations (illustrative)
g.opset.union(jsObject, jsObject.rename('dup'))   // → fine: names are disjoint after rename
// g.opset.union(jsObject, jsObject)           // → OpsetConflict: 'js.get' defined twice

// Hermes provides each set.
const hermesObject = g.hermes.provider('js.object')
hermesObject.covers(jsObject)                  // → { ok: true, missing: [] }
hermesObject.lowering('js.get')
// → { call: 'shllvm_get', wraps: '_sh_ljs_get_by_val_rjs', signature: 'void (ptr out, ptr shr, ptr object, ptr key)',
//     obligations: ['mayCollect', 'nonlocalThrow', 'borrows 0 1'],
//     source: 'hermes/lib/BCGen/SH/LLVMNative/runtime.c:240' }

// A provider of our own, partially covering a set, is rejected until complete.
const mine = g.provider('strata.js.object')
  .implements(jsObject)
  .lowers('obj.new', (op, $) => $.call('strata_obj_new', [], { collects: true, throws: false }))
mine.covers(jsObject)
// → { ok: false, missing: ['js.get', 'js.put', 'obj.literal'] }

// An opaque escape hatch exists, and it is priced honestly.
const opaque = g.op.opaque('native.call', { symbol: 'legacy_helper' })
g.perm(opaque)                                 // → none: behaviour unknown, every obligation assumed
opaque.contract.behaviour                      // → fx.unknown

// Import Hermes's instruction inventory as contract skeletons to review.
const inventory = g.hermes.inventory({ at: 'before-lowering' })
inventory.summary()
// → { instructions: 212, mapped: 168, unmapped: 44, contractsConservative: 44 }   (illustrative)
inventory.unmapped().slice(0, 3)
// → [{ hermes: 'CallBuiltinInst',       proposed: 'js.call_builtin', contract: 'conservative (unknown)', review: 'open' },
//    { hermes: 'CreateScopeInst',       proposed: 'js.env.new',      contract: 'conservative', review: 'open' },
//    { hermes: 'GetTemplateObjectInst', proposed: 'js.template',     contract: 'conservative', review: 'open' }]
inventory.mapped().find(m => m.hermes === 'LoadPropertyInst')
// → { hermes: 'LoadPropertyInst', op: 'js.get', contract: 'from js.object@0.1.0' }

// A pipeline names which provider implements which set; summary() shows it.
const p = g.pipeline().provide('js.object', hermesObject)
p.summary().providers
// → { core: 'reference', 'js.value': 'hermes', 'js.object': 'hermes', 'js.function': 'hermes',
//     'js.control': 'hermes', 'js.module': 'hermes', 'js.dynamic': 'hermes (bytecode)' }
