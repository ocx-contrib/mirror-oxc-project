# oxfmt smoke test.
#
# DIALECT: Bazel `.bzl` Starlark — no top-level `if`/`for` STATEMENTS. The
# branch below is a dict index, which is an expression and legal at module
# scope.
#
# WHY THE BINARY NAME IS A TABLE: upstream ships each archive with a single
# member named after its own TARGET TRIPLE (`oxfmt-x86_64-unknown-linux-musl`,
# `oxfmt-x86_64-pc-windows-msvc.exe`), and no part of the pipeline renames an
# archive member. So the on-PATH command name is platform-dependent and this
# table has to mirror `metadata*.json` exactly. `ocx.target_platform` exposes
# `.os` and `.arch` only — never the `+libc.*` feature — which is why the spec
# declares ONE Linux key per arch (the static musl build) rather than a
# gnu/musl pair it could not tell apart.
TOOL = {
    "linux/amd64": "oxfmt-x86_64-unknown-linux-musl",
    "linux/arm64": "oxfmt-aarch64-unknown-linux-musl",
    "darwin/amd64": "oxfmt-x86_64-apple-darwin",
    "darwin/arm64": "oxfmt-aarch64-apple-darwin",
    "windows/amd64": "oxfmt-x86_64-pc-windows-msvc.exe",
    "windows/arm64": "oxfmt-aarch64-pc-windows-msvc.exe",
}[str(ocx.target_platform.os) + "/" + str(ocx.target_platform.arch)]

# ─── Tier 1 + 2: liveness and version SHAPE ────────────────────────────────
# Never the exact version and never the surrounding prose — upstream prints
# "Version: 0.65.0" today and the label is not part of the contract. The shape
# is what matters here beyond liveness: this package's version comes from the
# release-note heading rather than from the tag (see mirror.yml), so a run whose
# binary printed something unversion-shaped would mean that derivation broke.
r_version = ocx.run(TOOL, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ─── Tier 3: the formatter contract, asserted by RESULT not by prose ───────
#
# oxfmt is a Prettier-compatible formatter, so its contract is: unformatted
# input is REPORTED, `--write` REWRITES it, and the rewritten bytes then pass.
# Exit codes alone would not prove it — `--write` exits 0 on zero matched files
# too, and "formatted nothing successfully" is the green-but-tested-nothing
# failure this fleet keeps hitting. The assertions below are the bytes on disk.
#
# Both files are written to scratch first: nothing outside scratch is readable
# or writable, and oxfmt takes explicit paths so no `.gitignore`/`.oxfmtrc.json`
# discovery in the scratch root can change what is formatted.
UGLY_JS = "const x={a:1,b:2};\nfunction   f( a,b ){return a+b}\n"
UGLY_TS = "interface P{a:string;b?:number}\nconst g=(p:P):string=>{return p.a}\n"

ocx.write_file("ugly.js", UGLY_JS)
ocx.write_file("ugly.ts", UGLY_TS)

# `--check` on unformatted input exits 1 (measured on 0.60.0 and 0.65.0). This
# is the half that fails if the binary silently matched no files.
r_check_before = ocx.run(TOOL, "--check", "ugly.js", "ugly.ts")
expect.ne(r_check_before.exit_code, 0)

r_write = ocx.run(TOOL, "--write", "ugly.js", "ugly.ts")
expect.ok(r_write)

# The formatted forms below are Prettier canon for these snippets and are
# byte-identical across the whole mirrored range (0.60.0 … 0.65.0). Substrings,
# not whole-file equality: the file's line endings are not part of the contract
# this mirror ships, but the formatting decisions are.
formatted_js = ocx.read_file("ugly.js")
expect.ne(formatted_js, UGLY_JS)
expect.contains(formatted_js, "const x = { a: 1, b: 2 };")
expect.contains(formatted_js, "  return a + b;")

# The TypeScript leg is not redundant: oxfmt parses TS itself (no tsc, no
# plugin), so a build that lost TS support would still pass the JS half.
formatted_ts = ocx.read_file("ugly.ts")
expect.ne(formatted_ts, UGLY_TS)
expect.contains(formatted_ts, "  b?: number;")
expect.contains(formatted_ts, "const g = (p: P): string => {")

# Idempotence + the other exit-code half: the same files now pass `--check`.
r_check_after = ocx.run(TOOL, "--check", "ugly.js", "ugly.ts")
expect.ok(r_check_after)
