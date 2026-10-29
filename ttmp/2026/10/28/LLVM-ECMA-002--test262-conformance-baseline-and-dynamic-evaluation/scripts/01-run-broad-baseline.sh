#!/bin/sh
# Run from the repository root; all machine-specific paths are explicit.
set -eu
if [ "$#" -ne 5 ]; then
  echo 'usage: sh 01-run-broad-baseline.sh SUITE BUILD LLVM_BIN OUTPUT JOBS' >&2
  exit 2
fi
python3 hermes/utils/test_shllvm_test262.py \
  --suite "$1" --build-dir "$2" --llvm-bin "$3" --output "$4" \
  --jobs "$5" --compact --checkpoint-every 2000 test
