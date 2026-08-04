# oxlint smoke test.
#
# DIALECT: Bazel `.bzl` Starlark — no top-level `if`/`for` STATEMENTS. Every
# branch below is either an if-EXPRESSION or a dict index, both of which are
# expressions and legal at module scope.
#
# WHY THE BINARY NAME IS A TABLE: upstream ships each archive with a single
# member named after its own TARGET TRIPLE (`oxlint-x86_64-unknown-linux-musl`,
# `oxlint-aarch64-apple-darwin`, `oxlint-x86_64-pc-windows-msvc.exe`), and no
# part of the pipeline renames an archive member. So the on-PATH command name
# is platform-dependent and this table has to mirror `metadata*.json` exactly.
# `ocx.target_platform` exposes `.os` and `.arch` only — never the `+libc.*`
# feature — which is precisely why the spec declares ONE Linux key per arch
# (the static musl build) rather than a gnu/musl pair it could not tell apart.
TOOL = {
    "linux/amd64": "oxlint-x86_64-unknown-linux-musl",
    "linux/arm64": "oxlint-aarch64-unknown-linux-musl",
    "darwin/amd64": "oxlint-x86_64-apple-darwin",
    "darwin/arm64": "oxlint-aarch64-apple-darwin",
    "windows/amd64": "oxlint-x86_64-pc-windows-msvc.exe",
    "windows/arm64": "oxlint-aarch64-pc-windows-msvc.exe",
}[str(ocx.target_platform.os) + "/" + str(ocx.target_platform.arch)]

# ─── Tier 1 + 2: liveness and version SHAPE ────────────────────────────────
# Never the exact version and never the surrounding prose — upstream prints
# "Version: 1.77.0" today and the label is not part of the contract.
r_version = ocx.run(TOOL, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ─── Tier 3: a real lint, asserted by RESULT COUNT ─────────────────────────
# oxlint is a linter: its default severity is `warning`, so a run that finds
# violations still EXITS 0. `expect.ok` alone would therefore pass against a
# binary that linted nothing at all — and oxlint's own failure mode for that is
# a *successful-looking* "No files found to lint" with `number_of_files: 0`.
# Both are covered: the counts below are the assertion, and `number_of_files`
# is the guard that a file was actually read.
#
# `-f json` is the machine format: colourless, byte-stable, and it names the
# rule ids the tool itself computed.
ocx.write_file("bad.js", "const o = { a: 1, a: 2 };\ndebugger;\nexport default o;\n")
ocx.write_file("good.js", "const o = { a: 1, b: 2 };\nexport default o;\n")

r_bad = ocx.run(TOOL, "-f", "json", "bad.js")
expect.ok(r_bad)
expect.contains(r_bad.stdout, "\"number_of_files\": 1")
expect.eq(r_bad.stdout.count("\"severity\": \"warning\""), 2)
expect.eq(r_bad.stdout.count("\"code\": \"eslint(no-dupe-keys)\""), 1)
expect.eq(r_bad.stdout.count("\"code\": \"eslint(no-debugger)\""), 1)

# Negative control. A tool that merely echoes, or one whose rule engine never
# ran, would pass the block above by accident; a clean file must produce ZERO
# diagnostics while STILL reporting that it read one file.
r_good = ocx.run(TOOL, "-f", "json", "good.js")
expect.ok(r_good)
expect.contains(r_good.stdout, "\"number_of_files\": 1")
expect.eq(r_good.stdout.count("\"severity\""), 0)

# ─── Tier 3b: exit-code polarity through the deny mechanism ────────────────
# `-D correctness` promotes those same two findings from warning to error, so
# the identical input that exited 0 above must now exit non-zero — and the
# clean file must still exit 0. This pins the severity plumbing, which is the
# part a CI consumer actually depends on.
r_deny_bad = ocx.run(TOOL, "-D", "correctness", "bad.js")
expect.eq(r_deny_bad.exit_code, 1)

r_deny_good = ocx.run(TOOL, "-D", "correctness", "good.js")
expect.eq(r_deny_good.exit_code, 0)
