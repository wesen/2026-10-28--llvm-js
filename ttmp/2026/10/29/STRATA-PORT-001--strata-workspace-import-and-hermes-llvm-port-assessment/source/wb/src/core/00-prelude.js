// core.js: the Strata engine.
// A small compiler framework for a JavaScript subset, built to be read: a reference
// interpreter that defines meaning, a core IR, operation contracts, one fixed-point
// solver, rewrites, lowering with root plans, and two backends (LLVM IR text and
// WebAssembly). Everything is plain JavaScript and runs in a browser or in Node.
(function (root) {
'use strict';

const VERSION = '0.1.0';

// ---------------------------------------------------------------- small helpers

function hashString(text) {                       // FNV-1a, 32 bits, as 8 hex digits
  let h = 0x811c9dc5;
  for (let i = 0; i < text.length; i++) { h ^= text.charCodeAt(i); h = Math.imul(h, 0x01000193) >>> 0; }
  return h.toString(16).padStart(8, '0');
}

function stable(value) {                          // JSON with sorted keys, for hashing
  if (value === undefined) return 'undefined';
  if (value === null || typeof value !== 'object') return JSON.stringify(value);
  if (Array.isArray(value)) return '[' + value.map(stable).join(',') + ']';
  if (typeof value.toJSON === 'function') return stable(value.toJSON());
  return '{' + Object.keys(value).sort().map(k => JSON.stringify(k) + ':' + stable(value[k])).join(',') + '}';
}

function rng(seed = 1) {                          // mulberry32: deterministic samples
  let a = seed >>> 0;
  const next = () => {
    a = (a + 0x6D2B79F5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  next.int = (lo, hi) => lo + Math.floor(next() * (hi - lo + 1));
  next.pick = list => list[Math.floor(next() * list.length)];
  next.chance = p => next() < p;
  return next;
}

const now = () => (typeof performance !== 'undefined' ? performance.now() : Date.now());
const round = (x, d = 3) => Math.round(x * 10 ** d) / 10 ** d;

class StrataError extends Error {
  constructor(message, detail = {}) { super(message); this.name = 'StrataError'; Object.assign(this, detail); }
}

// ---------------------------------------------------------------- YAML (the agent reads this)

const PLAIN = /^[A-Za-z0-9 .,:/()+\-·×→%_@<>=*|[\]#'?!]*$/;

function yamlScalar(v) {
  if (v === null) return 'null';
  if (v === undefined) return 'undefined';
  if (typeof v === 'number') {
    if (Number.isNaN(v)) return 'NaN';
    if (!Number.isFinite(v)) return v > 0 ? 'Infinity' : '-Infinity';
    if (Object.is(v, -0)) return '-0';
    return String(Math.round(v * 1e5) / 1e5);
  }
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'bigint') return v + 'n';
  if (typeof v === 'function') return `[function ${v.name || 'anonymous'}]`;
  if (typeof v === 'string') {
    if (v.includes('\n')) return null;           // caller writes a block
    if (v.length < 120 && PLAIN.test(v) && v.trim() === v && v !== '' &&
        !/^(true|false|null|undefined|NaN|-?\d)/.test(v) && !/: /.test(v) && !v.startsWith('- ')) return v;
    return JSON.stringify(v);
  }
  return undefined;
}

function yaml(value, indent = '', depth = 0, seen = new Set()) {
  const s = yamlScalar(value);
  if (s !== undefined && s !== null) return s;
  if (typeof value === 'string') {
    return '|\n' + value.split('\n').map(line => indent + '  ' + line).join('\n');
  }
  if (value && typeof value.yamlTag === 'function') return value.yamlTag();
  if (seen.has(value)) return '[circular]';
  if (depth > 5) return Array.isArray(value) ? `[array ${value.length}]` : '{…}';
  seen = new Set(seen); seen.add(value);
  if (value instanceof Map) value = Object.fromEntries(value);
  if (value instanceof Set) value = [...value];
  if (ArrayBuffer.isView(value)) value = Array.from(value);
  if (Array.isArray(value)) {
    if (value.length === 0) return '[]';
    if (value.every(x => typeof x === 'number')) {
      const shown = value.slice(0, 64).map(yamlScalar).join(', ');
      return '[' + shown + (value.length > 64 ? `, … ${value.length - 64} items` : '') + ']';
    }
    const out = value.slice(0, 60).map(item => {
      const body = yaml(item, indent + '  ', depth + 1, seen);
      if (item && typeof item === 'object' && !Array.isArray(item) && !(item.yamlTag) && body.includes('\n')) {
        return indent + '- ' + body.trimStart();
      }
      return indent + '- ' + body;
    });
    if (value.length > 60) out.push(indent + `# … ${value.length - 60} more`);
    return '\n' + out.join('\n');
  }
  if (typeof value === 'object') {
    if (typeof value.toYAML === 'function') return yaml(value.toYAML(), indent, depth, seen);
    const keys = Object.keys(value).filter(k => value[k] !== undefined && typeof value[k] !== 'function');
    if (keys.length === 0) return '{}';
    const out = keys.slice(0, 80).map(k => {
      const body = yaml(value[k], indent + '  ', depth + 1, seen);
      const key = /^[A-Za-z_$][\w$\-/.]*$/.test(k) ? k : JSON.stringify(k);
      return indent + key + ':' + (body.startsWith('\n') ? body : ' ' + body);
    });
    if (keys.length > 80) out.push(indent + `# … ${keys.length - 80} more keys`);
    return (depth === 0 ? '' : '\n') + out.join('\n');
  }
  return String(value);
}

function toYAML(value) {
  const text = yaml(value);
  return text.startsWith('\n') ? text.slice(1) : text;
}

// ---------------------------------------------------------------- quantities with units

class DimensionError extends Error {
  constructor(message) { super(message); this.name = 'DimensionError'; }
}

class Quantity {
  constructor(n, unit) { this.n = n; this.unit = unit; Object.freeze(this); }
  same(q, verb) {
    if (!(q instanceof Quantity)) throw new DimensionError(`cannot ${verb} a plain number and ${this.unit}; give it a unit`);
    if (q.unit !== this.unit) throw new DimensionError(`cannot ${verb} ${q.unit} and ${this.unit}; convert through a layout`);
    return q.n;
  }
  add(q) { return new Quantity(this.n + this.same(q, 'add'), this.unit); }
  sub(q) { return new Quantity(this.n - this.same(q, 'subtract'), this.unit); }
  mul(k) {
    if (k instanceof Quantity) throw new DimensionError(`cannot multiply ${this.unit} by ${k.unit}`);
    return new Quantity(this.n * k, this.unit);
  }
  div(k) { return k instanceof Quantity ? this.n / this.same(k, 'divide') : new Quantity(this.n / k, this.unit); }
  lt(q) { return this.n < this.same(q, 'compare'); }
  le(q) { return this.n <= this.same(q, 'compare'); }
  gt(q) { return this.n > this.same(q, 'compare'); }
  ge(q) { return this.n >= this.same(q, 'compare'); }
  eq(q) { return this.n === this.same(q, 'compare'); }
  max(q) { return this.n >= this.same(q, 'compare') ? this : q; }
  min(q) { return this.n <= this.same(q, 'compare') ? this : q; }
  toString() {
    if (this.unit === 'B') {
      if (this.n !== 0 && this.n % 1048576 === 0) return `${this.n / 1048576} MiB`;
      if (this.n !== 0 && this.n % 1024 === 0) return `${this.n / 1024} KiB`;
      return `${round(this.n, 2)} B`;
    }
    if (this.unit === 'count') return String(this.n);
    const singular = { slots: 'slot', jobs: 'job' }[this.unit];
    return `${round(this.n, 3)} ${this.n === 1 && singular ? singular : this.unit}`;
  }
  toJSON() { return this.toString(); }
  yamlTag() { return this.toString(); }
}

const bytes = n => new Quantity(n, 'B');
const kib = n => bytes(n * 1024);
const mib = n => bytes(n * 1048576);
const slots = n => new Quantity(n, 'slots');
const jobs = n => new Quantity(n, 'jobs');
const ms = n => new Quantity(n, 'ms');
const count = n => new Quantity(n, 'count');
for (const [name, f] of Object.entries({ bytes, slots, jobs, ms, count })) f.unit = f(0).unit, f.unitName = name;

const layout = {
  host64: {
    name: 'host64', slotBytes: 8, align: 16,
    bytes(q) { if (q.unit !== 'slots') throw new DimensionError('layout.bytes takes slots'); return bytes(q.n * 8); },
    slots(q) { if (q.unit !== 'B') throw new DimensionError('layout.slots takes bytes'); return slots(Math.ceil(q.n / 8)); },
  },
};

// ---------------------------------------------------------------- the type lattice
// A type is a set of value kinds. Join is union, meet is intersection, le is inclusion.

const KINDS = ['undefined', 'null', 'boolean', 'int32', 'double', 'string', 'object', 'function', 'cell', 'completion'];
const KBIT = Object.fromEntries(KINDS.map((k, i) => [k, 1 << i]));
const NAMED = {
  bottom: 0, undefined: KBIT.undefined, null: KBIT.null, boolean: KBIT.boolean, int32: KBIT.int32,
  number: KBIT.int32 | KBIT.double, string: KBIT.string, object: KBIT.object, function: KBIT.function,
  cell: KBIT.cell, completion: KBIT.completion,
};
NAMED.any = NAMED.undefined | NAMED.null | NAMED.boolean | NAMED.number | NAMED.string | NAMED.object | NAMED.function;
NAMED.top = NAMED.any | NAMED.cell | NAMED.completion;
NAMED.propertyKey = NAMED.string | NAMED.number;
const MANAGED = KBIT.object | KBIT.function | KBIT.cell | KBIT.completion;

const typeCache = new Map();
class Type {
  constructor(bits) { this.bits = bits; Object.freeze(this); }
  static of(bits) { if (!typeCache.has(bits)) typeCache.set(bits, new Type(bits)); return typeCache.get(bits); }
  join(o) { return Type.of(this.bits | o.bits); }
  meet(o) { return Type.of(this.bits & o.bits); }
  minus(o) { return Type.of(this.bits & ~o.bits); }
  le(o) { return (this.bits & ~o.bits) === 0; }
  eq(o) { return this.bits === o.bits; }
  has(kind) { return (this.bits & KBIT[kind]) !== 0; }
  get managed() { return (this.bits & MANAGED) !== 0; }
  get isBottom() { return this.bits === 0; }
  toString() {
    for (const name of ['bottom', 'any', 'top', 'number']) if (NAMED[name] === this.bits) return name;
    const parts = [];
    let rest = this.bits;
    if ((rest & NAMED.number) === NAMED.number) { parts.push('number'); rest &= ~NAMED.number; }
    for (const k of KINDS) if (rest & KBIT[k]) parts.push(k);
    return parts.join('|');
  }
  toJSON() { return this.toString(); }
  yamlTag() { return this.toString(); }
}

const t = {};
for (const [name, bits] of Object.entries(NAMED)) t[name] = Type.of(bits);
t.union = (...types) => types.reduce((a, b) => a.join(b), t.bottom);
t.parse = text => {
  const parts = String(text).split('|').map(s => s.trim());
  return t.union(...parts.map(p => {
    if (!(p in NAMED)) throw new StrataError(`unknown type ${p}`);
    return t[p];
  }));
};
t.ofValue = v => {                                // the kind of one runtime value
  if (v === undefined) return t.undefined;
  if (v === null) return t.null;
  if (typeof v === 'boolean') return t.boolean;
  if (typeof v === 'number') return (Object.is(v, -0) || (v | 0) !== v) ? Type.of(KBIT.double) : t.int32;
  if (typeof v === 'string') return t.string;
  if (v && v.isRef) return v.kindType || t.object;
  return t.any;
};
t.double = Type.of(KBIT.double);
t.all = () => Object.keys(NAMED).map(n => t[n]);

// Representations: how a value of a type is stored after lowering.
const rep = {
  tagged: { name: 'tagged', canHold: () => true, bits: 64 },
  f64: { name: 'f64', canHold: ty => ty.le(t.number), bits: 64 },
  i32: { name: 'i32', canHold: ty => ty.le(t.int32), bits: 32 },
  bool: { name: 'bool', canHold: ty => ty.le(t.boolean), bits: 32 },
};
for (const r of Object.values(rep)) { r.toString = () => r.name; r.toJSON = () => r.name; }
