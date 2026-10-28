#!/usr/bin/env bash
set -u
cd /home/manuel/code/wesen/2026-10-28--llvm-js
results=ttmp/2026-10-28/extensions-validation
while [ ! -f "$results/build.exit" ]; do sleep 3; done
if [ "$(cat "$results/build.exit")" != 0 ]; then exit 1; fi
cmake --build hermes/build-llvm --target shermes shllvm_runtime shllvm_runtime_shared -- -n > "$results/build-dry-run.log" 2>&1
python3 hermes/utils/test_shllvm.py --build-dir hermes/build-llvm --llvm-bin /usr/lib/llvm-18/bin --jobs 3 --output "$results/core-validation.json" > "$results/core-validation.log" 2>&1
core_status=$?
python3 hermes/utils/test_shllvm_extensions.py --build-dir hermes/build-llvm --llvm-bin /usr/lib/llvm-18/bin --jobs 3 --output "$results/extension-validation.json" > "$results/extension-validation.log" 2>&1
extension_status=$?
python3 hermes/utils/test_shllvm_driver.py --evidence "$results/driver-validation.json" > "$results/driver-validation.log" 2>&1
driver_status=$?
python3 hermes/utils/test_shllvm_defaults.py --build-dir hermes/build-llvm --clang /usr/bin/clang-18 --evidence "$results/defaults-validation.json" > "$results/defaults-validation.log" 2>&1
defaults_status=$?
printf 'core=%s\nextensions=%s\ndriver=%s\ndefaults=%s\n' "$core_status" "$extension_status" "$driver_status" "$defaults_status" > "$results/tests.exit"
