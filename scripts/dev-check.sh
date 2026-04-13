#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/dev-check.sh [--fast] [--dry-run]

Options:
  --fast      Run a shorter set (fmt + clippy + test)
  --dry-run   Print commands without executing
  -h, --help  Show this help message
EOF
}

main() {
  local fast="false"
  local dry_run="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --fast)
        fast="true"
        shift
        ;;
      --dry-run)
        dry_run="true"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done

  run_or_echo "${dry_run}" cargo fmt --all -- --check
  run_or_echo "${dry_run}" cargo clippy --workspace --all-targets --all-features -- -D warnings
  run_or_echo "${dry_run}" cargo test --workspace --all-targets --all-features

  if [[ "${fast}" != "true" ]]; then
    run_or_echo "${dry_run}" cargo check --workspace --all-targets --all-features
  fi
}

main "$@"
