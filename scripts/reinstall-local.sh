#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"
INSTALL_BINARY_SCRIPT="${SCRIPT_DIR}/install-binary.sh"
INSTALL_DESKTOP_SCRIPT="${SCRIPT_DIR}/install-desktop-entry.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/reinstall-local.sh [--binary-root /abs/path] [--autostart] [--force] [--exec-path /abs/path/to/aw-tray-control] [--dry-run]

Options:
  --binary-root PATH  Passed to install-binary.sh --binary-root
  --autostart         Also install autostart desktop entry
  --force             Overwrite existing desktop/autostart entries
  --exec-path PATH    Explicit binary path for desktop entry Exec/TryExec
  --dry-run           Print actions without executing
  -h, --help          Show this help message

Notes:
  - If --exec-path is not provided and --binary-root is set, this script
    will use <binary-root>/bin/aw-tray-control.
  - Otherwise, install-desktop-entry.sh resolves the executable from PATH.
EOF
}

main() {
  local binary_root=""
  local autostart="false"
  local force="false"
  local dry_run="false"
  local exec_path=""

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
      --autostart)
        autostart="true"
        shift
        ;;
      --force)
        force="true"
        shift
        ;;
      --exec-path)
        if [[ $# -lt 2 ]]; then
          echo "Missing value for --exec-path" >&2
          exit 1
        fi
        exec_path="$2"
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

  require_executable "${INSTALL_BINARY_SCRIPT}"
  require_executable "${INSTALL_DESKTOP_SCRIPT}"

  local install_binary_cmd=("${INSTALL_BINARY_SCRIPT}")
  if [[ -n "${binary_root}" ]]; then
    install_binary_cmd+=(--binary-root "${binary_root}")
  fi

  if [[ -z "${exec_path}" && -n "${binary_root}" ]]; then
    exec_path="${binary_root}/bin/aw-tray-control"
  fi

  local install_desktop_cmd=("${INSTALL_DESKTOP_SCRIPT}")
  if [[ "${autostart}" == "true" ]]; then
    install_desktop_cmd+=(--autostart)
  fi
  if [[ "${force}" == "true" ]]; then
    install_desktop_cmd+=(--force)
  fi
  if [[ -n "${exec_path}" ]]; then
    install_desktop_cmd+=(--exec-path "${exec_path}")
  fi

  if [[ "${dry_run}" == "true" ]]; then
    run_or_echo "true" "${install_binary_cmd[@]}" --dry-run
    run_or_echo "true" "${install_desktop_cmd[@]}" --dry-run
    exit 0
  fi

  "${install_binary_cmd[@]}"
  "${install_desktop_cmd[@]}"
}

main "$@"
