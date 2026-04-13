# Development recipes for aw-tray-control
# Usage: just <command>

set shell := ["bash", "-c"]

# Run all code quality checks (fmt, clippy, test, shellcheck)
check:
  cargo fmt --all -- --check
  cargo clippy --workspace --all-targets --all-features -- -D warnings
  shellcheck scripts/*.sh
  cargo test --all-targets --all-features

# Install repo-local git hooks
hooks:
  chmod +x .githooks/pre-commit .githooks/pre-push
  git config core.hooksPath .githooks

# Format code
fmt:
  cargo fmt --all

# Lint with clippy
lint:
  cargo clippy --workspace --all-targets --all-features -- -D warnings

# Run tests
test:
  cargo test --all-targets --all-features

# Lint shell scripts
shellcheck:
  shellcheck scripts/*.sh

# Run app with debug logging
run:
  RUST_LOG=debug cargo run --

# Install binary and desktop entry (requires password for sudo)
install:
  ./scripts/reinstall-local.sh --force

# Run type check
check-build:
  cargo check --workspace --all-targets --all-features

# Build release binary
build-release:
  cargo build --release

# Clean all build artifacts
clean:
  cargo clean
  rm -rf target/

# Show documentation without downloading dependencies
doc:
  RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps

# Run security audit
audit:
  cargo audit

# Check dependencies for known vulnerabilities and misuse
deny:
  cargo deny check advisories bans sources

# List all available recipes
@help:
  just --list
