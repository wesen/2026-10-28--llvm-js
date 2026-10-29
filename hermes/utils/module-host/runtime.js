// Source-text module lifecycle for a closed, build-time supplied graph.
// This function and the generated module factories compile through LLVM.
function createModuleHost(definitions, aliases) {
  'use strict';
  const records = Object.create(null);
  const marker = {};
  const ambiguous = {};
  let nextAsyncOrder = 0;
  const PromiseCtor = Promise;
  const resolvePromise = Promise.resolve.bind(Promise);
  const apply = Reflect.apply;
  const own = (object, key) => Object.prototype.hasOwnProperty.call(object, key);
  function then(promise, fulfilled, rejected) {
    return $SHBuiltin.moduleThen(promise, fulfilled, rejected);
  }
  function capability() {
    let resolve, reject;
    const promise = new PromiseCtor((yes, no) => { resolve = yes; reject = no; });
    return {promise, resolve, reject};
  }
  for (const definition of definitions) {
    records[definition.id] = {
      definition, id: definition.id, state: 'new', cells: Object.create(null),
      namespace: null, namespaceCell: null, iterator: null, error: undefined, failed: false,
      ancestor: 0, root: null, order: null, pending: 0, parents: [], completion: null,
      meta: Object.assign(Object.create(null), {url: definition.url})
    };
  }
  function record(id) {
    if (!own(records, id)) throw new TypeError('Module is not included: ' + id);
    return records[id];
  }
  function resolve(referrer, request) {
    // Template substitution uses ToString (including a Symbol TypeError).
    const specifier = `${request}`;
    if (!(specifier.startsWith('./') || specifier.startsWith('../')) ||
        /[?#\\\u0000]/.test(specifier))
      throw new TypeError('Only exact relative module paths are supported: ' + specifier);
    const parts = referrer.split('/');
    parts.pop();
    for (const part of specifier.split('/')) {
      if (part === '.' || part === '') continue;
      if (part === '..') { if (!parts.length) throw new TypeError('Module path escapes graph root'); parts.pop(); }
      else parts.push(part);
    }
    const path = parts.join('/');
    return own(aliases, path) ? aliases[path] : path;
  }
  function failure(definition) {
    const error = definition.error;
    if (error) throw error.type === 'SyntaxError'
      ? new SyntaxError(error.message) : new TypeError(error.message);
  }
  function exportCell(module, name, seen) {
    const key = JSON.stringify([module.id, name]);
    if (seen.indexOf(key) >= 0) return null;
    const next = seen.concat([key]);
    const entries = module.definition.exports;
    if (own(entries, name)) {
      const entry = entries[name];
      if (entry.local !== undefined) return module.cells[entry.local];
      const target = record(entry.from);
      if (entry.name === '*') {
        if (!target.namespaceCell) target.namespaceCell = {read: () => namespace(target)};
        return target.namespaceCell;
      }
      return exportCell(target, entry.name, next);
    }
    if (name === 'default') return null;
    let found = null;
    for (const id of module.definition.stars) {
      const candidate = exportCell(record(id), name, next);
      if (candidate === ambiguous) return ambiguous;
      if (candidate !== null && candidate !== undefined) {
        if (found && candidate !== found) return ambiguous;
        found = candidate;
      }
    }
    return found;
  }
  function requireCell(module, name) {
    const cell = exportCell(module, name, []);
    if (!cell || cell === ambiguous)
      throw new SyntaxError('Missing or ambiguous export ' + name + ' in ' + module.id);
    return cell;
  }
  function exportNames(module, visited) {
    if (visited.indexOf(module.id) >= 0) return [];
    const seen = visited.concat([module.id]);
    const names = Object.keys(module.definition.exports);
    for (const id of module.definition.stars)
      for (const name of exportNames(record(id), seen))
        if (name !== 'default' && names.indexOf(name) < 0) names.push(name);
    return names;
  }
  function namespace(module) {
    if (module.namespace) return module.namespace;
    const cells = Object.create(null);
    const target = Object.create(null);
    const names = exportNames(module, []).filter(name => {
      const cell = exportCell(module, name, []);
      if (!cell || cell === ambiguous) return false;
      cells[name] = cell;
      return true;
    }).sort();
    for (const name of names)
      Object.defineProperty(target, name, {value: undefined, writable: true, enumerable: true, configurable: false});
    Object.defineProperty(target, Symbol.toStringTag, {value: 'Module'});
    Object.preventExtensions(target);
    module.namespace = new Proxy(target, {
      get(object, key) { return own(cells, key) ? cells[key].read() : Reflect.get(object, key); },
      getOwnPropertyDescriptor(object, key) {
        return own(cells, key)
          ? {value: cells[key].read(), writable: true, enumerable: true, configurable: false}
          : Reflect.getOwnPropertyDescriptor(object, key);
      },
      ownKeys() { return names.concat([Symbol.toStringTag]); },
      set() { return false; },
      defineProperty(object, key, descriptor) {
        if (!own(cells, key)) return Reflect.defineProperty(object, key, descriptor);
        if (descriptor.configurable || descriptor.enumerable === false ||
            descriptor.writable === false || own(descriptor, 'get') || own(descriptor, 'set')) return false;
        return !own(descriptor, 'value') || Object.is(descriptor.value, cells[key].read());
      },
      deleteProperty(object, key) { return !own(object, key); },
      setPrototypeOf(object, prototype) { return prototype === null; }
    });
    return module.namespace;
  }
  function iteratorResult(value) {
    if (value === null || (typeof value !== 'object' && typeof value !== 'function'))
      throw new TypeError('Iterator result is not an object');
    return value;
  }
  function asyncIterator(value) {
    const asyncMethod = value[Symbol.asyncIterator];
    const synchronous = asyncMethod == null;
    const method = synchronous ? value[Symbol.iterator] : asyncMethod;
    const iterator = iteratorResult(apply(method, value, []));
    const next = iterator.next;
    function continuation(result) {
      iteratorResult(result);
      const done = !!result.done;
      return then(resolvePromise(result.value), value => ({value, done}));
    }
    return {
      next() {
        const result = apply(next, iterator, []);
        return synchronous ? continuation(result) : result;
      },
      close() {
        const method = iterator.return;
        if (method == null) return synchronous ? () => resolvePromise({value: undefined, done: true}) : null;
        return () => {
          const result = apply(method, iterator, []);
          return synchronous ? continuation(result) : result;
        };
      }
    };
  }
  function context(module) {
    return {
      instantiated: marker,
      iterator: asyncIterator,
      result: iteratorResult,
      bind(name, read) { module.cells[name] = {read}; },
      defaultName(value) { Object.defineProperty(value, 'name', {value: 'default', configurable: true}); return value; },
      target(id, name) {
        return {
          get value() { return name === '*' ? namespace(record(id)) : requireCell(record(id), name).read(); },
          set value(value) { throw new TypeError('Cannot assign an imported binding'); }
        };
      },
      read(id, name) { return requireCell(record(id), name).read(); },
      namespace(id) { return namespace(record(id)); },
      import(request, options) {
        return new PromiseCtor((fulfill, reject) => {
          // Conversion belongs to import evaluation, but errors reject its Promise.
          let id;
          try {
            id = resolveRequest(request);
            if (options !== undefined) {
              if (options === null || (typeof options !== 'object' && typeof options !== 'function'))
                throw new TypeError('Import options must be an object');
              const attributes = options.with;
              if (attributes !== undefined) {
                if (attributes === null || (typeof attributes !== 'object' && typeof attributes !== 'function'))
                  throw new TypeError('Import attributes must be an object');
                const keys = Object.keys(attributes);
                for (const key of keys)
                  if (typeof attributes[key] !== 'string') throw new TypeError('Import attribute values must be strings');
                if (keys.length) throw new TypeError('Import attributes are not supported by this module host');
              }
            }
          } catch (error) { reject(error); return; }
          then(resolvePromise(), () => {
            try {
              const target = record(id);
              link(target);
              then(evaluate(target), () => fulfill(namespace(target)), reject);
            } catch (error) { reject(error); }
          }, reject);
        });
        function resolveRequest(request) { return resolve(module.id, request); }
      },
      meta: module.meta,
      global(name) {
        if (!(name in globalThis)) throw new ReferenceError(name + ' is not defined');
        return globalThis[name];
      },
      globalTypeof(name) { return name in globalThis ? typeof globalThis[name] : 'undefined'; }
    };
  }
  function link(entry) {
    if (entry.failed) throw entry.error;
    if (entry.state !== 'new') return;
    const pending = [];
    function instantiate(module) {
      if (module.failed) throw module.error;
      if (module.state !== 'new') return;
      failure(module.definition);
      module.state = 'linking';
      pending.push(module);
      module.iterator = apply(module.definition.factory, undefined, [context(module)]);
      const result = module.iterator.next();
      if (result.done || result.value !== marker) throw new Error('Invalid module instantiation suspension');
      for (const id of module.definition.dependencies) instantiate(record(id));
    }
    try {
      instantiate(entry);
      // Every reachable cell exists before resolving aliases and star cycles.
      for (const module of pending) {
        for (const entry of module.definition.imports)
          if (entry.name !== '*') requireCell(record(entry.from), entry.name);
        for (const name of Object.keys(module.definition.exports))
          requireCell(module, name);
      }
      for (const module of pending) module.state = 'linked';
    } catch (error) {
      // Undo unfinished instantiation; a bad importer must not poison valid
      // dependencies that another graph can subsequently link and evaluate.
      for (const module of pending) {
        module.state = 'new'; module.iterator = null;
        module.cells = Object.create(null); module.namespace = null;
      }
      entry.failed = true; entry.error = error; entry.state = 'failed';
      throw error;
    }
  }
  function executeSync(module) {
    const result = module.iterator.next();
    if (!result.done) throw new Error('Synchronous module unexpectedly suspended');
  }
  function executeAsync(module) {
    const done = capability();
    function resume(method, value) {
      let result;
      try { result = module.iterator[method](value); }
      catch (error) { done.reject(error); return; }
      if (result.done) { done.resolve(); return; }
      then(resolvePromise(result.value), value => resume('next', value), error => resume('throw', error));
    }
    resume('next', undefined);
    then(done.promise, () => fulfilled(module), error => rejected(module, error));
  }
  function rejected(module, error) {
    if (module.failed) return;
    module.failed = true; module.error = error; module.state = 'evaluated';
    if (module.completion) module.completion.reject(error);
    for (const parent of module.parents) rejected(parent, error);
  }
  function gather(module, ready) {
    for (const parent of module.parents) {
      if (ready.indexOf(parent) >= 0 || parent.root.failed) continue;
      parent.pending--;
      if (parent.pending === 0) {
        ready.push(parent);
        if (!parent.definition.async) gather(parent, ready);
      }
    }
  }
  function fulfilled(module) {
    if (module.failed) return;
    module.order = null; module.state = 'evaluated';
    if (module.completion) module.completion.resolve();
    const ready = [];
    gather(module, ready);
    ready.sort((a, b) => a.order - b.order);
    for (const parent of ready) {
      if (parent.failed) continue;
      if (parent.definition.async) executeAsync(parent);
      else {
        try {
          executeSync(parent);
          parent.order = null; parent.state = 'evaluated';
          if (parent.completion) parent.completion.resolve();
        } catch (error) { rejected(parent, error); }
      }
    }
  }
  function inner(module, stack, index) {
    if (module.failed) throw module.error;
    if (module.state === 'evaluated' || module.state === 'evaluating-async' || module.state === 'evaluating') return index;
    module.state = 'evaluating';
    const moduleIndex = index;
    module.ancestor = index++;
    stack.push(module);
    for (const id of module.definition.dependencies) {
      let required = record(id);
      index = inner(required, stack, index);
      if (required.state === 'evaluating') module.ancestor = Math.min(module.ancestor, required.ancestor);
      else {
        required = required.root;
        if (required.failed) throw required.error;
      }
      if (required.order !== null) {
        module.pending++;
        required.parents.push(module);
      }
    }
    if (module.pending > 0 || module.definition.async) {
      module.order = nextAsyncOrder++;
      if (module.pending === 0) executeAsync(module);
    } else executeSync(module);
    if (module.ancestor === moduleIndex) {
      let required;
      do {
        required = stack.pop();
        required.state = required.order === null ? 'evaluated' : 'evaluating-async';
        required.root = module;
      } while (required !== module);
    }
    return index;
  }
  function evaluate(entry) {
    if (entry.state === 'evaluated' || entry.state === 'evaluating-async') entry = entry.root;
    if (entry.completion) return entry.completion.promise;
    entry.completion = capability();
    if (entry.failed) { entry.completion.reject(entry.error); return entry.completion.promise; }
    const stack = [];
    try {
      inner(entry, stack, 0);
      if (entry.order === null) entry.completion.resolve();
    } catch (error) {
      for (const module of stack) {
        module.failed = true; module.error = error; module.state = 'evaluated'; module.root = entry;
      }
      entry.failed = true; entry.error = error;
      entry.completion.reject(error);
    }
    return entry.completion.promise;
  }
  return {
    check(id) { link(record(id)); },
    run(id, onComplete, onError) {
      const entry = record(id);
      link(entry);
      then(evaluate(entry), onComplete, onError);
    }
  };
}
