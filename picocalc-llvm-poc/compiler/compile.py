#!/usr/bin/env python3
"""Host-only LLVM compiler. Cross-compile a restricted JS world to a freestanding RV32 ELF.

The generated ELF is ET_EXEC, prelinked at a requested code slot. No dynamic
linker, libc, crt, or unresolved symbols. Each reload generation may use a
separate slot; this is remote AOT/JIT, NOT position-independent runtime linking.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
CLANG = os.environ.get('CLANG', 'clang')
LINKER = os.environ.get('LD_LLD', 'ld.lld')
READELF = os.environ.get('READELF', 'readelf')

def check_elf(p: Path, base: int):
    """Sanity check on bytes + readelf; the device loader independently verifies."""
    buf = p.read_bytes()
    if len(buf) < 52 or buf[:4] != b'\x7fELF' or buf[4] != 1 or buf[5] != 1:
        raise ValueError('not little-endian ELF32')
    typ, mach, vers = struct.unpack_from('<HHI', buf, 16)
    if typ != 2 or mach != 243 or vers != 1:
        raise ValueError(f'expect ET_EXEC/RISC-V ELF, got {typ}/{mach}/{vers}')
    phtoff = struct.unpack_from('<I',buf,28)[0]
    entry = struct.unpack_from('<I',buf,24)[0]
    phentsize, phnum = struct.unpack_from('<HH',buf,42)
    if not (base <= entry < base+0x10000):
        raise ValueError(f'entry {entry:#x} outside requested slot {base:#x}')
    if phentsize != 32 or phnum < 1 or phnum > 6:
        raise ValueError('unexpected program headers')
    segs=[]
    for i in range(phnum):
        off = phtoff+i*32
        if off+32 > len(buf): raise ValueError('truncated program headers')
        typ, foff, vaddr, paddr, filesz, memsz, flags, align = struct.unpack_from('<IIIIIIII',buf,off)
        if typ == 1:
            if not (base<=vaddr<base+0x10000 and memsz<=0x10000 and vaddr+memsz<=base+0x10000):
                raise ValueError(f'bad code/data segment {vaddr:#x}')
            if foff+filesz>len(buf) or memsz<filesz or (flags&2 and flags&1):
                raise ValueError('bad filesz or writable-executable segment')
            segs.append({'vaddr':vaddr,'filesz':filesz,'memsz':memsz,'flags':flags})
    if not segs or not any(s['flags']&1 for s in segs): raise ValueError('no executable segment')
    out = subprocess.check_output([READELF,'--wide','-s',str(p)],text=True)
    for sym in ['pico_world_step','pico_world_migrate']:
        if not re.search(r'\b'+sym+r'\s*$',out,re.M): raise ValueError('missing exported '+sym)
    # undefined symbols except ELF's normal zero-index UND row are not allowed.
    for line in out.splitlines():
        if re.search(r'\bUND\b',line) and not re.match(r'\s*0:',line):
            raise ValueError('unresolved symbol: '+line)
    return {'size':len(buf),'sha256':hashlib.sha256(buf).hexdigest(),'entry':entry,'segments':segs,'target':'riscv32-unknown-elf','march':'rv32im','abi':'ilp32','no_libc':True}

def compile_js(source: str, output: Path, base: int, opt='2', language='js', backend='llvm'):
    if base not in (0x00100000,0x00200000):
        raise ValueError('only two prelinked code slots supported in PoC')
    if opt not in ('0','1','2','3','s'):
        raise ValueError('bad optimizer level')
    if backend not in ('llvm', 'c'):
        raise ValueError('backend must be llvm or c')
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='picojit-') as td:
        td = Path(td)
        js=td/'module.js'; c=td/'module.c'; ir=td/'module.ll'; obj=td/'module.o'; elf=td/'module.elf'; ld=td/'link.ld'
        js.write_text(source)
        t0 = time.perf_counter()
        if language == 'js':
            generated = ir if backend == 'llvm' else c
            emitter = 'js2llvm.js' if backend == 'llvm' else 'js2c.js'
            generated.write_bytes(subprocess.check_output(['node',str(ROOT/'compiler'/emitter),str(js)],cwd=ROOT))
        elif language == 'c':
            c.write_text(source)
            generated = c
        else:
            raise ValueError('only js and freestanding c are supported')
        ld.write_text(f'''OUTPUT_ARCH(riscv)
ENTRY(pico_world_step)
PHDRS {{ text PT_LOAD FLAGS(5); data PT_LOAD FLAGS(6); }}
SECTIONS {{
  . = 0x{base:08x};
  .text : {{ *(.text .text.*) }} :text
  .rodata : {{ *(.rodata .rodata.*) }} :text
  . = ALIGN(4096);
  .data : {{ *(.data .data.*) *(.sdata .sdata.*) }} :data
  .bss (NOLOAD) : {{ *(.bss .bss.*) *(.sbss .sbss.*) }} :data
}}
''')
        t1 = time.perf_counter()
        cc = [CLANG, '--target=riscv32-unknown-elf', '-march=rv32im', '-mabi=ilp32',
              '-fno-pic', '-mno-relax', '-Oz' if opt == 's' else '-O'+opt]
        if generated == ir:
            # -x ir selects LLVM's IR reader directly; no C parser or generated C.
            cc += ['-Wno-override-module', '-x', 'ir']
        else:
            cc += ['-nostdlib', '-ffreestanding', '-fno-builtin', '-fno-stack-protector',
                   '-fwrapv', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables',
                   '-fdata-sections', '-ffunction-sections', '-I', str(ROOT/'include')]
        cc += ['-c', str(generated), '-o', str(obj)]
        subprocess.run(cc, check=True, capture_output=True, text=True)
        t2 = time.perf_counter()
        subprocess.run([LINKER,'-m','elf32lriscv','--no-relax','--no-undefined',
            '--build-id=none','-T',str(ld),str(obj),'-o',str(elf)],check=True,capture_output=True,text=True)
        t3 = time.perf_counter()
        meta=check_elf(elf,base)
        meta.update({'language': language,
                     'backend': 'direct-llvm' if generated == ir else 'c',
                     'source_sha256': hashlib.sha256(source.encode()).hexdigest(),
                     'generated_sha256': hashlib.sha256(generated.read_bytes()).hexdigest(),
                     'optimization': opt,
                     'timings_ms': {'frontend': (t1-t0)*1000, 'llvm_compile': (t2-t1)*1000,
                                    'link': (t3-t2)*1000}})
        output.write_bytes(elf.read_bytes())
        (output.with_suffix('.meta.json')).write_text(json.dumps(meta,indent=2)+'\n')
        suffix = '.generated.ll' if generated == ir else '.generated.c'
        output.with_suffix(suffix).write_bytes(generated.read_bytes())
    return meta

if __name__=='__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('source',type=Path);ap.add_argument('-o','--output',type=Path,required=True)
    ap.add_argument('--base',type=lambda v:int(v,0),default=0x100000)
    ap.add_argument('--opt',default='2')
    ap.add_argument('--language',choices=['js','c'],default='js')
    ap.add_argument('--backend', choices=['llvm', 'c'], default='llvm',
                    help='JS lowering: direct LLVM IR (default), or original C oracle')
    a=ap.parse_args()
    print(json.dumps(compile_js(a.source.read_text(),a.output,a.base,a.opt,a.language,a.backend),indent=2))
