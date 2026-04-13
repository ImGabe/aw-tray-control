# aw-tray-control

A lightweight Linux system tray controller for ActivityWatch.

This app starts and supervises configured ActivityWatch-related processes, exposes a tray menu, and provides quick access to the ActivityWatch dashboard.

## AI Transparency Notice

This project is "vibe coded": generative AI tools were used during design and implementation.

If you prefer not to use AI-assisted projects, please evaluate this repository before adopting it.
All contributions are expected to be reviewed by humans for correctness, security, and license compliance.

## Features

- Loads configuration from the XDG config directory
- Verifies executable dependencies before startup
- Starts and tracks managed processes
- Exposes tray actions for opening the dashboard and stopping monitoring
- Handles `SIGINT`/`SIGTERM` for graceful shutdown

## Configuration

On first run, a default config is created at:

- `~/.config/aw-tray/config.toml`

Example:

```toml
dashboard_url = "http://localhost:5600"
process_paths = [
  "/home/user/.local/opt/activitywatch/aw-server/aw-server",
  "/home/user/.cargo/bin/aw-watcher-media-player",
  "/home/user/.cargo/bin/awatcher",
]
```

## Requirements

Build and development scripts require:
- **Bash 4.0+** (for associative arrays and modern features in `scripts/lib.sh`)

Check your Bash version:
```bash
bash --version
```

## Development

Primary entrypoint for script utilities:

```bash
./scripts/utils.sh help
```

Recommended usage:

```bash
./scripts/utils.sh dev-check --fast
./scripts/utils.sh dev-run --log-level debug
./scripts/utils.sh reinstall-local --autostart --force
./scripts/utils.sh uninstall --desktop-only
```

Legacy scripts still work, but prefer `utils.sh` for discoverability.

```bash
cargo check
cargo fmt --all
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-targets --all-features
```

Utility script for local validation:

```bash
./scripts/dev-check.sh
```

Options:

```bash
./scripts/dev-check.sh --fast
./scripts/dev-check.sh --dry-run
```

Run utility for local execution:

```bash
./scripts/dev-run.sh
./scripts/dev-run.sh --release
./scripts/dev-run.sh --log-level debug -- --help
```

Reinstall utility (binary + desktop entry):

```bash
./scripts/reinstall-local.sh --force
./scripts/reinstall-local.sh --autostart --force
./scripts/reinstall-local.sh --binary-root "$HOME/.local" --autostart --force
```

## Desktop Launcher

If you want to start the app again after closing it completely, a desktop
launcher is a good Linux-native option.

A ready-to-use launcher is provided at `desktop/aw-tray-control.desktop`.
Use the installer script:

```bash
./scripts/install-desktop-entry.sh
```

This installs the launcher to `~/.local/share/applications/` (or
`$XDG_DATA_HOME/applications` if set).

The script resolves the binary path in this order:

1. `--exec-path` value (if provided)
2. `aw-tray-control` found in `PATH`

You can force a specific binary path:

```bash
./scripts/install-desktop-entry.sh --exec-path "$HOME/.local/bin/aw-tray-control"
```

Strict production flow (recommended):

```bash
./scripts/install-binary.sh
./scripts/install-desktop-entry.sh --autostart --force
```

This installs the binary first, then installs desktop and autostart entries
using the installed binary path.

If you want a custom install root for the binary:

```bash
./scripts/install-binary.sh --binary-root "$HOME/.local"
./scripts/install-desktop-entry.sh --autostart --force --exec-path "$HOME/.local/bin/aw-tray-control"
```

Dry-run examples:

```bash
./scripts/install-binary.sh --dry-run
./scripts/install-desktop-entry.sh --autostart --dry-run
```

## Uninstall

Remove binary + desktop + autostart:

```bash
./scripts/uninstall.sh
```

Remove only desktop/autostart entries:

```bash
./scripts/uninstall.sh --desktop-only
```

Remove only binary (keep desktop/autostart):

```bash
./scripts/uninstall.sh --keep-desktop
```

If the binary was installed with a custom cargo root:

```bash
./scripts/uninstall.sh --binary-root "$HOME/.local"
```

Dry-run:

```bash
./scripts/uninstall.sh --dry-run
```

The installer writes absolute `Exec` and `TryExec` paths, so desktop launch
does not depend on terminal `PATH` after installation.

If you want automatic startup on login (XDG autostart):

```bash
./scripts/install-desktop-entry.sh --autostart
```

Removal options:

```bash
./scripts/install-desktop-entry.sh --remove
./scripts/install-desktop-entry.sh --remove-autostart
```

## Community

- Contribution guide: CONTRIBUTING.md
- Code of conduct: CODE_OF_CONDUCT.md
- Security policy: SECURITY.md

## License

Licensed under the GNU Affero General Public License, version 3 or later:

- `AGPL-3.0-or-later`
- See `LICENSE`
