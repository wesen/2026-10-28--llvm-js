#!/usr/bin/env bash
set -u
cd /home/manuel/code/wesen/2026-10-28--llvm-js
results=ttmp/2026-10-28/import-validation
while [ ! -f "$results/build.exit" ]; do sleep 3; done
if [ "$(cat "$results/build.exit")" != 0 ]; then
  echo 'Compiler build failed; see build.log.'
  exit 1
fi
python3 hermes/utils/test_shllvm.py --build-dir hermes/build-llvm --llvm-bin /usr/lib/llvm-18/bin --jobs 3 --output "$results/host-validation.json" > "$results/host-validation.log" 2>&1
matrix_status=$?
python3 hermes/utils/test_shllvm_driver.py --evidence "$results/driver-validation.json" > "$results/driver-validation.log" 2>&1
driver_status=$?
python3 hermes/utils/test_shllvm_defaults.py --build-dir hermes/build-llvm --clang /usr/bin/clang-18 --evidence "$results/defaults-validation.json" > "$results/defaults-validation.log" 2>&1
defaults_status=$?
printf 'matrix=%s\ndriver=%s\ndefaults=%s\n' "$matrix_status" "$driver_status" "$defaults_status" > "$results/host-tests.exit"
