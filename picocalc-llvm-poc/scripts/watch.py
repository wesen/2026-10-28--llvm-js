#!/usr/bin/env python3
"""Interactive edit/reload loop with compiler in a separate process.

The compiler uses LLVM on the host; the simulator only loads RV32 ELF. The
watcher waits for reload acknowledgement and retries the inactive slot after a
failed migration. It never assumes a compiled image became the active one.
"""
import argparse
import json
from pathlib import Path
import re
import select
import subprocess
import sys
import tempfile
import time
from demo import ROOT,send

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('source',type=Path)
    ap.add_argument('--poll',type=float,default=.25)
    a=ap.parse_args();source=a.source.resolve()
    with tempfile.TemporaryDirectory(prefix='picocalc-live-') as temp:
        temp=Path(temp);(temp/'modules').mkdir();sock=temp/'jitd.sock'
        compiler=subprocess.Popen([sys.executable,str(ROOT/'compiler/jitd.py'),'--socket',str(sock),'--outdir',str(temp/'modules')],cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.PIPE)
        sim=None
        def command(c):
            sim.stdin.write(c+'\n');sim.stdin.flush()
            line=sim.stdout.readline()
            if not line:raise RuntimeError('simulator ended unexpectedly')
            print(line.rstrip(),flush=True)
            return json.loads(line)
        try:
            for _ in range(300):
                if sock.exists():break
                if compiler.poll() is not None:break
                time.sleep(.01)
            if not sock.exists():raise RuntimeError('jitd startup failed')
            attempt=0;active_base=None;mtime=None
            print('Edit '+str(source)+'; commands: add N, double, state, quit',flush=True)
            while True:
                now=source.stat().st_mtime_ns
                if now!=mtime:
                    mtime=now;code=source.read_text()
                    match=re.search(r'\b(?:export\s+)?const\s+schema\s*=\s*(\d+)\s*;',code)
                    if not match:
                        print('[watcher] no `const schema = N;` declaration',flush=True)
                        continue
                    schema=int(match.group(1))
                    base=0x100000 if active_base!=0x100000 else 0x200000
                    output=temp/'modules'/f'v{attempt}.elf';attempt+=1
                    try:
                        response=send(sock,code,output,base)
                        if sim is None:
                            sim=subprocess.Popen([str(ROOT/'build/pico-sim'),'--module',str(output),'--schema',str(schema),'--cap','emit'],cwd=ROOT,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=None,text=True,bufsize=1)
                            command('status')
                            active_base=base
                        else:
                            ack=command(f'reload {output} {schema}')
                            if ack['ok']:
                                active_base=base
                            else:
                                print('[watcher] reload rejected; existing version remains active',flush=True)
                        print(f'[jitd] LLVM produced {response["meta"]["size"]} ELF bytes; active slot {hex(active_base)}',flush=True)
                    except Exception as e:
                        print('[jitd] compile or reload failed; old world remains:',e,flush=True)
                readable,_,_=select.select([sys.stdin],[],[],a.poll)
                if readable:
                    line=sys.stdin.readline().strip()
                    if not line or line=='quit':break
                    if sim is None:continue
                    if line=='state':cmd='status'
                    elif line=='double':cmd='dispatch 2 0'
                    elif line.startswith('add '):cmd='dispatch 1 '+line[4:]
                    else:cmd=line
                    command(cmd)
        finally:
            if sim is not None:
                try:
                    sim.stdin.write('quit\n');sim.stdin.flush();sim.stdin.close();sim.wait(timeout=1)
                except Exception:sim.kill();sim.wait()
            compiler.terminate()
            try:compiler.wait(timeout=2)
            except subprocess.TimeoutExpired:compiler.kill();compiler.wait()
if __name__=='__main__':main()
