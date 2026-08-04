# NOTICE

This repository packages and redistributes upstream software published by the
[Oxc](https://github.com/oxc-project/oxc) project. The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — the redistributed bytes carry their
own license, recorded below.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `oxlint` | `ghcr.io/ocx-contrib/oxc-project/oxlint` | `MIT` |

---

## `oxlint`

Upstream: <https://github.com/oxc-project/oxc>
Published to `ghcr.io/ocx-contrib/oxc-project/oxlint`.

| Component | SPDX | Holder |
|---|---|---|
| oxlint (`oxlint-<target-triple>`) | **MIT** | Copyright (c) 2023 Boshen and contributors |

Verified at the license gate:

```
$ gh api repos/oxc-project/oxc/license --jq '{spdx: .license.spdx_id, name: .license.name}'
{"name":"MIT License","spdx":"MIT"}
```

MIT is permissive and grants redistribution of the compiled binary provided the
copyright notice and the permission notice are retained. The canonical text is
<https://github.com/oxc-project/oxc/blob/main/LICENSE>.

Note on scope: `MIT` is the license of the whole `oxc` monorepo, which is where
oxlint is developed and released; oxlint has no repository and no license file
of its own. Upstream's release archives contain the executable alone, with no
`LICENSE` file beside it, so the notice-retention condition is satisfied by this
file and by the `org.opencontainers.image.licenses: MIT` annotation the pipeline
writes onto every published manifest rather than by a file inside the bundle.

The published binaries statically link third-party Rust crates under permissive
licenses, enumerated in upstream's `Cargo.lock` and `THIRD-PARTY-LICENSE`.

## Logo

`logo.svg` is the **official Oxc icon**, redistributed unaltered from
<https://github.com/oxc-project/oxc-assets> (`black-bg-circle.svg`);
`logo.png` is a 512px render of that same file. It is used here for catalog
identification only, unaltered and uncombined. No endorsement or affiliation is
implied — this is an unaffiliated mirror.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
