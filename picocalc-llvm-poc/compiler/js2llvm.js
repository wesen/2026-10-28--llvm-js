#!/usr/bin/env node
'use strict';

/* Direct LLVM frontend for the existing PicoCalc restricted JS/i32 ABI.
 * There is no generated C, C AST, or Clang frontend on this path.
 * Dynamic JavaScript belongs to the separate Static Hermes backend.
 */
const fs = require('fs');
const path = require('path');
let ts;
try { ts = require('typescript'); } catch (_) {
  const root = process.env.NODE_GLOBAL_ROOT;
  if (!root) throw new Error('TypeScript 5.8.3 is required: run npm install');
  ts = require(path.join(root, 'typescript', 'lib', 'typescript.js'));
}
const K = ts.SyntaxKind;
const infile = process.argv[2];
if (!infile) { console.error('usage: node compiler/js2llvm.js input.js'); process.exit(2); }
const source = fs.readFileSync(infile, 'utf8');
if (Buffer.byteLength(source) > 65536) throw new Error('source exceeds 64 KiB');
const ast = ts.createSourceFile(infile, source, ts.ScriptTarget.ES2022, true, ts.ScriptKind.JS);
if (ast.parseDiagnostics.length) throw new Error(ts.flattenDiagnosticMessageText(ast.parseDiagnostics[0].messageText, '\n'));
function die(node, message) {
  const at = ast.getLineAndCharacterOfPosition(node ? node.getStart(ast) : 0);
  throw new Error(`${infile}:${at.line + 1}:${at.character + 1}: ${message}`);
}
function ident(node) {
  if (!node || !ts.isIdentifier(node)) die(node, 'expected identifier');
  return node.text;
}
function literal(node) {
  if (!node || !ts.isNumericLiteral(node) || !/^(?:0|[1-9][0-9]*)$/.test(node.text)) die(node, 'expected unsigned integer literal');
  const n = Number(node.text);
  if (n > 0x7fffffff) die(node, 'integer exceeds i32');
  return n;
}
function modifiers(node) {
  for (const m of node.modifiers || []) if (m.kind !== K.ExportKeyword) die(m, 'unsupported modifier');
}
const fields = new Map([['schema', 0], ['score', 1], ['ticks', 2], ['flags', 3]]);
const parameters = new Set(['state', 'event', 'arg', 'version']);
const integer = (value, unsigned = false) => ({value: String(value), unsigned});

class FunctionEmitter {
  constructor(name, node) {
    this.name = name; this.node = node; this.lines = []; this.allocas = [];
    this.serial = 0; this.labels = 0; this.label = 'entry'; this.terminated = false;
    this.scopes = [new Map()]; this.seenLocals = new Set(parameters);
    const signature = name === 'step' ? ['state', 'event', 'arg'] : ['state', 'version'];
    for (const p of signature.slice(1)) this.scopes[0].set(p, {argument: `%${p}`, unsigned: p !== 'arg'});
  }
  temp() { return `%v${++this.serial}`; }
  blockName(prefix) { return `${prefix}.${++this.labels}`; }
  emit(line) { this.lines.push(`  ${line}`); }
  value(line, unsigned = false) { const v = this.temp(); this.emit(`${v} = ${line}`); return integer(v, unsigned); }
  block(name) { this.lines.push(`${name}:`); this.label = name; this.terminated = false; }
  branch(name) { this.emit(`br label %${name}`); this.terminated = true; }
  boolean(v) { return this.value(`icmp ne i32 ${v.value}, 0`).value; }
  binding(name, node) {
    for (let i = this.scopes.length - 1; i >= 0; --i) if (this.scopes[i].has(name)) return this.scopes[i].get(name);
    die(node, `unbound identifier ${name}`);
  }
  address(node) {
    if (ts.isIdentifier(node)) {
      const b = this.binding(node.text, node);
      if (b.argument) die(node, 'argument assignment not supported');
      return b;
    }
    if (!ts.isPropertyAccessExpression(node) || node.questionDotToken || ident(node.expression) !== 'state') die(node, 'only state.field access supported');
    const field = ident(node.name);
    if (!fields.has(field)) die(node, `unknown state field ${field}`);
    const pointer = this.temp();
    this.emit(`${pointer} = getelementptr %PicoState, ptr %state, i32 0, i32 ${fields.get(field)}`);
    return {pointer, unsigned: field === 'schema'};
  }
  load(a) { return a.argument ? integer(a.argument, a.unsigned) : this.value(`load i32, ptr ${a.pointer}, align 4`, a.unsigned); }
  expression(node) {
    if (ts.isParenthesizedExpression(node)) return this.expression(node.expression);
    if (ts.isNumericLiteral(node)) return integer(literal(node));
    if (node.kind === K.TrueKeyword) return integer(1);
    if (node.kind === K.FalseKeyword) return integer(0);
    if (ts.isIdentifier(node)) return this.load(this.binding(node.text, node));
    if (ts.isPropertyAccessExpression(node)) return this.load(this.address(node));
    if (ts.isPrefixUnaryExpression(node)) {
      const a = this.expression(node.operand);
      switch (node.operator) {
        case K.PlusToken: return a;
        case K.MinusToken: return this.value(`sub i32 0, ${a.value}`, a.unsigned);
        case K.TildeToken: return this.value(`xor i32 ${a.value}, -1`, a.unsigned);
        case K.ExclamationToken: {
          const b = this.value(`icmp eq i32 ${a.value}, 0`);
          return this.value(`zext i1 ${b.value} to i32`);
        }
        default: die(node, 'unsupported unary operator');
      }
    }
    if (ts.isBinaryExpression(node)) {
      const op = node.operatorToken.kind;
      if ([K.EqualsToken, K.PlusEqualsToken, K.MinusEqualsToken].includes(op)) {
        const dst = this.address(node.left);
        const old = op === K.EqualsToken ? null : this.load(dst);
        let result = this.expression(node.right);
        if (old) result = this.value(`${op === K.PlusEqualsToken ? 'add' : 'sub'} i32 ${old.value}, ${result.value}`, dst.unsigned);
        this.emit(`store i32 ${result.value}, ptr ${dst.pointer}, align 4`);
        return integer(result.value, dst.unsigned);
      }
      const left = this.expression(node.left);
      if ([K.AmpersandAmpersandToken, K.BarBarToken].includes(op)) {
        // The inherited integer language uses C-style logical results 0/1.
        // The RHS is evaluated only on the appropriate predecessor edge.
        const and = op === K.AmpersandAmpersandToken;
        const cond = this.boolean(left), origin = this.label;
        const rhs = this.blockName('logic.rhs'), join = this.blockName('logic.join');
        this.emit(`br i1 ${cond}, label %${and ? rhs : join}, label %${and ? join : rhs}`);
        this.terminated = true; this.block(rhs);
        const right = this.boolean(this.expression(node.right)), rightOrigin = this.label;
        this.branch(join); this.block(join);
        const b = this.value(`phi i1 [ ${and ? 'false' : 'true'}, %${origin} ], [ ${right}, %${rightOrigin} ]`);
        return this.value(`zext i1 ${b.value} to i32`);
      }
      const right = this.expression(node.right), unsigned = left.unsigned || right.unsigned;
      const arithmetic = new Map([[K.PlusToken, 'add'], [K.MinusToken, 'sub'], [K.AsteriskToken, 'mul'], [K.AmpersandToken, 'and'], [K.BarToken, 'or'], [K.CaretToken, 'xor']]);
      if (arithmetic.has(op)) return this.value(`${arithmetic.get(op)} i32 ${left.value}, ${right.value}`, unsigned);
      const comparisons = new Map([[K.EqualsEqualsEqualsToken, 'eq'], [K.ExclamationEqualsEqualsToken, 'ne'], [K.LessThanToken, 'lt'], [K.LessThanEqualsToken, 'le'], [K.GreaterThanToken, 'gt'], [K.GreaterThanEqualsToken, 'ge']]);
      if (comparisons.has(op)) {
        let predicate = comparisons.get(op);
        if (!['eq', 'ne'].includes(predicate)) predicate = (unsigned ? 'u' : 's') + predicate;
        const b = this.value(`icmp ${predicate} i32 ${left.value}, ${right.value}`);
        return this.value(`zext i1 ${b.value} to i32`);
      }
      die(node, `unsupported operator ${ts.tokenToString(op)}`);
    }
    if (ts.isCallExpression(node)) {
      if (node.questionDotToken || node.typeArguments || !ts.isPropertyAccessExpression(node.expression) || node.expression.questionDotToken || ident(node.expression.expression) !== 'cap') die(node, 'only cap.emit/cap.abort/cap.rect calls supported');
      const name = ident(node.expression.name), arity = {emit: 1, abort: 1, rect: 5}, ids = {emit: 1, abort: 2, rect: 3};
      if (!(name in arity) || node.arguments.length !== arity[name]) die(node, 'unsupported host call');
      const args = node.arguments.map(arg => this.expression(arg));
      const constraints = ['={x10}', '{x17}', ...args.map((_, i) => `{x${10 + i}}`), '~{memory}'].join(',');
      const values = [`i32 ${ids[name]}`, ...args.map(arg => `i32 ${arg.value}`)].join(', ');
      return this.value(`call i32 asm sideeffect "ecall", "${constraints}"(${values})`);
    }
    die(node, `unsupported expression ${K[node.kind]}`);
  }
  body(node, scope = true) {
    if (scope) this.scopes.push(new Map());
    for (const s of ts.isBlock(node) ? node.statements : [node]) this.statement(s);
    if (scope) this.scopes.pop();
  }
  statement(node) {
    // Still validate dead source; its block is unreachable and LLVM can remove it.
    if (this.terminated) this.block(this.blockName('dead'));
    if (ts.isBlock(node)) return this.body(node);
    if (ts.isEmptyStatement(node)) return;
    if (ts.isExpressionStatement(node)) { this.expression(node.expression); return; }
    if (ts.isReturnStatement(node)) {
      const v = node.expression ? this.expression(node.expression) : integer(0);
      this.emit(`ret i32 ${v.value}`); this.terminated = true; return;
    }
    if (ts.isVariableStatement(node)) {
      if (node.modifiers?.length) die(node, 'local declaration cannot have modifiers');
      for (const d of node.declarationList.declarations) {
        const name = ident(d.name);
        if (this.seenLocals.has(name)) die(d, `duplicate local ${name}`);
        if (d.type || !d.initializer) die(d, 'local requires an untyped initializer');
        const initial = this.expression(d.initializer), pointer = this.temp();
        this.seenLocals.add(name); this.scopes[this.scopes.length - 1].set(name, {pointer, unsigned: false});
        this.allocas.push(`  ${pointer} = alloca i32, align 4`);
        this.emit(`store i32 ${initial.value}, ptr ${pointer}, align 4`);
      }
      return;
    }
    if (ts.isIfStatement(node)) {
      const condition = this.boolean(this.expression(node.expression));
      const yes = this.blockName('if.yes'), no = this.blockName('if.no'), done = this.blockName('if.end');
      this.emit(`br i1 ${condition}, label %${yes}, label %${node.elseStatement ? no : done}`);
      this.terminated = true; this.block(yes); this.body(node.thenStatement);
      if (!this.terminated) this.branch(done);
      if (node.elseStatement) { this.block(no); this.body(node.elseStatement); if (!this.terminated) this.branch(done); }
      this.block(done); return;
    }
    if (ts.isWhileStatement(node)) {
      const head = this.blockName('while.test'), body = this.blockName('while.body'), done = this.blockName('while.end');
      this.branch(head); this.block(head);
      const condition = this.boolean(this.expression(node.expression));
      this.emit(`br i1 ${condition}, label %${body}, label %${done}`); this.terminated = true;
      this.block(body); this.body(node.statement); if (!this.terminated) this.branch(head);
      this.block(done); return;
    }
    die(node, `unsupported statement ${K[node.kind]}`);
  }
  generate() {
    this.body(this.node.body, false);
    if (!this.terminated) this.emit('ret i32 0');
    const args = this.name === 'step' ? 'ptr %state, i32 %event, i32 %arg' : 'ptr %state, i32 %version';
    return `define i32 @pico_world_${this.name}(${args}) {\nentry:\n${this.allocas.concat(this.lines).join('\n')}\n}\n`;
  }
}

let schema = null;
const functions = new Map();
for (const s of ast.statements) {
  modifiers(s);
  if (ts.isVariableStatement(s)) {
    for (const d of s.declarationList.declarations) {
      if (ident(d.name) !== 'schema' || schema !== null || d.type) die(d, 'only one top-level schema is supported');
      schema = literal(d.initializer);
    }
  } else if (ts.isFunctionDeclaration(s)) {
    const name = ident(s.name), expected = name === 'step' ? ['state', 'event', 'arg'] : ['state', 'version'];
    if (!['step', 'migrate'].includes(name) || functions.has(name)) die(s, 'expected step and optional migrate');
    if (!s.body || s.asteriskToken || s.type || s.typeParameters) die(s, 'unsupported function declaration');
    if (s.parameters.length !== expected.length || s.parameters.some((p, i) => ident(p.name) !== expected[i] || p.initializer || p.dotDotDotToken || p.questionToken || p.type)) die(s, `bad signature of ${name}`);
    functions.set(name, new FunctionEmitter(name, s).generate());
  } else die(s, 'only functions and schema at top level');
}
if (schema === null || schema < 1 || schema > 1000) throw new Error('expected const schema = integer (1..1000)');
if (!functions.has('step')) throw new Error('expected function step(state, event, arg)');
if (!functions.has('migrate')) functions.set('migrate', `define i32 @pico_world_migrate(ptr %state, i32 %version) {\nentry:\n  %p = getelementptr %PicoState, ptr %state, i32 0, i32 0\n  store i32 ${schema}, ptr %p, align 4\n  ret i32 0\n}\n`);
process.stdout.write(`; Direct LLVM IR from the PicoCalc restricted JS/i32 frontend.\n; C-compatible integer semantics, not general ECMAScript.\ntarget datalayout = "e-m:e-p:32:32-i64:64-n32-S128"\ntarget triple = "riscv32-unknown-elf"\n%PicoState = type { i32, i32, i32, i32 }\n\n${Array.from(functions.values()).join('\n')}`);
