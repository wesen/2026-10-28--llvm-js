#!/usr/bin/env python3
"""Application qualification with retained commands, outputs, identities and oracles."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import os
import signal
import subprocess
import sys
import time
import zipfile
import gzip

ROOT = Path(__file__).resolve().parents[2]
APPS = ROOT / 'hermes/examples/llvm-apps'
NAMES = ['data-pipeline', 'async-queue', 'persistent-host', 'archive-library']
SCALES = {'small': (32, 12, 12, 10), 'medium': (2048, 96, 80, 400),
          'large': (16384, 256, 240, 4000)}
MARKER = '__LLVM_APP_COMPLETED__'


def data_fixture(count):
    rows, rejected, groups, seen = [], [], {}, set()
    for i in range(count):
        row = {'id': f'order-{i}', 'cents': i * 17 + 10,
               'customer': f' Customer{i % 23} ', 'region': ['east', 'north', 'west'][i % 3],
               'items': [{'qty': i % 4 + 1}, {'qty': 2}]}
        # The oracle is generated from intended fixtures, not by re-running JS validation.
        reason = None
        if i % 19 == 1:
            row['id'], reason = 'invalid', 'id'
        elif i % 19 == 2:
            row['id'], reason = 'order-0', 'duplicate'
        elif i % 19 == 3:
            row['cents'], reason = -1, 'amount'
        elif i % 19 == 4:
            row['items'], reason = [{'qty': 0}], 'items'
        rows.append(row)
        if reason:
            rejected.append({'index': i, 'reason': reason})
            continue
        seen.add(row['id'])
        group = groups.setdefault(row['region'], {'region': row['region'], 'orders': 0,
            'cents': 0, 'units': 0, 'customers': set()})
        group['orders'] += 1
        group['cents'] += i * 17 + 10
        group['units'] += i % 4 + 3
        group['customers'].add(f'customer{i % 23}')
    regions = [dict(g, customers=len(g['customers'])) for _, g in sorted(groups.items())]
    return {'json': json.dumps(rows)}, {'application': 'data-pipeline', 'accepted': len(seen),
        'rejected': rejected, 'regions': regions, 'totalCents': sum(g['cents'] for g in regions)}


def queue_fixture(count):
    jobs, results, attempts = [], [], []
    for i in range(count):
        j = {'id': i, 'payload': i + 1, 'delay': i % 3,
             'cancelBefore': i % 11 == 5, 'cancelDuring': i % 11 == 6,
             'permanent': i % 11 == 7, 'transient': i % 11 == 8}
        jobs.append(j)
        n = 0 if j['cancelBefore'] else 1 if j['cancelDuring'] else 3 if j['permanent'] else 2 if j['transient'] else 1
        status = 'cancelled' if j['cancelBefore'] or j['cancelDuring'] else 'failed' if j['permanent'] else 'completed'
        result = {'id': i, 'status': status, 'attempts': n}
        if status == 'completed': result['value'] = (i + 1) * 3 + 1
        results.append(result)
        if n: attempts.append([i, n])
    return {'jobs': jobs, 'concurrency': 4}, {'application': 'async-queue', 'results': results,
        'peak': 4, 'cleaned': len(attempts), 'attempts': attempts}


def archive_fixture(scale):
    docs = [{'name': 'empty.txt', 'text': ''},
            {'name': 'unicode.txt', 'text': 'café λ 😀\n' * scale},
            {'name': 'records.json', 'text': json.dumps([{'i': i, 'value': i * 193 % 65521} for i in range(scale)])},
            {'name': 'pattern.txt', 'text': ''.join(chr(33 + (i * 73 + i // 7) % 90) for i in range(scale * 17))}]
    return {'documents': docs}


def corpus(directory, count):
    entries = []
    def add(outcome, source):
        path = directory / f'plugin-{len(entries):04}.js'
        path.write_text(source + '\n')
        entries.append(f'{outcome} {path}')
    add('ok', 'globalThis.ledger={sum:0,jobs:0,plugins:[],failures:0};')
    failures = 0
    for i in range(count):
        add('ok', f'''(function(){{let privateValue={i + 1};
          ledger.plugins.push(function(){{return privateValue;}});
          ledger.sum+=privateValue;
          setTimeout(function(){{ledger.jobs+=privateValue;}},0);
        }})();''')
        if i % 7 == 3:
            failures += 1
            add('parse-error', 'const broken = ;')
            add('execute-error', f"globalThis.escaped=()=>{i};ledger.failures++;throw Error('expected-plugin-failure');")
            add('ok', f"if(escaped()!=={i}||ledger.plugins.length!=={i+1})throw Error('recovery');")
    total = count * (count + 1) // 2
    add('ok', f'''setTimeout(function(){{
      const sum=ledger.plugins.reduce((n,fn)=>n+fn(),0);
      if(sum!=={total}||ledger.sum!==sum||ledger.jobs!==sum||ledger.failures!=={failures})throw Error('ledger');
      print(JSON.stringify({{application:'persistent-host',plugins:ledger.plugins.length,
        sum:sum,jobs:ledger.jobs,failures:ledger.failures}}));
    }},0);''')
    manifest = directory / 'corpus.txt'
    manifest.write_text('\n'.join(entries) + '\n')
    return manifest, {'application': 'persistent-host', 'plugins': count, 'sum': total,
                      'jobs': total, 'failures': failures}, len(entries), failures


class Campaign:
    def __init__(self, args):
        self.args = args
        self.out = args.output.resolve()
        self.out.parent.mkdir(parents=True, exist_ok=True)
        self.work = self.out.parent / (self.out.stem + '-artifacts')
        self.work.mkdir(exist_ok=True)
        self.records = []
        self.commands = []

    def command(self, args, timeout=None):
        start = time.monotonic()
        p = subprocess.Popen(['/usr/bin/time', '-f', '__APP_RSS_KIB__=%M', *map(str, args)],
            cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            start_new_session=True)
        timed_out = False
        try:
            stdout, stderr = p.communicate(timeout=timeout or self.args.timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            os.killpg(p.pid, signal.SIGKILL)
            stdout, stderr = p.communicate()
        result = {'command': list(map(str, args)), 'returncode': p.returncode,
                  'stdout': stdout, 'stderr': stderr, 'timeout': timed_out}
        result['elapsed_ms'] = (time.monotonic() - start) * 1000
        m = re.findall(r'__APP_RSS_KIB__=(\d+)', result['stderr'])
        result['peak_rss_kib'] = int(m[-1]) if m else None
        self.commands.append(result)
        return result

    def result(self, process, app, expected, completion=False):
        if process.get('timeout'): return 'timeout', None
        if process['returncode'] != 0: return 'process-failure', None
        lines = process['stdout'].splitlines()
        if completion and lines.count(MARKER) != 1: return 'missing-completion', None
        values = [json.loads(line) for line in lines if line.startswith('{')]
        apps = [v for v in values if v.get('application') == app]
        if len(apps) != 1: return 'missing-or-duplicate-result', None
        value = apps[0]
        if app == 'archive-library':
            # Independently decode actual binary outputs, then omit bulky transport fields.
            binary = value.pop('zipBytes')
            gz = value.pop('gzipBytes')
            docs = expected['documents']
            with zipfile.ZipFile(io.BytesIO(bytes(binary))) as archive:
                if sorted(archive.namelist()) != sorted(d['name'] for d in docs):
                    return 'archive-members', value
                for d in docs:
                    if archive.read(d['name']) != d['text'].encode(): return 'zip-content', value
            if gzip.decompress(bytes(gz)) != ''.join(d['text'] for d in docs).encode():
                return 'gzip-content', value
            if not value['corruptRejected']: return 'corrupt-input-accepted', value
        elif value != expected: return 'oracle-mismatch', value
        return 'pass', value

    def record(self, app, size, mode, profile, run, process, expected, completion=False):
        try: status, value = self.result(process, app, expected, completion)
        except Exception as e: status, value = 'result-error: ' + str(e), None
        record = {'app': app, 'size': size, 'mode': mode, 'profile': profile,
                  'repeat': run, 'status': status, 'value': value, 'process': process}
        self.records.append(record)
        print(f'{app} {size} {mode}/{profile} #{run}: {status}', flush=True)
        return record

    def modules(self, app, size):
        counts = SCALES[size]
        data, expected = data_fixture(counts[0]) if app == 'data-pipeline' else queue_fixture(counts[1]) if app == 'async-queue' else (archive_fixture(counts[3]), None)
        if app == 'archive-library': expected = data
        directory = self.work / f'{app}-{size}'
        directory.mkdir(exist_ok=True)
        setup = directory / 'input.js'
        setup.write_text('globalThis.APP_INPUT=' + json.dumps(data, ensure_ascii=True) + ';\n')
        entry = APPS / app / 'main.mjs'
        launcher = directory / 'node.mjs'
        launcher.write_text(f"globalThis.print=console.log;\nawait import({json.dumps(setup.as_uri())});\nawait import({json.dumps(entry.as_uri())});\nconsole.log('{MARKER}');\n")
        node_value = None
        for repeat in range(self.args.repeat):
            r = self.record(app, size, 'node', '-', repeat, self.command(['node', launcher]), expected, True)
            if r['status'] == 'pass': node_value = r['value']
        for profile in self.args.profiles:
            for mode in ['jit', 'aot']:
                bundle = directory / f'{mode}-{profile}.js'
                cmd = ['node', ROOT/'hermes/utils/module-host/compiler.cjs', entry, '--root', APPS,
                       '--output', bundle, '--manifest', bundle.with_suffix('.json')]
                cmd += ['--host-completion'] if mode == 'jit' else ['--completion', MARKER]
                prepared = self.command(cmd)
                if prepared['returncode'] != 0:
                    self.record(app, size, mode, profile, 0, prepared, expected)
                    continue
                if mode == 'aot':
                    bundle.write_text(setup.read_text() + bundle.read_text())
                    exe = directory / f'app-{profile}'
                    built = self.command([sys.executable, ROOT/'hermes/utils/shllvm.py', 'build', bundle,
                        '--build-dir', self.args.build_dir, '--llvm-bin', self.args.llvm_bin,
                        '--hermes-opt', profile, '--llvm-opt', '2', '--no-runtime-build', '-o', exe])
                    if built['returncode'] != 0:
                        self.record(app, size, mode, profile, 0, built, expected)
                        continue
                    run_cmd = [exe]
                else:
                    run_cmd = [self.args.build_dir/'bin/shllvm-jit', '--stats'] + (['-O'] if profile == 'O' else []) + [setup, bundle]
                for repeat in range(self.args.repeat):
                    record = self.record(app, size, mode, profile, repeat, self.command(run_cmd), expected, mode == 'aot')
                    if app == 'archive-library' and record['status'] == 'pass' and record['value'] != node_value:
                        record['status'] = 'node-mismatch'

    def persistent(self, size):
        directory = self.work / f'persistent-host-{size}'
        directory.mkdir(exist_ok=True)
        manifest, expected, submissions, failures = corpus(directory, SCALES[size][2])
        for profile in ['node', *self.args.profiles]:
            for repeat in range(self.args.repeat):
                cmd = ['node', APPS/'persistent-host/replay.mjs', manifest] if profile == 'node' else [self.args.build_dir/'bin/shllvm-app-host', manifest] + (['-O'] if profile == 'O' else [])
                record = self.record('persistent-host', size, 'node' if profile == 'node' else 'embedding', profile, repeat, self.command(cmd), expected)
                if profile != 'node' and record['status'] == 'pass':
                    stats = [line[len('host-stats '):] for line in record['process']['stderr'].splitlines() if line.startswith('host-stats ')]
                    actual = json.loads(stats[0]) if len(stats) == 1 else {}
                    record['host'] = actual
                    if any(actual.get(k) != v for k, v in {'submissions': submissions, 'units': submissions-failures, 'parseErrors': failures, 'executionErrors': failures}.items()):
                        record['status'] = 'host-count-mismatch'

    def run(self):
        identity_paths = sorted(APPS.rglob('*.mjs')) + [APPS/'persistent-host/main.cpp', APPS/'pnpm-lock.yaml',
            APPS/'node_modules/fflate/esm/browser.js', Path(__file__), self.args.build_dir/'bin/shllvm-jit',
            self.args.build_dir/'bin/shllvm-app-host', self.args.build_dir/'bin/shermes',
            ROOT/'hermes/utils/shllvm.py', ROOT/'hermes/utils/module-host/compiler.cjs',
            ROOT/'hermes/utils/module-host/runtime.js'] + list(self.args.build_dir.rglob('libshllvm_runtime*.so')) + list(self.args.build_dir.rglob('libhermesvm.so')) + list(self.args.build_dir.rglob('libshermes_console.so'))
        identity_paths = [p for p in identity_paths if 'node_modules' not in str(p) or p == APPS/'node_modules/fflate/esm/browser.js']
        def identities(): return {str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in identity_paths}
        before = identities()
        try:
            for app in self.args.apps:
                for size in self.args.sizes:
                    if app == 'persistent-host': self.persistent(size)
                    else: self.modules(app, size)
        finally:
            after = identities()
            for r in self.records:
                # Explicit known-boundary disposition, never relabeled as successful execution.
                if r['app'] == 'archive-library' and r['profile'] == 'O0' and r['status'] == 'process-failure' and 'exceeds 1024 combined root/argument-slot admission limit' in r['process']['stderr']:
                    r['status'] = 'known-admission-boundary'
            report = {'schema': 1, 'identities': before, 'inputs_unchanged': before == after,
                'fixture_identities': {str(p.relative_to(self.work)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(self.work.rglob('*')) if p.suffix in ['.js', '.mjs', '.txt']},
                'records': self.records, 'commands': self.commands,
                'summary': {s: sum(r['status'] == s for r in self.records) for s in sorted({r['status'] for r in self.records})}}
            self.out.write_text(json.dumps(report, indent=2) + '\n')
            print(json.dumps(report['summary']), flush=True)
        return 0 if before == after and all(r['status'] in ['pass', 'known-admission-boundary'] for r in self.records) else 1


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--apps', nargs='+', choices=NAMES, default=NAMES)
    p.add_argument('--sizes', nargs='+', choices=SCALES, default=list(SCALES))
    p.add_argument('--profiles', nargs='+', choices=['O0', 'O'], default=['O0', 'O'])
    p.add_argument('--repeat', type=int, default=2)
    p.add_argument('--timeout', type=float, default=180)
    p.add_argument('--build-dir', type=Path, default=ROOT/'hermes/build-llvm')
    p.add_argument('--llvm-bin', type=Path, default=Path('/usr/lib/llvm-18/bin'))
    p.add_argument('--output', type=Path, required=True)
    args = p.parse_args()
    if args.repeat < 1 or args.timeout <= 0: p.error('repeat and timeout must be positive')
    args.build_dir = args.build_dir.resolve()
    return Campaign(args).run()

if __name__ == '__main__':
    sys.exit(main())
