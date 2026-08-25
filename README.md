# mirror-oxc-project

OCX mirrors for [Oxc](https://oxc.rs) tooling. Each package republishes upstream
GitHub release binaries to the OCX registry; nothing here is built from source.

| Package | Coordinate | GHCR | Upstream |
|---|---|---|---|
| `oxlint` | [`ocx.sh/oxc-project/oxlint`](https://index.ocx.sh/oxc-project/oxlint) | `ghcr.io/ocx-contrib/oxc-project/oxlint` | [oxc-project/oxc](https://github.com/oxc-project/oxc) (`apps_v*` tags) |
| `oxfmt` | [`ocx.sh/oxc-project/oxfmt`](https://index.ocx.sh/oxc-project/oxfmt) | `ghcr.io/ocx-contrib/oxc-project/oxfmt` | [oxc-project/oxc](https://github.com/oxc-project/oxc) (`apps_v*` tags) |

```bash
ocx add ocx.sh/oxc-project/oxlint
ocx add ocx.sh/oxc-project/oxfmt
```

## ⚠ The two packages do NOT share a version

Both tools ship in the same `apps_vX.Y.Z` release, but that tag carries
**oxlint's** version: the oxfmt binary inside `apps_v1.80.0` reports
`Version: 0.65.0`. Each package is therefore versioned the way its own tool
versions itself. That is also why the two specs use different source types —
`oxlint` reads the tag (`github_release`), while `oxfmt` is a `url_index` whose
`scripts/generate.py` takes the version from upstream's `## Oxfmt vX.Y.Z`
release-note heading. The trade-off is recorded in `oxfmt/mirror.yml`:
a url_index carries no asset digests, so `verify.github_asset_digest` is
oxlint-only.

## ⚠ The command is named after its target triple

Upstream's release archives each hold a single executable named after its own
Rust target triple — `oxlint-x86_64-unknown-linux-musl`, not `oxlint`; likewise
`oxfmt-x86_64-unknown-linux-musl`, not `oxfmt`. Nothing
in the mirror pipeline renames an archive member (`asset_type: binary` has a
`name:` field; `asset_type: archive` has none), so this package puts upstream's
own name on `PATH`. Each package's `CATALOG.md` has the per-platform table.

## Layout

```
mirror-oxc-project/
├── ocx.toml / ocx.lock     # pinned toolchain (floating minor :0.5) + uv
├── logo.svg / logo.png     # shared describe assets, named by every spec
├── LICENSE / NOTICE.md     # Apache-2.0 here; upstream SPDX recorded per package
├── oxlint/
│   ├── mirror.yml          # the spec
│   ├── metadata.json       # + metadata-<platform>.json — the binary name
│   │                       #   differs per platform, so every declared
│   │                       #   platform gets its own file
│   ├── CATALOG.md          # → `ocx package describe`
│   └── tests/smoke.star
├── oxfmt/                  # same shape, plus:
│   └── scripts/generate.py # url_index generator (runs under `uv`)
└── .github/workflows/      # ALL GENERATED — never hand-edit
```

## Editing

Change the **spec**, never the generated workflow YAML — `verify-generated.yml`
fails CI (exit 65) on any hand-edit. After touching a spec, a metadata file or
the smoke test:

```bash
direnv allow                                    # once, to activate the toolchain
ocx-mirror package validate oxlint/mirror.yml
ocx-mirror package validate oxfmt/mirror.yml
ocx-mirror package pipeline generate ci --spec oxlint/mirror.yml --spec oxfmt/mirror.yml
ocx-mirror package pipeline generate ci --check --spec oxlint/mirror.yml --spec oxfmt/mirror.yml
```

`--spec` **appends** rather than replaces, so every generate command above must
name **every** spec in this repo — dropping one deletes its workflows.

Commit straight to `main` — mirror repos take no PRs. A push to a spec path
triggers that package's mirror workflow.

## Toolchain

`ocx.toml` pins the **floating minor** (`ocx.sh/ocx/cli:0.5`,
`ocx.sh/ocx/mirror:0.5`) plus `ocx.sh/astral-sh/uv:0`, the runtime that runs
oxfmt's generator; concrete digests live in `ocx.lock`. `ocx update`
re-resolves them. Never pin `:0` (breaking changes land in the minor on a 0.x
project) and never a build-timestamped tag.
