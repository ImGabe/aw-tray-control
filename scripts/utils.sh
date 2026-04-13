#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/utils.sh <command> [args...]

Commands:
  dev-check         Run local quality checks
  dev-run           Run aw-tray-control locally
  install-binary    Install binary from current repository
  install-desktop   Install/remove desktop entry
  reinstall-local   Reinstall binary + desktop entry
  uninstall         Remove installed binary and/or desktop entries
  help              Show this help message

Examples:
  scripts/utils.sh dev-check --fast
  scripts/utils.sh dev-run --log-level debug
  scripts/utils.sh reinstall-local --autostart --force
  scripts/utils.sh uninstall --desktop-only

Notes:
  - Arguments after <command> are forwarded to that command.
  - Legacy scripts remain available for direct use.
EOF
}

run_command() {
  local cmd="$1"
  shift

  local script_path="${SCRIPT_DIR}/${cmd}.sh"
  require_executable "${script_path}"

  "${script_path}" "$@"
}

main() {
  [[ $# -gt 0 ]] || {
    usage
    exit 1
  }

  local command="$1"
  shift

  case "${command}" in
    dev-check)
      run_command "dev-check" "$@"
      ;;
    dev-run)
      run_command "dev-run" "$@"
      ;;
    install-binary)
      run_command "install-binary" "$@"
      ;;
    install-desktop)
      run_command "install-desktop-entry" "$@"
      ;;
    reinstall-local)
      run_command "reinstall-local" "$@"
      ;;
    uninstall)
      run_command "uninstall" "$@"
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      usage
      die "Unknown command: ${command}"
      ;;
  esac
}

main "$@"
