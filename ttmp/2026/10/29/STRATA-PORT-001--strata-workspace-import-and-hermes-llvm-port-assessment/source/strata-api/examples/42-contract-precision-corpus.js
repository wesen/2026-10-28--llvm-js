// 42 · Measuring whether contracts are precise enough to matter
//
// Model: an open question from the note: if most JavaScript operations end up
// "may do anything", the IR enables little optimization. This is measurable.
// Over a corpus, count operations by behaviour class before and after facts,
// how often narrowing finds a variant, and which permissions are granted.
// The same measurement also checks the frontend boundary: how much binding
// and source metadata survives import from Hermes IR.
//
// Notice: the measurement is defined once and applied to any corpus; the
// output names which operation sets would most reward better facts.

import { g } from 'strata'

const corpus = [...g.corpus.apps(), ...g.corpus.ladder(), ...g.corpus.test262({ subset: 'language/expressions', limit: 2000 })]

const precision = g.measurement('contract-precision', {
  per: 'operation',
  classify: (op, ctx) => {
    const b = ctx.contractAfterFacts(op).behaviour
    if (b.le(g.fx.none)) return 'pure'
    if (g.fx.callsUser.le(b)) return 'user-code'            // includes unknown, which is above callsUser
    if (b.le(g.fx.reads('heap').join(g.fx.writes('heap')).join(g.fx.fresh))) return 'heap-only'
    if (b.has('throws')) return 'may-throw'
    return 'other-effects'                                   // jobs, cells, host, divergence without user code
  },
  also: op => ({ narrowed: op.variant !== null, perms: g.perm(op).granted().length }),
})

const report = await precision.run(corpus, { pipeline: g.pipeline() })

report.byClass()
// → class               before facts   after facts      (share of dynamic ops, illustrative)
//   pure                21%            38%
//   heap-only           9%             17%
//   may-throw           5%             6%
//   other-effects       1%             1%
//   user-code           64%            38%

report.byOpset({ metric: 'user-code after facts', top: 4 })
// → js.object 52% · js.value 31% · js.function 74% (calls) · js.control 18%

report.narrowing()
// → { attempts: 412000, narrowed: 171000, topVariants: ['js.get.own_data', 'num.add', 'js.strict_eq.same_type'] }

// The question the seminar asked, answered with a threshold chosen in advance.
report.verdict({ question: 'Do contracts leave enough room to optimize?', threshold: { 'user-code after facts': { le: 0.5 } } })
// → { answer: 'yes, narrowly', value: 0.38, sensitivity: 'drops to 0.29 with shape facts from example 13' }

// The frontend boundary: what metadata survives importing Hermes IR?
const boundary = await g.measurement('frontend-metadata').run(corpus, {
  at: g.hermes.frontend({ importAt: 'before-lowering' }),
  require: ['source spans', 'binding cells for eval', 'class private brands', 'module live bindings'],
})
boundary.summary()
// → { 'source spans': '100%', 'binding cells for eval': '100%', 'class private brands': '100%',
//     'module live bindings': 'n/a (module host transforms before IR)' }
// → follow-up: move the import point, or carry module binding metadata through the module host
