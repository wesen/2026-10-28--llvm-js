/* Strata Workbench shell (js/app.js is built from src/shell/*.js by tools/build-shell.js).
   Part 1: base helpers, browser storage, the view registry, the presets store, the host and lab: links. */
(function () {
'use strict';
const W = window;
const C = W.STRATA_CONTENT || (W.STRATA_CONTENT = {});
const MD = W.StrataMarkdown;
const esc = MD.esc;
const S = () => W.strata || null;
const hasEngine = () => !!(W.strata && typeof W.strata.runScript === 'function');

const store = {
  get(k, d) { try { const v = W.localStorage.getItem('strata.v1.' + k); return v == null ? d : JSON.parse(v); } catch (e) { return d; } },
  set(k, v) { try { W.localStorage.setItem('strata.v1.' + k, JSON.stringify(v)); } catch (e) { /* storage unavailable */ } },
  del(k) { try { W.localStorage.removeItem('strata.v1.' + k); } catch (e) { /* storage unavailable */ } },
};
const safe = (fn, fallback) => { try { return fn(); } catch (e) { return typeof fallback === 'function' ? fallback(e) : fallback; } };
const fmtInt = n => (typeof n === 'number' && isFinite(n)) ? Math.round(n).toLocaleString('en-GB') : (n == null ? '—' : String(n));
const plural = (n, w, ws) => `${fmtInt(n)} ${n === 1 ? w : (ws || w + 's')}`;
const debounce = (fn, ms) => { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; };
const escRe = s => String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
/* plan().safepoints may come as a list [{ op: opId, … }] or a map { opId: { op: opName, … } }: views use the list */
const normPlan = p => {
  if (!p || typeof p !== 'object' || !p.safepoints || Array.isArray(p.safepoints)) return p;
  return Object.assign({}, p, { safepoints: Object.keys(p.safepoints).map(id => Object.assign({}, p.safepoints[id], { op: id, opName: p.safepoints[id] && p.safepoints[id].op })) });
};
/* fixed-point steps carry their own number i (from 0 or 1): lab:analysis?i=… names that number */
const stepIndex = (list, i) => { const k = (list || []).findIndex(s => s && s.i === i); return k >= 0 ? k : Math.max(0, Math.min((list || []).length - 1, i)); };

/* ---------- compact YAML (the agent's result format; used when the engine gives none) ---------- */
function yamlLocal(v) {
  const seen = new Set();
  const plain = s => /^[A-Za-z0-9 .,:/()+\-·×→%_]*$/.test(s) && s.length < 120 && s.trim() === s && s !== '' && !/^[-?:,[\]{}#&*!|>'"%@`]/.test(s) && !/^(true|false|null|yes|no|~|\d.*)$/i.test(s);
  const scalar = x => {
    if (x === null) return 'null';
    if (x === undefined) return 'undefined';
    if (typeof x === 'number') return Number.isFinite(x) ? String(Math.round(x * 1e5) / 1e5) : String(x);
    if (typeof x === 'bigint') return x.toString() + 'n';
    if (typeof x === 'boolean') return String(x);
    if (typeof x === 'function') return `[function ${x.name || 'anonymous'}]`;
    if (typeof x === 'string') return plain(x) ? x : (x.includes('\n') ? null : JSON.stringify(x));
    return undefined;
  };
  const lines = [];
  const emit = (x, ind, key) => {
    const pad = '  '.repeat(ind);
    const pre = key == null ? pad : `${pad}${key}:`;
    const s = scalar(x);
    if (s !== undefined && s !== null) { lines.push(key == null ? pad + s : `${pre} ${s}`); return; }
    if (typeof x === 'string') { lines.push(`${pre}${key == null ? '' : ' '}|`); for (const l of x.split('\n')) lines.push(pad + '  ' + l); return; }
    if (seen.has(x)) { lines.push(`${pre}${key == null ? '' : ' '}[circular]`); return; }
    if (ind > 5) { lines.push(`${pre}${key == null ? '' : ' '}${Array.isArray(x) ? `[array ${x.length}]` : '{…}'}`); return; }
    if (x && x.kind && x.id && Object.keys(x).length <= 3 && typeof x.id === 'string') { lines.push(`${pre}${key == null ? '' : ' '}${x.kind} ${x.id}`); return; }
    seen.add(x);
    if (x instanceof Map) x = Object.fromEntries(x);
    else if (x instanceof Set) x = [...x];
    else if (ArrayBuffer.isView(x)) x = Array.from(x);
    if (Array.isArray(x)) {
      if (!x.length) { lines.push(`${pre}${key == null ? '' : ' '}[]`); seen.delete(x); return; }
      if (x.every(e => typeof e === 'number')) { const sh = x.slice(0, 64).map(scalar); lines.push(`${pre}${key == null ? '' : ' '}[${sh.join(', ')}${x.length > 64 ? `, … ${x.length} items` : ''}]`); seen.delete(x); return; }
      if (key != null) lines.push(pre);
      x.slice(0, 60).forEach(e => {
        const s2 = scalar(e);
        if (s2 !== undefined && s2 !== null) lines.push(`${pad}- ${s2}`);
        else { const start = lines.length; emit(e, ind + 1, null); if (lines[start] != null) lines[start] = pad + '- ' + lines[start].trimStart(); }
      });
      if (x.length > 60) lines.push(`${pad}# … ${x.length - 60} more`);
      seen.delete(x); return;
    }
    const keys = Object.keys(x);
    if (!keys.length) { lines.push(`${pre}${key == null ? '' : ' '}{}`); seen.delete(x); return; }
    if (key != null) lines.push(pre);
    keys.slice(0, 80).forEach(k => emit(x[k], key != null ? ind + 1 : ind, k));
    if (keys.length > 80) lines.push(`${pad}# … ${keys.length - 80} more keys`);
    seen.delete(x);
  };
  emit(v, 0, null);
  return lines.join('\n');
}
const yaml = v => { const s = S(); if (s && typeof s.yaml === 'function') { try { return s.yaml(v); } catch (e) { /* fall back */ } } return yamlLocal(v); };
const yaml1 = v => typeof v === 'string' ? v : yaml(v).replace(/\s*\n\s*/g, ' ');

/* ---------- views ---------- */
const VIEWS = {
  notes: { title: 'Notes', about: 'what this preset is about' },
  code: { title: 'Code', about: "the preset's files, editable" },
  agent: { title: 'Agent', about: 'a coding agent with an eval tool' },
  docs: { title: 'Docs', about: 'compiler topics, one each' },
  book: { title: 'Book', about: 'the textbook: Compilers from First Principles' },
  reference: { title: 'Reference', about: 'the API, one page' },
  stage: { title: 'Stage', about: 'the control-flow graph as a drafting sheet' },
  ir: { title: 'IR', about: 'every level of the program as text' },
  facts: { title: 'Facts', about: 'analysis results and fixed-point steps' },
  plan: { title: 'Plan', about: 'root slots, safepoints and unwinding' },
  machine: { title: 'Machine', about: 'the reference interpreter, step by step' },
  events: { title: 'Events', about: 'output, diagnostics and decisions' },
  laws: { title: 'Laws', about: 'properties and counterexamples' },
  experiments: { title: 'Experiments', about: 'design spaces and comparisons' },
};
const VIEW_ORDER = Object.keys(VIEWS);
const GROUPS = { B: 'Basics', S: 'Semantics', I: 'IR', C: 'Contracts', A: 'Analysis', T: 'Transforms', L: 'Lowering', W: 'Backends', E: 'Engine', X: 'Experiments', M: 'Method', J: 'JavaScript scenarios', U: 'Your own' };
const GROUP_ORDER = 'BSICATLWEXMJU'.split('');
const groupOf = p => (p && p.id && GROUPS[p.id[0]]) ? p.id[0] : 'U';
const byId = (a, b) => String(a.id).localeCompare(String(b.id), 'en', { numeric: true });

/* ---------- presets: built-ins from content, your own in the db (collection "presets") or this browser ---------- */
const cleanPreset = (p, id) => ({
  id, title: String(p.title || 'Untitled'), group: GROUPS.U, about: String(p.about || ''),
  tries: Array.isArray(p.tries) ? p.tries.map(String).slice(0, 6) : (typeof p.tries === 'string' ? p.tries.split('|').map(s => s.trim()).filter(Boolean) : []),
  files: Object.assign({}, p.files || {}), notes: String(p.notes || ''), view: Object.assign({}, p.view || {}),
  chapters: Array.isArray(p.chapters) ? p.chapters.slice() : [], docs: Array.isArray(p.docs) ? p.docs.slice() : [],
  from: p.from || null, updated: new Date().toISOString(),
});
const Presets = {
  builtins: [], user: new Map(), db: null, dbState: 'pending',
  init() {
    this.builtins = (Array.isArray(C.presets) ? C.presets : []).slice().sort((a, b) => GROUP_ORDER.indexOf(groupOf(a)) - GROUP_ORDER.indexOf(groupOf(b)) || byId(a, b));
    const local = store.get('presets', {});
    for (const id of Object.keys(local || {})) if (/^U-/.test(id)) this.user.set(id, local[id]);
    const use = W.claude && typeof W.claude.use === 'function' ? W.claude.use.bind(W.claude) : null;
    if (!use) { this.dbState = 'off'; return; }
    Promise.resolve(use('db')).then(db => {
      if (!db) { this.dbState = 'off'; host.emit('presets'); return; }
      this.db = db;
      try {
        this.unsub = db.collection('presets').onSnapshot(snap => {
          const m = new Map();
          for (const d of (snap && snap.docs) || []) { const p = safe(() => d.data(), null); if (p && typeof p === 'object' && /^U-/.test(d.id)) m.set(d.id, JSON.parse(JSON.stringify(Object.assign({}, p, { id: d.id })))); }
          // presets kept only in this browser (from before the store answered) stay listed
          for (const [id, p] of this.user) if (!m.has(id) && p && p.localOnly) m.set(id, p);
          this.user = m; this.dbState = 'on'; host.emit('presets');
        }, err => { this.dbState = 'error'; this.dbError = err && err.code; host.emit('presets'); });
      } catch (e) { this.dbState = 'error'; this.dbError = e.message; host.emit('presets'); }
    }).catch(() => { this.dbState = 'off'; host.emit('presets'); });
  },
  all() { return this.builtins.concat([...this.user.values()].sort(byId)); },
  get(id) { return this.builtins.find(p => p.id === id) || this.user.get(id) || null; },
  isOwn(id) { return /^U-/.test(String(id)) && this.user.has(id); },
  nextId() { let n = 1; const has = k => this.user.has(k) || this.builtins.some(p => p.id === k); while (has('U-' + String(n).padStart(2, '0'))) n++; return 'U-' + String(n).padStart(2, '0'); },
  persistLocal() { const o = {}; for (const [id, p] of this.user) o[id] = p; store.set('presets', o); },
  where() { return this.dbState === 'on' ? 'the shared store' : 'this browser'; },
  async write(doc) {
    this.user.set(doc.id, doc); this.persistLocal();
    if (this.db && this.dbState === 'on') {
      try { await this.db.collection('presets').doc(doc.id).set(JSON.parse(JSON.stringify(doc))); }
      catch (e) { doc.localOnly = true; this.persistLocal(); host.toast(`Saving to the shared store failed (${e.code || e.message}): ${doc.id} is kept in this browser`, true); }
    } else { doc.localOnly = true; this.persistLocal(); }
    host.emit('presets');
  },
  async save(p) { const id = this.nextId(); const doc = cleanPreset(p, id); await this.write(doc); return id; },
  async edit(id, patch) {
    const cur = this.user.get(id);
    if (!cur) throw new Error(this.get(id) ? `${id} is a built-in preset; presets.edit changes your own (U-…) presets. Use presets.save to copy it.` : `no preset ${id}`);
    const next = cleanPreset(Object.assign({}, cur, patch, { files: Object.assign({}, cur.files, (patch && patch.files) || {}) }), id);
    for (const [k, v] of Object.entries((patch && patch.files) || {})) if (v == null) delete next.files[k];
    await this.write(next); return { id, files: Object.keys(next.files) };
  },
  async remove(id) {
    if (!this.user.has(id)) throw new Error(this.get(id) ? `${id} is a built-in preset and cannot be removed` : `no preset ${id}`);
    this.user.delete(id); this.persistLocal();
    if (this.db && this.dbState === 'on') { try { await this.db.collection('presets').doc(id).delete(); } catch (e) { host.toast(`Removing ${id} from the shared store failed (${e.code || e.message})`, true); } }
    host.emit('presets'); return id;
  },
};

/* ---------- the host: everything the views and the agent act on ---------- */
const host = {
  ui: { menu: null, theme: store.get('theme', 'system') },
  preset: null, files: {}, notes: '', base: { files: {}, notes: '' },
  program: null, run: null, laws: null, results: null, other: undefined, hasOther: false, logs: [], buildInfo: null, busy: false, builds: 0,
  fn: null, level: 'L1',
  overlays: new Set(store.get('overlays', ['live', 'safepoints', 'path', 'exceptional', 'stale', 'iteration'])),
  mode: store.get('mode', 'spec'), gc: store.get('gc', 'off'),
  selection: null, analysis: { name: 'liveness', i: null }, machineN: null,
  irLevel: 'L1', irFormat: 'text', irAll: false,
  openFile: 'main.js', codeJump: null,
  docId: null, docAt: null, bookCh: null, bookAt: null,
  listeners: new Set(),
  on(fn) { this.listeners.add(fn); return () => this.listeners.delete(fn); },
  emit(what) { for (const fn of [...this.listeners]) { try { fn(what); } catch (e) { console.error(e); } } },

  toast(msg, bad) {
    let box = document.querySelector('.toasts');
    if (!box) { box = document.createElement('div'); box.className = 'toasts'; document.body.appendChild(box); }
    const t = document.createElement('div'); t.className = 'toast' + (bad ? ' bad' : ''); t.textContent = msg; box.appendChild(t);
    setTimeout(() => t.remove(), bad ? 5200 : 2600);
  },

  /* ---- presets and files ---- */
  loadPreset(id, o) {
    const p = Presets.get(id);
    if (!p) { this.toast(`no preset ${id}`, true); return false; }
    this.preset = p;
    this.base = { files: Object.assign({}, p.files || {}), notes: p.notes || '' };
    const ed = store.get('edits.' + p.id, null);
    this.files = Object.assign({}, this.base.files);
    if (ed && ed.files) for (const [k, v] of Object.entries(ed.files)) { if (v == null) delete this.files[k]; else this.files[k] = v; }
    if (!this.files['main.js']) this.files['main.js'] = '';
    this.notes = ed && typeof ed.notes === 'string' ? ed.notes : this.base.notes;
    const v = p.view || {};
    this.fn = v.fn || null; this.level = v.level || 'L1'; this.irLevel = v.level && /^L[0-3]$|LLVM|WAT/.test(v.level) ? v.level : 'L1';
    if (Array.isArray(v.overlays) && v.overlays.length) this.overlays = new Set(v.overlays);
    if (v.mode) this.mode = v.mode; if (v.gc) this.gc = v.gc;
    this.selection = v.select || null; this.analysis = { name: v.analysis || 'liveness', i: null }; this.machineN = null;
    this.openFile = this.files['program.js'] != null && v.file === 'program.js' ? 'program.js' : (v.file && this.files[v.file] != null ? v.file : 'main.js');
    store.set('preset', p.id);
    this.program = null; this.run = null; this.laws = null; this.results = null; this.other = undefined; this.hasOther = false; this.logs = []; this.buildInfo = null;
    this.emit('preset');
    if (!(o && o.noFocus) && v.tab && VIEWS[v.tab]) this.focus(v.tab, { quiet: true });
    this.build();
    return true;
  },
  isDirty(f) { return (this.files[f] == null ? null : this.files[f]) !== (this.base.files[f] == null ? null : this.base.files[f]); },
  dirtyFiles() { const all = new Set([...Object.keys(this.files), ...Object.keys(this.base.files)]); return [...all].filter(f => this.isDirty(f)); },
  edited() { return this.dirtyFiles().length > 0 || this.notes !== this.base.notes; },
  saveEdits: null, // set below (debounced)
  writeEdits() {
    if (!this.preset) return;
    const files = {};
    for (const f of this.dirtyFiles()) files[f] = this.files[f] == null ? null : this.files[f];
    if (!Object.keys(files).length && this.notes === this.base.notes) store.del('edits.' + this.preset.id);
    else store.set('edits.' + this.preset.id, { files, notes: this.notes !== this.base.notes ? this.notes : null });
  },
  setFile(path, src) {
    path = String(path).replace(/^\.?\//, '');
    if (!path || /\.\.|^\//.test(path)) throw new Error(`bad file name ${path}`);
    this.files[path] = String(src); this.writeEdits(); this.emit('files');
  },
  deleteFile(path) { if (path === 'main.js') throw new Error('main.js cannot be deleted'); delete this.files[path]; this.writeEdits(); if (this.openFile === path) this.openFile = 'main.js'; this.emit('files'); },
  restoreFiles(snap) { this.files = Object.assign({}, snap); this.writeEdits(); this.emit('files'); },
  setNotes(md) { this.notes = String(md); this.writeEdits(); this.emit('notes'); },
  revertAll() { if (!this.preset) return; store.del('edits.' + this.preset.id); this.loadPreset(this.preset.id, { noFocus: true }); this.toast('Back to the preset as published'); },
  async saveAs(title) {
    const p = this.preset || {};
    const id = await Presets.save({ title: title || (p.title ? p.title + ' (copy)' : 'My preset'), about: p.about, tries: p.tries, files: this.files, notes: this.notes, view: Object.assign({}, p.view, { fn: this.fn, level: this.level }), chapters: p.chapters, docs: p.docs, from: p.id });
    if (p.id) store.del('edits.' + p.id);
    this.loadPreset(id, { noFocus: true });
    this.toast(`Saved as ${id} in ${Presets.where()}`);
    return id;
  },
  async saveOwn() {
    if (!this.preset || !Presets.isOwn(this.preset.id)) return;
    const id = this.preset.id;
    await Presets.edit(id, { files: Object.fromEntries(Object.keys(Object.assign({}, this.base.files, this.files)).map(k => [k, this.files[k] == null ? null : this.files[k]])), notes: this.notes, view: Object.assign({}, this.preset.view, { fn: this.fn, level: this.level }) });
    store.del('edits.' + id); this.loadPreset(id, { noFocus: true }); this.toast(`Saved ${id}`);
  },

  /* ---- building and running ---- */
  async build() {
    const myBuild = ++this.builds;
    if (!hasEngine()) { this.buildInfo = { ok: false, message: 'The engine did not load (js/core.js), so main.js cannot run. The reading views still work.' }; this.emit('build'); return this.buildInfo; }
    this.busy = true; this.emit('busy');
    const logs = [];
    const log = (...a) => { logs.push(a.map(yaml1).join(' ')); };
    let res;
    try {
      const scope = S().presetScope(Object.assign({}, this.files), { log });
      res = await S().runScript(this.files['main.js'] || '', scope, { timeoutMs: 25000 });
    } catch (e) { res = { ok: false, ms: 0, logs: [], error: { message: e && e.message || String(e) } }; }
    if (myBuild !== this.builds) return this.buildInfo; // a newer build started
    this.logs = (res.logs || []).concat(logs.filter(l => !(res.logs || []).includes(l)));
    if (!res.ok) {
      const er = res.error || { message: 'main.js failed' };
      this.buildInfo = { ok: false, ms: res.ms, message: er.message, line: er.line, at: er.at };
    } else {
      const c = safe(() => S().classify(res.value), e => ({ other: res.value, _err: e }));
      this.program = c.program || null; this.run = c.run || null; this.laws = c.laws || null; this.results = c.results || c.table || null;
      this.hasOther = 'other' in c && c.other !== undefined; this.other = c.other;
      let kind = [this.program && 'program', c.run && 'run', this.laws && 'laws', this.results && 'results', this.hasOther && 'a value'].filter(Boolean).join(', ') || 'nothing';
      this.buildInfo = { ok: true, ms: res.ms, kind };
      if (this.program && !this.run) this.run = safe(() => this.program.run({ mode: this.mode, gc: this.gc }), e => ({ kind: 'run', mode: this.mode, outcome: { kind: 'error' }, output: [], events: [], records: [], steps: 0, metrics: {}, error: { message: e.message } }));
      const fns = this.program ? safe(() => this.program.functions(), []) : [];
      if (!fns.length) this.fn = null;
      else if (!fns.includes(this.fn)) {
        const want = this.preset && this.preset.view && this.preset.view.fn;
        this.fn = want && fns.includes(want) ? want : fns[0];
      }
    }
    this.busy = false; this.machineN = null;
    this.emit('build');
    return this.buildInfo;
  },
  exec(opts) {
    if (!this.program) { this.toast('No program to run: main.js returned none', true); return null; }
    const o = Object.assign({ mode: this.mode, gc: this.gc }, opts || {});
    this.run = safe(() => this.program.run(o), e => ({ kind: 'run', mode: o.mode, outcome: { kind: 'error' }, output: [], events: [], records: [], steps: 0, metrics: {}, error: { message: e.message } }));
    this.machineN = null; this.emit('run'); return this.run;
  },
  setMode(m) { this.mode = m; store.set('mode', m); if (this.program) this.exec(); else this.emit('run'); },
  setGC(g) { this.gc = g; store.set('gc', g); if (this.program) this.exec(); else this.emit('run'); },
  setFn(name) {
    const fns = this.program ? safe(() => this.program.functions(), []) : [];
    if (this.program && !fns.includes(name)) { this.toast(`no function ${name}`, true); return false; }
    this.fn = name; if (this.selection && !this.selection.startsWith(name + '/')) this.selection = null; this.analysis.i = null; this.emit('fn'); return true;
  },
  setLevel(l) { this.level = /^L[1-3]$/.test(l) ? l : this.level; if (/^(L[0-3]|LLVM|WAT)$/.test(l)) this.irLevel = l; this.emit('level'); },
  toggleOverlay(name, on) {
    const known = (W.StrataStage && W.StrataStage.OVERLAYS || []).some(o => o.name === name);
    if (!known) { this.toast(`no overlay ${name}`, true); return false; }
    const want = on == null ? !this.overlays.has(name) : !!on;
    if (want) this.overlays.add(name); else this.overlays.delete(name);
    store.set('overlays', [...this.overlays]); this.emit('overlays'); return want;
  },
  select(id) {
    if (!id) { this.selection = null; this.emit('select'); return; }
    id = String(id); const fn = id.split('/')[0];
    if (this.program && fn && fn !== this.fn) { if (!this.setFn(fn)) return; }
    this.selection = id; this.emit('select');
  },
  diagList() {
    const out = [];
    if (this.buildInfo && !this.buildInfo.ok && this.buildInfo.message) out.push({ severity: 'error', kind: 'script', message: this.buildInfo.message, at: { file: 'main.js', line: this.buildInfo.line } });
    if (this.program) for (const d of safe(() => this.program.diagnostics || [], [])) out.push(d);
    return out;
  },
  steps() {
    if (!this.program || this.analysis.i == null) return null;
    const list = safe(() => this.program.steps(this.fn, this.analysis.name), []);
    return list[this.analysis.i] || null;
  },

  /* ---- views ---- */
  focus(view, o) { if (!VIEWS[view]) { this.toast(`no view ${view}`, true); return false; } Dock.focusView(view, o); return true; },
  openFile_(file, at) {
    if (this.files[file] == null) { this.toast(`no file ${file}`, true); return false; }
    this.openFile = file;
    let line = at && at.line ? +at.line : null;
    if (!line && at && at.find) { const i = this.files[file].indexOf(at.find); line = i < 0 ? 1 : this.files[file].slice(0, i).split('\n').length; }
    this.codeJump = { file, line: line || 1 };
    this.focus('code'); this.emit('open'); return true;
  },
  openBook(ch, at) {
    const b = C.book; const chs = (b && b.chapters) || [];
    const c = chs.find(x => String(x.n) === String(ch));
    if (!c) { this.toast(`no chapter ${ch}`, true); return false; }
    this.bookCh = String(c.n); this.bookAt = at || null; this.focus('book'); this.emit('book'); return true;
  },
  openDoc(id, at) {
    const d = (C.docs || []).find(x => x.id === id);
    if (!d) { this.toast(`no doc ${id}`, true); return false; }
    this.docId = id; this.docAt = at || null; this.focus('docs'); this.emit('doc'); return true;
  },

  /* ---- lab: links ---- */
  link(href) {
    let u; const raw = String(href || '');
    try { u = new URL(raw.replace(/^lab:/, 'lab://x/')); } catch (e) { this.toast('unknown lab link ' + raw, true); return false; }
    const a = u.pathname.replace(/^\/+/, ''); const q = {}; u.searchParams.forEach((v, k) => { q[k] = v; });
    const flag = v => v == null ? null : !(v === '0' || v === 'false' || v === 'off');
    switch (a) {
      case 'preset': return this.loadPreset(q.id);
      case 'book': return this.openBook(q.ch, q.at);
      case 'doc': return this.openDoc(q.id, q.at);
      case 'open': return this.openFile_(q.file, { line: q.line, find: q.find });
      case 'fn': if (this.setFn(q.name)) { this.focus('stage'); return true; } return false;
      case 'node': case 'select': this.select(q.id); this.focus(q.in === 'ir' ? 'ir' : 'stage'); return true;
      case 'level': this.setLevel(q.l || q.level); if (/LLVM|WAT|L0/.test(q.l || '')) this.focus('ir'); return true;
      case 'overlay': this.toggleOverlay(q.name, flag(q.on)); this.focus('stage', { quiet: true }); return true;
      case 'run': if (q.mode) { this.mode = q.mode; store.set('mode', q.mode); } if (q.gc) { this.gc = q.gc; store.set('gc', q.gc); } this.exec(); this.focus('machine'); return true;
      case 'step': this.machineN = q.n == null ? null : +q.n; this.focus('machine'); this.emit('step'); return true;
      case 'analysis': { const name = q.name || 'liveness'; let i = null; if (q.i != null && this.program && this.fn) { const list = safe(() => this.program.steps(this.fn, name), []); i = list.length ? stepIndex(list, +q.i) : null; } this.analysis = { name, i }; this.focus('facts'); this.emit('analysis'); return true; }
      case 'law': this.focus('laws'); this.build(); return true;
      case 'exp': this.focus('experiments'); this.build(); return true;
      case 'show': case 'tile': return this.focus(q.view);
      case 'build': this.build(); return true;
      case 'ask': this.focus('agent'); if (W.StrataAgent && W.StrataAgent.prefill) W.StrataAgent.prefill(q.q || ''); return true;
      default: this.toast('unknown lab link ' + raw, true); return false;
    }
  },

  /* ---- the agent's eval scope ---- */
  labScope(o) {
    const H = this, readOnly = !!(o && o.readOnly);
    const off = name => () => { throw new Error(`read-only mode: ${name}() is off`); };
    const P = () => { if (!H.program) throw new Error('no program: main.js returned none. Call run() and read diagnostics()'); return H.program; };
    const files = {
      list: () => Object.keys(H.files).sort().map(p => ({ path: p, lines: H.files[p].split('\n').length, edited: H.isDirty(p) })),
      read: (path, from, to) => {
        const s = H.files[path]; if (s == null) throw new Error(`no file ${path}`);
        if (from == null) return s;
        const L = s.split('\n'), a = Math.max(1, from | 0), b = to == null ? a + 39 : Math.min(L.length, to | 0);
        return L.slice(a - 1, b).map((l, i) => `${a + i}  ${l}`).join('\n');
      },
      grep: (pattern, path) => {
        const re = pattern instanceof RegExp ? pattern : new RegExp(escRe(pattern));
        const out = [];
        for (const f of Object.keys(H.files).sort()) {
          if (path && f !== path) continue;
          H.files[f].split('\n').forEach((l, i) => { if (out.length < 80 && re.test(l)) out.push(`${f}:${i + 1}  ${l.trim().slice(0, 160)}`); });
        }
        return out;
      },
      edit: (path, find, replace) => {
        const s = H.files[path]; if (s == null) throw new Error(`edit: no file ${path}`);
        const n = find ? s.split(find).length - 1 : 0;
        if (!n) throw new Error(`edit: text not found in ${path} (it must match exactly, including spaces)`);
        if (n > 1) throw new Error(`edit: text occurs ${n} times in ${path}; add context until it is unique`);
        const i = s.indexOf(find);
        H.setFile(path, s.slice(0, i) + replace + s.slice(i + find.length));
        return { path, line: s.slice(0, i).split('\n').length };
      },
      write: (path, src) => { H.setFile(path, String(src)); return { path, lines: String(src).split('\n').length }; },
    };
    if (readOnly) { files.edit = () => { throw new Error('read-only mode: files.edit is off'); }; files.write = () => { throw new Error('read-only mode: files.write is off'); }; }
    const runSummary = r => r && ({
      mode: r.mode, outcome: r.outcome && (r.outcome.kind + (r.outcome.value !== undefined ? ' ' + yaml1(r.outcome.value) : '')),
      output: (r.output || []).slice(0, 20), steps: r.steps, metrics: r.metrics,
      stale: (r.events || []).filter(e => e.type === 'stale').slice(0, 5), error: r.error,
    });
    const B = C.book || { chapters: [] };
    const presets = {
      list: () => Presets.all().map(p => ({ id: p.id, title: p.title, group: p.group || GROUPS[groupOf(p)], about: p.about, own: Presets.isOwn(p.id) })),
      get: id => { const p = Presets.get(id); if (!p) throw new Error(`no preset ${id}`); return JSON.parse(JSON.stringify(p)); },
      save: async p => { if (!p || typeof p !== 'object') throw new Error('presets.save({ title, about, files, notes, tries? }) needs an object'); if (!p.files || !p.files['main.js']) throw new Error("presets.save: files['main.js'] is required"); const id = await Presets.save(p); return { id, where: Presets.where() }; },
      edit: async (id, patch) => Presets.edit(id, patch || {}),
      remove: async id => Presets.remove(id),
      load: id => { if (!H.loadPreset(id)) throw new Error(`no preset ${id}`); return id; },
    };
    if (readOnly) { presets.save = off('presets.save'); presets.edit = off('presets.edit'); presets.remove = off('presets.remove'); }
    const scope = {
      files,
      run: readOnly ? off('run') : async () => { const b = await H.build(); return { ok: !!b.ok, ms: b.ms, kind: b.kind || null, errors: b.ok ? [] : [{ message: b.message, at: 'main.js' + (b.line ? ':' + b.line : '') }] }; },
      program: () => H.program,
      ir: (level = 'L1', fn = H.fn) => P().ir(level, { fn }),
      cfg: (fn = H.fn, level) => P().cfg(fn, level),
      facts: (fn = H.fn) => P().facts(fn),
      steps: (fn = H.fn, analysis = 'liveness') => P().steps(fn, analysis),
      plan: (fn = H.fn) => P().plan(fn),
      perm: id => P().perm(id),
      why: t => P().why(t),
      diagnostics: () => H.diagList(),
      exec: (opts = {}) => runSummary(H.exec(opts)),
      g: S() && S().g, strata: S(), t: S() && S().g && S().g.t,
      compile: (src, pipeline) => { const g = S().g; return g.compile(pipeline || g.pipeline(), typeof src === 'string' ? g.source.text(src, { name: 'agent.js' }) : src); },
      presets,
      notes: () => H.notes,
      setNotes: readOnly ? off('setNotes') : md => { H.setNotes(String(md)); return H.notes.length; },
      doc: id => { const d = (C.docs || []).find(x => x.id === id); if (!d) throw new Error(`no doc ${id}`); return d.md; },
      book: {
        contents: () => (B.chapters || []).map(c => ({ n: c.n, part: c.part, title: c.title, about: c.about, written: !!(c.md && c.md.trim()) })),
        chapter: n => { const c = (B.chapters || []).find(x => String(x.n) === String(n)); if (!c) throw new Error(`no chapter ${n}`); return c.md; },
        search: text => { const t = String(text).toLowerCase(); return (B.chapters || []).map(c => ({ n: c.n, title: c.title, hits: (MD.plainText(c.md).toLowerCase().split(t).length - 1) })).filter(x => x.hits); },
        open: (n, at) => H.link('lab:book?ch=' + n + (at ? '&at=' + at : '')),
      },
      link: href => H.link(href),
      select: id => { H.select(id); return id; },
      show: v => H.focus(v),
      overlay: (name, on = true) => { H.toggleOverlay(name, on); return [...H.overlays]; },
    };
    const ps = safe(() => S().presetScope(Object.assign({}, H.files), {}), {});
    for (const k of ['bytes', 'kib', 'mib', 'slots', 'jobs', 'ms', 'count']) if (ps && ps[k]) scope[k] = ps[k];
    return scope;
  },

  /* ---- the agent's context block ---- */
  context() {
    const p = this.preset || {}, lines = [`preset: ${p.id || '—'} ${p.title || ''} (${p.group || GROUPS[groupOf(p)] || ''}) — ${p.about || ''}`];
    const bi = this.buildInfo;
    if (!bi) lines.push('build: none');
    else if (bi.ok) {
      let what = bi.kind;
      if (this.program) { const sm = safe(() => this.program.summary(), null); const c = sm && sm.counts; if (c) what += `: ${plural(c.functions, 'function')}, ${plural(c.blocks, 'block')}, ${plural(c.ops, 'op')}`; }
      lines.push(`build: ok (returned ${what})`);
    } else lines.push(`build: FAILS — ${bi.message}${bi.line ? ' at main.js:' + bi.line : ''}`);
    const r = this.run;
    if (r) lines.push(`run: ${r.mode || this.mode} · gc ${this.gc} · ${r.outcome ? r.outcome.kind + (r.outcome.value !== undefined ? ' ' + yaml1(r.outcome.value).slice(0, 60) : '') : '—'} · ${fmtInt(r.steps)} steps · ${fmtInt((r.metrics || {}).collections || 0)} collections`);
    lines.push('files: ' + Object.keys(this.files).sort().map(f => f + (this.isDirty(f) ? '*' : '')).join(', ') + ' (* edited)');
    if (this.program) lines.push(`view: function ${this.fn || '—'}, level ${this.level}, overlays ${[...this.overlays].join(', ') || 'none'}`);
    if (this.selection) lines.push('selected: ' + this.selection);
    const ds = this.diagList().filter(d => d.severity !== 'info');
    if (ds.length) lines.push('diagnostics:\n' + ds.slice(0, 8).map(d => `  ${d.severity} ${d.at && d.at.file ? d.at.file + (d.at.line ? ':' + d.at.line : '') : d.at && d.at.fn ? `${d.at.fn}${d.at.block ? '/' + d.at.block : ''}${d.at.op != null ? '/' + d.at.op : ''}` : ''} ${d.message}`).join('\n'));
    if (this.laws && Array.isArray(this.laws.laws)) { const L = this.laws.laws; const bad = L.filter(l => !l.ok); lines.push(`laws: ${L.length - bad.length} ok, ${bad.length} failed${bad.length ? ' (' + bad.map(l => l.name).slice(0, 4).join(', ') + ')' : ''}`); }
    if (this.results) lines.push(`results: ${this.results.title || 'a table'} (${(this.results.rows || []).length} rows)`);
    return '[context]\n' + lines.join('\n') + '\n[/context]';
  },
};
host.saveEdits = debounce(() => host.writeEdits(), 250);
W.StrataHost = host;
