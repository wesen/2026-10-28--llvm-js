/* TEST STUB of window.strata, for checking the shell only (tools/shot.js swaps it in for js/core.js).
   It implements the CONTRACT §2 surface over one fixed program (main calls total(n), a loop with two
   allocations), with a tiny interpreter so runs, records, collections and stale uses look real.
   Not the engine; never ship it. */
(function (root) {
  'use strict';
  const ID = /^[A-Za-z_$][\w$]*$/;

  /* ---------- yaml (compact) ---------- */
  function yaml(v) {
    const sc = x => {
      if (x === null || x === undefined) return x === null ? 'null' : '~';
      if (typeof x === 'number' || typeof x === 'boolean') return String(x);
      if (typeof x === 'string') return /^[\w .,:/()+\-·→%]*$/.test(x) && x.trim() === x && x !== '' && !/^(true|false|null|\d.*)$/.test(x) ? x : JSON.stringify(x);
      if (typeof x === 'function') return '<function>';
      return null;
    };
    const out = [];
    const emit = (x, ind, key, dash) => {
      const pad = '  '.repeat(ind), pre = (dash ? '- ' : '') + (key != null ? key + ':' : '');
      const s = sc(x);
      if (s != null) { out.push(pad + (pre ? pre + ' ' : '') + s); return; }
      if (Array.isArray(x)) {
        if (!x.length) { out.push(pad + pre + ' []'); return; }
        if (x.every(e => sc(e) != null) && x.length <= 12) { out.push(pad + (pre ? pre + ' ' : '') + '[' + x.map(sc).join(', ') + ']'); return; }
        if (pre) out.push(pad + pre);
        for (const e of x.slice(0, 60)) emit(e, pre ? ind + 1 : ind, null, true);
        if (x.length > 60) out.push(pad + '  # … ' + (x.length - 60) + ' more');
        return;
      }
      const keys = Object.keys(x);
      if (!keys.length) { out.push(pad + pre + ' {}'); return; }
      if (pre) out.push(pad + pre);
      keys.forEach((k, i) => emit(x[k], pre ? ind + 1 : ind, k, dash && !pre && i === 0));
    };
    emit(v, 0, null, false);
    return out.join('\n');
  }

  /* ---------- the fixed program ---------- */
  const op = (fn, blk, i, text, o) => Object.assign({ id: `${fn}/${blk}/${i}`, text, op: 'op', args: [], results: [], invoke: false, mayThrow: false, safepoint: false }, o);
  function makeCfgs() {
    const main = {
      name: 'main', entry: 'entry', params: [],
      blocks: [
        { name: 'entry', params: [], ops: [op('main', 'entry', 0, 'v1 = const 4', { op: 'const', results: ['v1'], k: 4 })],
          term: { id: 'main/entry/term', kind: 'invoke', text: 'v2 = invoke total(v1) to done(v2) unwind catch(e)', call: 'total', args: ['v1'], result: 'v2', edges: [{ to: 'done', args: ['v2'], kind: 'normal' }, { to: 'catch', args: ['e'], kind: 'throw' }] } },
        { name: 'done', params: [{ id: 'r', type: 'number' }], ops: [op('main', 'done', 0, 'print r', { op: 'print', args: ['r'], mayThrow: false })],
          term: { id: 'main/done/term', kind: 'return', text: 'return r', args: ['r'], edges: [] } },
        { name: 'catch', params: [{ id: 'e', type: 'any' }], ops: [op('main', 'catch', 0, 'v3 = const 0', { op: 'const', results: ['v3'], k: 0 }), op('main', 'catch', 1, 'print "caught"', { op: 'print', k: 'caught' })],
          term: { id: 'main/catch/term', kind: 'return', text: 'return v3', args: ['v3'], edges: [] } },
      ],
    };
    const total = {
      name: 'total', entry: 'entry', params: [{ id: 'n', type: 'number' }],
      blocks: [
        { name: 'entry', params: [], ops: [op('total', 'entry', 0, 'v1 = const 0', { op: 'const', results: ['v1'], k: 0 }), op('total', 'entry', 1, 'v2 = const 0', { op: 'const', results: ['v2'], k: 0 })],
          term: { id: 'total/entry/term', kind: 'jump', text: 'jump head(v1, v2)', edges: [{ to: 'head', args: ['v1', 'v2'], kind: 'jump' }] } },
        { name: 'head', params: [{ id: 'i', type: 'int32' }, { id: 's', type: 'number' }], ops: [op('total', 'head', 0, 'v3 = lt i, n', { op: 'lt', args: ['i', 'n'], results: ['v3'] })],
          term: { id: 'total/head/term', kind: 'branch', text: 'branch v3, body(), exit(s)', cond: 'v3', edges: [{ to: 'body', args: [], kind: 'true' }, { to: 'exit', args: ['s'], kind: 'false' }] } },
        { name: 'body', params: [], ops: [
          op('total', 'body', 0, 'v4 = add s, i', { op: 'add', args: ['s', 'i'], results: ['v4'] }),
          op('total', 'body', 1, 'v5 = add i, 1', { op: 'add', args: ['i'], results: ['v5'], k: 1 }),
          op('total', 'body', 2, 'v6 = box.alloc v4', { op: 'box.alloc', args: ['v4'], results: ['v6'], mayThrow: true, safepoint: true }),
          op('total', 'body', 3, 'v8 = box.alloc v5', { op: 'box.alloc', args: ['v5'], results: ['v8'], mayThrow: true, safepoint: true }),
          op('total', 'body', 4, 'v7 = box.get v6', { op: 'box.get', args: ['v6'], results: ['v7'] }),
        ], term: { id: 'total/body/term', kind: 'jump', text: 'jump head(v5, v7)', edges: [{ to: 'head', args: ['v5', 'v7'], kind: 'jump' }] } },
        { name: 'exit', params: [{ id: 'r', type: 'number' }], ops: [], term: { id: 'total/exit/term', kind: 'return', text: 'return r', args: ['r'], edges: [] } },
      ],
    };
    return { main, total };
  }

  const FACTS = {
    main: { live: { in: { entry: [], done: ['r'], catch: [] }, out: { entry: [], done: [], catch: [] }, across: { 'main/entry/0': [], 'main/done/0': ['r'], 'main/catch/0': [], 'main/catch/1': ['v3'] } },
      types: { v1: 'int32', v2: 'number', r: 'number', e: 'any', v3: 'int32' }, safepoints: ['main/entry/term'], idom: { entry: null, done: 'entry', catch: 'entry' }, iterations: { liveness: 2, types: 2 } },
    total: { live: { in: { entry: ['n'], head: ['n', 'i', 's'], body: ['n', 'i', 's'], exit: ['r'] }, out: { entry: ['n'], head: ['n', 'i', 's'], body: ['n'], exit: [] },
      across: { 'total/entry/0': ['n'], 'total/entry/1': ['n', 'v1'], 'total/head/0': ['n', 'i', 's'], 'total/body/0': ['n', 'i'], 'total/body/1': ['n', 'v4'], 'total/body/2': ['n', 'v5'], 'total/body/3': ['n', 'v5', 'v6'], 'total/body/4': ['n', 'v5'] } },
      types: { n: 'number', v1: 'int32', v2: 'int32', i: 'int32', s: 'number', v3: 'boolean', v4: 'number', v5: 'int32', v6: 'object', v8: 'object', v7: 'number', r: 'number' },
      safepoints: ['total/body/2', 'total/body/3'], idom: { entry: null, head: 'entry', body: 'head', exit: 'head' }, iterations: { liveness: 3, types: 4 } },
  };
  const STEPS = {
    liveness: [
      { i: 0, block: 'exit', before: { in: [], out: [] }, after: { in: ['r'], out: [] }, changed: true },
      { i: 1, block: 'body', before: { in: [], out: [] }, after: { in: ['n', 's', 'i'], out: ['n'] }, changed: true },
      { i: 2, block: 'head', before: { in: [], out: [] }, after: { in: ['n', 'i', 's'], out: ['n', 'i', 's'] }, changed: true },
      { i: 3, block: 'body', before: { in: ['n', 's', 'i'], out: ['n'] }, after: { in: ['n', 's', 'i'], out: ['n'] }, changed: false },
      { i: 4, block: 'entry', before: { in: [], out: [] }, after: { in: ['n'], out: ['n'] }, changed: true },
    ],
    types: [
      { i: 0, block: 'entry', before: { in: {}, out: {} }, after: { in: { n: 'number' }, out: { v1: 'int32', v2: 'int32' } }, changed: true },
      { i: 1, block: 'head', before: { in: {}, out: {} }, after: { in: { i: 'int32', s: 'int32' }, out: { v3: 'boolean' } }, changed: true },
      { i: 2, block: 'body', before: { in: {}, out: {} }, after: { in: { i: 'int32', s: 'int32' }, out: { v4: 'number', v5: 'int32' } }, changed: true },
      { i: 3, block: 'head', before: { in: { i: 'int32', s: 'int32' }, out: { v3: 'boolean' } }, after: { in: { i: 'int32', s: 'number' }, out: { v3: 'boolean' } }, changed: true },
    ],
  };

  function makeProgram(pipeline, src) {
    const C = makeCfgs();
    const roots = (pipeline && pipeline.options && pipeline.options.roots) || 'stackReuse';
    const name = (src && src.name) || 'program.js';
    const fnNames = ['main', 'total'];
    const needFn = fn => { if (!C[fn]) throw new Error(`no function ${fn} (functions: ${fnNames.join(', ')})`); return C[fn]; };
    const plan = fn => {
      needFn(fn);
      if (fn === 'main') return { strategy: roots, rootSlots: 0, fixedSlots: 0, argSlots: 1, frameBytes: 8, peakLive: 2, slots: [], safepoints: [{ op: 'main/entry/term', live: [], rooted: [], missing: [] }], reps: { v1: 'i32', v2: 'f64', r: 'f64', v3: 'i32' }, unwind: [{ op: 'main/entry/term', handler: 'catch', strategy: 'setjmp', restores: ['frame'] }] };
      const none = roots === 'none';
      return { strategy: roots, rootSlots: none ? 0 : 1, fixedSlots: 0, argSlots: 1, frameBytes: none ? 16 : 24, peakLive: 3,
        slots: none ? [] : [{ slot: 0, values: ['v6'] }],
        safepoints: [{ op: 'total/body/2', live: ['n', 'v5'], rooted: [], missing: [] }, { op: 'total/body/3', live: ['n', 'v5', 'v6'], rooted: none ? [] : ['v6'], missing: none ? ['v6'] : [] }],
        reps: { n: 'f64', i: 'i32', s: 'f64', v3: 'bool', v4: 'f64', v5: 'i32', v6: 'tagged', v8: 'tagged', v7: 'f64' }, unwind: [] };
    };
    const levelText = (level, fn) => {
      const one = f => {
        const c = C[f];
        if (level === 'L0') return src && src.text || '// (no source)';
        if (level === 'WAT') return f === 'total' ? ';; total: not accepted by the Wasm backend (box.alloc allocates on the GC heap)' : `(func $main (result f64)\n  f64.const 4\n  call $total\n)`;
        if (level === 'LLVM') return `define internal i64 @${f}(ptr %shr) {\n` + c.blocks.map(b => `${b.name}:\n` + b.ops.map(o => `  ; ${o.text}\n  %${(o.results[0] || 'x')} = call i64 @shllvm_${o.op.replace('.', '_')}(ptr %shr)`).join('\n') + `\n  ; ${b.term.text}`).join('\n') + '\n}';
        const head = `fn ${f}(${c.params.map(p => p.id + ': ' + p.type).join(', ')}) {`;
        const body = c.blocks.map(b => `  ${b.name}(${b.params.map(p => p.id + ': ' + p.type).join(', ')}):\n` + b.ops.map(o => {
          let t = o.text;
          if (level === 'L2' && o.op === 'box.alloc') t = t.replace('box.alloc', 'call @rt_box_alloc') + '   ; obligation: mayCollect';
          if (level === 'L3' && o.safepoint) { const sp = plan(f).safepoints.find(s => s.op === o.id); t += `   ; safepoint live [${sp ? sp.live.join(', ') : ''}] rooted [${sp ? sp.rooted.join(', ') : ''}]`; }
          return '    ' + t;
        }).join('\n') + (b.ops.length ? '\n' : '') + '    ' + b.term.text).join('\n');
        return head + '\n' + body + '\n}';
      };
      if (!fn) return fnNames.map(one).join('\n\n');
      needFn(fn); return one(fn);
    };
    const allOps = () => fnNames.flatMap(f => C[f].blocks.flatMap(b => b.ops.map(o => Object.assign({ fn: f, block: b.name }, o))));
    const perm = id => {
      const o = allOps().find(x => x.id === id);
      if (!o) { if (/\/term$/.test(id)) return { op: id, contract: { behaviour: 'control', obligations: [] }, erase: false, merge: false, move: false, duplicate: false, hoist: false, speculate: false, because: { erase: ['a terminator is never erased'] } }; throw new Error(`no op ${id}`); }
      const alloc = o.op === 'box.alloc';
      return { op: id, contract: { behaviour: alloc ? 'alloc' : 'pure', obligations: alloc ? ['mayCollect', 'mayThrow'] : [] },
        erase: alloc ? 'when the result is unused and mayThrow is discharged' : true, merge: !alloc, move: alloc ? false : true, duplicate: !alloc, hoist: alloc ? false : 'when its operands dominate the target', speculate: !alloc,
        because: { erase: alloc ? ['behaviour alloc: allocation is observable only through its result', 'obligation mayThrow: an out-of-memory throw must stay'] : ['behaviour pure'], move: alloc ? ['obligation mayCollect: moving it changes which values are live at the safepoint'] : ['behaviour pure'] } };
    };
    const P = {
      kind: 'program', name, pipeline, source: src && src.text,
      functions: () => fnNames.slice(),
      ir: (level = 'L1', o = {}) => o.format === 'json' ? JSON.stringify(o.fn ? needFn(o.fn) : C) : levelText(level, o.fn),
      cfg: (fn, level = 'L1') => JSON.parse(JSON.stringify(needFn(fn))),
      facts: fn => { needFn(fn); return JSON.parse(JSON.stringify(FACTS[fn])); },
      steps: (fn, a = 'liveness') => { needFn(fn); if (!STEPS[a]) throw new Error(`no analysis ${a} (liveness, types)`); return fn === 'total' ? JSON.parse(JSON.stringify(STEPS[a])) : STEPS[a].slice(0, 2).map(s => Object.assign({}, s, { block: 'entry' })); },
      plan,
      perm,
      why: t => {
        t = String(t);
        if (t.startsWith('slot:')) return { slot: t, values: ['v6'], because: 'v6 (object) is live across the safepoint total/body/3' };
        if (/\//.test(t)) { const parts = t.split('/'); if (parts.length === 2) return { block: t, idom: (FACTS[parts[0]] || {}).idom && FACTS[parts[0]].idom[parts[1]], liveIn: ((FACTS[parts[0]] || {}).live || {}).in && FACTS[parts[0]].live.in[parts[1]] }; return Object.assign({ op: t }, perm(t)); }
        return { value: t, type: FACTS.total.types[t] || 'unknown', definedAt: allOps().find(o => o.results.includes(t)) ? allOps().find(o => o.results.includes(t)).id : 'a block parameter' };
      },
      find: pred => allOps().filter(o => { try { return pred(o); } catch (e) { return false; } }),
      diagnostics: [
        { severity: 'info', kind: 'pass', message: 'promote-cells: 4 cells became SSA values', at: { fn: 'total', block: 'entry', op: 0 } },
        { severity: 'warning', kind: 'dead', message: 'v8 is never used', at: { fn: 'total', block: 'body', op: 3 } },
      ].concat(roots === 'none' ? [{ severity: 'error', kind: 'plan', message: 'root strategy none: v6 is live across a safepoint without a root slot', at: { fn: 'total', block: 'body', op: 3 } }] : []),
      trace: [
        { pass: 'frontend', level: 'L0→L1', ms: 0.6, note: '2 functions' }, { pass: 'promote-cells', level: 'L1', ms: 0.2, note: '4 cells' },
        { pass: 'eraseDead', level: 'L1', ms: 0.1, note: '0 erased' }, { pass: 'lower', level: 'L1→L2', ms: 0.3, note: 'box.alloc → rt_box_alloc' }, { pass: 'plan', level: 'L2→L3', ms: 0.4, note: 'roots ' + roots },
      ],
      decisions: [
        { by: 'eraseDead', at: 'total/body/3', fired: false, because: 'obligation mayThrow blocks erase' },
        { by: 'constFold', at: 'total/entry/0', fired: true, because: 'operands are constants' },
      ],
      summary: () => ({ profile: 'core', frontend: 'stub', providers: ['stub-runtime'], strategies: { roots, exceptions: 'setjmp' }, checks: ['verify', 'plan'], counts: { functions: 2, blocks: 7, ops: allOps().length, values: 18 } }),
      run: o => runProgram(C, plan, Object.assign({ mode: 'spec', gc: 'off' }, o || {}), roots),
    };
    return P;
  }

  /* ---------- a tiny interpreter over the fixed CFGs ---------- */
  function runProgram(C, plan, o, roots) {
    const mode = o.mode, gc = mode === 'plan' ? o.gc : 'off';
    const records = [], events = [], output = [];
    const metrics = { steps: 0, calls: 0, collections: 0, moved: 0, peakRootSlots: 0, rootBytes: 0, jobs: 0, maxDepth: 0 };
    let n = 0;
    const POISON = { poisoned: true };
    const call = (fname, args, depth) => {
      const c = C[fname];
      metrics.calls++; metrics.maxDepth = Math.max(metrics.maxDepth, depth);
      events.push({ n, type: 'call', fn: fname, args: args.slice() });
      const env = {}; c.params.forEach((p, i) => { env[p.id] = args[i]; });
      let blk = c.blocks.find(b => b.name === c.entry);
      for (let guard = 0; guard < 10000; guard++) {
        blk.ops.forEach((x, i) => {
          n++; metrics.steps++;
          let val;
          const a = x.args.map(k => env[k]);
          if (x.op === 'const') val = x.k;
          else if (x.op === 'lt') val = a[0] < a[1];
          else if (x.op === 'add') val = a.length > 1 ? a[0] + a[1] : a[0] + x.k;
          else if (x.op === 'print') { const s = String(a.length ? a[0] : x.k); output.push(s); events.push({ n, type: 'print', text: s }); }
          else if (x.op === 'box.alloc') {
            val = { box: a[0] };
            if (gc === 'stress' || (gc === 'alloc' && n % 7 === 0)) {
              metrics.collections++; metrics.moved++;
              events.push({ n, type: 'collect', at: x.id, live: (plan(fname).safepoints.find(s => s.op === x.id) || {}).live || [], moved: 1 });
              const sp = plan(fname).safepoints.find(s => s.op === x.id);
              if (sp) for (const m of sp.missing) if (env[m] && typeof env[m] === 'object') env[m] = POISON;
            }
          } else if (x.op === 'box.get') {
            if (a[0] === POISON) { events.push({ n, type: 'stale', value: x.args[0], at: { fn: fname, block: blk.name, op: i }, note: 'the object moved at the last collection and no root slot held it' }); val = NaN; }
            else val = a[0].box;
          }
          if (x.results[0]) env[x.results[0]] = val;
          if (records.length < 4000) records.push({ n, fn: fname, block: blk.name, op: i, text: x.text, value: val && typeof val === 'object' ? (val === POISON ? '<moved>' : '<box>') : val, depth });
        });
        const t = blk.term; n++; metrics.steps++;
        if (records.length < 4000) records.push({ n, fn: fname, block: blk.name, op: 'term', text: t.text, value: undefined, depth });
        const goto = e => { const b = c.blocks.find(x => x.name === e.to); b.params.forEach((p, i) => { env[p.id] = env[e.args[i]]; }); blk = b; };
        if (t.kind === 'jump') goto(t.edges[0]);
        else if (t.kind === 'branch') goto(env[t.cond] ? t.edges[0] : t.edges[1]);
        else if (t.kind === 'return') { const v = env[t.args[0]]; events.push({ n, type: 'return', fn: fname, value: v }); return v; }
        else if (t.kind === 'invoke') { env[t.result] = call(t.call, t.args.map(k => env[k]), depth + 1); goto(t.edges[0]); }
      }
      throw new Error('step budget exhausted');
    };
    let outcome;
    try { outcome = { kind: 'normal', value: call('main', [], 0) }; } catch (e) { outcome = { kind: 'error', value: e.message }; events.push({ n, type: 'error', message: e.message }); }
    if (mode === 'plan') { metrics.peakRootSlots = roots === 'none' ? 0 : 1; metrics.rootBytes = metrics.peakRootSlots * 8; }
    if (mode === 'wasm') events.push({ n: 0, type: 'error', message: 'total is not accepted by the Wasm backend; ran it on the reference interpreter' });
    events.sort((a, b) => a.n - b.n).forEach((e, i) => { e.n = e.n || i; });
    return { kind: 'run', mode, outcome, output, events, steps: metrics.steps, records, metrics };
  }

  /* ---------- g ---------- */
  const units = {};
  for (const u of ['bytes', 'kib', 'mib', 'slots', 'jobs', 'ms', 'count']) units[u] = x => ({ unit: u, n: x });
  const g = {
    source: { text: (text, o) => ({ kind: 'source', text: String(text || ''), name: (o && o.name) || 'program.js' }) },
    pipeline: options => ({ kind: 'pipeline', options: options || {}, passes: () => ['frontend', 'promote-cells', 'eraseDead', 'lower', 'plan'], check: () => ({ ok: true }) }),
    compile: (pipeline, src) => {
      if (!src || src.kind !== 'source') throw new TypeError('g.compile(pipeline, source): source must come from g.source.text');
      if (/\bsyntax error\b/.test(src.text)) { const e = new SyntaxError('Unexpected token (3:4)'); throw e; }
      return makeProgram(pipeline, src);
    },
    law: {
      check: list => ({ kind: 'laws', laws: (list || []).map(l => Object.assign({ samples: 200, note: '' }, l)) }),
    },
    table: (t) => Object.assign({ kind: 'results', title: 'a table', columns: [], rows: [], note: '' }, t),
  };

  function presetScope(files, o) {
    const log = (o && o.log) || (() => {});
    const print = (...a) => log(...a);
    return Object.assign({ g, files: Object.freeze(Object.assign({}, files)), source: (name = 'program.js') => g.source.text(files[name], { name }), print, log, console: { log, info: log, warn: log, error: log } }, units);
  }

  async function runScript(code, scope, opts) {
    const keys = Object.keys(scope || {}).filter(k => ID.test(k));
    const logs = [];
    const t0 = (typeof performance !== 'undefined' ? performance : Date).now();
    const now = () => (typeof performance !== 'undefined' ? performance : Date).now() - t0;
    try {
      const f = new Function(...keys, '"use strict";\nreturn (async () => {\n' + code + '\n})();\n//# sourceURL=main.js');
      const timeout = (opts && opts.timeoutMs) || 25000;
      const value = await Promise.race([f(...keys.map(k => scope[k])), new Promise((_, rej) => setTimeout(() => rej(new Error(`main.js timed out after ${timeout / 1000} s`)), timeout))]);
      return { ok: true, ms: now(), value, logs };
    } catch (e) {
      const m = String(e && e.stack || '').match(/main\.js:(\d+)/);
      return { ok: false, ms: now(), logs, error: { message: (e && e.name ? e.name + ': ' : '') + (e && e.message || String(e)), line: m ? Math.max(1, +m[1] - 4) : null } };
    }
  }

  function classify(v) {
    const kindOf = x => x && typeof x === 'object' && x.kind;
    const out = {};
    const put = x => { const k = kindOf(x); if (k === 'program' || k === 'run' || k === 'laws' || k === 'results') { out[k] = x; return true; } return false; };
    if (put(v)) return out;
    if (v && typeof v === 'object' && !Array.isArray(v)) {
      let any = false;
      for (const k of ['program', 'run', 'laws', 'results']) if (v[k] && put(v[k])) any = true;
      const rest = Object.keys(v).filter(k => !['program', 'run', 'laws', 'results'].includes(k));
      if (any) { if (rest.length) out.other = Object.fromEntries(rest.map(k => [k, v[k]])); return out; }
    }
    if (v !== undefined) out.other = v;
    return out;
  }

  const strata = { g, version: 'test-stub', yaml, runScript, presetScope, classify };
  root.strata = strata;
  if (typeof module !== 'undefined' && module.exports) module.exports = strata;
})(typeof window !== 'undefined' ? window : globalThis);
