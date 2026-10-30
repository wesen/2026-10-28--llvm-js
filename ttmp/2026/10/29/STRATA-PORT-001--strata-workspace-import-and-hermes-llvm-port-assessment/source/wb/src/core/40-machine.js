
// ---------------------------------------------------------------- the machine
// One interpreter serves two purposes. With mode 'spec' it is the reference semantics
// of the core IR: it never collects and nothing moves. With mode 'plan' it runs the
// same program under an execution plan: at collecting operations a moving collector
// copies every reachable object to a new address and updates only what the plan rooted.
// A value the plan forgot still holds the old address, and its next use is reported as
// a stale reference: the bug a real backend must never have.

class Ref {
  constructor(addr, kind, oid) { this.addr = addr; this.kind = kind; this.oid = oid; this.isRef = true; Object.freeze(this); }
  get kindType() { return this.kind === 'function' ? t.function : this.kind === 'cell' ? t.cell : this.kind === 'completion' ? t.completion : t.object; }
  toString() { return `#${this.oid}`; }
  toJSON() { return { ref: this.oid, kind: this.kind }; }
  yamlTag() { return `${this.kind} #${this.oid}`; }
}

class JSThrow { constructor(value) { this.value = value; } }
class Diverge { constructor(steps) { this.steps = steps; } }
class StaleUse extends Error {
  constructor(detail) {
    const where = String(detail.collectedAt || '?'), freed = where.endsWith(' (freed)'), site = where.replace(' (freed)', '');
    super(`stale reference: ${detail.value} (object #${detail.oid}) was not rooted, so the collection at ${site} ${freed ? 'freed it' : 'moved it'}; it was then used at ${detail.at}`);
    this.detail = detail;
  }
}

const HOLE = Symbol('uninitialized');

class Machine {
  constructor(module, opts = {}) {
    this.module = module;
    this.mode = opts.mode || 'spec';
    this.plans = opts.plans || {};
    this.gc = this.mode === 'plan' ? (opts.gc || 'off') : 'off';
    this.budget = opts.budget || 200000;
    this.recordLimit = opts.recordLimit === undefined ? 4000 : opts.recordLimit;
    this.maxDepth = opts.maxDepth || 300;
    this.heap = new Map(); this.nextAddr = 1; this.nextOid = 1; this.sinceGC = 0;
    this.forwardTo = new Map(); this.execDepth = 0; this.hostRoots = [];
    this.output = []; this.trace = []; this.events = []; this.records = [];
    this.microtasks = []; this.timers = []; this.vtime = 0; this.timerSeq = 0;
    this.frames = []; this.steps = 0; this.lastCollection = null; this.movedAt = new Map();
    this.metrics = { steps: 0, calls: 0, allocations: 0, collections: 0, moved: 0, peakRootSlots: 0, rootBytes: 0, jobs: 0, maxDepth: 0 };
    this.HOLE = HOLE;
    this.globals = new Map();
    this.installBuiltins();
  }

  // ---- heap
  alloc(kind, fields = {}) {
    const addr = this.nextAddr++, oid = this.nextOid++;
    this.heap.set(addr, { kind, oid, props: new Map(), ...fields });
    this.metrics.allocations++; this.sinceGC++;
    return new Ref(addr, kind, oid);
  }
  deref(v, what = 'value') {
    let o = this.heap.get(v.addr);
    // A helper holds its operands through handles, as a real runtime does: an object the
    // collector moved during the helper's own execution is found at its new address. An
    // object that nothing rooted was freed, and reading it is a stale use.
    for (let a = v.addr; !o && this.forwardTo.has(a);) { a = this.forwardTo.get(a); o = this.heap.get(a); }
    if (!o) throw new StaleUse({ value: what, oid: v.oid, collectedAt: this.movedAt.get(v.addr) || '?', at: this.here() });
    return o;
  }
  here() { const f = this.frames[this.frames.length - 1]; return f ? f.at : 'top level'; }

  // ---- the semantic helpers the operations' steps call
  sameRef(a, b) { return this.strictEquals(a, b); }
  strictEquals(a, b) {
    if (a && a.isRef && b && b.isRef) { this.deref(a); this.deref(b); return a.oid === b.oid; }   // identity survives moves
    if ((a && a.isRef) || (b && b.isRef)) return false;
    return a === b;
  }
  truthy(v) { return v && v.isRef ? true : !!v; }
  typeOf(v) {
    if (v === null) return 'object';
    if (v && v.isRef) return this.deref(v).kind === 'function' ? 'function' : 'object';
    return typeof v;
  }
  toPrimitive(v, hint = 'default') {
    if (!(v && v.isRef)) return v;
    const o = this.deref(v);
    for (const name of hint === 'string' ? ['toString', 'valueOf'] : ['valueOf', 'toString']) {
      const m = this.lookup(o, name, v);
      if (m && m.isRef && this.deref(m).kind === 'function') {
        const r = this.callValue(m, v, []);
        if (!(r && r.isRef)) return r;
      }
    }
    if (o.kind === 'array') return o.elems.map(e => (e === undefined || e === null ? '' : this.toString(e))).join(',');
    if (o.kind === 'function') return 'function';
    if (o.kind === 'error') return `${this.toString(this.getProperty(v, 'name'))}: ${this.toString(this.getProperty(v, 'message'))}`;
    if (o.kind === 'promise') return '[object Promise]';
    return '[object Object]';
  }
  toNumber(v) {
    if (v && v.isRef) return this.toNumber(this.toPrimitive(v, 'number'));
    if (v === undefined) return NaN;
    if (v === null) return 0;
    if (typeof v === 'boolean') return v ? 1 : 0;
    if (typeof v === 'string') return Number(v);
    return v;
  }
  toString(v) {
    if (v && v.isRef) return this.toString(this.toPrimitive(v, 'string'));
    if (typeof v === 'number' && Object.is(v, -0)) return '0';
    return String(v);
  }
  add(a, b) {
    const pa = this.toPrimitive(a), pb = this.toPrimitive(b);
    if (typeof pa === 'string' || typeof pb === 'string') return this.toString(pa) + this.toString(pb);
    return this.toNumber(pa) + this.toNumber(pb);
  }
  compare(a, b, f) {
    const pa = this.toPrimitive(a, 'number'), pb = this.toPrimitive(b, 'number');
    if (typeof pa === 'string' && typeof pb === 'string') return f(pa, pb);
    return f(this.toNumber(pa), this.toNumber(pb));
  }
  key(k) { return typeof k === 'number' ? (Object.is(k, -0) ? '0' : String(k)) : this.toString(k); }
  lookup(o, k, self) {                            // own properties only; no prototype chain in this subset
    if (o.kind === 'array') {
      if (k === 'length') return o.elems.length;
      if (/^\d+$/.test(k)) return o.elems[Number(k)];
    }
    if (o.kind === 'promise' && k === 'then') return this.builtin('then');
    const slot = o.props.get(k);
    if (!slot) return undefined;
    if ('value' in slot) return slot.value;
    return slot.get ? this.callValue(slot.get, self, []) : undefined;
  }
  getProperty(v, k) {
    if (v === undefined || v === null) this.throwError('TypeError', `cannot read property ${this.key(k)} of ${v}`);
    if (typeof v === 'string') {
      const key = this.key(k);
      if (key === 'length') return v.length;
      return /^\d+$/.test(key) ? v[Number(key)] : undefined;
    }
    if (!(v && v.isRef)) return undefined;
    return this.lookup(this.deref(v), this.key(k), v);
  }
  getOwnData(v, k) { const s = this.deref(v).props.get(this.key(k)); return s && 'value' in s ? s.value : undefined; }
  setProperty(v, k, value) {
    if (!(v && v.isRef)) this.throwError('TypeError', `cannot set property ${this.key(k)} of ${v === undefined || v === null ? v : typeof v}`);
    const o = this.deref(v), key = this.key(k);
    if (o.kind === 'array' && (key === 'length' || /^\d+$/.test(key))) {
      if (key === 'length') o.elems.length = this.toNumber(value); else o.elems[Number(key)] = value;
      return;
    }
    const slot = o.props.get(key);
    if (slot && !('value' in slot)) {
      if (!slot.set) this.throwError('TypeError', `cannot set ${key}: it has a getter and no setter`);
      this.callValue(slot.set, v, [value]); return;
    }
    o.props.set(key, { value });
  }
  define(v, k, value) { this.deref(v).props.set(this.key(k), { value }); }
  defineAccessor(v, k, f, which) {
    const o = this.deref(v), key = this.key(k);
    const slot = o.props.get(key);
    const acc = slot && !('value' in slot) ? slot : {};
    acc[which] = f; o.props.set(key, acc);
  }
  newObject() { return this.alloc('object'); }
  newArray(elems) { return this.alloc('array', { elems: elems.slice() }); }
  newClosure(callee, caps) {
    if (!this.module.fn(callee)) this.throwError('TypeError', `no function @${callee}`);
    return this.alloc('function', { fn: callee, caps: caps.slice() });
  }
  newCell(v) { return this.alloc('cell', { value: v }); }
  cellLoad(c, checked, name) {
    const v = this.deref(c, 'cell').value;
    if (v === HOLE) {
      if (checked) this.throwError('ReferenceError', `cannot access ${name || 'a variable'} before initialization`);
      return undefined;
    }
    return v;
  }
  cellStore(c, v) { this.deref(c, 'cell').value = v; }
  globalGet(name) {
    if (!this.globals.has(name)) this.throwError('ReferenceError', `${name} is not defined`);
    return this.globals.get(name);
  }
  globalPut(name, v) { this.globals.set(name, v); }
  newError(kind, message) {
    const e = this.alloc('error');
    const o = this.heap.get(e.addr);
    o.props.set('name', { value: kind }); o.props.set('message', { value: message === undefined ? '' : this.toString(message) });
    return e;
  }
  throwError(kind, message) {
    const e = this.alloc('error');
    const o = this.heap.get(e.addr);
    o.props.set('name', { value: kind }); o.props.set('message', { value: message });
    throw new JSThrow(e);
  }
  display(v) {
    if (v && v.isRef) {
      const o = this.heap.get(v.addr);
      if (!o) return '<stale>';
      if (o.kind === 'array') return o.elems.map(e => (e === undefined || e === null ? '' : this.display(e))).join(',');
      if (o.kind === 'function') return 'function';
      if (o.kind === 'error') return `${this.display(o.props.get('name').value)}: ${this.display(o.props.get('message').value)}`;
      if (o.kind === 'promise') return '[object Promise]';
      if (o.kind === 'cell') return '<cell>';
      return '[object Object]';
    }
    if (typeof v === 'number' && Object.is(v, -0)) return '0';
    return String(v);
  }
  // A debugger's view of a value, for the step records: identity and a few fields.
  inspect(v, depth = 0) {
    if (v === HOLE) return '<uninitialized>';
    if (typeof v === 'string') return JSON.stringify(v.length > 40 ? v.slice(0, 40) + '…' : v);
    if (!(v && v.isRef)) return typeof v === 'number' && Object.is(v, -0) ? '-0' : String(v);
    let o = this.heap.get(v.addr);
    for (let a = v.addr; !o && this.forwardTo.has(a);) { a = this.forwardTo.get(a); o = this.heap.get(a); }
    if (!o) return `#${v.oid} <stale>`;
    const inner = x => (depth > 0 ? (x && x.isRef ? `#${x.oid}` : this.inspect(x, depth + 1)) : this.inspect(x, depth + 1));
    switch (o.kind) {
      case 'function': return `#${v.oid} fn ${o.native ? o.name + ' (builtin)' : '@' + o.fn}`;
      case 'cell': return `#${v.oid} cell = ${o.value === HOLE ? '<uninitialized>' : inner(o.value)}`;
      case 'completion': return `#${v.oid} completion(${o.ckind}${o.value !== undefined ? ', ' + inner(o.value) : ''})`;
      case 'promise': return `#${v.oid} promise ${o.state}${o.state !== 'pending' ? ' ' + inner(o.value) : ''}`;
      case 'array': return `#${v.oid} [${o.elems.slice(0, 4).map(inner).join(', ')}${o.elems.length > 4 ? ', …' : ''}]`;
      case 'error': return `#${v.oid} ${this.display(v)}`;
      default: {
        const ks = [...o.props.keys()];
        const shown = ks.slice(0, 3).map(k => { const sl = o.props.get(k); return 'value' in sl ? `${k}: ${inner(sl.value)}` : `${k}: <accessor>`; });
        return `#${v.oid} {${shown.join(', ')}${ks.length > 3 ? ', …' : ''}}`;
      }
    }
  }
  print(args) {
    const line = args.map(a => this.display(a)).join(' ');
    this.output.push(line);
    this.trace.push({ type: 'print', values: args.map(a => (a && a.isRef ? { ref: a.oid } : a)) });
    this.event('print', { line });
  }
  enqueue(f, args = []) { this.microtasks.push({ f, args }); this.event('job', { what: 'enqueue', queue: this.microtasks.length }); }
  setTimer(f, delay) { this.timers.push({ at: this.vtime + Math.max(0, this.toNumber(delay) || 0), seq: this.timerSeq++, f }); this.event('timer', { what: 'set', at: this.vtime + delay }); }
  promiseResolve(v) {
    if (v && v.isRef && this.deref(v).kind === 'promise') return v;
    return this.alloc('promise', { state: 'fulfilled', value: v, reactions: [] });
  }
  promiseThen(p, onFulfilled) {
    const q = this.alloc('promise', { state: 'pending', value: undefined, reactions: [] });
    const po = this.deref(p);
    const reaction = { handler: onFulfilled, target: q };
    if (po.state === 'fulfilled') this.enqueue(this.builtin('react'), [reaction, po.value]);
    else po.reactions.push(reaction);
    return q;
  }
  fulfil(q, value) {
    const qo = this.deref(q);
    if (qo.state !== 'pending') return;
    if (value && value.isRef && this.deref(value).kind === 'promise') { this.promiseThen(value, this.builtin('adopt', q)); return; }
    qo.state = 'fulfilled'; qo.value = value;
    for (const r of qo.reactions) this.enqueue(this.builtin('react'), [r, value]);
    qo.reactions = [];
  }
  completion(kind, value) { return this.alloc('completion', { ckind: kind, value }); }
  completionIs(c, kind) { return this.deref(c, 'completion').ckind === kind; }
  completionValue(c) { return this.deref(c, 'completion').value; }

  // ---- builtins are native function objects
  installBuiltins() {
    const native = (name, impl) => { const r = this.alloc('function', { native: impl, name }); return r; };
    this.natives = {
      print: native('print', (self, args) => { this.print(args); return undefined; }),
      queueMicrotask: native('queueMicrotask', (self, [f]) => { this.enqueue(f, []); return undefined; }),
      setTimeout: native('setTimeout', (self, [f, d]) => { this.setTimer(f, d || 0); return undefined; }),
      then: native('then', (self, [f]) => this.promiseThen(self, f)),
      react: native('react', (self, [reaction, value]) => {
        let result = value;
        if (reaction.handler && reaction.handler.isRef && this.deref(reaction.handler).kind === 'function') {
          try { result = this.callValue(reaction.handler, undefined, [value]); }
          catch (e) { if (e instanceof JSThrow) { const q = this.deref(reaction.target); q.state = 'rejected'; q.value = e.value; this.event('error', { what: 'unhandled rejection', value: this.display(e.value) }); return undefined; } throw e; }
        }
        this.fulfil(reaction.target, result); return undefined;
      }),
    };
    const promise = this.alloc('object');
    this.heap.get(promise.addr).props.set('resolve', { value: native('resolve', (self, [v]) => this.promiseResolve(v)) });
    for (const [k, v] of Object.entries(this.natives)) if (!['then', 'react'].includes(k)) this.globals.set(k, v);
    this.globals.set('Promise', promise);
  }
  builtin(name, bound) {
    if (name === 'adopt') return this.alloc('function', { native: (self, [v]) => { this.fulfil(bound, v); return undefined; }, name: 'adopt' });
    return this.natives[name];
  }

  // ---- calls
  callValue(f, self, args) {
    if (!(f && f.isRef) || this.deref(f).kind !== 'function') this.throwError('TypeError', `${this.display(f)} is not a function`);
    const o = this.deref(f);
    this.metrics.calls++;
    if (o.native) return o.native(self, args);
    const fn = this.module.fn(o.fn);
    return this.callFn(fn, [...o.caps, self, ...args]);
  }
  callMethod(o, key, args) { return this.callValue(this.getProperty(o, key), o, args); }
  callDirect(callee, args) { const fn = this.module.fn(callee); if (!fn) this.throwError('TypeError', `no function @${callee}`); this.metrics.calls++; return this.callFn(fn, args); }

  event(type, data = {}) { if (this.events.length < 2000) this.events.push({ n: this.steps, type, ...data }); }
  tick(fn, block, op, text, value) {
    this.steps++;
    if (this.steps > this.budget) throw new Diverge(this.steps);
    if (this.records.length < this.recordLimit) this.records.push({ n: this.steps, fn: fn.name, block: block.name, op, text, value: value === undefined ? undefined : this.inspect(value), depth: this.frames.length });
  }

  value(a, frame) {
    if (isLit(a)) return a.lit;
    if (!frame.env.has(a)) throw new StrataError(`${a} has no value in ${frame.fn.name} (at ${frame.at})`);
    const v = frame.env.get(a);
    if (this.mode === 'plan' && v && v.isRef && !this.heap.has(v.addr)) {
      const detail = { value: a, oid: v.oid, collectedAt: this.movedAt.get(v.addr) || '?', at: frame.at };
      this.event('stale', detail);
      throw new StaleUse(detail);
    }
    return v;
  }

  exec(o, frame) {
    const d = lookupOp(o.op);
    if (this.execDepth === 0) this.forwardTo.clear();   // handles live only while a helper runs
    if (this.mode === 'plan' && d.mayCollect) this.maybeCollect();
    const args = o.args.map(a => this.value(a, frame));
    this.execDepth++;
    try { return d.step(this, args, o); } finally { this.execDepth--; }
  }

  callFn(fn, args) {
    if (this.frames.length >= this.maxDepth) this.throwError('RangeError', 'maximum call stack size exceeded');
    const frame = { fn, env: new Map(), at: `${fn.name}/${fn.entry}/0`, plan: this.plans[fn.name] };
    fn.params.forEach((p, i) => frame.env.set(p.id, args[i]));
    this.frames.push(frame);
    this.metrics.maxDepth = Math.max(this.metrics.maxDepth, this.frames.length);
    if (this.mode === 'plan') {
      const total = this.frames.reduce((n, f) => n + (f.plan ? f.plan.frameSlots : 0), 0);
      if (total > this.metrics.peakRootSlots) { this.metrics.peakRootSlots = total; this.metrics.rootBytes = total * 8; }
    }
    try {
      let block = fn.blocks[0], incoming = [];
      for (;;) {
        block.params.forEach((p, i) => frame.env.set(p.id, incoming[i]));
        let next = null;
        for (let i = 0; i < block.ops.length && !next; i++) {
          const o = block.ops[i];
          frame.at = `${fn.name}/${block.name}/${i}`;
          let v;
          try { v = this.exec(o, frame); }
          catch (e) {
            if (!(e instanceof JSThrow) || !block.onThrow || block.onThrow === 'unwind') throw e;
            this.event('catch', { at: frame.at, handler: block.onThrow, value: this.display(e.value) });
            next = { block: fn.block(block.onThrow), incoming: [e.value, ...(block.throwArgs || []).map(x => this.value(x, frame))] };
            break;
          }
          if (o.result) frame.env.set(o.result, v);
          this.tick(fn, block, i, opText(o), v);
        }
        if (next) { block = next.block; incoming = next.incoming; continue; }
        const term = block.term;
        frame.at = `${fn.name}/${block.name}/term`;
        const edgeArgs = e => e.args.map(a => this.value(a, frame));
        switch (term.kind) {
          case 'jump': this.tick(fn, block, 'term', termText(term)); incoming = edgeArgs(term.to); block = fn.block(term.to.block); break;
          case 'branch': {
            const c = this.value(term.cond, frame);
            this.tick(fn, block, 'term', termText(term), c);
            const e = this.truthy(c) ? term.t : term.f;
            incoming = edgeArgs(e); block = fn.block(e.block); break;
          }
          case 'return': { const v = this.value(term.value, frame); this.tick(fn, block, 'term', termText(term), v); return v; }
          case 'throw': {
            const v = this.value(term.value, frame);
            this.tick(fn, block, 'term', termText(term), v);
            this.event('throw', { at: frame.at, value: this.display(v) });
            if (block.onThrow && block.onThrow !== 'unwind') {   // a throw in a protected block goes to its handler
              this.event('catch', { at: frame.at, handler: block.onThrow, value: this.display(v) });
              incoming = [v, ...(block.throwArgs || []).map(x => this.value(x, frame))]; block = fn.block(block.onThrow); break;
            }
            throw new JSThrow(v);
          }
          case 'unreachable': throw new StrataError(`reached unreachable in ${fn.name}/${block.name}`);
          case 'invoke': {
            const d = lookupOp(term.op.op);
            let v;
            try { v = this.exec(term.op, frame); }
            catch (e) {
              if (!(e instanceof JSThrow)) throw e;
              this.tick(fn, block, 'term', termText(term), e.value);
              this.event('catch', { at: frame.at, handler: term.exc.block, value: this.display(e.value) });
              incoming = [e.value, ...edgeArgs(term.exc)]; block = fn.block(term.exc.block); break;
            }
            this.tick(fn, block, 'term', termText(term), v);
            incoming = [...(d.results.length ? [v] : []), ...edgeArgs(term.normal)]; block = fn.block(term.normal.block); break;
          }
          default: throw new StrataError(`unknown terminator ${term.kind}`);
        }
      }
    } finally {
      this.frames.pop();
    }
  }

  // ---- the simulated moving collector (plan mode only)
  maybeCollect() {
    if (this.gc === 'stress' || (this.gc === 'alloc' && this.sinceGC >= 16)) this.collect();
  }
  rootsOfFrame(frame) {                           // what the plan says is rooted here
    const plan = frame.plan;
    if (!plan) return [];
    const sp = plan.safepoints[frame.at];
    return sp ? sp.rooted : [];
  }
  collect() {
    const at = this.here();
    const forward = new Map(), next = new Map();
    let addr = this.nextAddr;
    const move = v => {
      if (!(v && v.isRef)) return v;
      if (forward.has(v.addr)) return forward.get(v.addr);
      const o = this.heap.get(v.addr);
      if (!o) return v;                             // already stale: stays stale
      const nv = new Ref(addr++, v.kind, v.oid);
      forward.set(v.addr, nv); next.set(nv.addr, o); queue.push(o);
      return nv;
    };
    const queue = [];
    // Roots: the slots of every frame, the globals, the job and timer queues, the builtins.
    const slotUpdates = [];
    for (const frame of this.frames) {
      const plan = frame.plan, slotsHeld = new Map();
      for (const id of this.rootsOfFrame(frame)) {
        const slot = plan.slotOf[id];
        if (slot === undefined) continue;
        slotsHeld.set(slot, id);                    // a later value in the same slot overwrites an earlier one
      }
      for (const [, id] of slotsHeld) if (frame.env.has(id)) slotUpdates.push([frame, id, move(frame.env.get(id))]);
    }
    for (const [k, v] of this.globals) this.globals.set(k, move(v));
    for (const k of Object.keys(this.natives)) this.natives[k] = move(this.natives[k]);
    for (const j of this.microtasks) { j.f = move(j.f); j.args = j.args.map(a => (a && a.handler !== undefined ? this.moveReaction(a, move) : move(a))); }
    for (const tm of this.timers) tm.f = move(tm.f);
    for (const h of this.hostRoots) { h.f = move(h.f); h.args = h.args.map(a => (a && a.handler !== undefined ? this.moveReaction(a, move) : move(a))); }
    // Trace: copy what the roots reach, updating every reference inside moved objects.
    while (queue.length) {
      const o = queue.shift();
      for (const [k, s] of o.props) o.props.set(k, 'value' in s ? { value: move(s.value) } : { get: move(s.get), set: move(s.set) });
      if (o.elems) o.elems = o.elems.map(move);
      if (o.caps) o.caps = o.caps.map(move);
      if ('value' in o && o.kind !== 'object') o.value = move(o.value);
      if (o.reactions) o.reactions = o.reactions.map(r => this.moveReaction(r, move));
    }
    for (const [frame, id, nv] of slotUpdates) frame.env.set(id, nv);
    for (const oldAddr of this.heap.keys()) if (!forward.has(oldAddr)) this.movedAt.set(oldAddr, at + ' (freed)');
    for (const [oldAddr, nv] of forward) { this.movedAt.set(oldAddr, at); this.forwardTo.set(oldAddr, nv.addr); }
    this.metrics.collections++; this.metrics.moved += forward.size;
    this.event('collect', { at, moved: forward.size, freed: this.heap.size - forward.size });
    this.heap = next; this.nextAddr = addr; this.sinceGC = 0; this.lastCollection = at;
  }
  moveReaction(r, move) { r.handler = move(r.handler); r.target = move(r.target); return r; }

  // ---- running a program: main, then the job queues
  runMain(name, args) {
    const fn = this.module.fn(name || this.module.main);
    if (!fn) throw new StrataError(`no function ${name || this.module.main}`);
    try { return { kind: 'normal', value: this.callFn(fn, fn.params.map((p, i) => (args ? args[i] : undefined))) }; }
    catch (e) { return this.outcomeOf(e); }
  }
  outcomeOf(e) {
    if (e instanceof JSThrow) { this.event('throw', { what: 'uncaught', value: this.display(e.value) }); return { kind: 'throw', value: e.value }; }
    if (e instanceof Diverge) return { kind: 'diverge', steps: e.steps };
    if (e instanceof StaleUse) return { kind: 'error', stale: e.detail, message: e.message };
    this.event('error', { message: e.message });
    return { kind: 'error', message: e.message };
  }
  runJobs(limit = Infinity) {
    let ran = 0;
    while (ran < limit && (this.microtasks.length || this.timers.length)) {
      let job;
      if (this.microtasks.length) job = this.microtasks.shift();
      else {
        this.timers.sort((a, b) => a.at - b.at || a.seq - b.seq);
        const tm = this.timers.shift(); this.vtime = tm.at; job = { f: tm.f, args: [] };
        this.event('timer', { what: 'fire', at: tm.at });
      }
      ran++; this.metrics.jobs++;
      this.hostRoots.push(job);                   // the running job is the host's: it stays rooted
      try { this.execDepth++; this.callValue(job.f, undefined, job.args); }
      catch (e) {
        const out = this.outcomeOf(e);
        if (out.kind !== 'throw') return { ran, stopped: out };
      } finally { this.execDepth--; this.hostRoots.pop(); }
    }
    return { ran, remaining: this.microtasks.length + this.timers.length };
  }
  result(outcome, extra = {}) {
    this.metrics.steps = this.steps;
    return {
      kind: 'run', mode: this.mode, gc: this.gc, outcome: { ...outcome, display: outcome.value !== undefined ? this.display(outcome.value) : undefined },
      output: this.output.slice(), trace: this.trace.slice(), events: this.events.slice(), steps: this.steps,
      records: this.records, metrics: { ...this.metrics }, ...extra,
      error: outcome.kind === 'error' ? { message: outcome.message, at: outcome.stale ? outcome.stale.at : undefined, stale: outcome.stale } : undefined,
      yamlTag: undefined,
    };
  }
}

function runModule(module, opts = {}) {
  const m = new Machine(module, opts);
  const t0 = now();
  const outcome = m.runMain(opts.entry, opts.args);
  let jobsOut = { ran: 0 };
  if (outcome.kind !== 'diverge' && !(outcome.kind === 'error')) jobsOut = m.runJobs(opts.jobs === undefined ? 10000 : (opts.jobs.n !== undefined ? opts.jobs.n : opts.jobs));
  const final = jobsOut.stopped && jobsOut.stopped.kind !== 'throw' ? jobsOut.stopped : outcome;
  return m.result(final, { ms: round(now() - t0, 2), jobsRun: jobsOut.ran });
}

// Observations: equal up to a renaming of objects that preserves identity, numbers by SameValue.
function observeEqual(a, b, opts = {}) {
  const map = new Map(), back = new Map();
  const same = (x, y, at) => {
    const rx = x && typeof x === 'object' && 'ref' in x, ry = y && typeof y === 'object' && 'ref' in y;
    if (rx || ry) {
      if (!(rx && ry)) return { equal: false, at, left: x, right: y, rule: 'an object against a primitive' };
      if (map.has(x.ref) && map.get(x.ref) !== y.ref) return { equal: false, at, rule: 'identity: one object on the left is two on the right' };
      if (back.has(y.ref) && back.get(y.ref) !== x.ref) return { equal: false, at, rule: 'identity: two objects on the left are one on the right' };
      map.set(x.ref, y.ref); back.set(y.ref, x.ref); return null;
    }
    if (!Object.is(x, y)) {
      const signedZero = typeof x === 'number' && typeof y === 'number' && x === 0 && y === 0;
      return { equal: false, at, left: x, right: y, rule: signedZero ? 'SameValue distinguishes -0 and +0' : 'values differ' };
    }
    return null;
  };
  const ta = a.trace || [], tb = b.trace || [];
  if (a.outcome.kind === 'error' || b.outcome.kind === 'error') return { equal: 'unknown', reason: 'a run stopped with an engine error: ' + (a.error || b.error || {}).message };
  if (a.outcome.kind === 'diverge' || b.outcome.kind === 'diverge') {
    if (a.outcome.kind !== b.outcome.kind) return { equal: 'unknown', reason: 'one run exhausted its step budget; compare under equal budgets' };
  }
  for (let i = 0; i < Math.max(ta.length, tb.length); i++) {
    if (!ta[i] || !tb[i]) return { equal: false, at: `trace[${i}]`, left: ta[i] || 'nothing', right: tb[i] || 'nothing', rule: 'different number of observations' };
    const va = ta[i].values, vb = tb[i].values;
    if (va.length !== vb.length) return { equal: false, at: `trace[${i}]`, rule: 'different arity' };
    for (let j = 0; j < va.length; j++) { const d = same(va[j], vb[j], `trace[${i}] argument ${j}`); if (d) return d; }
  }
  if (a.outcome.kind !== b.outcome.kind) return { equal: false, at: 'outcome', left: a.outcome.kind, right: b.outcome.kind, rule: 'outcomes differ' };
  // An uncaught exception is observed by what it prints as (its kind and message for an error).
  if (a.outcome.kind === 'throw' && a.outcome.display !== undefined && b.outcome.display !== undefined && a.outcome.display !== b.outcome.display)
    return { equal: false, at: 'outcome', left: a.outcome.display, right: b.outcome.display, rule: 'different uncaught values' };
  return { equal: true, observations: ta.length };
}
