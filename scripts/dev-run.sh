#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/dev-run.sh [--release] [--log-level LEVEL] [--dry-run] [-- ARGS...]

Options:
  --release          Run with release profile
  --log-level LEVEL  Set RUST_LOG (default: info)
  --dry-run          Print the command without executing
  -h, --help         Show this help message

Examples:
  scripts/dev-run.sh
  scripts/dev-run.sh --release
  scripts/dev-run.sh --log-level debug -- --help
EOF
}

main() {
  local profile="debug"
  local dry_run="false"
  local log_level="${RUST_LOG:-info}"
  local app_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --release)
        profile="release"
        shift
        ;;
      --log-level)
        if [[ $# -lt 2 ]]; then
          log_error "Missing value for --log-level"
          exit 1
        fi
        log_level="$2"
        shift 2
        ;;
      --dry-run)
        dry_run="true"
        shift
        ;;
      --)
        shift
        app_args=("$@")
        break
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

  local cmd=(cargo run --bin aw-tray-control)
  if [[ "${profile}" == "release" ]]; then
    cmd+=(--release)
  fi

  if [[ ${#app_args[@]} -gt 0 ]]; then
    cmd+=(-- "${app_args[@]}")
  fi

  run_or_echo "${dry_run}" env "RUST_LOG=${log_level}" "${cmd[@]}"
}

main "$@"
