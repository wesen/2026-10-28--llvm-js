#!/usr/bin/env python3
"""Run a pinned Test262 selection through direct LLVM (never silently skip).

This is an initial script host, not a full conformance claim. Modules and
unavailable host capabilities are reported explicitly. No inherited skip list
is applied. See docs/llvm/TEST262.md for evidence and remaining boundaries.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import os
import signal
from pathlib import Path
import re
import subprocess
import tempfile
import time

import shllvm
from testsuite.external.parse_test262 import parseTestRecord, findAttrs

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / 'test/LLVMTest262/suite-lock.json'
SANITIZERS = ('AddressSanitizer', 'LeakSanitizer', 'UndefinedBehaviorSanitizer',
              'runtime error:', 'Assertion failed', 'Assertion `')


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def invoke(command, timeout, cwd):
    start = time.monotonic()
    result = {'command': [str(x) for x in command], 'exit_code': None,
              'stdout': '', 'stderr': ''}
    try:
        # Files bound Python memory use; kill the entire tool process group on
        # timeout so a compiler's linker child cannot outlive its test.
        with tempfile.TemporaryFile() as out, tempfile.TemporaryFile() as err:
            proc = subprocess.Popen(result['command'], cwd=cwd, stdout=out,
                                    stderr=err, start_new_session=True)
            try:
                result['exit_code'] = proc.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                result['failure'] = 'timeout'
                os.killpg(proc.pid, signal.SIGKILL)
                proc.wait()
            for key, stream in [('stdout', out), ('stderr', err)]:
                stream.seek(0)
                data = stream.read(1024 * 1024 + 1)
                if len(data) > 1024 * 1024:
                    result.setdefault('failure', 'infrastructure_error')
                    result['output_truncated'] = True
                result[key] = data[:1024 * 1024].decode(errors='replace')
    except OSError as exc:
        result.update(failure='infrastructure_error', stderr=str(exc))
    result['seconds'] = round(time.monotonic() - start, 6)
    return result


def process_failure(record):
    if record.get('failure'):
        return record['failure']
    if record['exit_code'] is not None and record['exit_code'] < 0:
        return 'crash'
    if any(x in record['stderr'] for x in SANITIZERS):
        return 'crash'
    return None


def classify(record, phase, expected=None, asynchronous=False):
    """Only a known language diagnostic can satisfy a negative contract."""
    failure = process_failure(record)
    if failure:
        return failure
    if phase not in ('parse', 'runtime'):
        return 'unsupported' if phase == 'compile' else 'infrastructure_error'
    error = None
    if phase == 'parse' and record['exit_code'] == 1:
        if re.search(r'^.+:\d+:\d+: error:', record['stderr'], re.M):
            error = 'SyntaxError'
    elif phase == 'runtime' and record['exit_code'] == 1:
        match = re.search(r'^SHLLVM_TEST262_EXCEPTION:([A-Za-z]+Error)$', record['stderr'], re.M)
        if match:
            error = match.group(1)
    if asynchronous:
        lines = record['stdout'].splitlines()
        if any(x.startswith('Test262:AsyncTestFailure:') for x in lines):
            return 'semantic_failure'
        if lines.count('Test262:AsyncTestComplete') != 1:
            return 'semantic_failure'
    if expected:
        return ('pass' if error and expected == {'phase': phase, 'type': error}
                else 'semantic_failure')
    return 'pass' if record['exit_code'] == 0 else 'semantic_failure'


def metadata(source, name):
    if findAttrs(source)[1] is None:
        raise ValueError('missing Test262 metadata')
    meta = parseTestRecord(source, name, verbose=False)
    for key in ('flags', 'includes', 'features'):
        values = meta.get(key, [])
        if not isinstance(values, list) or any(not isinstance(x, str) for x in values):
            raise ValueError(f'invalid {key}')
    flags = set(meta.get('flags', []))
    if 'onlyStrict' in flags and flags.intersection({'noStrict', 'raw', 'module'}):
        raise ValueError('conflicting strictness flags')
    negative = meta.get('negative')
    if negative is not None and (not isinstance(negative, dict) or
            set(negative) != {'phase', 'type'} or
            negative['phase'] not in ('parse', 'resolution', 'runtime') or
            not isinstance(negative['type'], str)):
        raise ValueError('invalid negative expectation')
    return meta


def variants(meta):
    flags = meta.get('flags', [])
    if 'module' in flags:
        return ['module']
    if 'raw' in flags or 'noStrict' in flags:
        return ['sloppy']
    if 'onlyStrict' in flags:
        return ['strict']
    return ['sloppy', 'strict']


def prepare_source(source, meta, variant, suite):
    if 'raw' in meta.get('flags', []):
        return source, []
    names = ['sta.js', 'assert.js']
    if 'async' in meta.get('flags', []):
        names.append('doneprintHandle.js')
    names += meta.get('includes', [])
    harness = (suite / 'harness').resolve()
    paths = [(harness / name).resolve() for name in dict.fromkeys(names)]
    if any(not p.is_relative_to(harness) for p in paths):
        raise ValueError('harness include escapes harness directory')
    # Keep the test body and its metadata intact; never wrap it in a function.
    prefix = '"use strict";\n' if variant == 'strict' else ''
    return prefix + ''.join(p.read_text() + '\n' for p in paths) + source, paths


def unsupported_reason(meta):
    flags = set(meta.get('flags', []))
    features = set(meta.get('features', []))
    if 'module' in flags:
        return 'module loading/linking/evaluation is not implemented by this runner'
    missing = features.intersection({'cross-realm', 'SharedArrayBuffer', 'Atomics', 'IsHTMLDDA'})
    if missing:
        return 'host capability unavailable: ' + ', '.join(sorted(missing))
    if flags.intersection({'CanBlockIsTrue', 'CanBlockIsFalse'}):
        return 'agent blocking policy is not implemented by this runner'
    return None


def execute_variant(path, meta, variant, suite, args, context, directory):
    result = {'test': str(path.relative_to(suite)), 'source_sha256': digest(path),
              'variant': variant, 'features': meta.get('features', []),
              'expected': meta.get('negative'), 'commands': []}
    reason = unsupported_reason(meta)
    if reason:
        return dict(result, status='unsupported', reason=reason)
    try:
        source, includes = prepare_source(path.read_bytes().decode('utf-8'), meta, variant, suite)
    except (OSError, ValueError) as exc:
        return dict(result, status='harness_error', reason=str(exc))
    result['includes'] = {str(p.relative_to(suite)): digest(p) for p in includes}
    generated = directory / 'test.js'
    generated.write_bytes(source.encode('utf-8'))
    result['prepared_sha256'] = digest(generated)
    build, settings, tools, compiler, runtime, asan, ubsan = context
    frontend = [compiler, f'-{args.hermes_opt}', '-test262', '-fno-static-builtins',
                '-Xes6-block-scoping', '-Xenable-tdz', '-Xasync-generators']
    expected = meta.get('negative')
    # Parse negatives get frontend parsing and semantic validation: an emitter crash or unsupported
    # instruction must never satisfy a SyntaxError expectation.
    if expected and expected['phase'] == 'parse':
        record = invoke([*frontend, '-dump-transformed-ast', generated], args.compile_timeout, directory)
        result['commands'].append(record)
        return dict(result, status=classify(record, 'parse', expected), observed_phase='parse')
    raw, bitcode, optimized, executable = [directory / x for x in ('test.ll', 'test.bc', 'opt.bc', 'program')]
    library_dirs = [build / 'lib', build / 'tools/shermes', build / 'jsi']
    linkflags = [flag for p in library_dirs for flag in (f'-L{p}', f'-Wl,-rpath,{p}')]
    if asan:
        linkflags.append('-fsanitize=address')
    if ubsan:
        linkflags.append('-fsanitize=undefined')
    pipeline = 'verify' if args.llvm_opt == '0' else f'verify,default<O{args.llvm_opt}>,verify'
    stages = [
        ('compile', [*frontend, '-emit-llvm', generated, '-o', raw]),
        ('assemble', [tools['llvm-as'], raw, '-o', bitcode]),
        ('verify', [tools['opt'], f'-passes={pipeline}', bitcode, '-o', optimized]),
        ('link', [tools['clang'], optimized, f'-O{args.llvm_opt}', '-Wno-override-module',
                  *linkflags, runtime, '-lshermes_console', '-lhermesvm', '-lm', '-o', executable])]
    for phase, command in stages:
        record = invoke(command, args.compile_timeout, directory)
        result['commands'].append(record)
        if record['exit_code'] != 0:
            return dict(result, status=classify(record, phase, expected), observed_phase=phase)
    record = invoke([executable, '--shllvm-test262', '-Xhermes-internal-test-methods', '-Xes6-proxy',
                     '-Xmicrotask-queue'], args.run_timeout, directory)
    result['commands'].append(record)
    result['artifacts'] = {p.name: digest(p) for p in (raw, bitcode, optimized, executable)}
    return dict(result, status=classify(record, 'runtime', expected,
                                       'async' in meta.get('flags', [])), observed_phase='runtime')


def write_report(path, report):
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(report, indent=2) + '\n')
    temporary.replace(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--suite', type=Path, required=True)
    parser.add_argument('--build-dir', required=True)
    parser.add_argument('--llvm-bin', required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--hermes-opt', choices=['O0', 'O'], default='O0')
    parser.add_argument('--llvm-opt', choices=['0', '2'], default='0')
    parser.add_argument('--compile-timeout', type=float, default=60)
    parser.add_argument('--run-timeout', type=float, default=10)
    parser.add_argument('paths', nargs='+', help='suite-relative files or directories; explicit selection required')
    args = parser.parse_args()
    if min(args.compile_timeout, args.run_timeout) <= 0:
        parser.error('timeouts must be positive')
    suite = args.suite.resolve()
    lock = json.loads(LOCK.read_text())
    if digest(suite / 'INTERPRETING.md') != lock['interpretation_sha256']:
        parser.error('Test262 interpretation document hash mismatch')
    revision = subprocess.check_output(['git', '-C', str(suite), 'rev-parse', 'HEAD'], text=True).strip()
    if revision != lock['test262_revision']:
        parser.error(f'suite revision mismatch: expected {lock["test262_revision"]}, got {revision}')
    if subprocess.check_output(['git', '-C', str(suite), 'status', '--porcelain'], text=True).strip():
        parser.error('suite checkout must be clean')
    files = set()
    for selection in args.paths:
        path = (suite / selection).resolve()
        if not path.is_relative_to(suite / 'test') or not path.exists():
            parser.error(f'invalid selection: {selection}')
        files.update(path.rglob('*.js') if path.is_dir() else [path])
    if not files:
        parser.error('selection contains no JavaScript files')
    args.output = args.output.resolve()
    if args.output.is_relative_to(suite):
        parser.error('output must be outside the pinned suite')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.action, args.compiler, args.no_runtime_build = 'build', None, True
    context = shllvm.prepare(args)
    build = context[0]
    inputs = files | set((suite / 'harness').rglob('*.js')) | {
        Path(__file__).resolve(), LOCK, Path(shllvm.__file__).resolve(),
        *context[2].values(),
        *Path(__file__).resolve().parent.joinpath('testsuite/external').glob('*.py'),
        build / 'CMakeCache.txt', build / 'lib/config/libhermesvm-config.h',
        build / 'bin/shermes', build / 'lib/libshllvm_runtime.a',
        build / 'lib/libhermesvm.so', build / 'tools/shermes/libshermes_console.so'}
    fingerprints = {str(p): digest(p) for p in sorted(inputs)}
    report = {'complete': False, 'scope': 'explicit selection; not full ECMAScript conformance',
              'suite_revision': revision, 'specification': lock['specification'],
              'selection': args.paths, 'hermes_opt': args.hermes_opt, 'llvm_opt': args.llvm_opt,
              'fingerprints': fingerprints, 'results': [], 'fixtures': [],
              'host_limitations': ['modules', 'cross-realm', 'agents/shared memory',
                                   'asynchronous uncaught exceptions lack structured identity']}
    write_report(args.output, report)
    for path in sorted(files):
        if '_FIXTURE' in path.name:
            report['fixtures'].append(str(path.relative_to(suite)))
            continue
        try:
            meta = metadata(path.read_bytes().decode('utf-8'), str(path))
        except (ValueError, TypeError, OSError) as exc:
            report['results'].append({'test': str(path.relative_to(suite)),
                                      'status': 'harness_error', 'reason': str(exc)})
            continue
        for variant in variants(meta):
            with tempfile.TemporaryDirectory(prefix='shllvm-test262-') as tmp:
                result = execute_variant(path, meta, variant, suite, args, context, Path(tmp))
            report['results'].append(result)
            print(result['status'], result['test'], variant, flush=True)
            write_report(args.output, report)
    report['changed_inputs'] = [str(p) for p in inputs if not p.is_file() or digest(p) != fingerprints[str(p)]]
    report['counts'] = dict(Counter(r['status'] for r in report['results']))
    report['suite_dirty_after'] = bool(subprocess.check_output(
        ['git', '-C', str(suite), 'status', '--porcelain'], text=True).strip())
    report['complete'] = not report['changed_inputs'] and not report['suite_dirty_after']
    write_report(args.output, report)
    return 0 if report['complete'] and set(report['counts']) == {'pass'} else 1


if __name__ == '__main__':
    raise SystemExit(main())
