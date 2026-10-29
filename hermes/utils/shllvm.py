#!/usr/bin/env python3
"""Compile JavaScript directly through Hermes SSA to LLVM IR and native code.

The static runtime bridge is built once through CMake/Ninja dependency tracking.
No per-program C file is emitted or parsed on this path. Python dependencies:
standard library only. Configure Hermes first; see docs/llvm/README.md.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]


class BuildError(RuntimeError):
    pass


def frontend_argument(value):
    """Keep output selection and filenames under the driver's control."""
    if not value.startswith("-X") or len(value) <= 2 or any(c.isspace() for c in value):
        raise argparse.ArgumentTypeError(
            "--hermes-arg accepts a single frontend -X option, for example "
            "--hermes-arg=-Xasync-generators")
    return value


def command(argv, *, env=None, capture=False, timeout=180, log=None):
    argv = [str(x) for x in argv]
    start = time.monotonic()
    try:
        p = subprocess.run(argv, env=env, text=True, capture_output=True,
                           timeout=timeout)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise BuildError(f"{' '.join(argv)}: {exc}") from exc
    if log is not None:
        log.append({"command": argv, "exit_code": p.returncode,
                    "seconds": round(time.monotonic()-start, 6),
                    "stdout": p.stdout, "stderr": p.stderr})
    if not capture or p.returncode:
        if p.stdout:
            print(p.stdout, end="", file=sys.stderr)
        if p.stderr:
            print(p.stderr, end="", file=sys.stderr)
    if p.returncode:
        raise BuildError(f"command failed ({p.returncode}): {' '.join(argv)}")
    return p


def cache_settings(build):
    result = {}
    path = build / "CMakeCache.txt"
    if not path.is_file():
        raise BuildError(f"No configured Hermes build at {build}; configure it with CMake first")
    for line in path.read_text().splitlines():
        if line.startswith(("#", "//")) or ":" not in line or "=" not in line:
            continue
        key, rest = line.split(":", 1)
        _, value = rest.split("=", 1)
        result[key] = value
    return result


def find_tool(name, llvm_bin=None, settings=None):
    if llvm_bin:
        p = Path(llvm_bin) / name
        if p.is_file():
            return p.resolve()
    found = shutil.which(name)
    if found:
        return Path(found).resolve()
    if settings:
        if name == "cmake" and settings.get("CMAKE_COMMAND"):
            p = Path(settings["CMAKE_COMMAND"])
            if p.is_file():
                return p
        compiler = settings.get("CMAKE_C_COMPILER")
        if compiler:
            p = Path(compiler).resolve().parent / name
            if p.is_file():
                return p
    raise BuildError(f"Required tool {name!r} was not found; set LLVM_BIN or --llvm-bin")


def sha256(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as f:
        for chunk in iter(lambda: f.read(1024*1024), b""):
            h.update(chunk)
    return h.hexdigest()


def prepare(args, *, need_runtime=True, log=None):
    build = Path(args.build_dir).expanduser().resolve()
    settings = cache_settings(build)
    llvm_bin = args.llvm_bin or os.environ.get("LLVM_BIN")
    tool_names = ["clang", "llvm-as", "opt", "lli"]
    tools = {n: find_tool(n, llvm_bin, settings) for n in tool_names}
    compiler = Path(args.compiler).resolve() if args.compiler else build / "bin/shermes"
    if not compiler.is_file():
        raise BuildError(f"Build the compiler first: cmake --build {build} --target shermes")
    runtime = build / ("lib/libshllvm_runtime.so" if args.action == "jit" else "lib/libshllvm_runtime.a")
    if need_runtime and not args.no_runtime_build:
        cmake = find_tool("cmake", llvm_bin, settings)
        command([cmake, "--build", build, "--target", "shllvm_runtime", "shllvm_runtime_shared", "--parallel", "3"],
                timeout=900, capture=True, log=log)
    if need_runtime and not runtime.is_file():
        raise BuildError(f"Missing runtime bridge {runtime}; build targets shllvm_runtime shllvm_runtime_shared")
    asan = settings.get("HERMES_ENABLE_ADDRESS_SANITIZER") == "ON"
    ubsan = settings.get("HERMES_ENABLE_UNDEFINED_BEHAVIOR_SANITIZER") == "ON"
    return build, settings, tools, compiler, runtime, asan, ubsan


def emit_and_verify(args, ll_path, context, log, output):
    build, settings, tools, compiler, runtime, asan, ubsan = context
    source = Path(args.source).resolve()
    if not source.is_file():
        raise BuildError(f"JavaScript source not found: {source}")
    ll_path.parent.mkdir(parents=True, exist_ok=True)
    # Publish only verified complete outputs. An unsupported opcode or LLVM
    # verifier error leaves an existing user output untouched.
    with tempfile.TemporaryDirectory(prefix="shllvm-", dir=ll_path.parent) as td:
        temp = Path(td)
        compilation_source = source
        module_manifest = None
        if args.module:
            compilation_source = temp / "modules.js"
            graph_manifest = temp / "modules.json"
            node = find_tool("node")
            module_command = [node, ROOT / "utils/module-host/compiler.cjs", source,
                              "--output", compilation_source, "--manifest", graph_manifest]
            if args.module_root:
                module_command += ["--root", Path(args.module_root).resolve()]
            for included in args.module_include:
                module_command += ["--include", Path(included).resolve()]
            command(module_command, capture=True, log=log)
            module_manifest = json.loads(graph_manifest.read_text())
            module_manifest["bundle_sha256"] = sha256(compilation_source)
            # Protect every graph input, including aliases and hardlinks, from
            # every published artifact, not just the entry/executable pair.
            for target in (output, ll_path, ll_path.with_suffix(".bc"),
                           ll_path.with_suffix(".build.json")):
                for input_name in module_manifest["inputs"]:
                    input_path = Path(input_name)
                    if target.resolve() == input_path or (target.exists() and target.samefile(input_path)):
                        raise BuildError("Output must not overwrite a module graph input: " + str(target))
        raw = temp / "program.ll"
        bc = temp / "program.bc"
        optimized = temp / "optimized.bc"
        command([compiler, f"-{args.hermes_opt}", "-Xes6-block-scoping", "-Xenable-tdz",
                 *args.hermes_arg, "-emit-llvm", compilation_source, "-o", raw],
                capture=True, log=log)
        command([tools["llvm-as"], raw, "-o", bc], capture=True, log=log)
        command([tools["opt"], "-passes=verify", "-disable-output", bc], capture=True, log=log)
        pipeline = "verify" if args.llvm_opt == "0" else f"verify,default<O{args.llvm_opt}>,verify"
        command([tools["opt"], f"-passes={pipeline}", bc, "-o", optimized], capture=True, log=log)
        # Rename within one filesystem to keep each output replacement atomic.
        os.replace(raw, ll_path)
        os.replace(optimized, ll_path.with_suffix(".bc"))
    return module_manifest


def execute(args):
    log = []
    context = prepare(args, need_runtime=args.action != "emit", log=log)
    build, settings, tools, compiler, runtime, asan, ubsan = context
    source = Path(args.source).resolve()
    default = build / "shllvm-artifacts" / source.stem
    output = Path(args.output).resolve() if args.output else default
    if output == source:
        raise BuildError("Output must not overwrite the JavaScript source")
    ll_path = output if args.action == "emit" else output.with_name(output.name + ".ll")
    if args.action == "emit" and ll_path.suffix != ".ll":
        ll_path = ll_path.with_suffix(".ll")
    module_manifest = emit_and_verify(args, ll_path, context, log, output)
    manifest = {"source": str(source), "source_sha256": sha256(source),
                "llvm_ir": str(ll_path), "llvm_ir_sha256": sha256(ll_path),
                "hermes_optimization": args.hermes_opt,
                "hermes_frontend_arguments": args.hermes_arg,
                "llvm_optimization": args.llvm_opt,
                "pipeline": "JavaScript -> Hermes SSA -> LLVM IR -> LLVM",
                "program_c_generation": False,
                "compiler_sha256": sha256(compiler),
                "runtime_bridge": str(runtime),
                "runtime_source_sha256": sha256(ROOT / "lib/BCGen/SH/LLVMNative/runtime.c"),
                "runtime_header_sha256": sha256(ROOT / "lib/BCGen/SH/LLVMNative/runtime.h"),
                "runtime_config_sha256": sha256(build / "lib/config/libhermesvm-config.h"),
                "es6_block_scoping": True, "temporal_dead_zone_checks": True,
                "runtime_bridge_sha256": sha256(runtime) if runtime.is_file() else None,
                "runtime_address_sanitizer": asan,
                "runtime_undefined_behavior_sanitizer": ubsan,
                "commands": log}
    if module_manifest is not None:
        manifest["modules"] = module_manifest
        manifest["pipeline"] = "Source modules -> binding-aware module factories -> Hermes SSA -> LLVM IR -> LLVM"
    sanitizer_flags = []
    if asan:
        sanitizer_flags += ["-fsanitize=address"]
    if ubsan:
        sanitizer_flags += ["-fsanitize=undefined"]
    if args.action in ("build", "run"):
        output.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="shllvm-link-", dir=output.parent) as td:
            temporary_exe = Path(td) / "program"
            library_dirs = [build / "lib", build / "tools/shermes", build / "jsi"]
            flags = [x for p in library_dirs for x in (f"-L{p}", f"-Wl,-rpath,{p}")]
            command([tools["clang"], ll_path.with_suffix(".bc"), f"-O{args.llvm_opt}",
                     "-Wno-override-module", *sanitizer_flags, *flags,
                     runtime, "-lshermes_console", "-lhermesvm", "-lm",
                     "-o", temporary_exe], capture=True, log=log)
            os.replace(temporary_exe, output)
        manifest["native_executable"] = str(output)
        manifest["native_executable_sha256"] = sha256(output)
    manifest_path = ll_path.with_suffix(".build.json")
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    if args.action == "emit":
        print(ll_path)
        return 0
    if args.action == "build":
        print(output)
        return 0
    forwarded = args.arguments
    if forwarded and forwarded[0] == "--":
        forwarded = forwarded[1:]
    if args.action == "run":
        return subprocess.run([str(output), *forwarded], timeout=args.timeout).returncode
    env = os.environ.copy()
    if asan:
        arch = "aarch64" if os.uname().machine == "aarch64" else "x86_64"
        library_name = f"libclang_rt.asan-{arch}.so"
        asan_path = command([tools["clang"], f"-print-file-name={library_name}"],
                            capture=True).stdout.strip()
        if not Path(asan_path).is_file():
            raise BuildError(f"ASan runtime required for lli: {library_name}")
        env["LD_PRELOAD"] = asan_path + (":" + env["LD_PRELOAD"] if env.get("LD_PRELOAD") else "")
    jit_command = [str(tools["lli"]), f"--dlopen={runtime}",
                   str(ll_path.with_suffix(".bc")), *forwarded]
    manifest["jit_command"] = jit_command
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    return subprocess.run(jit_command, env=env, timeout=args.timeout).returncode


def parser():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="action", required=True)
    for name in ("emit", "build", "run", "jit"):
        q = sub.add_parser(name)
        q.add_argument("--build-dir", default=os.environ.get("HERMES_BUILD_DIR", str(ROOT / "build-llvm")))
        q.add_argument("--llvm-bin", default=os.environ.get("LLVM_BIN"))
        q.add_argument("--compiler")
        q.add_argument("--module", action="store_true", help="compile a source-text module graph")
        q.add_argument("--module-root", help="module graph filesystem root (default: entry directory)")
        q.add_argument("--module-include", action="append", default=[],
                       help="include an additional module root for computed dynamic imports")
        q.add_argument("--hermes-opt", choices=("O0", "O"), default="O")
        q.add_argument("--hermes-arg", action="append", type=frontend_argument, default=[],
                       help="extra frontend -X option; repeat as --hermes-arg=-Xname")
        q.add_argument("--llvm-opt", choices=("0", "1", "2", "3", "s"), default="2")
        q.add_argument("--no-runtime-build", action="store_true", help="use an already built matching bridge")
        q.add_argument("-o", "--output", help="output .ll (emit) or executable (build/run/jit artifact stem)")
        q.add_argument("--timeout", type=float, default=60, help="execution timeout in seconds")
        q.add_argument("source")
    return p


def main():
    argv = sys.argv[1:]
    if "--" in argv:
        split = argv.index("--")
        compiler_args, forwarded = argv[:split], argv[split+1:]
    else:
        compiler_args, forwarded = argv, []
    args = parser().parse_args(compiler_args)
    args.arguments = forwarded
    if not args.module and (args.module_root or args.module_include):
        parser().error("--module-root and --module-include require --module")
    try:
        return execute(args)
    except (BuildError, subprocess.TimeoutExpired) as exc:
        print(f"shllvm: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
