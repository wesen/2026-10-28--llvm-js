"""Inventory only: this script does not execute tests or claim conformance."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import subprocess
import sys

root = next(p for p in Path(__file__).resolve().parents if (p / ".ttmp.yaml").exists())
sys.path.insert(0, str(root / "hermes/utils"))
from test_shllvm_test262 import metadata, variants, unsupported_reason

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--suite", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
suite = args.suite.resolve()
lock = json.loads((root / "hermes/test/LLVMTest262/suite-lock.json").read_text())
revision = subprocess.check_output(["git", "-C", str(suite), "rev-parse", "HEAD"], text=True).strip()
if revision != lock["test262_revision"]:
    parser.error("suite revision mismatch")
if subprocess.check_output(["git", "-C", str(suite), "status", "--porcelain"], text=True).strip():
    parser.error("dirty suite")
records, errors, fixtures = [], [], []
features, flags, phases = Counter(), Counter(), Counter()
for path in sorted((suite / "test").rglob("*.js")):
    name = str(path.relative_to(suite))
    if "_FIXTURE" in path.name:
        fixtures.append(name)
        continue
    try:
        raw = path.read_bytes()
        meta = metadata(raw.decode("utf-8"), name)
        features.update(meta.get("features", []))
        flags.update(meta.get("flags", []))
        phases.update([meta.get("negative", {}).get("phase", "positive")])
        records.append({"test": name, "sha256": hashlib.sha256(raw).hexdigest(),
                        "variants": variants(meta), "features": meta.get("features", []),
                        "negative": meta.get("negative"),
                        "runner_boundary": unsupported_reason(meta)})
    except Exception as exc:
        errors.append({"test": name, "error": str(exc)})
report = {"inventory_only": True, "suite_revision": revision, "test_files": len(records),
          "variants": sum(len(r["variants"]) for r in records),
          "fixture_files": len(fixtures), "metadata_errors": errors,
          "features": dict(sorted(features.items())), "flags": dict(flags),
          "phases": dict(phases), "records": records, "fixtures": fixtures}
args.output.write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps({k:v for k,v in report.items() if k not in ("records", "fixtures", "features")}, indent=2))
