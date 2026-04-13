#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  scripts/install-binary.sh [--binary-root /abs/path] [--dry-run]

Options:
  --binary-root PATH  Optional root passed to cargo install --root
  --dry-run           Print actions without executing
  -h, --help          Show this help message
EOF
}

main() {
  local binary_root=""
  local dry_run="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --binary-root)
        if [[ $# -lt 2 ]]; then
          echo "Missing value for --binary-root" >&2
          exit 1
        fi
        binary_root="$2"
        shift 2
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
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
  done

  local cmd=(cargo install --path "${REPO_ROOT}" --locked --force)
  if [[ -n "${binary_root}" ]]; then
    cmd+=(--root "${binary_root}")
  fi

  if [[ "${dry_run}" == "true" ]]; then
    echo "[dry-run] ${cmd[*]}"
    exit 0
  fi

  "${cmd[@]}"
}

main "$@"
