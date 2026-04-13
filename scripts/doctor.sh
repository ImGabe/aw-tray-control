#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "${SCRIPT_DIR}/lib.sh"

XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"

CONFIG_FILE="${XDG_CONFIG_HOME}/aw-tray/config.toml"
DESKTOP_FILE="${XDG_DATA_HOME}/applications/aw-tray-control.desktop"
AUTOSTART_FILE="${XDG_CONFIG_HOME}/autostart/aw-tray-control.desktop"

fail_count=0
warn_count=0

usage() {
  cat <<'EOF'
Usage:
  scripts/doctor.sh

Runs environment, installation, and configuration diagnostics for aw-tray-control.
Returns non-zero when critical checks fail.
EOF
}

ok() {
  printf '[OK] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*"
  warn_count=$((warn_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$*"
  fail_count=$((fail_count + 1))
}

check_command() {
  local cmd="$1"
  local label="$2"

  if command -v "${cmd}" >/dev/null 2>&1; then
    ok "${label}: $(command -v "${cmd}")"
  else
    fail "${label}: command not found (${cmd})"
  fi
}

check_optional_command() {
  local cmd="$1"
  local label="$2"

  if command -v "${cmd}" >/dev/null 2>&1; then
    ok "${label}: available"
  else
    warn "${label}: not installed"
  fi
}

extract_dashboard_url() {
  if [[ ! -f "${CONFIG_FILE}" ]]; then
    return
  fi

  sed -n 's/^dashboard_url[[:space:]]*=[[:space:]]*"\([^"]*\)"/\1/p' "${CONFIG_FILE}" | head -n 1
}

check_dashboard_reachability() {
  local url="$1"

  if [[ -z "${url}" ]]; then
    warn "dashboard_url not found in config"
    return
  fi

  if command -v curl >/dev/null 2>&1; then
    if curl --silent --show-error --fail --max-time 2 "${url}" >/dev/null 2>&1; then
      ok "Dashboard reachable: ${url}"
    else
      warn "Dashboard not reachable now: ${url}"
    fi
  else
    warn "curl not available; skipping dashboard reachability check"
  fi
}

check_gnome_appindicator() {
  local desktop="${XDG_CURRENT_DESKTOP:-unknown}"

  if [[ "${desktop}" != *GNOME* ]]; then
    ok "GNOME-specific AppIndicator check skipped (desktop=${desktop})"
    return
  fi

  if ! command -v gnome-shell >/dev/null 2>&1; then
    warn "GNOME detected but gnome-shell command not found"
    return
  fi

  ok "$(gnome-shell --version)"

  if ! command -v gnome-extensions >/dev/null 2>&1; then
    warn "gnome-extensions command not found; cannot verify AppIndicator extension"
    return
  fi

  if gnome-extensions list | grep -q '^appindicatorsupport@rgcjonas.gmail.com$'; then
    ok "AppIndicator extension installed"
  else
    fail "AppIndicator extension missing on GNOME (install: https://extensions.gnome.org/extension/615/appindicator-support/)"
  fi
}

check_process_paths() {
  if [[ ! -f "${CONFIG_FILE}" ]]; then
    warn "Config file not found: ${CONFIG_FILE}"
    return
  fi

  local in_array="false"
  local any_path="false"

  while IFS= read -r line; do
    if [[ "${line}" =~ ^process_paths[[:space:]]*=\ \[$ ]]; then
      in_array="true"
      continue
    fi

    if [[ "${in_array}" == "true" && "${line}" =~ ^\] ]]; then
      in_array="false"
      break
    fi

    if [[ "${in_array}" == "true" && "${line}" =~ \"([^\"]+)\" ]]; then
      local path
      path="${BASH_REMATCH[1]}"
      any_path="true"
      if [[ -x "${path}" ]]; then
        ok "Managed process executable found: ${path}"
      else
        fail "Managed process path missing or not executable: ${path}"
      fi
    fi
  done < "${CONFIG_FILE}"

  if [[ "${any_path}" != "true" ]]; then
    warn "No process_paths entries detected in ${CONFIG_FILE}"
  fi
}

main() {
  if [[ $# -gt 0 ]]; then
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      *)
        usage
        die "Unknown option: $1"
        ;;
    esac
  fi

  log_info "Running aw-tray-control doctor"
  printf 'Desktop=%s Session=%s\n' "${XDG_CURRENT_DESKTOP:-unknown}" "${XDG_SESSION_TYPE:-unknown}"

  check_command "bash" "Bash"
  check_optional_command "shellcheck" "ShellCheck"
  check_optional_command "cargo" "Cargo"
  check_command "pkg-config" "pkg-config"

  if command -v aw-tray-control >/dev/null 2>&1; then
    ok "aw-tray-control binary in PATH: $(command -v aw-tray-control)"
  else
    warn "aw-tray-control binary not found in PATH"
  fi

  if [[ -f "${DESKTOP_FILE}" ]]; then
    ok "Desktop entry exists: ${DESKTOP_FILE}"
  else
    warn "Desktop entry missing: ${DESKTOP_FILE}"
  fi

  if [[ -f "${AUTOSTART_FILE}" ]]; then
    ok "Autostart entry exists: ${AUTOSTART_FILE}"
  else
    warn "Autostart entry missing: ${AUTOSTART_FILE}"
  fi

  if [[ -f "${CONFIG_FILE}" ]]; then
    ok "Config file exists: ${CONFIG_FILE}"
    check_process_paths
    check_dashboard_reachability "$(extract_dashboard_url)"
  else
    warn "Config file missing (will be created on first run): ${CONFIG_FILE}"
  fi

  check_gnome_appindicator

  printf '\nSummary: fails=%d warnings=%d\n' "${fail_count}" "${warn_count}"
  if [[ "${fail_count}" -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
