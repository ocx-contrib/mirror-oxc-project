---
title: oxfmt
description: >
  Oxfmt — the JavaScript/TypeScript formatter from the Oxc toolchain, written
  in Rust. A Prettier-compatible formatter that rewrites a whole repository in
  a fraction of the time, with no Node.js runtime required.
keywords:
  - formatter
  - javascript
  - typescript
  - jsx
  - prettier
  - oxc
  - rust
  - code-style
---

# oxfmt

`oxfmt` is the formatter of the [Oxc](https://oxc.rs) toolchain — a JavaScript
and TypeScript code formatter written in Rust, aiming at Prettier-compatible
output. It ships as a single self-contained executable with no Node.js, npm or
plugin install step, formats JS, JSX, TS and TSX, and honours `.gitignore` and
`.prettierignore` by default.

## ⚠ The command is named after its target triple

**Upstream ships each release archive containing a single executable named after
its own Rust target triple, not `oxfmt`.** This package publishes upstream's
bytes under upstream's own name, so the command this package puts on `PATH` is:

| Platform | Command |
|---|---|
| `linux/amd64` | `oxfmt-x86_64-unknown-linux-musl` |
| `linux/arm64` | `oxfmt-aarch64-unknown-linux-musl` |
| `darwin/amd64` | `oxfmt-x86_64-apple-darwin` |
| `darwin/arm64` | `oxfmt-aarch64-apple-darwin` |
| `windows/amd64` | `oxfmt-x86_64-pc-windows-msvc.exe` |
| `windows/arm64` | `oxfmt-aarch64-pc-windows-msvc.exe` |

Alias it if you want the short name — `alias oxfmt=oxfmt-$(uname -m)-…` — or
invoke it through `ocx run`.

## ⚠ Versions are oxfmt's own, not the oxc release train's

oxfmt is released from the `oxc` monorepo, whose release tags (`apps_v1.80.0`)
carry **oxlint's** version. oxfmt numbers itself separately and reports that
number: the binary inside `apps_v1.80.0` prints `Version: 0.65.0`. This package
is versioned the way the tool versions itself, so `0.65.0` here is the
`## Oxfmt v0.65.0` section of upstream's `apps_v1.80.0` release notes.

## What's included

One executable, named per the table above. No plugins, config files or shared
libraries: everything the formatter needs is inside the binary.

## Usage

```bash
# Format a directory in place (--write is the default).
oxfmt-x86_64-unknown-linux-musl src/

# CI mode: report unformatted files and exit non-zero.
oxfmt-x86_64-unknown-linux-musl --check src/

# Just list what would change.
oxfmt-x86_64-unknown-linux-musl --list-different src/

# Exclude patterns are quoted so the shell does not expand them first.
oxfmt-x86_64-unknown-linux-musl 'src/**/*.ts' '!**/fixtures/*'
```

Configuration is an `.oxfmtrc.json` picked up automatically or passed with `-c`;
with no config file, oxfmt formats with its defaults and says so. Nested
configuration in subdirectories is searched by default and can be turned off
with `--disable-nested-config`.

## Platform notes

Linux is served by upstream's **statically linked** musl build, which requires
nothing of the host userland and therefore runs on glibc and musl systems
alike — verified in CI on `ubuntu:24.04`, `alpine:3.20` and `fedora:40`. The
separate `-gnu` builds upstream also publishes are deliberately not mirrored:
oxfmt touches only the local filesystem, so neither of the usual reasons to
split the key (musl's DNS resolver, musl's allocator) applies.

Upstream additionally ships armv7, i686, ppc64le, riscv64, s390x and FreeBSD
artifacts. OCX's platform grammar has no way to express those, so they are out
of scope rather than missing.

## Upstream

- Source: <https://github.com/oxc-project/oxc> (the `apps_v*` release train)
- Website: <https://oxc.rs>
- License: MIT
