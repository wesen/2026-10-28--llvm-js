#!/usr/bin/env python3
"""Recheck all timed-out sources in a complete baseline as a separate profile."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--baseline', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
report = json.loads(args.baseline.read_text())
if not report.get('complete') or report.get('changed_inputs'):
    parser.error('baseline must be complete with unchanged inputs')
paths = sorted({r['test'] for r in report['results'] if r['status'] == 'timeout'})
if not paths:
    parser.error('baseline has no timeouts to recheck')
root = next(p for p in Path(__file__).resolve().parents
            if (p / 'hermes/utils/test_shllvm_test262.py').is_file())
command = [sys.executable, str(root / 'hermes/utils/test_shllvm_test262.py'),
           '--suite', '/tmp/llvm-test262', '--build-dir', str(root / 'hermes/build-llvm'),
           '--llvm-bin', '/usr/lib/llvm-18/bin', '--output', str(args.output.resolve()),
           '--jobs', '1', '--compact', '--run-timeout', '120', *paths]
print(json.dumps(command), flush=True)
raise SystemExit(subprocess.call(command, cwd=root))
