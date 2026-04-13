# Releasing

This document describes how to publish a new version of aw-tray-control.

## Versioning policy

- Use Semantic Versioning tags: `vMAJOR.MINOR.PATCH`
- Keep `Cargo.toml` version, changelog version, and tag aligned

## Release checklist

1. Ensure local checks pass:

```bash
cargo fmt --all
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-targets --all-features
shellcheck -x scripts/*.sh
cargo audit
cargo deny check advisories bans sources
```

2. Update `CHANGELOG.md` for the release version.
3. Bump `[package].version` in `Cargo.toml` if needed.
4. Commit and push to `main`.
5. Create and push a release tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

## What the release workflow publishes

When a `v*.*.*` tag is pushed, `.github/workflows/release.yml` will:

1. Build `aw-tray-control` in release mode.
2. Create `aw-tray-control-<version>-x86_64-unknown-linux-gnu.tar.gz`.
3. Generate a `.sha256` checksum file.
4. Create/update the GitHub Release and upload both files.

## Manual re-run

- Open Actions and run the `Release` workflow manually.
- Re-running will overwrite existing release assets using `--clobber`.
