#!/usr/bin/env python3
"""Differential validation of direct LLVM language extensions.

The default gate compares every positive program with Node and the inherited
Static Hermes C path, executes native LLVM with O0/O frontends and LLVM O0/O2,
and executes every positive program with the real lli JIT. Explicit runtime
errors and compiler rejections are separate contracts. This is a targeted
integration suite, not a claim of complete ECMAScript conformance.

An optional first-line // SHLLVM_TEST: JSON object supplies fixture metadata.
See test/LLVMNativeExtensions/README.md for the schema and oracle policy.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "test/LLVMNativeExtensions"
NODE_WRAPPER = (
    'globalThis.print=(...a)=>console.log(...a);'
    'require("vm").runInThisContext('
    'require("fs").readFileSync(process.argv[1],"utf8"),'
    '{filename:process.argv[1]});'
)
BASE_FLAGS = ["-Xes6-block-scoping", "-Xenable-tdz"]


def run(argv, *, timeout, env):
    argv = [str(arg) for arg in argv]
    start = time.monotonic()
    try:
        process = subprocess.run(argv, capture_output=True, text=True,
                                 timeout=timeout, env=env, cwd=ROOT)
        return {"command": argv, "exit_code": process.returncode,
                "stdout": process.stdout, "stderr": process.stderr,
                "seconds": round(time.monotonic() - start, 6)}
    except (subprocess.TimeoutExpired, OSError) as error:
        return {"command": argv, "exit_code": None, "stdout": "",
                "stderr": str(error), "infrastructure_error": type(error).__name__,
                "seconds": round(time.monotonic() - start, 6)}


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def fingerprint_inputs(build, cases):
    """Detect a rebuild or source edit during a purported single-build gate."""
    files = {case["source"] for case in cases}
    # Also detect fixtures added during the gate: otherwise a newly added
    # case could silently be absent from an apparently complete run.
    files.update(SOURCE.glob("*.js"))
    files.update({ROOT / "utils/shllvm.py", Path(__file__).resolve()})
    for directory in ("lib/BCGen/SH", "include/hermes/BCGen/SH",
                      "lib/BCGen/HBC", "include/hermes/BCGen/HBC", "lib/VM",
                      "include/hermes/VM", "lib/InternalJavaScript", "tools/shermes",
                      "include/hermes/AST", "lib/AST",
                      "include/hermes/IR", "lib/IR", "lib/IRGen", "lib/Optimizer", "lib/Sema",
                      "include/hermes/Optimizer", "include/hermes/Sema"):
        files.update(path for path in (ROOT / directory).rglob("*")
                     if path.is_file() and (path.suffix in {".c", ".cpp", ".h", ".def", ".js"}
                                           or path.name == "CMakeLists.txt"))
    files.update({build / "bin/shermes", build / "lib/libshllvm_runtime.a",
                  build / "lib/libshllvm_runtime.so", build / "lib/libhermesvm.so",
                  build / "tools/shermes/libshermes_console.so",
                  ROOT / "CMakeLists.txt",
                  ROOT / "lib/CMakeLists.txt",
                  build / "lib/config/libhermesvm-config.h"})
    return {str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path):
            sha256(path) if path.is_file() else None for path in sorted(files)}


def metadata(source):
    data = {}
    for line in source.read_text().splitlines()[:6]:
        if line.startswith("// SHLLVM_TEST:"):
            data = json.loads(line.split(":", 1)[1])
            break
    if not isinstance(data, dict):
        raise ValueError(f"{source.name}: SHLLVM_TEST must contain an object")
    default_kind = ("runtime-error" if source.name.startswith("error_") else
                    "compile-error" if source.name.startswith(("reject_", "unsupported_")) else
                    "positive")
    data.setdefault("kind", default_kind)
    data.setdefault("family", source.stem.split("_", 1)[0])
    data.setdefault("c_oracle", "required")
    data.setdefault("hermes_flags", [])
    data.setdefault("runtime_flags", [])
    data.setdefault("expected_error", "TypeError")
    if data["kind"] not in {"positive", "runtime-error", "runtime-rejection", "compile-error"}:
        raise ValueError(f"{source.name}: unknown kind {data['kind']!r}")
    if data["kind"] == "runtime-rejection" and not data.get("rejection_reason"):
        raise ValueError(f"{source.name}: runtime-rejection requires rejection_reason")
    if data["c_oracle"] not in {"required", "record-only", "skip"}:
        raise ValueError(f"{source.name}: unknown c_oracle policy")
    if data["c_oracle"] != "required" and not data.get("c_oracle_reason"):
        raise ValueError(f"{source.name}: a C oracle limitation needs c_oracle_reason")
    for field in ("hermes_flags", "runtime_flags"):
        if not isinstance(data[field], list) or any(not isinstance(x, str) for x in data[field]):
            raise ValueError(f"{source.name}: {field} must be a string array")
    if any(not flag.startswith("-X") for flag in data["hermes_flags"]):
        raise ValueError(f"{source.name}: hermes_flags must be frontend -X options")
    if data.get("completion") is not None and not isinstance(data["completion"], str):
        raise ValueError(f"{source.name}: completion must be a complete output line")
    return {"source": source, **data}


def successful_output(record, case):
    return (record["exit_code"] == 0
            and clean_sanitizers(record)
            and (not case.get("completion") or case["completion"] in record["stdout"].splitlines())
            and not any(line.startswith("FAIL") for line in record["stdout"].splitlines()))


def expected_exception(record, case, *, node=False):
    exit_ok = (record["exit_code"] is not None and record["exit_code"] != 0
               if node else record["exit_code"] == 1)
    return bool(exit_ok and clean_sanitizers(record)
                and re.search(r"\b" + re.escape(case["expected_error"]) + r"\b",
                                     record["stderr"])
                and (node or not case.get("expected_diagnostic")
                     or re.search(case["expected_diagnostic"], record["stderr"])))


def clean_sanitizers(record):
    return not any(marker in record["stderr"] for marker in (
        "ERROR: AddressSanitizer", "ERROR: LeakSanitizer",
        "UndefinedBehaviorSanitizer", "runtime error:"))


def compiler_rejected(record, *, driver=False):
    # A signal, compiler assertion, timeout, or sanitizer failure is not a
    # successful rejection contract even if an old output survived it.
    return (record["exit_code"] == (2 if driver else 1)
            and clean_sanitizers(record)
            and "error:" in record["stderr"].lower())


def build_manifest(executable):
    path = executable.with_name(executable.name + ".build.json")
    try:
        data = json.loads(path.read_text())
    except (OSError, ValueError) as error:
        return {"manifest": str(path), "manifest_valid": False, "manifest_error": str(error)}
    direct = (data.get("program_c_generation") is False
              and data.get("pipeline") == "JavaScript -> Hermes SSA -> LLVM IR -> LLVM")
    return {"manifest": str(path), "manifest_valid": direct,
            "program_c_generation": data.get("program_c_generation"),
            "compiler_sha256": data.get("compiler_sha256"),
            "runtime_bridge_sha256": data.get("runtime_bridge_sha256")}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-dir", default=os.environ.get("HERMES_BUILD_DIR", str(ROOT / "build-llvm")))
    parser.add_argument("--llvm-bin", default=os.environ.get("LLVM_BIN"))
    parser.add_argument("--output", default=str(ROOT / "docs/llvm/feature-work/extension-validation.json"))
    parser.add_argument("--case", action="append", default=[], help="filename substring; repeat to select several")
    parser.add_argument("--jobs", type=int, default=2)
    parser.add_argument("--timeout", type=float, default=120)
    parser.add_argument("--skip-jit", action="store_true", help="partial gate: omit lli execution")
    parser.add_argument("--quick", action="store_true", help="partial gate: native LLVM O2 only")
    parser.add_argument("--oracle-only", action="store_true", help="inspect Node and C only; does not validate LLVM")
    args = parser.parse_args()
    if args.jobs < 1 or args.timeout <= 0:
        parser.error("jobs and timeout must be positive")
    build = Path(args.build_dir).expanduser().resolve()
    compiler = build / "bin/shermes"
    node = shutil.which("node")
    if not node or not compiler.is_file():
        parser.error("Node and a built shermes compiler are required")
    try:
        cases = [metadata(path) for path in sorted(SOURCE.glob("*.js"))
                 if not args.case or any(word in path.name for word in args.case)]
    except (ValueError, OSError) as error:
        parser.error(str(error))
    if not cases:
        parser.error("no fixtures matched the selection")
    work = build / "shllvm-extension-tests"
    work.mkdir(parents=True, exist_ok=True)
    output = Path(args.output).expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.setdefault("ASAN_OPTIONS", "detect_leaks=0")
    levels = ["2"] if args.quick else ["0", "2"]
    base_driver = [sys.executable, ROOT / "utils/shllvm.py"]
    driver_options = ["--build-dir", build, "--no-runtime-build", "--timeout", str(args.timeout)]
    if args.llvm_bin:
        driver_options += ["--llvm-bin", args.llvm_bin]
    before = fingerprint_inputs(build, cases)
    started = time.time()

    def invoke(argv):
        return run(argv, timeout=args.timeout, env=env)

    def driver(case, action, hopt, lopt, destination):
        flags = ["--hermes-arg=" + flag for flag in case["hermes_flags"]]
        command = [*base_driver, action, *driver_options, "--hermes-opt", hopt,
                   "--llvm-opt", lopt, *flags, "-o", destination, case["source"]]
        if action == "jit" and case["runtime_flags"]:
            command += ["--", *case["runtime_flags"]]
        return invoke(command)

    def compile_error_case(case):
        source = case["source"]
        records = []
        if args.oracle_only:
            return {"name": source.name, "kind": case["kind"], "family": case["family"],
                    "passed": None, "status": "not-run-in-oracle-only-mode", "records": []}
        passed = True
        for hopt in ["O0", "O"]:
            flags = [compiler, "-" + hopt, *BASE_FLAGS, *case["hermes_flags"], "-emit-llvm", source]
            target = work / (source.stem + "-" + hopt + "-existing.ll")
            sentinel = b"existing published LLVM output must remain unchanged\n"
            target.write_bytes(sentinel)
            result = invoke([*flags, "-o", target])
            preserved = target.is_file() and target.read_bytes() == sentinel
            good = (compiler_rejected(result)
                    and not result["stdout"] and preserved)
            if case.get("expected_diagnostic"):
                good = good and bool(re.search(case["expected_diagnostic"], result["stderr"]))
            records.append({"stage": "compiler-rejection-file", "hermes_opt": hopt,
                            "existing_output_preserved": preserved, "passed": good, **result})
            passed = passed and good
            result = invoke([*flags, "-o", "-"])
            good = compiler_rejected(result) and not result["stdout"]
            records.append({"stage": "compiler-rejection-stdout", "hermes_opt": hopt,
                            "no_partial_stdout_module": not result["stdout"], "passed": good, **result})
            passed = passed and good
            executable = work / (source.stem + "-" + hopt + "-existing-executable")
            artifacts = [executable, executable.with_name(executable.name + ".ll"),
                         executable.with_name(executable.name + ".bc")]
            for artifact in artifacts:
                artifact.write_bytes(sentinel)
            result = driver(case, "build", hopt, "2", executable)
            preserved = all(artifact.is_file() and artifact.read_bytes() == sentinel for artifact in artifacts)
            good = compiler_rejected(result, driver=True) and preserved
            records.append({"stage": "driver-rejection-publication", "hermes_opt": hopt,
                            "all_existing_outputs_preserved": preserved, "passed": good, **result})
            passed = passed and good
        return {"name": source.name, "kind": case["kind"], "family": case["family"],
                "passed": passed, "llvm_validated": True, "records": records}

    def executable_case(case):
        source = case["source"]
        records = []
        runtime_error = case["kind"] == "runtime-error"
        runtime_rejection = case["kind"] == "runtime-rejection"
        oracle = invoke([node, "--expose-gc", "-e", NODE_WRAPPER, source])
        oracle_good = (expected_exception(oracle, case, node=True) if runtime_error else
                       successful_output(oracle, case))
        if "expected_stdout" in case:
            oracle_good = oracle_good and oracle["stdout"] == case["expected_stdout"]
        records.append({"stage": "node", "passed": oracle_good, **oracle})
        passed = oracle_good
        c_statuses = []
        for hopt in ["O0", "O"]:
            c_run = None
            c_good = False
            c_status = "skipped"
            if case["c_oracle"] != "skip":
                c_exe = work / (source.stem + "-" + hopt + "-c")
                compiled = invoke([compiler, "-" + hopt, *BASE_FLAGS, *case["hermes_flags"],
                                   source, "-o", c_exe])
                records.append({"stage": "c-build", "hermes_opt": hopt, **compiled})
                c_status = "compile-failed"
                if compiled["exit_code"] == 0:
                    c_run = invoke([c_exe, *case["runtime_flags"]])
                    c_good = (expected_exception(c_run, case) if runtime_error else
                              successful_output(c_run, case) and c_run["stdout"] == oracle["stdout"])
                    c_status = "matched" if c_good else "mismatched"
                    records.append({"stage": "c-run", "hermes_opt": hopt,
                                    "matches_node_contract": c_good, **c_run})
            c_statuses.append({"hermes_opt": hopt, "status": c_status,
                               "required": case["c_oracle"] == "required"})
            if case["c_oracle"] == "required":
                passed = passed and c_good
            if args.oracle_only:
                continue
            for lopt in levels:
                executable = work / (source.stem + "-" + hopt + "-llvm" + lopt)
                compiled = driver(case, "build", hopt, lopt, executable)
                manifest = build_manifest(executable) if compiled["exit_code"] == 0 else {}
                build_good = compiled["exit_code"] == 0 and manifest.get("manifest_valid", False)
                records.append({"stage": "llvm-build", "hermes_opt": hopt, "llvm_opt": lopt,
                                "passed": build_good, **manifest, **compiled})
                passed = passed and build_good
                if not build_good:
                    continue
                execution = invoke([executable, *case["runtime_flags"]])
                good = (expected_exception(execution, case) if runtime_error or runtime_rejection else
                        successful_output(execution, case) and execution["stdout"] == oracle["stdout"])
                if c_run is None or runtime_rejection:
                    matches_c = None
                elif runtime_error:
                    matches_c = expected_exception(execution, case) and c_good
                else:
                    matches_c = (execution["stdout"] == c_run["stdout"]
                                 and execution["exit_code"] == c_run["exit_code"])
                records.append({"stage": "llvm-run", "hermes_opt": hopt, "llvm_opt": lopt,
                                "matches_node_contract": None if runtime_rejection else good,
                                "matches_declared_rejection": good if runtime_rejection else None,
                                "matches_c": matches_c,
                                "passed": good, **execution})
                passed = passed and good
        if not args.skip_jit and not args.oracle_only:
            destination = work / (source.stem + "-jit")
            execution = driver(case, "jit", "O", "2", destination)
            good = (expected_exception(execution, case) if runtime_error or runtime_rejection else
                    successful_output(execution, case) and execution["stdout"] == oracle["stdout"])
            manifest = build_manifest(destination)
            good = good and manifest.get("manifest_valid", False)
            records.append({"stage": "lli-jit", "hermes_opt": "O", "llvm_opt": "2",
                            "matches_node_contract": None if runtime_rejection else good,
                            "matches_declared_rejection": good if runtime_rejection else None,
                            "passed": good, **manifest, **execution})
            passed = passed and good
        return {"name": source.name, "kind": case["kind"], "family": case["family"],
                "passed": bool(passed), "llvm_validated": not args.oracle_only,
                "completion": case.get("completion"), "c_oracle_policy": case["c_oracle"],
                "rejection_reason": case.get("rejection_reason"),
                "c_oracle_reason": case.get("c_oracle_reason"), "c_oracles": c_statuses,
                "c_oracle_fully_matched": all(status["status"] == "matched" for status in c_statuses),
                "records": records}

    def test(case):
        try:
            return compile_error_case(case) if case["kind"] == "compile-error" else executable_case(case)
        except Exception as error:
            # Preserve other fixtures and an auditable failure if a fixture or
            # environment triggers an unexpected harness exception.
            return {"name": case["source"].name, "kind": case["kind"], "passed": False,
                    "harness_error": f"{type(error).__name__}: {error}", "records": []}

    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = {pool.submit(test, case): case for case in cases}
        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            results.append(result)
            label = "SKIP" if result["passed"] is None else "PASS" if result["passed"] else "FAIL"
            if result.get("c_oracle_policy") in {"skip", "record-only"}:
                label += " [C ORACLE LIMITED]"
            if result["kind"] == "runtime-rejection":
                label += " [EXPECTED RUNTIME REJECTION]"
            print(label + " " + result["name"], flush=True)
            if result.get("harness_error"):
                print("  " + result["harness_error"], flush=True)
            if result["passed"] is False:
                for record in result["records"]:
                    if (record.get("passed") is False or record.get("matches_node_contract") is False
                            or record.get("stage") in {"c-build", "llvm-build"} and record.get("exit_code") != 0):
                        detail = record["stderr"][:1000].strip() or repr(record["stdout"][:500])
                        print("  " + record["stage"] + " " + record.get("hermes_opt", "")
                              + "/" + record.get("llvm_opt", "") + ": " + detail, flush=True)
            # Keep completed case records available even if a later test is
            # interrupted. The final evidence replaces this incomplete record.
            output.write_text(json.dumps({"complete": False, "started_at_unix": started,
                                          "results": results}, indent=2) + "\n")

    after = fingerprint_inputs(build, cases)
    changed = sorted(path for path in before.keys() | after.keys() if before.get(path) != after.get(path))
    all_records = [record for result in results for record in result["records"]]
    limitations = [{"name": result["name"], "policy": result["c_oracle_policy"],
                    "reason": result["c_oracle_reason"], "results": result["c_oracles"]}
                   for result in results if result.get("c_oracle_policy") in {"skip", "record-only"}]
    summary = {
        "schema_version": 1, "complete": True, "started_at_unix": started,
        "finished_at_unix": time.time(), "source_cases": len(results),
        "passed_cases": sum(result["passed"] is True for result in results),
        "failed_cases": sum(result["passed"] is False for result in results),
        "skipped_cases": sum(result["passed"] is None for result in results),
        "positive_cases": sum(result["kind"] == "positive" for result in results),
        "runtime_error_cases": sum(result["kind"] == "runtime-error" for result in results),
        "runtime_rejection_cases": sum(result["kind"] == "runtime-rejection" for result in results),
        "compile_error_cases": sum(result["kind"] == "compile-error" for result in results),
        "native_llvm_executions": sum(record["stage"] == "llvm-run" for record in all_records),
        "native_llvm_matches": sum(record["stage"] == "llvm-run" and record["passed"] for record in all_records),
        "native_llvm_vs_node_matches": sum(record["stage"] == "llvm-run" and record.get("matches_node_contract") is True
                                            for record in all_records),
        "native_llvm_expected_rejections": sum(record["stage"] == "llvm-run" and record.get("matches_declared_rejection") is True
                                               for record in all_records),
        "lli_executions": sum(record["stage"] == "lli-jit" for record in all_records),
        "lli_matches": sum(record["stage"] == "lli-jit" and record["passed"] for record in all_records),
        "lli_vs_node_matches": sum(record["stage"] == "lli-jit" and record.get("matches_node_contract") is True
                                    for record in all_records),
        "lli_expected_rejections": sum(record["stage"] == "lli-jit" and record.get("matches_declared_rejection") is True
                                       for record in all_records),
        "c_oracle_fully_matched_cases": sum(result.get("c_oracle_fully_matched", False) for result in results),
        "c_oracle_limitations": limitations, "input_files_unchanged": not changed,
        "changed_input_files": changed, "input_sha256": before,
        "hermes_optimization_levels": ["O0", "O"], "llvm_optimization_levels": levels,
        "jit_optimization_levels": {"hermes": "O", "llvm": "2"},
        "selection": args.case, "partial_gate": bool(args.case or args.quick or args.skip_jit or args.oracle_only),
        "llvm_validation_performed": not args.oracle_only,
        "asan_options": env.get("ASAN_OPTIONS", ""), "lsan_options": env.get("LSAN_OPTIONS", ""),
        "scope": ("Node and inherited C oracle inspection only" if args.oracle_only else
                  "host native and real lli execution; targeted language extension contracts; "
                  "not device execution or full ECMAScript conformance"),
        "node_semantics": "script via vm.runInThisContext; not a CommonJS module wrapper",
        "results": sorted(results, key=lambda result: result["name"]),
    }
    output.write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps({key: value for key, value in summary.items()
                      if key not in {"results", "input_sha256"}}, indent=2))
    print("Evidence: " + str(output))
    return 1 if summary["failed_cases"] or changed else 0


if __name__ == "__main__":
    raise SystemExit(main())
