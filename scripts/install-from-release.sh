#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/install-from-release.sh --version <semver> [options]

Options:
  --version X.Y.Z      Release version to install (required)
  --owner NAME         GitHub owner (default: ImGabe)
  --repo NAME          GitHub repo (default: aw-tray-control)
  --binary-root PATH   Install root (default: $HOME/.local)
  --autostart          Also install desktop entry to autostart
  --force              Overwrite existing desktop/autostart entries
  --dry-run            Print actions without executing
  -h, --help           Show this help message

Examples:
  scripts/install-from-release.sh --version 0.1.0
  scripts/install-from-release.sh --version 0.1.0 --autostart --force
EOF
}

main() {
  local version=""
  local owner="ImGabe"
  local repo="aw-tray-control"
  local binary_root="${HOME}/.local"
  local autostart="false"
  local force="false"
  local dry_run="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version)
        [[ $# -ge 2 ]] || die "Missing value for --version"
        version="$2"
        shift 2
        ;;
      --owner)
        [[ $# -ge 2 ]] || die "Missing value for --owner"
        owner="$2"
        shift 2
        ;;
      --repo)
        [[ $# -ge 2 ]] || die "Missing value for --repo"
        repo="$2"
        shift 2
        ;;
      --binary-root)
        [[ $# -ge 2 ]] || die "Missing value for --binary-root"
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
      --dry-run)
        dry_run="true"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        usage
        die "Unknown option: $1"
        ;;
    esac
  done

  [[ -n "${version}" ]] || {
    usage
    die "--version is required"
  }

  local arch
  arch="$(uname -m)"
  if [[ "${arch}" != "x86_64" ]]; then
    die "Unsupported architecture for this installer: ${arch} (expected x86_64)"
  fi

  local target="x86_64-unknown-linux-gnu"
  local base_name="aw-tray-control-${version}-${target}"
  local archive_name="${base_name}.tar.gz"
  local checksum_name="${archive_name}.sha256"
  local release_url="https://github.com/${owner}/${repo}/releases/download/v${version}"

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir}"' EXIT

  local archive_path="${tmpdir}/${archive_name}"
  local checksum_path="${tmpdir}/${checksum_name}"
  local install_dir="${binary_root}/bin"
  local install_path="${install_dir}/aw-tray-control"

  if [[ "${dry_run}" == "true" ]]; then
    echo "[dry-run] curl -fL ${release_url}/${archive_name} -o ${archive_path}"
    echo "[dry-run] curl -fL ${release_url}/${checksum_name} -o ${checksum_path}"
    echo "[dry-run] (cd ${tmpdir} && sha256sum -c ${checksum_name})"
    echo "[dry-run] tar -xzf ${archive_path} -C ${tmpdir}"
    echo "[dry-run] install -Dm755 ${tmpdir}/aw-tray-control ${install_path}"
  else
    run_or_echo "false" curl -fL "${release_url}/${archive_name}" -o "${archive_path}"
    run_or_echo "false" curl -fL "${release_url}/${checksum_name}" -o "${checksum_path}"
    (
      cd "${tmpdir}"
      sha256sum -c "${checksum_name}"
    )
    run_or_echo "false" tar -xzf "${archive_path}" -C "${tmpdir}"
    run_or_echo "false" install -Dm755 "${tmpdir}/aw-tray-control" "${install_path}"
    log_info "Installed binary: ${install_path}"
  fi

  local desktop_args=(--exec-path "${install_path}")
  if [[ "${autostart}" == "true" ]]; then
    desktop_args+=(--autostart)
  fi
  if [[ "${force}" == "true" ]]; then
    desktop_args+=(--force)
  fi
  if [[ "${dry_run}" == "true" ]]; then
    desktop_args+=(--dry-run)
  fi

  "${SCRIPT_DIR}/install-desktop-entry.sh" "${desktop_args[@]}"

  if [[ "${dry_run}" != "true" ]]; then
    log_info "Install completed for release v${version}"
  fi
}

main "$@"
