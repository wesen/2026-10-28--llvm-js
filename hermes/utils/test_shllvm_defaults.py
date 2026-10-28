#!/usr/bin/env python3
"""Execute raw --emit-llvm lexical defaults and explicit-override checks.

Build shermes, shllvm_runtime, and shllvm_runtime_shared first. This test calls
the compiler directly, so a wrapper cannot hide an incorrect CLI default.
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
    parser.add_argument("--build-dir", type=Path, default=root / "build-llvm")
    parser.add_argument("--clang", default=os.environ.get("CLANG", "clang"))
    parser.add_argument("--evidence", type=Path)
    args = parser.parse_args()
    build = args.build_dir.resolve()
    cache = (build / "CMakeCache.txt").read_text()
    sanitizer = ["-fsanitize=address"] if "HERMES_ENABLE_ADDRESS_SANITIZER:BOOL=ON" in cache else []
    loop = "let f=[]; for(let i=0;i<3;i++){f.push(() => i);} print(f[0](),f[1](),f[2]());\n"
    tdz = ("function call(fn){return fn();} function f(){let read=()=>x; "
           "try {print(call(read));}catch(e){print(e.name);} let x=7;return read();}print(f());\n")
    cases = [
        ("loop-default", loop, [], "0 1 2\n"),
        ("loop-explicit-off", loop, ["-Xes6-block-scoping=false"], "3 3 3\n"),
        ("tdz-default", tdz, [], "ReferenceError\n7\n"),
        ("tdz-explicit-off", tdz, ["-Xenable-tdz=false"], "undefined\n7\n"),
    ]
    results = []
    with tempfile.TemporaryDirectory(prefix="shllvm-defaults-") as temporary:
        directory = Path(temporary)
        for name, source, flags, expected in cases:
            source_path = directory / (name + ".js")
            ir_path = directory / (name + ".ll")
            executable = directory / name
            source_path.write_text(source)
            compile_command = [str(build / "bin/shermes"), "-O0", "--emit-llvm",
                               *flags, str(source_path), "-o", str(ir_path)]
            compiled = subprocess.run(compile_command, capture_output=True, text=True, timeout=30)
            record = {"case": name, "source": source, "flags": flags,
                      "compile_exit": compiled.returncode, "compile_stderr": compiled.stderr,
                      "expected": expected, "passed": False}
            if compiled.returncode == 0:
                link_command = [args.clang, "-Wno-override-module", "-O2", *sanitizer,
                                str(ir_path), str(build / "lib/libshllvm_runtime.a"),
                                "-L" + str(build / "lib"),
                                "-L" + str(build / "tools/shermes"),
                                "-Wl,-rpath," + str(build / "lib"),
                                "-Wl,-rpath," + str(build / "tools/shermes"),
                                "-lshermes_console", "-lhermesvm", "-lm", "-o", str(executable)]
                linked = subprocess.run(link_command, capture_output=True, text=True, timeout=30)
                record.update(link_exit=linked.returncode, link_stderr=linked.stderr)
                if linked.returncode == 0:
                    run = subprocess.run([str(executable)], capture_output=True, text=True, timeout=30)
                    record.update(exit=run.returncode, actual=run.stdout, stderr=run.stderr,
                                  passed=run.returncode == 0 and run.stdout == expected)
            results.append(record)

        # Preserve the frontend's documented limit: an obvious TDZ violation
        # is an early diagnostic, including when source surrounds it with try.
        source = "function f(){try {print(x);}catch(e){print(e.name);} let x=7;} f();\n"
        source_path = directory / "static-tdz.js"
        source_path.write_text(source)
        compiled = subprocess.run(
            [str(build / "bin/shermes"), "-O0", "--emit-llvm", str(source_path), "-o", "-"],
            capture_output=True, text=True, timeout=30,
        )
        results.append({"case": "static-tdz-diagnostic", "source": source,
                        "exit": compiled.returncode, "stderr": compiled.stderr,
                        "passed": compiled.returncode != 0 and compiled.stdout == ""
                        and "TDZ violation" in compiled.stderr})

    report = {"passed": sum(item["passed"] for item in results),
              "total": len(results), "results": results}
    rendered = json.dumps(report, indent=2) + "\n"
    if args.evidence:
        args.evidence.parent.mkdir(parents=True, exist_ok=True)
        args.evidence.write_text(rendered)
    print(rendered, end="")
    return 0 if report["passed"] == report["total"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
