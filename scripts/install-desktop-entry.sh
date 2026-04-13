#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DESKTOP_FILE="${REPO_ROOT}/desktop/aw-tray-control.desktop"
# shellcheck source=scripts/lib.sh
source "${SCRIPT_DIR}/lib.sh"

XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"

APPLICATIONS_DIR="${XDG_DATA_HOME}/applications"
AUTOSTART_DIR="${XDG_CONFIG_HOME}/autostart"
TARGET_DESKTOP_FILE="${APPLICATIONS_DIR}/aw-tray-control.desktop"
TARGET_AUTOSTART_FILE="${AUTOSTART_DIR}/aw-tray-control.desktop"

usage() {
  cat <<'EOF'
Usage:
  scripts/install-desktop-entry.sh [--autostart] [--force] [--exec-path /abs/path/to/aw-tray-control] [--dry-run]
  scripts/install-desktop-entry.sh --remove
  scripts/install-desktop-entry.sh --remove-autostart

Options:
  --autostart         Also install launcher to XDG autostart directory
  --force             Overwrite existing desktop entry without prompting
  --exec-path PATH    Explicit binary path used in Exec/TryExec
  --dry-run           Print actions without executing
  --remove            Remove launcher from XDG applications directory
  --remove-autostart  Remove launcher from XDG autostart directory
  -h, --help          Show this help message
EOF
}

require_file() {
  if [[ ! -f "${SOURCE_DESKTOP_FILE}" ]]; then
    log_error "Desktop entry not found at ${SOURCE_DESKTOP_FILE}"
    exit 1
  fi
}

maybe_overwrite() {
  local target="$1"
  local force="$2"
  local dry_run="$3"

  if [[ -f "${target}" && "${force}" != "true" ]]; then
    if [[ "${dry_run}" == "true" ]]; then
      log_warn "[dry-run] Target exists and would require --force: ${target}"
      return
    fi
    log_error "Target already exists: ${target}"
    log_error "Use --force to overwrite."
    exit 1
  fi
}

canonicalize_path() {
  local input_path="$1"

  if command -v realpath >/dev/null 2>&1; then
    realpath "${input_path}"
    return
  fi

  if command -v readlink >/dev/null 2>&1; then
    readlink -f "${input_path}"
    return
  fi

  log_error "Neither realpath nor readlink is available to canonicalize paths."
  exit 1
}

resolve_exec_path() {
  local exec_path="$1"

  if [[ -n "${exec_path}" ]]; then
    if [[ ! -x "${exec_path}" ]]; then
      log_error "Provided --exec-path is not executable: ${exec_path}"
      exit 1
    fi
    canonicalize_path "${exec_path}"
    return
  fi

  if command -v aw-tray-control >/dev/null 2>&1; then
    canonicalize_path "$(command -v aw-tray-control)"
    return
  fi

  log_error "Could not locate 'aw-tray-control' binary."
  log_error "Install it on PATH (cargo install --path .) or pass --exec-path."
  exit 1
}

write_desktop_file() {
  local target="$1"
  local resolved_exec_path="$2"

  awk -v exec_path="${resolved_exec_path}" '
    /^Exec=/ { print "Exec=" exec_path; next }
    /^TryExec=/ { print "TryExec=" exec_path; next }
    { print }
  ' "${SOURCE_DESKTOP_FILE}" > "${target}"
}

install_entry() {
  local force="$1"
  local resolved_exec_path="$2"
  local dry_run="$3"

  require_file
  run_or_echo "${dry_run}" mkdir -p "${APPLICATIONS_DIR}"
  maybe_overwrite "${TARGET_DESKTOP_FILE}" "${force}" "${dry_run}"
  if [[ "${dry_run}" == "true" ]]; then
    echo "[dry-run] write desktop entry to ${TARGET_DESKTOP_FILE} (Exec=${resolved_exec_path})"
  else
    write_desktop_file "${TARGET_DESKTOP_FILE}" "${resolved_exec_path}"
    chmod 0644 "${TARGET_DESKTOP_FILE}"
  fi
  echo "Installed desktop entry: ${TARGET_DESKTOP_FILE}"
}

install_autostart() {
  local force="$1"
  local resolved_exec_path="$2"
  local dry_run="$3"

  require_file
  run_or_echo "${dry_run}" mkdir -p "${AUTOSTART_DIR}"
  maybe_overwrite "${TARGET_AUTOSTART_FILE}" "${force}" "${dry_run}"
  if [[ "${dry_run}" == "true" ]]; then
    echo "[dry-run] write autostart entry to ${TARGET_AUTOSTART_FILE} (Exec=${resolved_exec_path})"
  else
    write_desktop_file "${TARGET_AUTOSTART_FILE}" "${resolved_exec_path}"
    chmod 0644 "${TARGET_AUTOSTART_FILE}"
  fi
  echo "Installed autostart entry: ${TARGET_AUTOSTART_FILE}"
}

remove_entry() {
  local dry_run="$1"

  if [[ -f "${TARGET_DESKTOP_FILE}" ]]; then
    run_or_echo "${dry_run}" rm -f "${TARGET_DESKTOP_FILE}"
    echo "Removed desktop entry: ${TARGET_DESKTOP_FILE}"
  else
    echo "Desktop entry not found: ${TARGET_DESKTOP_FILE}"
  fi
}

remove_autostart() {
  local dry_run="$1"

  if [[ -f "${TARGET_AUTOSTART_FILE}" ]]; then
    run_or_echo "${dry_run}" rm -f "${TARGET_AUTOSTART_FILE}"
    echo "Removed autostart entry: ${TARGET_AUTOSTART_FILE}"
  else
    echo "Autostart entry not found: ${TARGET_AUTOSTART_FILE}"
  fi
}

main() {
  local install_autostart_flag="false"
  local remove_flag="false"
  local remove_autostart_flag="false"
  local dry_run="false"
  local force="false"
  local exec_path=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --autostart)
        install_autostart_flag="true"
        shift
        ;;
      --remove)
        remove_flag="true"
        shift
        ;;
      --remove-autostart)
        remove_autostart_flag="true"
        shift
        ;;
      --force)
        force="true"
        shift
        ;;
      --dry-run)
        dry_run="true"
        shift
        ;;
      --exec-path)
        if [[ $# -lt 2 ]]; then
          log_error "Missing value for --exec-path"
          exit 1
        fi
        exec_path="$2"
        shift 2
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

  if [[ "${remove_flag}" == "true" && "${install_autostart_flag}" == "true" ]]; then
    log_error "--remove cannot be combined with --autostart"
    exit 1
  fi

  if [[ "${remove_flag}" == "true" && "${remove_autostart_flag}" == "true" ]]; then
    remove_entry "${dry_run}"
    remove_autostart "${dry_run}"
    exit 0
  fi

  local resolved_exec_path=""

  if [[ "${remove_flag}" == "true" ]]; then
    remove_entry "${dry_run}"
  elif [[ "${remove_autostart_flag}" != "true" ]]; then
    resolved_exec_path="$(resolve_exec_path "${exec_path}")"
    install_entry "${force}" "${resolved_exec_path}" "${dry_run}"
  fi

  if [[ "${remove_autostart_flag}" == "true" ]]; then
    remove_autostart "${dry_run}"
  elif [[ "${install_autostart_flag}" == "true" ]]; then
    if [[ -z "${resolved_exec_path}" ]]; then
      resolved_exec_path="$(resolve_exec_path "${exec_path}")"
    fi
    install_autostart "${force}" "${resolved_exec_path}" "${dry_run}"
  fi
}

main "$@"
