#!/usr/bin/env python3
"""Focused tests for direct LLVM driver publication and output selection.

Run after building shermes. The process inherits ASAN_OPTIONS; restricted
environments that prohibit LeakSanitizer process inspection can use
ASAN_OPTIONS=detect_leaks=0 while retaining AddressSanitizer checks.
"""

import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile


def main():
    root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compiler", type=Path, default=root / "build-llvm/bin/shermes")
    parser.add_argument("--evidence", type=Path)
    args = parser.parse_args()
    compiler = args.compiler.resolve()
    environment = os.environ.copy()
    environment["CC"] = "/nonexistent/direct-llvm-emission-must-not-invoke-cc"
    results = []

    with tempfile.TemporaryDirectory(prefix="shllvm-driver-") as temporary:
        directory = Path(temporary)
        valid = directory / "valid.js"
        valid.write_text("print(6 * 7);\n")
        invalid = directory / "invalid.js"
        invalid.write_text("function {")
        unsupported = directory / "unsupported.js"
        unsupported.write_text('print(/abc/.test("abc"));\n')
        output = directory / "existing.ll"
        sentinel = b"existing LLVM module must survive failed compilation\n"
        output.write_bytes(sentinel)

        def invoke(source, *options):
            return subprocess.run(
                [str(compiler), "-O0", "--emit-llvm", str(source), *options],
                cwd=directory,
                env=environment,
                capture_output=True,
                text=True,
                timeout=30,
            )

        def record(name, process, checks):
            results.append({
                "case": name,
                "exit": process.returncode,
                "checks": checks,
                "pass": all(checks.values()),
                "stderr": process.stderr,
            })

        for name, source in [("syntax failure preserves output", invalid),
                             ("unsupported opcode preserves output", unsupported)]:
            process = invoke(source, "-o", str(output))
            record(name, process, {
                "rejected": process.returncode != 0,
                "previous_output_preserved": output.read_bytes() == sentinel,
                "stdout_empty": process.stdout == "",
                "diagnostic": "error:" in process.stderr,
            })

        process = invoke(unsupported, "-o", "-")
        record("unsupported opcode produces no partial stdout module", process, {
            "rejected": process.returncode != 0,
            "stdout_empty": process.stdout == "",
            "opcode_diagnostic": "CreateRegExpInst" in process.stderr,
        })

        process = invoke(valid)
        record("default output bypasses C generation and compiler", process, {
            "success": process.returncode == 0,
            "llvm_output_created": (directory / "valid.ll").is_file(),
            "no_generated_c": not (directory / "valid.c").exists(),
        })

        process = invoke(valid, "-o", "-")
        record("stdout module has default main", process, {
            "success": process.returncode == 0,
            "main_present": "define i32 @main" in process.stdout,
        })

        process = invoke(valid, "-exported-unit=driver_test", "-o", "-")
        record("exported unit suppresses main", process, {
            "success": process.returncode == 0,
            "main_absent": "define i32 @main" not in process.stdout,
            "unit_symbol_present": "sh_export_driver_test" in process.stdout,
        })

    report = {
        "compiler": str(compiler),
        "passed": sum(item["pass"] for item in results),
        "total": len(results),
        "results": results,
    }
    rendered = json.dumps(report, indent=2) + "\n"
    if args.evidence:
        args.evidence.parent.mkdir(parents=True, exist_ok=True)
        args.evidence.write_text(rendered)
    print(rendered, end="")
    return 0 if report["passed"] == report["total"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
