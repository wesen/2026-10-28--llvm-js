#!/usr/bin/env node
'use strict';
/* Deliberately restricted JS/i32 subset: whitelist AST nodes, no eval or arbitrary C. */
const fs = require('fs');
const path = require('path');
let ts;
try { ts = require('typescript'); } catch (_) {
  const root = process.env.NODE_GLOBAL_ROOT || '/opt/nvm/versions/node/v22.16.0/lib/node_modules';
  ts = require(path.join(root, 'typescript', 'lib', 'typescript.js'));
}
const K = ts.SyntaxKind;
const infile = process.argv[2];
if (!infile) { console.error('usage: node compiler/js2c.js input.js'); process.exit(2); }
const src = fs.readFileSync(infile, 'utf8');
const ast = ts.createSourceFile(infile, src, ts.ScriptTarget.ES2022, true, ts.ScriptKind.JS);
if (ast.parseDiagnostics.length) throw new Error(ts.flattenDiagnosticMessageText(ast.parseDiagnostics[0].messageText,'\n'));
function die(node, msg) { throw new Error(`${infile}:${ast.getLineAndCharacterOfPosition(node.getStart(ast)).line+1}: ${msg}`); }
function ident(n) { if (!ts.isIdentifier(n)) die(n,'expected identifier'); return n.text; }
function literal(n) { if (!ts.isNumericLiteral(n) || !/^(?:0|[1-9][0-9]*)$/.test(n.text)) die(n,'expected unsigned integer literal'); const v=Number(n.text);if(v>0x7fffffff) die(n,'integer exceeds i32'); return v; }
const allowedState = new Set(['schema','score','ticks','flags']);
function property(n){if(!ts.isPropertyAccessExpression(n) || ident(n.expression)!=='state')die(n,'only state.field access supported'); const p=ident(n.name);if(!allowedState.has(p))die(n,'unknown state field '+p);return `state->${p}`;}
let locals = new Set(['state','event','arg','version']);
function expr(n) {
  if (ts.isParenthesizedExpression(n))return `(${expr(n.expression)})`;
  if (ts.isNumericLiteral(n))return String(literal(n));
  if (n.kind===K.TrueKeyword) return '1';
  if (n.kind===K.FalseKeyword) return '0';
  if (ts.isIdentifier(n)) { if(!locals.has(n.text))die(n,'unbound identifier '+n.text);return n.text; }
  if (ts.isPropertyAccessExpression(n))return property(n);
  if (ts.isPrefixUnaryExpression(n)){
    const ops={ [K.MinusToken]:'-', [K.PlusToken]:'+', [K.ExclamationToken]:'!', [K.TildeToken]:'~'};
    if(!ops[n.operator])die(n,'unsupported unary operator');return `(${ops[n.operator]}${expr(n.operand)})`;
  }
  if (ts.isBinaryExpression(n)) {
    const ops={
      [K.PlusToken]:'+', [K.MinusToken]:'-', [K.AsteriskToken]:'*',
      [K.AmpersandToken]:'&', [K.BarToken]:'|', [K.CaretToken]:'^',
      [K.EqualsEqualsEqualsToken]:'==', [K.ExclamationEqualsEqualsToken]:'!=',
      [K.LessThanToken]:'<', [K.LessThanEqualsToken]:'<=',
      [K.GreaterThanToken]:'>', [K.GreaterThanEqualsToken]:'>=',
      [K.AmpersandAmpersandToken]:'&&', [K.BarBarToken]:'||',
      [K.EqualsToken]:'=', [K.PlusEqualsToken]:'+=', [K.MinusEqualsToken]:'-='
    };
    const op=ops[n.operatorToken.kind];if(!op)die(n,'unsupported operator '+ts.tokenToString(n.operatorToken.kind));
    if(['=','+=','-='].includes(op)){
      const lhs=ts.isIdentifier(n.left)?ident(n.left):property(n.left);
      if(ts.isIdentifier(n.left)&&!locals.has(lhs))die(n.left,'unbound assignment');
      if(lhs==='event'||lhs==='arg'||lhs==='version')die(n,'argument assignment not supported');
      return `(${lhs} ${op} ${expr(n.right)})`;
    }
    return `(${expr(n.left)} ${op} ${expr(n.right)})`;
  }
  if(ts.isCallExpression(n)){
    if(!ts.isPropertyAccessExpression(n.expression)||ident(n.expression.expression)!=='cap')die(n,'only cap.emit/cap.abort calls supported');
    const f=ident(n.expression.name);const arity={emit:1,abort:1,rect:5};
    if(!(f in arity)||n.arguments.length!==arity[f])die(n,'unsupported host call');
    return `pico_cap_${f}(${n.arguments.map(expr).join(', ')})`;
  }
  die(n,`unsupported expression ${K[n.kind]}`);
}
function stmt(n, level=1) {
  const pad='  '.repeat(level);
  if(ts.isBlock(n))return `\n${pad}{\n${n.statements.map(s=>stmt(s,level+1)).join('')} ${pad}}\n`;
  if(ts.isIfStatement(n))return `${pad}if (${expr(n.expression)}) {\n${stmtBody(n.thenStatement,level+1)}${pad}}${n.elseStatement?` else {\n${stmtBody(n.elseStatement,level+1)}${pad}}`:''}\n`;
  if(ts.isWhileStatement(n))return `${pad}while (${expr(n.expression)}) {\n${stmtBody(n.statement,level+1)}${pad}}\n`;
  if(ts.isReturnStatement(n))return `${pad}return ${n.expression?expr(n.expression):'0'};\n`;
  if(ts.isExpressionStatement(n))return `${pad}${expr(n.expression)};\n`;
  if(ts.isVariableStatement(n)){
    let s='';for(const d of n.declarationList.declarations){const name=ident(d.name);if(locals.has(name))die(d,'duplicate local '+name);if(!d.initializer)die(d,'local must have initializer');locals.add(name);s+=`${pad}int32_t ${name} = ${d.initializer?expr(d.initializer):'0'};\n`;}return s;
  }
  if(ts.isEmptyStatement(n))return `${pad};\n`;
  die(n,`unsupported statement ${K[n.kind]}`);
}
function stmtBody(n,l){return (ts.isBlock(n)?n.statements:[n]).map(s=>stmt(s,l)).join('');}
let schema=null;const funs={};
for(const s of ast.statements){
  if(ts.isVariableStatement(s)){
    for(const d of s.declarationList.declarations){if(ident(d.name)!=='schema'||schema!==null)die(d,'only one top-level const schema is supported');schema=literal(d.initializer);}
  } else if(ts.isFunctionDeclaration(s)){
    const name=ident(s.name);if(!['step','migrate'].includes(name)||funs[name])die(s,'expected step and optional migrate');
    const expected=name==='step'?['state','event','arg']:['state','version'];
    if(s.parameters.length!==expected.length||s.parameters.some((p,i)=>ident(p.name)!==expected[i]))die(s,'bad signature of '+name);
    if(!s.body)die(s,'missing body');
    locals = new Set(['state','event','arg','version']);
    const body=stmtBody(s.body,1);
    funs[name]=`int32_t pico_world_${name}(PicoState *state, ${name==='step'?'uint32_t event, int32_t arg':'uint32_t version'}) {\n${body}  return 0;\n}\n`;
  } else die(s,'only functions and const schema at top level');
}
if(schema===null||schema<1||schema>1000)throw new Error('expected const schema = integer (1..1000)');
if(!funs.step)throw new Error('expected function step(state, event, arg)');
const out=`/* GENERATED by js2c.js from restricted integer JS; not full ECMAScript. */\n#include "pico_abi.h"\n#define PICO_SCHEMA ${schema}\n${funs.step}\n${funs.migrate||`int32_t pico_world_migrate(PicoState *state, uint32_t version) { (void)version; state->schema = PICO_SCHEMA; return 0; }\n`}\n`;
process.stdout.write(out);
