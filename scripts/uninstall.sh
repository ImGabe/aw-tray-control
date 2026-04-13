#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_SCRIPT="${SCRIPT_DIR}/install-desktop-entry.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/uninstall.sh [--binary-root /abs/path] [--keep-desktop] [--dry-run]
  scripts/uninstall.sh --desktop-only

Options:
  --binary-root PATH  Optional root passed to cargo uninstall --root
  --keep-desktop      Remove binary only, keep desktop and autostart entries
  --desktop-only      Remove desktop and autostart entries only
  --dry-run           Print actions without executing
  -h, --help          Show this help message
EOF
}

remove_desktop_entries() {
  local dry_run="$1"

  if [[ ! -x "${INSTALLER_SCRIPT}" ]]; then
    echo "Installer script not executable: ${INSTALLER_SCRIPT}" >&2
    exit 1
  fi

  if [[ "${dry_run}" == "true" ]]; then
    "${INSTALLER_SCRIPT}" --remove --dry-run
    "${INSTALLER_SCRIPT}" --remove-autostart --dry-run
  else
    "${INSTALLER_SCRIPT}" --remove
    "${INSTALLER_SCRIPT}" --remove-autostart
  fi
}

remove_binary() {
  local binary_root="$1"
  local dry_run="$2"

  local cmd=(cargo uninstall aw-tray-control)
  if [[ -n "${binary_root}" ]]; then
    cmd+=(--root "${binary_root}")
  fi

  if [[ "${dry_run}" == "true" ]]; then
    echo "[dry-run] ${cmd[*]}"
    return
  fi

  if "${cmd[@]}"; then
    echo "Removed cargo-installed binary: aw-tray-control"
  else
    echo "Binary uninstall reported an issue. It may already be removed." >&2
  fi
}

main() {
  local binary_root=""
  local keep_desktop="false"
  local desktop_only="false"
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
      --keep-desktop)
        keep_desktop="true"
        shift
        ;;
      --desktop-only)
        desktop_only="true"
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
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
  done

  if [[ "${desktop_only}" == "true" && "${keep_desktop}" == "true" ]]; then
    echo "--desktop-only cannot be combined with --keep-desktop" >&2
    exit 1
  fi

  if [[ "${desktop_only}" == "true" ]]; then
    remove_desktop_entries "${dry_run}"
    exit 0
  fi

  remove_binary "${binary_root}" "${dry_run}"

  if [[ "${keep_desktop}" != "true" ]]; then
    remove_desktop_entries "${dry_run}"
  fi
}

main "$@"
