#!/usr/bin/env python3
"""Require ordinary source files to reject directly encoded surrogate values."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

root = next(p for p in Path(__file__).resolve().parents
            if (p / 'hermes/utils/shllvm.py').is_file())
compiler = root / 'hermes/build-llvm/bin/shermes'
results = []
with tempfile.TemporaryDirectory(prefix='llvm-static-utf8-') as work:
    for code_unit in (0xD800, 0xDC00):
        source = Path(work) / f'invalid-{code_unit:x}.js'
        source.write_bytes(b"print('" + chr(code_unit).encode('utf-8', 'surrogatepass') + b"');\n")
        command = [str(compiler), '-emit-llvm', str(source), '-o', str(source.with_suffix('.ll'))]
        result = subprocess.run(command, capture_output=True, text=True, errors='replace', timeout=60)
        passed = result.returncode == 1 and 'Invalid UTF-8' in result.stderr
        results.append(dict(code_unit=code_unit, source_hex=source.read_bytes().hex(),
                            command=command, exit=result.returncode, stderr=result.stderr, passed=passed))
receipt = dict(compiler_sha256=hashlib.sha256(compiler.read_bytes()).hexdigest(), results=results,
               passed=all(r['passed'] for r in results))
output = Path(__file__).resolve().parents[1] / 'reference/evidence/static-utf8-rejection.json'
output.write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps(receipt, indent=2))
raise SystemExit(0 if receipt['passed'] else 1)
