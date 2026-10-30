// frontend.js: a JavaScript subset to the core IR.
// Parsing is acorn's. This file resolves every name to its declaration, gives every
// variable a cell, turns each function into an IR function whose first parameters are
// the cells it captures, and lowers control flow (if, loops, logical operators,
// try/catch/finally) to blocks and edges. The promote-cells pass later turns the cells
// that nothing captures into SSA values.
(function (root) {
'use strict';
const strata = root.strata || (typeof module !== 'undefined' && require('./core.js'));
const acornLib = root.acorn || (typeof require !== 'undefined' ? (() => { try { return require('acorn'); } catch (e) { return null; } })() : null);
const { lit, Fn, Module, t, StrataError } = strata.internals;

class Unsupported extends StrataError {
  constructor(message, node) { super(message, { kind: 'unsupported', loc: node && node.loc ? { line: node.loc.start.line, col: node.loc.start.column + 1 } : null }); }
}

// ---------------------------------------------------------------- scopes
// A scope holds declarations. Function scopes hold var, parameters and `this`; block
// scopes hold let, const and function declarations. Resolution walks outward.

class Scope {
  constructor(kind, parent, fnScope) {
    this.kind = kind; this.parent = parent; this.fnScope = kind === 'function' ? this : fnScope;
    this.decls = new Map();
    this.strict = parent ? parent.strict : false;
  }
  declare(name, kind, node) {
    if (this.decls.has(name) && kind !== 'var' && kind !== 'function') throw new Unsupported(`${name} is declared twice in one scope`, node);
    if (!this.decls.has(name)) this.decls.set(name, { name, kind, scope: this, captured: false, node, id: ++Scope.n });
    return this.decls.get(name);
  }
  lookup(name) { for (let s = this; s; s = s.parent) if (s.decls.has(name)) return s.decls.get(name); return null; }
}
Scope.n = 0;

const BUILTINS = new Set(['print', 'queueMicrotask', 'setTimeout', 'Promise', 'Error', 'TypeError', 'RangeError', 'undefined', 'NaN', 'Infinity']);

// Pass 1: build scopes and declarations; pass 2: resolve references and record captures.
function hasStrictDirective(body) {
  for (const statement of body) {
    if (!statement.directive) return false;
    if (statement.directive === 'use strict') return true;
  }
  return false;
}

function analyzeScopes(program) {
  const scopeOf = new Map(), fnInfo = new Map();
  const top = new Scope('function', null, null);
  top.strict = hasStrictDirective(program.body);
  top.declare('this', 'this');
  scopeOf.set(program, top);
  fnInfo.set(program, { scope: top, free: new Map(), node: program, usesThis: false });

  const hoistVars = (node, fnScope) => {          // var declarations anywhere in the function body
    walk(node, n => {
      if (n !== node && isFunction(n)) return false;
      if (n.type === 'VariableDeclaration' && n.kind === 'var') for (const d of n.declarations) declarePattern(d.id, fnScope, 'var');
      return true;
    });
  };
  const declareBlock = (body, scope) => {
    for (const st of body) {
      if (st.type === 'VariableDeclaration' && st.kind !== 'var') for (const d of st.declarations) declarePattern(d.id, scope, st.kind);
      if (st.type === 'FunctionDeclaration') scope.declare(st.id.name, 'function', st);
      if (st.type === 'ClassDeclaration') throw new Unsupported('classes are outside this subset', st);
    }
  };
  const visitFn = (node, parentScope) => {
    if (node.async || node.generator) throw new Unsupported('async and generator functions are outside the native subset', node);
    const s = new Scope('function', parentScope, null);
    s.strict = s.strict || hasStrictDirective(node.body.type === 'BlockStatement' ? node.body.body : []);
    if (node.type !== 'ArrowFunctionExpression') s.declare('this', 'this');
    node.params.forEach(p => {
      if (p.type !== 'Identifier') throw new Unsupported('only simple parameters are supported (no defaults, rest or destructuring)', p);
      s.declare(p.name, 'param', p);
    });
    if (node.type === 'FunctionExpression' && node.id) s.declare(node.id.name, 'self', node);
    scopeOf.set(node, s);
    fnInfo.set(node, { scope: s, free: new Map(), node, usesThis: false });
    if (node.body.type === 'BlockStatement') { hoistVars(node.body, s); declareBlock(node.body.body, s); scopeOf.set(node.body, s); visitBody(node.body.body, s); }
    else visitExpr(node.body, s);
  };
  const visitBody = (stmts, scope) => stmts.forEach(st => visitStmt(st, scope));
  const blockScope = (node, parent) => { const s = new Scope('block', parent, parent.fnScope); scopeOf.set(node, s); return s; };
  const visitStmt = (st, scope) => {
    if (!st) return;
    switch (st.type) {
      case 'BlockStatement': { const s = blockScope(st, scope); declareBlock(st.body, s); visitBody(st.body, s); return; }
      case 'FunctionDeclaration': visitFn(st, scope); return;
      case 'VariableDeclaration': for (const d of st.declarations) { if (d.id.type === 'Identifier') scopeOf.set(d.id, scope); if (d.init) visitExpr(d.init, scope); } return;
      case 'ForStatement': {
        const s = blockScope(st, scope);
        if (st.init && st.init.type === 'VariableDeclaration' && st.init.kind !== 'var') for (const d of st.init.declarations) declarePattern(d.id, s, st.init.kind);
        if (st.init) (st.init.type === 'VariableDeclaration' ? visitStmt : visitExpr)(st.init, s);
        if (st.test) visitExpr(st.test, s); if (st.update) visitExpr(st.update, s);
        visitStmt(st.body, s); return;
      }
      case 'ForOfStatement': {
        const s = blockScope(st, scope);
        if (st.left.type === 'VariableDeclaration') for (const d of st.left.declarations) declarePattern(d.id, s, st.left.kind === 'var' ? 'var' : st.left.kind);
        else visitExpr(st.left, s);
        visitExpr(st.right, scope); visitStmt(st.body, s); return;
      }
      case 'TryStatement': {
        visitStmt(st.block, scope);
        if (st.handler) {
          const s = blockScope(st.handler, scope);
          if (st.handler.param) { if (st.handler.param.type !== 'Identifier') throw new Unsupported('catch binding must be a name', st.handler.param); s.declare(st.handler.param.name, 'let', st.handler.param); }
          visitStmt(st.handler.body, s);
        }
        if (st.finalizer) visitStmt(st.finalizer, scope);
        return;
      }
      case 'IfStatement': visitExpr(st.test, scope); visitStmt(st.consequent, scope); visitStmt(st.alternate, scope); return;
      case 'WhileStatement': case 'DoWhileStatement': visitExpr(st.test, scope); visitStmt(st.body, scope); return;
      case 'ExpressionStatement': visitExpr(st.expression, scope); return;
      case 'ReturnStatement': case 'ThrowStatement': if (st.argument) visitExpr(st.argument, scope); return;
      case 'BreakStatement': case 'ContinueStatement': if (st.label) throw new Unsupported('labels are outside this subset', st); return;
      case 'EmptyStatement': return;
      case 'LabeledStatement': throw new Unsupported('labels are outside this subset', st);
      case 'SwitchStatement': throw new Unsupported('switch is outside this subset; use if/else', st);
      case 'ForInStatement': throw new Unsupported('for-in is outside this subset; use for-of over an array', st);
      default: throw new Unsupported(`${st.type} is outside this subset`, st);
    }
  };
  const visitExpr = (e, scope) => {
    if (!e) return;
    if (isFunction(e)) { visitFn(e, scope); return; }
    if (e.type === 'Identifier') { scopeOf.set(e, scope); return; }
    if (e.type === 'ThisExpression') { scopeOf.set(e, scope); return; }
    if (e.type === 'ObjectExpression') { for (const p of e.properties) { if (p.type === 'SpreadElement') throw new Unsupported('object spread is outside this subset', p); if (p.computed) visitExpr(p.key, scope); visitExpr(p.value, scope); } return; }
    if (e.type === 'MemberExpression') { visitExpr(e.object, scope); if (e.computed) visitExpr(e.property, scope); return; }
    for (const k of Object.keys(e)) {
      if (k === 'loc' || k === 'start' || k === 'end') continue;
      const v = e[k];
      if (Array.isArray(v)) v.forEach(x => x && typeof x.type === 'string' && visitExpr(x, scope));
      else if (v && typeof v.type === 'string') visitExpr(v, scope);
    }
  };
  hoistVars(program, top); declareBlock(program.body, top); visitBody(program.body, top);

  // Pass 2: references. A name used in a function other than its declaring one is
  // captured; every function on the way from the use to the declaration passes its cell.
  const resolve = (name, scope, node) => {
    const d = scope.lookup(name);
    if (!d) return null;
    let fs = scope.fnScope;
    if (fs !== d.scope.fnScope) {
      d.captured = true;
      for (let s = fs; s && s !== d.scope.fnScope; s = s.parent && s.parent.fnScope) {
        const info = [...fnInfo.values()].find(i => i.scope === s);
        if (info) info.free.set(d.id, d);
      }
    }
    return d;
  };
  walk(program, n => {
    if (n.type === 'Identifier' && scopeOf.has(n)) resolve(n.name, scopeOf.get(n), n);
    if (n.type === 'ThisExpression' && scopeOf.has(n)) resolve('this', scopeOf.get(n), n);
    return true;
  });
  return { scopeOf, fnInfo, top, resolve };
}

function declarePattern(id, scope, kind) {
  if (id.type !== 'Identifier') throw new Unsupported('destructuring is outside this subset', id);
  scope.declare(id.name, kind, id);
}
const isFunction = n => n && (n.type === 'FunctionDeclaration' || n.type === 'FunctionExpression' || n.type === 'ArrowFunctionExpression');
function walk(node, visit) {
  if (!node || typeof node.type !== 'string') return;
  if (visit(node) === false) return;
  for (const k of Object.keys(node)) {
    if (k === 'loc') continue;
    const v = node[k];
    if (Array.isArray(v)) v.forEach(x => walk(x, visit));
    else if (v && typeof v.type === 'string') walk(v, visit);
  }
}

// ---------------------------------------------------------------- lowering

function compileJS(text, opts = {}) {
  if (!acornLib) throw new StrataError('acorn is not loaded; the frontend needs it');
  let ast;
  try { ast = acornLib.parse(text, { ecmaVersion: 2022, sourceType: 'script', locations: true }); }
  catch (e) { throw new StrataError(`parse error: ${e.message}`, { kind: 'parse', loc: e.loc ? { line: e.loc.line, col: e.loc.column + 1 } : null }); }
  if (opts.native) walk(ast, n => {
    if (n.type === 'FunctionExpression' && n.id) throw new Unsupported('named function expressions require current-callee support and are not admitted', n);
    return true;
  });
  const sc = analyzeScopes(ast);
  const fns = [], names = new Set();
  const uniqueName = base => { let n = base.replace(/[^\w$]/g, '_') || 'anon', i = 1; const b = n; while (names.has(n)) n = `${b}_${++i}`; names.add(n); return n; };
  const fnName = new Map();
  for (const [node] of sc.fnInfo) {
    if (node === ast) { fnName.set(node, uniqueName(opts.main || 'main')); continue; }
    const base = node.id ? node.id.name : (node.strataName || (node.type === 'ArrowFunctionExpression' ? 'arrow' : 'anon'));
    fnName.set(node, uniqueName(base));
  }
  // Name functions that are property values or variable initialisers after what they become.
  walk(ast, n => {
    if (n.type === 'VariableDeclarator' && n.init && isFunction(n.init) && !n.init.id) { names.delete(fnName.get(n.init)); fnName.set(n.init, uniqueName(n.id.name)); }
    if (n.type === 'Property' && isFunction(n.value) && !n.value.id && !n.computed) {
      const key = n.key.name || String(n.key.value);
      names.delete(fnName.get(n.value)); fnName.set(n.value, uniqueName((n.kind === 'get' ? 'get_' : n.kind === 'set' ? 'set_' : '') + key));
    }
    return true;
  });
  const order = [...sc.fnInfo.keys()];
  for (const node of order) fns.push(lowerFunction(node, sc, fnName, opts));
  const mod = new Module(fns, { main: fnName.get(ast), source: opts.name || 'program.js', lang: 'js' });
  return mod;
}

function lowerFunction(node, sc, fnName, opts) {
  const info = sc.fnInfo.get(node), scope = info.scope;
  const isScript = node.type === 'Program';
  const captures = [...info.free.values()];
  const fn = new Fn({ name: fnName.get(node), params: [], result: t.any, meta: {
    kind: isScript ? 'script' : node.type === 'ArrowFunctionExpression' ? 'arrow' : 'function',
    strict: scope.strict, captures: captures.map(d => d.name), jsParams: isScript ? 0 : node.params.length,
    loc: node.loc ? { line: node.loc.start.line, col: node.loc.start.column + 1 } : null, source: opts.name,
  } });
  const L = new Lowerer(fn, sc, fnName, opts);
  // Parameters: the captured cells, then `this`, then the JavaScript parameters.
  captures.forEach(d => { const id = L.paramName('c_' + d.name); fn.params.push({ id, type: t.cell }); L.cellOf.set(d.id, id); });
  if (!isScript) {
    const thisId = L.paramName('this'); fn.params.push({ id: thisId, type: t.any });
    const thisDecl = scope.decls.get('this');
    node.params.forEach(p => fn.params.push({ id: L.paramName(p.name), type: t.any }));
    L.start();
    if (thisDecl) L.bindParam(thisDecl, thisId);
    node.params.forEach((p, i) => L.bindParam(scope.decls.get(p.name), fn.params[captures.length + 1 + i].id));
    const self = [...scope.decls.values()].find(d => d.kind === 'self');
    if (self) L.declareCell(self, L.emit('js.closure', { callee: fn.name }, ...captures.map(d => L.cellOf.get(d.id))));
  } else {
    L.start();
    const thisDecl = scope.decls.get('this');
    if (thisDecl) L.bindParam(thisDecl, opts.native ? L.emit('js.global_object') : lit(undefined));
  }
  // Cells for every declaration of the function scope (var, let, const, functions).
  L.enterScope(scope, node.body && node.body.type === 'BlockStatement' ? node.body.body : node.type === 'Program' ? node.body : []);
  if (node.type === 'ArrowFunctionExpression' && node.body.type !== 'BlockStatement') {
    const v = L.expr(node.body);
    L.ret(v);
  } else {
    L.stmts(isScript ? node.body : node.body.body);
    if (!L.done()) L.ret(lit(undefined));
  }
  L.finish();
  return fn;
}

class Lowerer {
  constructor(fn, sc, fnName, opts) {
    this.fn = fn; this.sc = sc; this.fnName = fnName; this.opts = opts;
    this.cellOf = new Map();                      // declaration id → SSA value holding its cell
    this.direct = new Map();                      // declaration id → value (uncaptured params before cells)
    this.counter = 0; this.blockCounter = 0;
    this.handlers = [];                           // stack of { kind: 'catch'|'finally', block }
    this.loops = [];                              // stack of { brk, cont, depth }
    this.cur = null;
  }
  paramName(base) { const id = this.unique(base); return id; }
  unique(base) {
    this.taken = this.taken || new Set();
    let id = base.replace(/[^\w$]/g, '_'), i = 1;
    while (this.taken.has(id)) id = `${base}${++i}`;
    this.taken.add(id); return id;
  }
  value(hint = 'v') { return this.unique(hint + (++this.counter)); }
  newBlock(base, params = []) {
    const name = base === 'entry' ? 'entry' : this.unique(base + (++this.blockCounter));
    const top = this.handlers[this.handlers.length - 1];
    const b = { name, params: params.map(id => ({ id, type: t.any })), ops: [], term: null, onThrow: top ? top.block : 'unwind', throwArgs: [] };
    this.fn.blocks.push(b);
    return b;
  }
  start() { this.cur = this.newBlock('entry'); }
  done() { return !this.cur || !!this.cur.term; }
  at(node) { return node && node.loc ? { line: node.loc.start.line, col: node.loc.start.column + 1 } : undefined; }
  emit(op, ...args) {
    // Attributes may come first (emit(op, { callee }, ...args)) or last (emit(op, a, b, { hint })).
    const isAttrs = x => x && typeof x === 'object' && !(x instanceof strata.internals.Lit) && !Array.isArray(x);
    let attrs = {};
    if (args.length && isAttrs(args[0])) attrs = { ...args.shift() };
    if (args.length && isAttrs(args[args.length - 1])) attrs = { ...attrs, ...args.pop() };
    const node = attrs.node; delete attrs.node;
    if (this.done()) this.cur = this.newBlock('dead');
    const def = strata.internals.lookupOp(op);
    const result = def.results.length ? this.value(attrs.hint || 'v') : null;
    delete attrs.hint;
    const o = { op, args, result, attrs };
    if (node) o.loc = this.at(node);
    this.cur.ops.push(o);
    return result;
  }
  term(term) { if (this.done()) this.cur = this.newBlock('dead'); this.cur.term = term; }
  jump(block, args = []) { this.term({ kind: 'jump', to: { block: block.name, args } }); }
  branch(cond, tb, fb) { this.term({ kind: 'branch', cond, t: { block: tb.name, args: [] }, f: { block: fb.name, args: [] } }); }
  ret(v) {                                        // a return passes through every enclosing finally
    const fin = [...this.handlers].reverse().find(h => h.kind === 'finally');
    if (fin) { const c = this.emit('completion.return', v, { hint: 'c' }); this.jump(fin.join, [c]); return; }
    this.term({ kind: 'return', value: v });
  }
  finish() {
    // Drop empty dead blocks that nothing reaches; give every block a terminator.
    for (const b of this.fn.blocks) if (!b.term) b.term = { kind: 'unreachable' };
  }

  // ---- variables
  bindParam(decl, valueId) {
    if (!decl) return;
    this.cellOf.set(decl.id, this.emit('cell.new', valueId, { hint: 'c_' + decl.name }));
  }
  declareCell(decl, init) { this.cellOf.set(decl.id, init === undefined ? this.emit('cell.new', { hint: 'c_' + decl.name }) : this.emit('cell.new', init, { hint: 'c_' + decl.name })); }
  enterScope(scope, body) {
    for (const d of scope.decls.values()) {
      if (this.cellOf.has(d.id)) continue;
      if (d.kind === 'var') this.declareCell(d, lit(undefined));
      else if (d.kind === 'let' || d.kind === 'const') this.declareCell(d);   // uninitialized until its declaration runs
      else if (d.kind === 'function') this.declareCell(d, lit(undefined));
    }
    for (const st of body || []) if (st.type === 'FunctionDeclaration') {
      const d = scope.decls.get(st.id.name);
      this.emit('cell.store', this.cellOf.get(d.id), this.closure(st));
    }
  }
  closure(node) {
    const info = this.sc.fnInfo.get(node);
    const caps = [...info.free.values()].map(d => this.cellRef(d, node));
    return this.emit('js.closure', { callee: this.fnName.get(node), hint: 'f', node }, ...caps);
  }
  cellRef(decl, node) {
    if (this.cellOf.has(decl.id)) return this.cellOf.get(decl.id);
    throw new Unsupported(`internal: no cell for ${decl.name}`, node);
  }
  scopeOf(node) { return this.sc.scopeOf.get(node); }
  load(decl, node) {
    const c = this.cellRef(decl, node);
    const checked = (decl.kind === 'let' || decl.kind === 'const') && (decl.scope.fnScope !== this.scopeOf(node).fnScope || node.start < decl.node.end);
    return checked ? this.emit('cell.load_checked', c, { name: decl.name, node, hint: decl.name }) : this.emit('cell.load', c, { hint: decl.name });
  }
  store(decl, v, node) {
    if (decl.kind === 'const' && !this.initializing) { this.emit('js.type_error', lit(`assignment to constant ${decl.name}`)); return; }
    this.emit('cell.store', this.cellRef(decl, node), v);
  }

  // ---- statements
  stmts(list) { for (const st of list) this.stmt(st); }
  stmt(st) {
    switch (st.type) {
      case 'ExpressionStatement': this.expr(st.expression); return;
      case 'VariableDeclaration': for (const d of st.declarations) {
        const decl = this.scopeOf(d.id).lookup(d.id.name);
        const v = d.init ? this.expr(d.init) : lit(undefined);
        if (d.init || st.kind !== 'var') { this.initializing = true; this.store(decl, v, d.id); this.initializing = false; }
      } return;
      case 'FunctionDeclaration': return;           // hoisted by enterScope
      case 'EmptyStatement': return;
      case 'BlockStatement': { const s = this.scopeOf(st); if (s && s.kind === 'block') this.enterScope(s, st.body); this.stmts(st.body); return; }
      case 'ReturnStatement': this.ret(st.argument ? this.expr(st.argument) : lit(undefined)); return;
      case 'ThrowStatement': this.term({ kind: 'throw', value: this.expr(st.argument) }); return;
      case 'IfStatement': {
        const tb = this.newBlock('then'), join = this.newBlock('endif');
        const fb = st.alternate ? this.newBlock('else') : join;
        this.branch(this.test(st.test), tb, fb);
        this.cur = tb; this.stmt(st.consequent); if (!this.done()) this.jump(join);
        if (st.alternate) { this.cur = fb; this.stmt(st.alternate); if (!this.done()) this.jump(join); }
        this.cur = join; return;
      }
      case 'WhileStatement': {
        const head = this.newBlock('while'), body = this.newBlock('body'), exit = this.newBlock('endwhile');
        this.jump(head); this.cur = head; this.branch(this.test(st.test), body, exit);
        this.loops.push({ brk: exit, cont: head, handlers: this.handlers.length });
        this.cur = body; this.stmt(st.body); if (!this.done()) this.jump(head);
        this.loops.pop(); this.cur = exit; return;
      }
      case 'DoWhileStatement': {
        const body = this.newBlock('do'), test = this.newBlock('dotest'), exit = this.newBlock('enddo');
        this.jump(body);
        this.loops.push({ brk: exit, cont: test, handlers: this.handlers.length });
        this.cur = body; this.stmt(st.body); if (!this.done()) this.jump(test);
        this.loops.pop();
        this.cur = test; this.branch(this.test(st.test), body, exit); this.cur = exit; return;
      }
      case 'ForStatement': return this.forStatement(st);
      case 'ForOfStatement': return this.forOf(st);
      case 'BreakStatement': case 'ContinueStatement': {
        const loop = this.loops[this.loops.length - 1];
        if (!loop) throw new Unsupported(`${st.type === 'BreakStatement' ? 'break' : 'continue'} outside a loop`, st);
        if (this.handlers.slice(loop.handlers).some(h => h.kind === 'finally')) throw new Unsupported('break or continue through finally is outside this subset', st);
        this.jump(st.type === 'BreakStatement' ? loop.brk : loop.cont); return;
      }
      case 'TryStatement': return this.tryStatement(st);
      default: throw new Unsupported(`${st.type} is outside this subset`, st);
    }
  }
  forStatement(st) {
    const s = this.scopeOf(st);
    this.enterScope(s, []);
    if (st.init) { if (st.init.type === 'VariableDeclaration') this.stmt(st.init); else this.expr(st.init); }
    const perIteration = st.init && st.init.type === 'VariableDeclaration' && st.init.kind !== 'var'
      ? st.init.declarations.map(d => s.decls.get(d.id.name)).filter(d => d.captured) : [];
    const head = this.newBlock('for'), body = this.newBlock('body'), cont = this.newBlock('next'), exit = this.newBlock('endfor');
    this.jump(head); this.cur = head;
    if (st.test) this.branch(this.test(st.test), body, exit); else this.jump(body);
    this.cur = body;
    // A captured let gets a fresh cell per iteration, so closures made in the body keep
    // the value of their own iteration; it is copied back before the update.
    const outer = new Map();
    for (const d of perIteration) {
      outer.set(d.id, this.cellOf.get(d.id));
      const v = this.emit('cell.load', this.cellOf.get(d.id), { hint: d.name });
      this.cellOf.set(d.id, this.emit('cell.new', v, { hint: 'c_' + d.name }));
    }
    const inner = new Map(perIteration.map(d => [d.id, this.cellOf.get(d.id)]));
    this.loops.push({ brk: exit, cont, handlers: this.handlers.length });
    this.stmt(st.body); if (!this.done()) this.jump(cont);
    this.loops.pop();
    this.cur = cont;
    for (const d of perIteration) {
      const v = this.emit('cell.load', inner.get(d.id), { hint: d.name });
      this.emit('cell.store', outer.get(d.id), v);
      this.cellOf.set(d.id, outer.get(d.id));
    }
    if (st.update) this.expr(st.update);
    this.jump(head); this.cur = exit;
  }
  forOf(st) {                                    // over arrays: index from 0 to length
    const s = this.scopeOf(st);
    const arr = this.expr(st.right);
    const iCell = this.emit('cell.new', lit(0), { hint: 'c_i' });
    this.enterScope(s, []);
    const head = this.newBlock('forof'), body = this.newBlock('body'), cont = this.newBlock('next'), exit = this.newBlock('endfor');
    this.jump(head); this.cur = head;
    const i = this.emit('cell.load', iCell, { hint: 'i' });
    const len = this.emit('js.get', arr, lit('length'), { hint: 'len' });
    this.branch(this.emit('js.lt', i, len, { hint: 'more' }), body, exit);
    this.cur = body;
    const item = this.emit('js.get', arr, this.emit('cell.load', iCell, { hint: 'i' }), { hint: 'item' });
    const left = st.left.type === 'VariableDeclaration' ? st.left.declarations[0].id : st.left;
    const decl = this.scopeOf(left) ? this.scopeOf(left).lookup(left.name) : s.lookup(left.name);
    if (st.left.type === 'VariableDeclaration' && decl.captured) this.cellOf.set(decl.id, this.emit('cell.new', item, { hint: 'c_' + decl.name }));
    else { this.initializing = true; this.store(decl, item, left); this.initializing = false; }
    this.loops.push({ brk: exit, cont, handlers: this.handlers.length });
    this.stmt(st.body); if (!this.done()) this.jump(cont);
    this.loops.pop();
    this.cur = cont;
    this.emit('cell.store', iCell, this.emit('js.add', this.emit('cell.load', iCell, { hint: 'i' }), lit(1), { hint: 'i' }));
    this.jump(head); this.cur = exit;
  }
  tryStatement(st) {
    if (st.finalizer) return this.tryFinally(st);
    this.tryCatch(st.block, st.handler);
  }
  tryCatch(block, handler) {
    const catchB = this.newBlock('catch', [this.value('e')]);
    const join = this.newBlock('endtry');
    this.handlers.push({ kind: 'catch', block: catchB.name });
    const body = this.newBlock('try');
    this.jump(body); this.cur = body;
    this.stmt(block);
    if (!this.done()) this.jump(join);
    this.handlers.pop();
    this.cur = catchB;
    const s = this.scopeOf(handler);
    if (handler.param) { const d = s.decls.get(handler.param.name); this.cellOf.set(d.id, this.emit('cell.new', catchB.params[0].id, { hint: 'c_' + d.name })); }
    this.stmt(handler.body);
    if (!this.done()) this.jump(join);
    this.cur = join;
  }
  tryFinally(st) {
    // Every way out of the protected region becomes a completion record: normal, return
    // or throw. The finally body runs once, then the record says where to continue.
    const join = this.newBlock('finally', [this.value('c')]);
    join.params[0].type = t.completion;            // the record of how the protected region ended
    const thrown = this.newBlock('finthrow', [this.value('e')]);
    const after = this.newBlock('endfinally');
    this.handlers.push({ kind: 'finally', block: thrown.name, join });
    const body = this.newBlock('try');
    this.jump(body); this.cur = body;
    if (st.handler) this.tryCatch(st.block, st.handler); else this.stmt(st.block);
    if (!this.done()) this.jump(join, [this.emit('completion.normal', { hint: 'c' })]);
    this.handlers.pop();
    this.cur = thrown; this.jump(join, [this.emit('completion.throw', thrown.params[0].id, { hint: 'c' })]);
    this.cur = join;
    const c = join.params[0].id;
    this.stmt(st.finalizer);
    if (this.done()) { this.cur = after; return; }
    const isRet = this.newBlock('fin_return'), notRet = this.newBlock('fin_rest'), doThrow = this.newBlock('fin_throw');
    this.branch(this.emit('completion.is', c, { kind: 'return', hint: 'isret' }), isRet, notRet);
    this.cur = isRet; this.ret(this.emit('completion.value', c, { hint: 'r' }));
    this.cur = notRet; this.branch(this.emit('completion.is', c, { kind: 'throw', hint: 'isthrow' }), doThrow, after);
    this.cur = doThrow; this.term({ kind: 'throw', value: this.emit('completion.value', c, { hint: 'e' }) });
    this.cur = after;
  }

  // ---- expressions
  test(e) {                                       // a condition as a boolean value
    const v = this.expr(e);
    return this.isBoolean(e) ? v : this.emit('js.truthy', v, { hint: 'b' });
  }
  isBoolean(e) {
    return (e.type === 'BinaryExpression' && ['<', '<=', '>', '>=', '===', '!=='].includes(e.operator)) ||
      (e.type === 'UnaryExpression' && e.operator === '!') || (e.type === 'Literal' && typeof e.value === 'boolean');
  }
  expr(e) {
    switch (e.type) {
      case 'Literal':
        if (e.regex) throw new Unsupported('regular expressions are outside this subset', e);
        if (typeof e.value === 'bigint' || e.bigint) throw new Unsupported('BigInt is outside this subset', e);
        return lit(e.value);
      case 'TemplateLiteral': {
        let acc = lit(e.quasis[0].value.cooked);
        e.expressions.forEach((x, i) => {
          acc = this.emit('js.add', acc, this.expr(x), { hint: 's', node: x });
          const q = e.quasis[i + 1].value.cooked; if (q) acc = this.emit('js.add', acc, lit(q), { hint: 's' });
        });
        return acc;
      }
      case 'Identifier': return this.identifier(e);
      case 'ThisExpression': { const d = this.scopeOf(e).lookup('this'); return d ? this.load(d, e) : lit(undefined); }
      case 'BinaryExpression': {
        const ops = { '+': 'js.add', '-': 'js.sub', '*': 'js.mul', '/': 'js.div', '%': 'js.mod', '<': 'js.lt', '<=': 'js.le', '>': 'js.gt', '>=': 'js.ge', '===': 'js.strict_eq', '!==': 'js.strict_ne' };
        if (!ops[e.operator]) throw new Unsupported(`the operator ${e.operator} is outside this subset${e.operator === '==' || e.operator === '!=' ? '; use === or !==' : ''}`, e);
        const a = this.expr(e.left), b = this.expr(e.right);
        return this.emit(ops[e.operator], a, b, { node: e });
      }
      case 'LogicalExpression': return this.logical(e);
      case 'ConditionalExpression': {
        const tb = this.newBlock('then'), fb = this.newBlock('else'), join = this.newBlock('endif', [this.value('v')]);
        this.branch(this.test(e.test), tb, fb);
        this.cur = tb; const a = this.expr(e.consequent); this.jump(join, [a]);
        this.cur = fb; const b = this.expr(e.alternate); this.jump(join, [b]);
        this.cur = join; return join.params[0].id;
      }
      case 'UnaryExpression': {
        if (e.operator === 'typeof' && e.argument.type === 'Identifier' && !this.scopeOf(e.argument).lookup(e.argument.name) && !BUILTINS.has(e.argument.name)) return this.emit('js.typeof', this.emit('js.global_get', lit(e.argument.name), { allowMissing: true }));
        const v = this.expr(e.argument);
        if (e.operator === '-') return this.emit('js.neg', v, { node: e });
        if (e.operator === '+') return this.emit('js.mul', v, lit(1), { node: e });
        if (e.operator === '!') return this.emit('js.not', v);
        if (e.operator === 'typeof') return this.emit('js.typeof', v);
        if (e.operator === 'void') return lit(undefined);
        throw new Unsupported(`the operator ${e.operator} is outside this subset`, e);
      }
      case 'UpdateExpression': {
        const old = this.expr(e.argument);
        const num = this.emit('js.mul', old, lit(1), { hint: 'n' });
        const neu = this.emit(e.operator === '++' ? 'js.add' : 'js.sub', num, lit(1), { node: e });
        this.assignTo(e.argument, neu);
        return e.prefix ? neu : num;
      }
      case 'AssignmentExpression': {
        if (e.operator === '=') { const v = this.expr(e.right); this.assignTo(e.left, v); return v; }
        const ops = { '+=': 'js.add', '-=': 'js.sub', '*=': 'js.mul', '/=': 'js.div', '%=': 'js.mod' };
        if (!ops[e.operator]) throw new Unsupported(`the operator ${e.operator} is outside this subset`, e);
        if (e.left.type === 'MemberExpression') {
          const o = this.expr(e.left.object), k = e.left.computed ? this.expr(e.left.property) : lit(e.left.property.name);
          const old = this.emit('js.get', o, k, { node: e.left });
          const v = this.emit(ops[e.operator], old, this.expr(e.right), { node: e });
          this.emit('js.put', o, k, v, { strict: this.fn.meta.strict, node: e }); return v;
        }
        const v = this.emit(ops[e.operator], this.expr(e.left), this.expr(e.right), { node: e });
        this.assignTo(e.left, v); return v;
      }
      case 'SequenceExpression': { let v = lit(undefined); for (const x of e.expressions) v = this.expr(x); return v; }
      case 'MemberExpression': {
        if (e.optional) throw new Unsupported('optional chaining is outside this subset', e);
        const o = this.expr(e.object);
        const k = e.computed ? this.expr(e.property) : lit(e.property.name);
        return this.emit('js.get', o, k, { node: e, hint: e.computed ? 'v' : e.property.name });
      }
      case 'CallExpression': return this.call(e);
      case 'NewExpression': {
        if (e.callee.type === 'Identifier' && ['Error', 'TypeError', 'RangeError'].includes(e.callee.name) && !this.scopeOf(e.callee).lookup(e.callee.name)) {
          return this.emit('js.new_error', e.arguments[0] ? this.expr(e.arguments[0]) : lit(undefined), { kind: e.callee.name, node: e, hint: 'err' });
        }
        throw new Unsupported('new is supported only for Error, TypeError and RangeError', e);
      }
      case 'ObjectExpression': {
        const o = this.emit('obj.new', { hint: 'o', node: e });
        for (const p of e.properties) {
          const key = p.computed ? this.expr(p.key) : lit(p.key.type === 'Identifier' ? p.key.name : String(p.key.value));
          if (p.kind === 'get' || p.kind === 'set') {
            this.emit(p.kind === 'get' ? 'js.define_getter' : 'js.define_setter', o, key, this.closure(p.value));
          } else this.emit('js.define', o, key, isFunction(p.value) ? this.closure(p.value) : this.expr(p.value));
        }
        return o;
      }
      case 'ArrayExpression': {
        if (e.elements.some(x => !x || x.type === 'SpreadElement')) throw new Unsupported('holes and spread in arrays are outside this subset', e);
        return this.emit('arr.new', ...e.elements.map(x => this.expr(x)), { hint: 'arr', node: e });
      }
      case 'FunctionExpression': case 'ArrowFunctionExpression': return this.closure(e);
      default: throw new Unsupported(`${e.type} is outside this subset`, e);
    }
  }
  identifier(e) {
    const d = this.scopeOf(e).lookup(e.name);
    if (d) return this.load(d, e);
    if (e.name === 'undefined') return lit(undefined);
    if (e.name === 'NaN') return lit(NaN);
    if (e.name === 'Infinity') return lit(Infinity);
    if (this.opts.native && e.name === 'arguments') throw new Unsupported('implicit arguments objects are outside the native subset', e);
    return this.emit('js.global_get', lit(e.name), { hint: e.name, node: e });
  }
  assignTo(target, v) {
    if (target.type === 'Identifier') {
      const d = this.scopeOf(target).lookup(target.name);
      if (d) return this.store(d, v, target);
      return this.emit('js.global_put', lit(target.name), v, { strict: this.fn.meta.strict });
    }
    if (target.type === 'MemberExpression') {
      const o = this.expr(target.object), k = target.computed ? this.expr(target.property) : lit(target.property.name);
      return this.emit('js.put', o, k, v, { strict: this.fn.meta.strict, node: target });
    }
    throw new Unsupported('only names and properties can be assigned', target);
  }
  logical(e) {
    const a = this.expr(e.left);
    const join = this.newBlock('endlogic', [this.value('v')]), rhs = this.newBlock('rhs');
    let cond;
    if (e.operator === '??') cond = this.emit('bool.or', this.emit('js.strict_eq', a, lit(null)), this.emit('js.strict_eq', a, lit(undefined)));
    else cond = this.isBoolean(e.left) ? a : this.emit('js.truthy', a, { hint: 'b' });
    const here = this.cur;
    if (e.operator === '&&') here.term = { kind: 'branch', cond, t: { block: rhs.name, args: [] }, f: { block: join.name, args: [a] } };
    else if (e.operator === '||') here.term = { kind: 'branch', cond, t: { block: join.name, args: [a] }, f: { block: rhs.name, args: [] } };
    else here.term = { kind: 'branch', cond, t: { block: rhs.name, args: [] }, f: { block: join.name, args: [a] } };
    this.cur = rhs; const b = this.expr(e.right); this.jump(join, [b]);
    this.cur = join; return join.params[0].id;
  }
  call(e) {
    const args = () => e.arguments.map(a => { if (a.type === 'SpreadElement') throw new Unsupported('spread arguments are outside this subset', a); return this.expr(a); });
    const c = e.callee;
    if (c.type === 'Identifier' && c.name === 'eval' && !this.scopeOf(c).lookup('eval')) throw new Unsupported('direct eval needs lexical environment metadata and is not admitted', e);
    const builtin = name => c.type === 'Identifier' && c.name === name && !this.scopeOf(c).lookup(name);
    if (builtin('print')) { this.emit('host.print', ...args(), { node: e }); return lit(undefined); }
    if (builtin('queueMicrotask')) { this.emit('job.enqueue', ...args(), { node: e }); return lit(undefined); }
    if (builtin('setTimeout')) { const as = args(); this.emit('timer.set', as[0], as[1] === undefined ? lit(0) : as[1], { node: e }); return lit(undefined); }
    if (c.type === 'MemberExpression' && c.object.type === 'Identifier' && c.object.name === 'Promise' && !this.scopeOf(c.object).lookup('Promise') && !c.computed && c.property.name === 'resolve') {
      return this.emit('promise.resolve', ...(e.arguments.length ? args() : [lit(undefined)]), { node: e, hint: 'p' });
    }
    if (c.type === 'MemberExpression') {
      const o = this.expr(c.object), k = c.computed ? this.expr(c.property) : lit(c.property.name);
      const callee = this.emit('js.get', o, k, { node: c, hint: 'callee' });
      return this.emit('js.call', callee, o, ...args(), { node: e, hint: 'r' });
    }
    const f = this.expr(c);
    return this.emit('js.call', f, lit(undefined), ...args(), { node: e, hint: 'r' });
  }
}

strata.frontend = { compile: compileJS, Unsupported, analyzeScopes };
if (typeof module !== 'undefined') module.exports = strata.frontend;
})(typeof globalThis !== 'undefined' ? globalThis : this);
