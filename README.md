# mirror-oxc-project

OCX mirrors for [Oxc](https://oxc.rs) tooling. Each package republishes upstream
GitHub release binaries to the OCX registry; nothing here is built from source.

| Package | Coordinate | GHCR | Upstream |
|---|---|---|---|
| `oxlint` | [`ocx.sh/oxc-project/oxlint`](https://index.ocx.sh/oxc-project/oxlint) | `ghcr.io/ocx-contrib/oxc-project/oxlint` | [oxc-project/oxc](https://github.com/oxc-project/oxc) (`apps_v*` tags) |

```bash
ocx add ocx.sh/oxc-project/oxlint
```

## ⚠ The command is named after its target triple

Upstream's release archives each hold a single executable named after its own
Rust target triple — `oxlint-x86_64-unknown-linux-musl`, not `oxlint`. Nothing
in the mirror pipeline renames an archive member (`asset_type: binary` has a
`name:` field; `asset_type: archive` has none), so this package puts upstream's
own name on `PATH`. `oxlint/CATALOG.md` has the per-platform table.

## Layout

```
mirror-oxc-project/
├── ocx.toml / ocx.lock     # pinned toolchain (floating minor :0.5)
├── logo.svg / logo.png     # shared describe assets, named by every spec
├── LICENSE / NOTICE.md     # Apache-2.0 here; upstream SPDX recorded per package
├── oxlint/
│   ├── mirror.yml          # the spec
│   ├── metadata.json       # + metadata-<platform>.json — the binary name
│   │                       #   differs per platform, so every declared
│   │                       #   platform gets its own file
│   ├── CATALOG.md          # → `ocx package describe`
│   └── tests/smoke.star
└── .github/workflows/      # ALL GENERATED — never hand-edit
```

## Editing

Change the **spec**, never the generated workflow YAML — `verify-generated.yml`
fails CI (exit 65) on any hand-edit. After touching a spec, a metadata file or
the smoke test:

```bash
direnv allow                                    # once, to activate the toolchain
ocx-mirror package validate oxlint/mirror.yml
ocx-mirror package pipeline generate ci --spec oxlint/mirror.yml
ocx-mirror package pipeline generate ci --check --spec oxlint/mirror.yml
```

`--spec` **appends** rather than replaces, so every command above must name
**every** spec in this repo. Today that is one; adding `oxfmt/` (the sibling
tool shipped in the same `apps_v*` release) means adding `--spec
oxfmt/mirror.yml` to each line.

Commit straight to `main` — mirror repos take no PRs. A push to a spec path
triggers that package's mirror workflow.

## Toolchain

`ocx.toml` pins the **floating minor** (`ocx.sh/ocx/cli:0.5`,
`ocx.sh/ocx/mirror:0.5`); concrete digests live in `ocx.lock`. `ocx update`
re-resolves them. Never pin `:0` (breaking changes land in the minor on a 0.x
project) and never a build-timestamped tag.
