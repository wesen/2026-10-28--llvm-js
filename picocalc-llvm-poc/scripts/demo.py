#!/usr/bin/env python3
"""Reproducible integrated demonstration: separate jitd -> RV32 ELF -> target simulator."""
from pathlib import Path
import json
import os
import socket
import subprocess
import sys
import tempfile
import time

ROOT=Path(__file__).resolve().parents[1]

def send(sock: Path, source: str, out: Path, base: int):
    with socket.socket(socket.AF_UNIX,socket.SOCK_STREAM) as s:
        s.connect(str(sock))
        s.sendall((json.dumps({'source':source,'output':str(out),'base':base,'opt':'2'})+'\n').encode())
        with s.makefile('rb') as f: reply=json.loads(f.readline())
        if not reply.get('ok'):raise RuntimeError(reply)
        return reply

def run_demo(print_output=True):
    (ROOT/'build').mkdir(exist_ok=True)
    (ROOT/'logs').mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='picocalc-jitd-') as tmp:
        tmp=Path(tmp);outdir=tmp/'modules';outdir.mkdir(); sock=tmp/'jitd.sock'
        proc=subprocess.Popen([sys.executable,str(ROOT/'compiler/jitd.py'),'--socket',str(sock),'--outdir',str(outdir)],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        try:
            for _ in range(300):
                if sock.exists(): break
                if proc.poll() is not None:raise RuntimeError('jitd terminated: '+proc.stderr.read())
                time.sleep(.01)
            if not sock.exists():raise RuntimeError('jitd socket startup failed')
            ready=proc.stdout.readline().strip()
            variants=[('v1','counter_v1',0x100000),('v2','counter_v2',0x200000),('bad','bad_migrate',0x100000)]
            paths={}
            for tag,src,base in variants:
                elf=outdir/f'{tag}.elf';r=send(sock,(ROOT/'worlds'/f'{src}.js').read_text(),elf,base)
                paths[tag]=elf
                if print_output:print(json.dumps({'event':'jitd_compile','variant':tag,'bytes':r['meta']['size'],'sha256':r['meta']['sha256'],'base':hex(base)}))
            scenario='\n'.join([
                'status',
                'dispatch 1 3',
                'expect score 3',
                'queue 1 7',
                f'reload {paths["v2"]} 2',
                'expect flags 42','expect schema 2',
                'drain',
                'dispatch 1 4','expect score 43','expect epoch 2',
                f'reload {paths["bad"]} 3',
                'expect epoch 2',
                'dispatch 1 1','expect score 53',
                'status','quit',''
            ])
            run=subprocess.run([str(ROOT/'build/pico-sim'),'--module',str(paths['v1']),'--schema','1','--cap','emit','--fuel','10000'],cwd=ROOT,input=scenario,text=True,capture_output=True,check=True)
            if print_output: print(run.stdout,end='')
            (ROOT/'logs/demo.jsonl').write_text((json.dumps({'event':'jitd_ready','protocol':'unix socket / jsonl','separate_pid':proc.pid})+'\n')+run.stdout)
            (ROOT/'logs/sample_scenario.txt').write_text(scenario.replace(str(outdir),'<compiled-module-dir>'))
            return [json.loads(line) for line in run.stdout.splitlines() if line.strip()]
        finally:
            proc.terminate()
            try:proc.wait(timeout=3)
            except subprocess.TimeoutExpired:proc.kill();proc.wait()

if __name__=='__main__':
    run_demo(True)
