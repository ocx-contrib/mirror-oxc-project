# /// script
# requires-python = ">=3.13"
# dependencies = ["ocx-mirror-sdk~=0.6.0"]
# ///
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 The OCX Authors
"""Generate url_index JSON for oxfmt, released from the oxc monorepo.

WHY THIS IS NOT A `github_release` SOURCE
-----------------------------------------
oxfmt ships inside the SAME `apps_vX.Y.Z` releases as oxlint — 32 assets per
release, 16 of each tool — but the two do NOT share a version number. The tag
carries oxlint's:

    $ tar xf oxfmt-x86_64-unknown-linux-musl.tar.gz   # from tag apps_v1.80.0
    $ ./oxfmt-x86_64-unknown-linux-musl --version
    Version: 0.65.0                                   # <-- NOT 1.80.0

A `github_release` source derives the package version from the tag, so it would
publish upstream's 0.65.0 bytes as `oxc-project/oxfmt:1.80.0` — a version this
tool never reports about itself and no upstream document names. That is a false
claim, not a cosmetic mismatch, so the version is taken from upstream's own
release notes instead: every apps_v release body carries a `## Oxfmt vX.Y.Z`
heading, and that string is the version the binary prints.

Cross-checked against the tag graph rather than trusted: upstream also pushes a
per-app `oxfmt_vX.Y.Z` tag on the very same commit as the apps_v tag it rides
(`oxfmt_v0.65.0` and `apps_v1.80.0` are both 97e99b85), and those tags carry no
release assets of their own — which is why they cannot serve as the source.

    $ gh api repos/oxc-project/oxc/git/matching-refs/tags/oxfmt_v0.65.0 --jq '.[].object.sha'
    97e99b85…
    $ gh api repos/oxc-project/oxc/git/matching-refs/tags/apps_v1.80.0    --jq '.[].object.sha'
    97e99b85…

Consequence worth knowing: `url_index` asset maps carry no digests, so this
mirror cannot set `verify.github_asset_digest` the way its oxlint sibling does.
The URLs are upstream's own `github.com/…/releases/download/…` links.

WHAT IS EMITTED
---------------
Only the six declarable-platform archives, and only for releases that carry all
six. Emitting the exact filenames (rather than every oxfmt asset) is what makes
`mirror.yml`'s per-platform patterns match exactly one asset each: a pattern
matching ZERO assets is silently skipped, and a silently missing platform is a
green run that shipped a hole.

Two known upstream shapes are skipped by that rule, both deliberately:

  * `apps_v1.47.0`, `apps_v1.52.0`, `apps_v1.53.0` ship oxlint assets and NO
    oxfmt assets at all.
  * `apps_v1.43.0` and older name oxfmt archives by OS/arch
    (`oxfmt-linux-x64-musl.tar.gz`), not by Rust target triple. They are below
    `versions.min` and stay out of the index entirely.

A release that ships the six archives but whose body has no `## Oxfmt vX.Y.Z`
heading is a HARD FAILURE, not a skip: the version would have to be guessed,
and a silently dropped release is exactly the failure mode this generator
exists to avoid.
"""

from __future__ import annotations

import re
import sys

from ocx_mirror_sdk import IndexBuilder, github

REPO = "oxc-project/oxc"

# The oxc monorepo publishes three interleaved tag trains. `apps_v*` is the only
# one carrying binaries: `crates_v*` marks a Rust crate publish (zero assets),
# and the per-app `oxlint_v*` / `oxfmt_v*` tags carry no release assets either.
APPS_TAG = re.compile(r"^apps_v\d+\.\d+\.\d+$")

# Upstream's release body is a concatenation of per-app changelogs, each under
# its own `## <App> vX.Y.Z` heading. Anchored to a line start so a version
# mentioned in a bullet cannot match. `search` takes the FIRST — apps_v1.46.0 is
# a catch-up release carrying two oxfmt headings (0.31.0 then 0.29.0) and the
# newest is the one that shipped; it is below `versions.min` regardless.
OXFMT_HEADING = re.compile(r"^##\s+Oxfmt\s+v(\d+\.\d+\.\d+)\s*$", re.MULTILINE)

# The exact archives the six declarable platforms resolve to, in mirror.yml's
# order. Upstream ships 16 oxfmt artifacts per release; armv7 (gnueabihf and
# musleabihf), i686, powerpc64le, riscv64gc (gnu and musl), s390x and FreeBSD
# have no expression in ocx's platform grammar and are out of scope, not
# missing. Linux is the STATIC musl build — see the libc gate in mirror.yml.
REQUIRED = (
    "oxfmt-x86_64-unknown-linux-musl.tar.gz",
    "oxfmt-aarch64-unknown-linux-musl.tar.gz",
    "oxfmt-x86_64-apple-darwin.tar.gz",
    "oxfmt-aarch64-apple-darwin.tar.gz",
    "oxfmt-x86_64-pc-windows-msvc.zip",
    "oxfmt-aarch64-pc-windows-msvc.zip",
)


def log(message: str) -> None:
    sys.stderr.write(f"generate: {message}\n")


def main() -> int:
    releases = github.list_releases(REPO, include_prereleases=False, include_drafts=False)

    index = IndexBuilder()
    emitted = 0
    skipped = 0

    for release in releases:
        if not APPS_TAG.match(release.tag_name):
            continue

        assets = {
            asset.name: asset.browser_download_url
            for asset in release.assets
            if asset.name in REQUIRED
        }
        if not assets:
            skipped += 1
            continue
        if len(assets) != len(REQUIRED):
            missing = sorted(set(REQUIRED) - assets.keys())
            log(f"{release.tag_name}: skipped — missing {missing}")
            skipped += 1
            continue

        heading = OXFMT_HEADING.search(release.body or "")
        if heading is None:
            log(
                f"{release.tag_name} ships the oxfmt archives but its body carries no "
                "'## Oxfmt vX.Y.Z' heading — the oxfmt version cannot be derived from "
                "the tag, which is oxlint's. Refusing to guess."
            )
            return 1

        version = heading.group(1)
        index.add_version(version, assets=assets, prerelease=False)
        log(f"  {version} <- {release.tag_name} ({len(assets)} assets)")
        emitted += 1

    if emitted == 0:
        log("no versions generated — upstream asset naming or the body heading changed")
        return 1

    index.emit()
    log(f"done — {emitted} versions, {skipped} releases without the six archives")
    return 0


if __name__ == "__main__":
    sys.exit(main())
