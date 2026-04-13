#!/usr/bin/env bash
# Shared shell utilities for aw-tray-control automation.
# Bash 4+ required for modern shell features.

# log_info MESSAGE
#   Print [INFO] prefixed message to stdout.
log_info() {
  printf '[INFO] %s\n' "$*"
}

# log_warn MESSAGE
#   Print [WARN] prefixed message to stderr.
log_warn() {
  printf '[WARN] %s\n' "$*" >&2
}

# log_error MESSAGE
#   Print [ERROR] prefixed message to stderr.
log_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

# die MESSAGE
#   Log error and terminate with exit code 1.
die() {
  log_error "$*"
  exit 1
}

# require_executable PATH
#   Verify that PATH is executable or exit with error.
require_executable() {
  local path="$1"
  [[ -x "${path}" ]] || die "Script not executable: ${path}"
}

# run_or_echo DRY_RUN COMMAND...
#   Execute COMMAND if DRY_RUN is false; otherwise print quoted command to stdout.
run_or_echo() {
  local dry_run="$1"
  shift

  if [[ "${dry_run}" == "true" ]]; then
    printf '[dry-run]'
    for arg in "$@"; do
      printf ' %q' "${arg}"
    done
    printf '\n'
    return
  fi

  "$@"
}
