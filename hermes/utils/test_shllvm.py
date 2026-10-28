#!/usr/bin/env python3
"""Differential integration tests for the direct LLVM backend.

Each successful source case is compared with Node and the existing Static
Hermes C backend using the patched shared runtime, then run through direct LLVM
at both frontend and LLVM
optimization levels. Failing/unsupported programs are separate contracts.
"""
from __future__ import annotations
import argparse
import concurrent.futures
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "test/LLVMNative"


def run(argv, *, timeout=120, env=None):
    start = time.monotonic()
    try:
        p = subprocess.run([str(a) for a in argv], capture_output=True,
                           text=True, timeout=timeout, env=env)
        return {"command": [str(a) for a in argv], "exit_code": p.returncode,
                "stdout": p.stdout, "stderr": p.stderr,
                "seconds": round(time.monotonic()-start, 6)}
    except (subprocess.TimeoutExpired, OSError) as e:
        return {"command": [str(a) for a in argv], "exit_code": None,
                "stdout": "", "stderr": str(e),
                "seconds": round(time.monotonic()-start, 6)}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--build-dir", default=os.environ.get("HERMES_BUILD_DIR", str(ROOT / "build-llvm")))
    p.add_argument("--llvm-bin", default=os.environ.get("LLVM_BIN"))
    p.add_argument("--output", default=str(ROOT / "docs/llvm/evidence/validation.json"))
    p.add_argument("--case", help="test filename substring")
    p.add_argument("--jobs", type=int, default=2)
    p.add_argument("--skip-jit", action="store_true")
    p.add_argument("--quick", action="store_true", help="LLVM O2 only, still both Hermes levels")
    args = p.parse_args()
    build = Path(args.build_dir).resolve()
    work = build / "shllvm-tests"
    work.mkdir(exist_ok=True)
    compiler = build / "bin/shermes"
    node = shutil.which("node")
    if not node:
        p.error("Node is required for the independent semantic oracle")
    env = os.environ.copy()
    llvm_args = ["--llvm-bin", args.llvm_bin] if args.llvm_bin else []
    options = ["--build-dir", str(build), *llvm_args, "--no-runtime-build"]
    levels = ["2"] if args.quick else ["0", "2"]
    positive = [f for f in sorted(SOURCE.glob("*.js"))
                if not f.name.startswith(("error_", "unsupported_"))]
    if args.case:
        positive = [f for f in positive if args.case in f.name]
    results = []

    def positive_test(src):
        records = []
        oracle = run([node, "--expose-gc", "-e",
                      "globalThis.print = (...a) => console.log(...a); require(process.argv[1]);", src], env=env)
        records.append({"stage": "node", **oracle})
        success = oracle["exit_code"] == 0
        comparisons = 0
        for hopt in ["O0", "O"]:
            c_exe = work / (src.stem + "-" + hopt + "-c")
            compiled = run([compiler, "-" + hopt, "-Xes6-block-scoping", "-Xenable-tdz", src, "-o", c_exe], env=env)
            records.append({"stage": "c-build", "hermes_opt": hopt, **compiled})
            c_run = None
            if compiled["exit_code"] == 0:
                c_run = run([c_exe], env=env)
                good = c_run["exit_code"] == 0 and c_run["stdout"] == oracle["stdout"]
                success = success and good
                records.append({"stage": "c-run", "hermes_opt": hopt, "matches_node": good, **c_run})
            else:
                success = False
            for lopt in levels:
                exe = work / (src.stem + "-" + hopt + "-llvm" + lopt)
                llvm_build = run([sys.executable, ROOT / "utils/shllvm.py", "build",
                                  *options, "--hermes-opt", hopt, "--llvm-opt", lopt,
                                  "-o", exe, src], env=env)
                records.append({"stage": "llvm-build", "hermes_opt": hopt,
                                "llvm_opt": lopt, **llvm_build})
                if llvm_build["exit_code"] != 0:
                    success = False
                    continue
                llvm_run = run([exe], env=env)
                good = (llvm_run["exit_code"] == 0 and llvm_run["stdout"] == oracle["stdout"]
                        and c_run is not None and llvm_run["stdout"] == c_run["stdout"])
                records.append({"stage": "llvm-run", "hermes_opt": hopt,
                                "llvm_opt": lopt, "matches_node_and_c": good, **llvm_run})
                comparisons += 1
                success = success and good
        if not args.skip_jit and src.stem in ["functions", "closures", "gc_closures"]:
            jit = run([sys.executable, ROOT / "utils/shllvm.py", "jit", *options,
                       "--hermes-opt", "O", "--llvm-opt", "2", "-o",
                       work / (src.stem + "-jit"), src], env=env)
            good = jit["exit_code"] == 0 and jit["stdout"] == oracle["stdout"]
            records.append({"stage": "lli-jit", "matches_node": good, **jit})
            success = success and good
        return {"name": src.name, "kind": "positive", "passed": success,
                "llvm_native_comparisons": comparisons, "records": records}

    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
        for result in pool.map(positive_test, positive):
            results.append(result)
            print(("PASS" if result["passed"] else "FAIL") + " " + result["name"], flush=True)
            if not result["passed"]:
                for r in result["records"]:
                    if r["exit_code"] or r.get("matches_node_and_c") is False or r.get("matches_node") is False:
                        print(" ", r["stage"], r.get("hermes_opt", ""), r.get("llvm_opt", ""),
                              r["stderr"][:600].strip() or repr(r["stdout"][:350]), flush=True)

    for src in sorted(SOURCE.glob("error_*.js")):
        if args.case and args.case not in src.name:
            continue
        records = []
        expected = "ReferenceError" if "missing_global" in src.stem else "TypeError"
        passed = True
        for hopt in ["O0", "O"]:
            exe = work / (src.stem + "-" + hopt)
            compilation = run([sys.executable, ROOT / "utils/shllvm.py", "build", *options,
                               "--hermes-opt", hopt, "-o", exe, src], env=env)
            records.append({"stage": "error-build", "hermes_opt": hopt, **compilation})
            if compilation["exit_code"] != 0:
                passed = False
                continue
            execution = run([exe], env=env)
            good = execution["exit_code"] == 1 and expected in execution["stderr"]
            records.append({"stage": "runtime-error", "hermes_opt": hopt,
                            "expected_error": expected, "matches_expected": good, **execution})
            passed = passed and good
        result = {"name": src.name, "kind": "runtime-error", "passed": passed, "records": records}
        results.append(result)
        print(("PASS" if passed else "FAIL") + " " + src.name, flush=True)

    for src in sorted(SOURCE.glob("unsupported_*.js")):
        if args.case and args.case not in src.name:
            continue
        output = work / (src.stem + ".ll")
        sentinel = b"unchanged existing LLVM output\n"
        output.write_bytes(sentinel)
        compilation = run([compiler, "-O0", "-emit-llvm", src, "-o", output], env=env)
        preserved = output.read_bytes() == sentinel
        expected_diagnostic = ("invalid assignment left-hand side" if "const_assignment" in src.name
                               else "admission limit" if "root_limit" in src.name else "unsupported")
        passed = compilation["exit_code"] != 0 and expected_diagnostic in compilation["stderr"].lower() and preserved
        results.append({"name": src.name, "kind": "compile-rejection", "passed": passed,
                        "existing_output_preserved": preserved, "records": [compilation]})
        print(("PASS" if passed else "FAIL") + " " + src.name, flush=True)

    summary = {"generated_at_unix": time.time(), "source_cases": len(results),
               "passed_cases": sum(bool(r["passed"]) for r in results),
               "failed_cases": sum(not r["passed"] for r in results),
               "native_llvm_vs_node_and_c_comparisons": sum(r.get("llvm_native_comparisons", 0) for r in results),
               "hermes_optimization_levels": ["O0", "O"], "llvm_optimization_levels": levels,
               "asan_options": env.get("ASAN_OPTIONS", ""),
               "lsan_options": env.get("LSAN_OPTIONS", ""),
               "scope": "host native and optional lli execution; not device execution or full ECMAScript conformance",
               "results": results}
    path = Path(args.output).resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps({k:v for k,v in summary.items() if k != "results"}, indent=2))
    return 1 if summary["failed_cases"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
