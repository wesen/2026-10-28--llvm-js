#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {pathToFileURL} = require('node:url');
const parser = require('@babel/parser');
const traverse = require('@babel/traverse').default;
const generate = require('@babel/generator').default;
const t = require('@babel/types');
const hash = data => crypto.createHash('sha256').update(data).digest('hex');
const clone = node => t.cloneNode(node, true);

function compileGraph(entryPath, options = {}) {
  const entry = fs.realpathSync(entryPath);
  const root = fs.realpathSync(options.root || path.dirname(entry));
  const definitions = new Map();
  const aliases = Object.create(null);
  const inputs = Object.create(null);
  function identity(file) {
    const relative = path.relative(root, file).split(path.sep).join('/');
    if (relative.startsWith('../') || relative === '..' || path.isAbsolute(relative))
      throw new TypeError('Module path escapes graph root: ' + file);
    return relative;
  }
  function locate(file) {
    const lexical = path.resolve(file);
    let canonical;
    try { canonical = fs.realpathSync(lexical); } catch (_) { canonical = lexical; }
    const id = identity(canonical);
    aliases[identity(lexical)] = id;
    return {id, file: canonical};
  }
  function resolve(file, specifier) {
    if (!(specifier.startsWith('./') || specifier.startsWith('../')) || /[?#\\\u0000]/.test(specifier))
      throw new TypeError('Only exact relative module paths are supported: ' + specifier);
    return locate(path.resolve(path.dirname(file), specifier));
  }
  function discover(location) {
    if (definitions.has(location.id)) return location.id;
    const definition = {id: location.id, url: pathToFileURL(location.file).href,
      dependencies: [], imports: [], exports: Object.create(null), stars: [], async: false};
    definitions.set(location.id, definition);
    try {
      const bytes = fs.readFileSync(location.file);
      inputs[location.file] = hash(bytes);
      // Invalid UTF-8 must not silently become replacement characters.
      const source = new TextDecoder('utf-8', {fatal: true}).decode(bytes);
      const ast = parser.parse(source, {sourceType: 'module', createImportExpressions: true});
      let program;
      traverse(ast, {Program(p) { program = p; p.stop(); }});
      const contextId = program.scope.generateUidIdentifier('moduleContext');
      const contextCall = (method, args) => t.callExpression(t.memberExpression(clone(contextId), t.identifier(method)), args);
      const imports = new Map();
      const localExports = new Set();
      const defaultFunctions = [];
      const originalNodes = ast.program.body.slice();
      const replacements = new Map();
      function dependency(specifier) {
        const target = resolve(location.file, specifier);
        discover(target);
        if (!definition.dependencies.includes(target.id)) definition.dependencies.push(target.id);
        return target.id;
      }
      const nameOf = node => t.isIdentifier(node) ? node.name : node.value;
      function exportLocal(exported, local) { definition.exports[exported] = {local}; localExports.add(local); }
      for (const node of originalNodes) {
        if ((node.assertions && node.assertions.length) || (node.attributes && node.attributes.length))
          throw new SyntaxError('Import attributes are not supported by this module host');
        if (t.isImportDeclaration(node)) {
          const from = dependency(node.source.value);
          for (const specifier of node.specifiers) {
            const name = t.isImportNamespaceSpecifier(specifier) ? '*' :
              t.isImportDefaultSpecifier(specifier) ? 'default' : nameOf(specifier.imported);
            const binding = program.scope.getBinding(specifier.local.name);
            imports.set(specifier.local.name, {from, name, binding});
            definition.imports.push({from, name});
          }
          replacements.set(node, []);
        } else if (t.isExportAllDeclaration(node)) {
          definition.stars.push(dependency(node.source.value));
          replacements.set(node, []);
        } else if (t.isExportNamedDeclaration(node)) {
          if (node.declaration) {
            for (const local of Object.keys(t.getBindingIdentifiers(node.declaration))) exportLocal(local, local);
            replacements.set(node, [node.declaration]);
          } else {
            const from = node.source ? dependency(node.source.value) : null;
            for (const specifier of node.specifiers) {
              const exported = nameOf(specifier.exported);
              if (from !== null) definition.exports[exported] = {from, name: t.isExportNamespaceSpecifier(specifier) ? '*' : nameOf(specifier.local)};
              else exportLocal(exported, nameOf(specifier.local));
            }
            replacements.set(node, []);
          }
        } else if (t.isExportDefaultDeclaration(node)) {
          const value = node.declaration;
          if (t.isFunctionDeclaration(value) || t.isClassDeclaration(value)) {
            if (!value.id) {
              value.id = program.scope.generateUidIdentifier('default');
              if (t.isFunctionDeclaration(value)) defaultFunctions.push(value.id.name);
              else {
                const id = value.id;
                const expression = t.classExpression(null, value.superClass, value.body, value.decorators || []);
                exportLocal('default', id.name);
                replacements.set(node, [t.variableDeclaration('const', [t.variableDeclarator(id, contextCall('defaultName', [expression]))])]);
                continue;
              }
            }
            exportLocal('default', value.id.name);
            replacements.set(node, [value]);
          } else {
            const id = program.scope.generateUidIdentifier('default');
            exportLocal('default', id.name);
            replacements.set(node, [t.variableDeclaration('const', [t.variableDeclarator(id,
              t.isArrowFunctionExpression(value) || ((t.isFunctionExpression(value) || t.isClassExpression(value)) && !value.id)
                ? contextCall('defaultName', [value]) : value)])]);
          }
        }
      }
      // An export of an imported local resolves to the original cell identity.
      for (const exported of Object.keys(definition.exports)) {
        const item = definition.exports[exported];
        if (item.local !== undefined && imports.has(item.local)) {
          const imported = imports.get(item.local);
          definition.exports[exported] = {from: imported.from, name: imported.name};
          localExports.delete(item.local);
        }
      }
      function importRead(imported) {
        return contextCall(imported.name === '*' ? 'namespace' : 'read',
          imported.name === '*' ? [t.stringLiteral(imported.from)] : [t.stringLiteral(imported.from), t.stringLiteral(imported.name)]);
      }
      function rewriteTarget(p) {
        if (!p || !p.node) return;
        if (p.isIdentifier()) {
          const imported = imports.get(p.node.name);
          if (imported && p.scope.getBinding(p.node.name) === imported.binding)
            p.replaceWith(t.memberExpression(contextCall('target',
              [t.stringLiteral(imported.from), t.stringLiteral(imported.name)]), t.identifier('value')));
        } else if (p.isObjectPattern()) {
          for (const property of p.get('properties')) {
            if (property.isRestElement()) rewriteTarget(property.get('argument'));
            else { property.node.shorthand = false; rewriteTarget(property.get('value')); }
          }
        } else if (p.isArrayPattern()) {
          for (const element of p.get('elements')) rewriteTarget(element);
        } else if (p.isRestElement()) rewriteTarget(p.get('argument'));
        else if (p.isAssignmentPattern()) rewriteTarget(p.get('left'));
      }
      for (const imported of imports.values()) {
        for (const violation of imported.binding.constantViolations) {
          if (violation.isAssignmentExpression() || violation.isForOfStatement() || violation.isForInStatement()) rewriteTarget(violation.get('left'));
          else if (violation.isUpdateExpression()) rewriteTarget(violation.get('argument'));
        }
      }
      // Rewrite only references belonging to an import binding; preserve shadowing.
      for (const imported of imports.values()) {
        for (const ref of imported.binding.referencePaths) {
          if (ref.parentPath.isExportSpecifier() || !ref.isIdentifier()) continue;
          ref.replaceWith(importRead(imported));
        }
      }
      function topLevelThis(p) {
        for (let ancestor = p.parentPath; ancestor; ancestor = ancestor.parentPath) {
          if (ancestor.isFunction() && !ancestor.isArrowFunctionExpression()) return false;
          if (ancestor.isClassProperty() || ancestor.isClassPrivateProperty() || ancestor.isStaticBlock()) return false;
        }
        return true;
      }
      traverse(ast, {
        CallExpression(p) {
          if (t.isIdentifier(p.node.callee, {name: 'eval'}) && !p.scope.getBinding('eval'))
            throw new SyntaxError('Direct eval in source modules is not supported by this module host');
        },
        ThisExpression(p) { if (topLevelThis(p)) p.replaceWith(t.unaryExpression('void', t.numericLiteral(0))); },
        ReferencedIdentifier(p) {
          if (p.node.name !== 'arguments' || p.scope.getBinding('arguments') || !topLevelThis(p)) return;
          if (p.parentPath.isUnaryExpression({operator: 'typeof'}))
            p.parentPath.replaceWith(contextCall('globalTypeof', [t.stringLiteral('arguments')]));
          else p.replaceWith(contextCall('global', [t.stringLiteral('arguments')]));
        },
        MetaProperty(p) {
          if (p.node.meta.name === 'import') p.replaceWith(t.memberExpression(clone(contextId), t.identifier('meta')));
        },
        ImportExpression(p) {
          if (t.isStringLiteral(p.node.source)) {
            // A missing/invalid deferred target is represented by a failure record.
            try { discover(resolve(location.file, p.node.source.value)); } catch (_) {}
          }
          const args = [p.node.source];
          if (p.node.options) args.push(p.node.options);
          p.replaceWith(contextCall('import', args));
        },
        ForOfStatement(p) {
          if (p.node.await && !p.getFunctionParent())
            throw new SyntaxError('Top-level for-await is not yet supported by this module host');
        },
        AwaitExpression: {exit(p) {
          if (!p.getFunctionParent()) {
            definition.async = true;
            p.replaceWith(t.yieldExpression(p.node.argument));
          }
        }}
      });
      const body = [];
      for (const node of originalNodes) body.push(...(replacements.has(node) ? replacements.get(node) : [node]));
      const setup = [...localExports].map(name => t.expressionStatement(contextCall('bind',
        [t.stringLiteral(name), t.arrowFunctionExpression([], t.identifier(name))])));
      for (const name of defaultFunctions) setup.push(t.expressionStatement(contextCall('defaultName', [t.identifier(name)])));
      setup.push(t.expressionStatement(t.yieldExpression(t.memberExpression(clone(contextId), t.identifier('instantiated')))));
      const block = t.blockStatement([...setup, ...body], [t.directive(t.directiveLiteral('use strict'))]);
      definition.factorySource = generate(t.functionExpression(null, [contextId], block, true, false)).code;
    } catch (error) {
      definition.error = {type: error instanceof SyntaxError ? 'SyntaxError' : 'TypeError', message: location.id + ': ' + error.message};
      delete definition.factorySource;
    }
    return location.id;
  }
  const entryId = discover(locate(entry));
  for (const include of options.include || []) discover(locate(path.resolve(include)));
  const runtime = fs.readFileSync(path.join(__dirname, 'runtime.js'), 'utf8');
  // Emit a plain object expression (no runtime spread requirement).
  const emitted = [...definitions.values()].map(definition => {
    const {factorySource, ...metadata} = definition;
    const json = JSON.stringify(metadata);
    return json.slice(0, -1) + (factorySource ? ',"factory":' + factorySource : '') + '}';
  });
  // Factories are argument expressions, outside the runtime's lexical scope.
  const source = '(' + runtime.replace(/;?\s*$/, '') + ')([' + emitted.join(',\n') + '],' + JSON.stringify(aliases) +
    ').start(' + JSON.stringify(entryId) + ').catch(function(error) { setTimeout(function() { throw error; }, 0); });\n';
  return {source, manifest: {schema: 1, entry: entryId, root, inputs,
    modules: [...definitions.values()].map(({factorySource, ...metadata}) => metadata),
    aliases, compiler_sha256: hash(fs.readFileSync(__filename)), runtime_sha256: hash(runtime),
    lock_sha256: hash(fs.readFileSync(path.join(__dirname, 'pnpm-lock.yaml')))}};
}
function main(argv) {
  const options = {include: []};
  let entry, output, manifest;
  for (let i = 0; i < argv.length; i++) {
    const argument = argv[i];
    if (argument === '--root') options.root = argv[++i];
    else if (argument === '--include') options.include.push(argv[++i]);
    else if (argument === '--output') output = argv[++i];
    else if (argument === '--manifest') manifest = argv[++i];
    else if (!entry) entry = argument;
    else throw new Error('Unknown argument: ' + argument);
  }
  if (!entry || !output || !manifest) throw new Error('Usage: compiler.cjs entry --output file --manifest file [--root directory] [--include file]');
  const result = compileGraph(entry, options);
  const protectedPaths = Object.keys(result.manifest.inputs).map(file => path.resolve(file));
  for (const target of [output, manifest]) {
    let resolved = path.resolve(target);
    try { resolved = fs.realpathSync(target); } catch (_) {}
    if (protectedPaths.includes(resolved)) throw new Error('Output must not overwrite a module source');
  }
  if (path.resolve(output) === path.resolve(manifest)) throw new Error('Bundle and manifest outputs must differ');
  fs.writeFileSync(output, result.source);
  fs.writeFileSync(manifest, JSON.stringify(result.manifest, null, 2) + '\n');
}
if (require.main === module) {
  try { main(process.argv.slice(2)); }
  catch (error) { console.error(error.stack); process.exitCode = 1; }
}
module.exports = {compileGraph};
