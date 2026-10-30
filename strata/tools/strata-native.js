#!/usr/bin/env node
"use strict";
const fs = require("node:fs"),
  path = require("node:path"),
  crypto = require("node:crypto");
const { spawnSync } = require("node:child_process");
const { parseArgs } = require("node:util");
const { compileNative } = require("../native/emitter");
const repo = path.resolve(__dirname, "../..");
const sha = (data) => crypto.createHash("sha256").update(data).digest("hex");
function execute(command, args, records, options = {}) {
  records.push([command, ...args]);
  const r = spawnSync(command, args, {
    encoding: "utf8",
    timeout: options.timeout || 120000,
    maxBuffer: 16 * 1024 * 1024,
  });
  if (r.error || r.status !== 0)
    throw new Error(
      `${command} failed (${r.status}): ${r.error ? r.error.message : r.stderr || r.stdout}`,
    );
  return r.stdout;
}
function compilerInputs() {
  const base = path.join(repo, "strata");
  const names = ["src/frontend.js", "vendor/acorn.js"];
  for (const dir of ["src/core", "native", "tools"]) {
    for (const name of fs
      .readdirSync(path.join(base, dir))
      .filter((n) => n.endsWith(".js"))
      .sort())
      names.push(dir + "/" + name);
  }
  return Object.fromEntries(
    names.map((n) => [n, sha(fs.readFileSync(path.join(base, n)))]),
  );
}
function build(input, options = {}) {
  const buildDir = path.resolve(
    options.buildDir || path.join(repo, "hermes/build-llvm"),
  );
  const llvmBin = path.resolve(options.llvmBin || "/usr/lib/llvm-18/bin");
  const optimization = String(options.optimization || "0");
  if (!["0", "1", "2", "3"].includes(optimization))
    throw new Error("Optimization must be 0, 1, 2 or 3");
  const output = path.resolve(
    options.output ||
      path.join(
        repo,
        "strata/out",
        path.basename(input).replace(/\.[^.]+$/, ""),
      ),
  );
  if (
    [
      output,
      output + ".ll",
      output + ".bc",
      output + ".ir",
      output + ".build.json",
    ].includes(path.resolve(input))
  )
    throw new Error("Output must not overwrite the input source");
  fs.mkdirSync(path.dirname(output), { recursive: true });
  const source = fs.readFileSync(input, "utf8");
  const compiled = compileNative(source, {
    filename: input,
    roots: options.roots || "reuse",
    unitName: options.unitName || "strata",
  });
  const records = [];
  const work = fs.mkdtempSync(path.join(path.dirname(output), ".strata-"));
  const ll = path.join(work, "module.ll"),
    bc = path.join(work, "module.bc"),
    exe = path.join(work, "program");
  const tool = (n) => path.join(llvmBin, n);
  try {
    fs.writeFileSync(ll, compiled.llvm);
    execute(tool("llvm-as"), [ll, "-o", bc], records);
    execute(tool("opt"), ["-passes=verify", "-disable-output", bc], records);
    const runtime = path.join(buildDir, "lib/libshllvm_runtime.a");
    const cache = fs.readFileSync(
      path.join(buildDir, "CMakeCache.txt"),
      "utf8",
    );
    const sanitizers = [];
    if (/^HERMES_ENABLE_ADDRESS_SANITIZER:BOOL=ON$/m.test(cache))
      sanitizers.push("-fsanitize=address");
    if (/^HERMES_ENABLE_UNDEFINED_BEHAVIOR_SANITIZER:BOOL=ON$/m.test(cache))
      sanitizers.push("-fsanitize=undefined");
    if (options.action !== "emit") {
      const dirs = ["lib", "tools/shermes", "jsi"].map((d) =>
        path.join(buildDir, d),
      );
      execute(
        tool("clang"),
        [
          bc,
          `-O${optimization}`,
          "-Wno-override-module",
          ...sanitizers,
          ...dirs.flatMap((d) => [`-L${d}`, `-Wl,-rpath,${d}`]),
          runtime,
          "-lshermes_console",
          "-lhermesvm",
          "-lm",
          "-o",
          exe,
        ],
        records,
      );
    }
    const manifest = {
      ...compiled.metadata,
      compilerInputs: compilerInputs(),
      cmakeCacheSHA256: sha(cache),
      runtimeLibraries: Object.fromEntries(
        [
          "lib/libshllvm_runtime.a",
          "lib/libhermesvm.so",
          "tools/shermes/libshermes_console.so",
        ].map((n) => [n, sha(fs.readFileSync(path.join(buildDir, n)))]),
      ),
      executableSHA256:
        options.action === "emit" ? null : sha(fs.readFileSync(exe)),
      input: path.resolve(input),
      sourceSHA256: sha(source),
      llvmSHA256: sha(compiled.llvm),
      runtimeSHA256: sha(fs.readFileSync(runtime)),
      buildDir,
      llvmBin,
      optimization,
      sanitizers,
      llvmVersion: execute(tool("llvm-as"), ["--version"], records).trim(),
      commands: records,
    };
    fs.renameSync(ll, output + ".ll");
    fs.renameSync(bc, output + ".bc");
    fs.writeFileSync(output + ".ir", compiled.ir);
    if (options.action !== "emit") fs.renameSync(exe, output);
    fs.writeFileSync(
      output + ".build.json",
      JSON.stringify(manifest, null, 2) + "\n",
    );
    return { output, manifest };
  } finally {
    fs.rmSync(work, { recursive: true, force: true });
  }
}
if (require.main === module) {
  try {
    const { values, positionals } = parseArgs({
      allowPositionals: true,
      options: {
        output: { type: "string", short: "o" },
        "build-dir": { type: "string" },
        "llvm-bin": { type: "string" },
        optimization: { type: "string", short: "O" },
        roots: { type: "string" },
        "runtime-arg": { type: "string", multiple: true },
        help: { type: "boolean" },
      },
    });
    if (values.help) {
      console.log(
        "strata-native.js emit|build|run input.js [-o path] [-O 0|2] [--roots reuse|distinct] [--build-dir path] [--llvm-bin path]",
      );
      process.exit(0);
    }
    const [action, input] = positionals;
    if (
      !["emit", "build", "run"].includes(action) ||
      !input ||
      positionals.length !== 2
    )
      throw new Error("Expected emit|build|run and one input file; use --help");
    const r = build(input, {
      action,
      output: values.output,
      optimization: values.optimization,
      roots: values.roots,
      buildDir: values["build-dir"],
      llvmBin: values["llvm-bin"],
    });
    if (action === "run") {
      const run = spawnSync(r.output, values["runtime-arg"] || [], {
        stdio: "inherit",
        timeout: 30000,
      });
      if (run.error) throw run.error;
      process.exitCode = run.status === null ? 1 : run.status;
    } else console.log(action === "emit" ? r.output + ".ll" : r.output);
  } catch (e) {
    console.error(
      "strata: " + (e.loc ? `${e.loc.line}:${e.loc.col}: ` : "") + e.message,
    );
    process.exitCode = 1;
  }
}
module.exports = { build };
