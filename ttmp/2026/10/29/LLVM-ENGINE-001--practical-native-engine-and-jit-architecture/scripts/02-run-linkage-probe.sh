#!/bin/sh
set -eu
cd /home/manuel/code/wesen/2026-10-28--llvm-js
printf 'globalThis.shared={n:1};globalThis.inc=function(){return ++shared.n;};\n' > /tmp/llvm-engine-a.js
printf 'if(inc()!==2||shared.n!==2)throw Error("shared");print("two-units-ok");\n' > /tmp/llvm-engine-b.js
hermes/build-llvm/bin/shermes -emit-llvm -exported-unit=a /tmp/llvm-engine-a.js -o /tmp/llvm-engine-a.ll
hermes/build-llvm/bin/shermes -emit-llvm -exported-unit=b /tmp/llvm-engine-b.js -o /tmp/llvm-engine-b.ll
/usr/lib/llvm-18/bin/clang++ --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13 $(/usr/lib/llvm-18/bin/llvm-config --cxxflags) ttmp/2026/10/29/LLVM-ENGINE-001--practical-native-engine-and-jit-architecture/scripts/01-linkage-probe.cpp $(/usr/lib/llvm-18/bin/llvm-config --ldflags --libs orcjit native irreader --system-libs) -ldl -o /tmp/llvm-engine-probe
/tmp/llvm-engine-probe "$PWD/hermes/build-llvm/lib/libshllvm_runtime.so" /tmp/llvm-engine-a.ll /tmp/llvm-engine-b.ll
