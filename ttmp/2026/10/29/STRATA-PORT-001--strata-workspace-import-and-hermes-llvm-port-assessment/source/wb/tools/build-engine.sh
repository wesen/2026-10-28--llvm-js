#!/bin/sh
# Concatenate the engine parts into site/js/core.js and copy the frontend (atomically: other
# processes may be reading the files while this runs).
set -e
cd "$(dirname "$0")/.."
cat src/core/00-prelude.js src/core/10-effects.js src/core/20-ops.js src/core/30-ir.js src/core/40-machine.js src/core/50-analysis.js src/core/60-rewrite.js src/core/70-lower.js src/core/80-pipeline.js src/core/90-engine.js > site/js/core.tmp.js
cp src/frontend.js site/js/frontend.tmp.js
node --check site/js/core.tmp.js && node --check site/js/frontend.tmp.js
mv site/js/core.tmp.js site/js/core.js && mv site/js/frontend.tmp.js site/js/frontend.js
wc -l site/js/core.js site/js/frontend.js
