
// ---------------------------------------------------------------- behaviour summaries
// A behaviour is an upper bound on what an operation may do. Join is the union of what
// two operations may do, so it is associative, commutative and idempotent, with `none`
// as the unit and `unknown` as the top.

const USER_RESOURCES = ['heap', 'cells', 'jobs', 'timers', 'globals'];
const ALL_RESOURCES = [...USER_RESOURCES, 'engine'];

class Behaviour {
  constructor({ reads = [], writes = [], fresh = false, throws = false, diverges = false, callsUser = false, host = [] } = {}) {
    this.reads = new Set(reads); this.writes = new Set(writes);
    this.fresh = fresh; this.throws = throws; this.diverges = diverges; this.callsUser = callsUser;
    this.host = new Set(host);
    if (callsUser) {                              // user code may touch every user-visible resource
      for (const r of USER_RESOURCES) { this.reads.add(r); this.writes.add(r); }
      this.fresh = this.throws = this.diverges = true; this.host.add('*');
    }
    Object.freeze(this);
  }
  join(o) {
    return new Behaviour({
      reads: [...this.reads, ...o.reads], writes: [...this.writes, ...o.writes],
      fresh: this.fresh || o.fresh, throws: this.throws || o.throws, diverges: this.diverges || o.diverges,
      callsUser: this.callsUser || o.callsUser, host: [...this.host, ...o.host],
    });
  }
  le(o) {
    const sub = (a, b) => [...a].every(x => b.has(x) || b.has('*'));
    return sub(this.reads, o.reads) && sub(this.writes, o.writes) && sub(this.host, o.host) &&
      (!this.fresh || o.fresh) && (!this.throws || o.throws) && (!this.diverges || o.diverges) &&
      (!this.callsUser || o.callsUser);
  }
  eq(o) { return this.le(o) && o.le(this); }
  has(flag) { return !!this[flag] && (typeof this[flag] !== 'object' || this[flag].size > 0); }
  get isNone() { return this.le(fx.none); }
  get isUnknown() { return this.writes.has('engine'); }
  expand() { return this; }
  toString() {
    if (this.isNone) return 'none';
    if (this.isUnknown) return 'unknown';
    if (this.callsUser) return 'callsUser' + (this.writes.has('engine') ? ', engine' : '');
    const parts = [];
    const rw = [...this.writes].filter(r => !this.reads.has(r));
    const both = [...this.writes].filter(r => this.reads.has(r));
    const ro = [...this.reads].filter(r => !this.writes.has(r));
    if (ro.length) parts.push(`reads(${ro.join(', ')})`);
    if (both.length) parts.push(`reads+writes(${both.join(', ')})`);
    if (rw.length) parts.push(`writes(${rw.join(', ')})`);
    if (this.fresh) parts.push('fresh');
    if (this.throws) parts.push('throws');
    if (this.diverges) parts.push('diverges');
    if (this.host.size) parts.push(`host(${[...this.host].join(', ')})`);
    return parts.join(', ');
  }
  toJSON() { return this.toString(); }
  yamlTag() { return this.toString(); }
}

const fx = {
  none: new Behaviour(),
  reads: (...r) => new Behaviour({ reads: r }),
  writes: (...r) => new Behaviour({ reads: r, writes: r }),
  fresh: new Behaviour({ fresh: true }),
  throws: new Behaviour({ throws: true }),
  diverges: new Behaviour({ diverges: true }),
  callsUser: new Behaviour({ callsUser: true }),
  host: name => new Behaviour({ host: [name] }),
  unknown: new Behaviour({ callsUser: true, reads: ['engine'], writes: ['engine'] }),
  join: (...bs) => bs.reduce((a, b) => a.join(b), new Behaviour()),
  resources: ALL_RESOURCES,
};
fx.of = ops => fx.join(...[...ops].map(o => (o.contract ? o.contract.behaviour : o.behaviour || fx.none)));

// ---------------------------------------------------------------- runtime obligations
// What lowering must guarantee around an operation. A collecting operation borrows its
// managed operands: they must be in root slots while the helper runs.

const OBLIGATIONS = ['mayCollect', 'nonlocalThrow', 'writeBarrier', 'protectsResult', 'sharesBindingCells'];
class Obligations {
  constructor(flags = []) { this.flags = new Set(flags); Object.freeze(this); }
  join(o) { return new Obligations([...this.flags, ...o.flags]); }
  has(flag) { return this.flags.has(flag); }
  le(o) { return [...this.flags].every(f => o.flags.has(f)); }
  toString() { return this.flags.size ? [...this.flags].join(', ') : 'none'; }
  toJSON() { return this.toString(); }
  yamlTag() { return this.toString(); }
}
const ob = { none: new Obligations(), join: (...os) => os.reduce((a, b) => a.join(b), new Obligations()) };
for (const f of OBLIGATIONS) ob[f] = new Obligations([f]);
ob.needsHost = cap => new Obligations(['needsHost:' + cap]);

// ---------------------------------------------------------------- derived permissions
// Permissions answer: may a transformation erase, merge, move, duplicate, hoist or
// speculate this operation? They are derived from the behaviour, never declared.
// Each answer is true, false, or a condition string, with the reasons behind it.

const PERMS = ['erase', 'merge', 'move', 'duplicate', 'hoist', 'speculate'];

function derivePermissions(behaviour, facts = {}) {
  const b = behaviour, out = {}, because = {};
  const blockers = [];
  if (b.callsUser) blockers.push('may run user code');
  if (b.throws) blockers.push('may throw');
  if (b.diverges) blockers.push('may diverge');
  const writes = [...b.writes].filter(r => r !== 'engine' || b.isUnknown);
  if (writes.length) blockers.push(`writes ${writes.join(', ')}`);
  if (b.host.size) blockers.push('talks to the host');
  if (b.isUnknown) blockers.unshift('behaviour unknown');
  const reads = [...b.reads];
  const quiet = blockers.length === 0;           // total, silent, no observable writes

  // erase: only an operation whose result is unused and whose effects are unobservable
  if (quiet && (!b.fresh || facts.identityObserved === false)) out.erase = true;
  else if (quiet && b.fresh) out.erase = 'if its new identity is never observed';
  else out.erase = false;
  because.erase = out.erase === true
    ? ['no writes, no throw, no divergence, no user code' + (b.fresh ? '; the new identity is unobserved' : '')]
    : blockers.length ? blockers.slice() : ['creates a fresh identity'];

  // merge: two evaluations give the same value only without fresh identity
  if (quiet && !b.fresh && reads.length === 0) out.merge = true;
  else if (quiet && !b.fresh) out.merge = `if nothing writes ${reads.join(', ')} between them`;
  else out.merge = false;
  because.merge = out.merge === false ? (b.fresh ? ['creates a fresh identity', ...blockers] : blockers.slice()) : ['deterministic and silent'];

  // move: reorder with neighbours
  if (b.callsUser || b.isUnknown || b.host.size) out.move = false;
  else if (b.throws) out.move = 'not across other operations that throw or write';
  else if (writes.length) out.move = `not across operations that read or write ${writes.join(', ')}`;
  else if (reads.length) out.move = `not across operations that write ${reads.join(', ')}`;
  else out.move = true;
  because.move = out.move === true ? ['no reads, no writes, no throw'] : (out.move === false ? blockers.slice() : [String(out.move)]);

  // duplicate: run it twice where it ran once (e.g. in both arms of a split)
  out.duplicate = quiet && !b.fresh ? true : false;
  because.duplicate = out.duplicate ? ['silent and without fresh identity'] : (b.fresh ? ['creates a fresh identity', ...blockers] : blockers.slice());

  // speculate: run it where it would not have run
  out.speculate = quiet ? (reads.length && !facts.total ? 'with the facts that make it total' : true) : false;
  because.speculate = out.speculate === false ? blockers.slice() : ['cannot throw, diverge or write'];

  // hoist: speculate it out of a loop, keeping one evaluation for all iterations
  if (!quiet || b.fresh) out.hoist = false;
  else if (reads.length) out.hoist = `if nothing in the loop writes ${reads.join(', ')}`;
  else out.hoist = true;
  because.hoist = out.hoist === false ? (b.fresh ? ['creates a fresh identity', ...blockers] : blockers.slice()) : ['loop-invariant when its operands are'];

  return { ...out, because };
}

const PERM_RANK = v => (v === true ? 2 : v === false ? 0 : 1);
