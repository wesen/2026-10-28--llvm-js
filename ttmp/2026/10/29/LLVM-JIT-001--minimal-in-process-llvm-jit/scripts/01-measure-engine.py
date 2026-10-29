#!/usr/bin/env python3
"""Bounded smoke measurement; RSS includes LLVM/compiler/runtime, not just code."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import sys
root=Path(__file__).resolve().parents[6]
binary=root/'hermes/build-llvm/bin/shllvm-jit'
results=[]
with tempfile.TemporaryDirectory(prefix='jit-measure-') as directory:
    path=Path(directory)
    initial=path/'initial.js';initial.write_text('globalThis.counter=0;\n')
    increment=path/'increment.js';increment.write_text('counter++;\n')
    for count in [1,20,100]:
        check=path/'check.js';check.write_text(f'if(counter!=={count})throw Error("count");print(counter);\n')
        command=[str(binary),'--stats',str(initial),*[str(increment)]*count,str(check)]
        run=subprocess.run(command,text=True,capture_output=True,timeout=120)
        assert run.returncode==0 and run.stdout==str(count)+'\n',run.stderr
        results.append(dict(increments=count,stdout=run.stdout,statistics=run.stderr))
    trace=path/'exec.trace'
    proc=subprocess.run(['strace','-f','-e','trace=execve','-o',str(trace),str(binary),str(initial),str(increment)],capture_output=True,text=True,timeout=120)
    assert proc.returncode==0,proc.stderr
    executions=[line for line in trace.read_text().splitlines() if 'execve(' in line]
    assert len(executions)==1,executions
report=dict(binary_sha256=hashlib.sha256(binary.read_bytes()).hexdigest(),
            scope='Illustrative warm-host smoke measurements; no benchmark claim or leak proof',
            results=results,execve_records=executions)
Path(sys.argv[1]).write_text(json.dumps(report,indent=2)+'\n')
