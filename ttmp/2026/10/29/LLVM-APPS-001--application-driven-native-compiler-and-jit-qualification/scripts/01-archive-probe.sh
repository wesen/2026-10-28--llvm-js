#!/usr/bin/env bash
# Run from the repository root after the existing JIT build is available.
set -eu
out=${1:?Supply an output directory}
mkdir -p "$out"
pnpm --dir hermes/examples/llvm-apps install --frozen-lockfile --ignore-scripts
node hermes/utils/module-host/compiler.cjs \
  hermes/examples/llvm-apps/archive-library/main.mjs \
  --root hermes/examples/llvm-apps \
  --output "$out/archive.js" --manifest "$out/manifest.json" \
  --check-output "$out/check.json" --host-completion
input=ttmp/2026/10/29/LLVM-APPS-001--application-driven-native-compiler-and-jit-qualification/reference/evidence/archive-input.js
set +e
hermes/build-llvm/bin/shllvm-jit --stats "$input" "$out/archive.js" > "$out/unoptimized.txt" 2>&1
plain=$?
hermes/build-llvm/bin/shllvm-jit -O --stats "$input" "$out/archive.js" > "$out/optimized.txt" 2>&1
optimized=$?
set -e
printf 'unoptimized_exit=%s\noptimized_exit=%s\n' "$plain" "$optimized" > "$out/status.txt"
cat "$out/status.txt"
# This records both outcomes; it is not the future qualification runner.
