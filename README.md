# aw-tray-control

[![Project Status](https://img.shields.io/badge/status-active-success)](https://github.com/ImGabe/aw-tray-control)
[![CI](https://img.shields.io/github/actions/workflow/status/ImGabe/aw-tray-control/ci.yml?label=ci)](https://github.com/ImGabe/aw-tray-control/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/ImGabe/aw-tray-control?display_name=tag)](https://github.com/ImGabe/aw-tray-control/releases)
[![Dependencies](https://deps.rs/repo/github/ImGabe/aw-tray-control/status.svg)](https://deps.rs/repo/github/ImGabe/aw-tray-control)
[![GNOME Focus](https://img.shields.io/badge/GNOME-Wayland%20focused-4A86CF?logo=gnome&logoColor=white)](https://www.gnome.org/)
[![License](https://img.shields.io/badge/license-AGPL--3.0--or--later-blue)](./LICENSE)

Modern tray control for ActivityWatch, made for GNOME users who were left with a broken native tray experience.

![Tray menu preview](./docs/assets/tray-menu-preview.png)

## Why This Project Exists

If you use ActivityWatch on GNOME, you probably felt this pain already:

- ❌ The native ActivityWatch tray icon does not behave well on GNOME.
- ❌ The old GNOME extension ecosystem is outdated and not actively maintained.

`aw-tray-control` is the practical replacement layer that restores daily usability:

- ✅ **Reliable tray actions:** no more disappearing icons.
- ✅ **Predictable startup behavior:** starts consistently with your session.
- ✅ **Easier install/update workflow:** quick paths for release and source users.
- ✅ **Clear diagnostics:** actionable checks when something is wrong.

---

## Table of Contents

- [Why This Project Exists](#why-this-project-exists)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [First-Run Experience](#first-run-experience)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Desktop Compatibility](#desktop-compatibility)
- [FAQ](#faq)
- [Uninstall](#uninstall)
- [Privacy and Data](#privacy-and-data)
- [AI Transparency](#ai-transparency)
- [Development](#development)
- [Community](#community)
- [License](#license)

---

## Features

- 🧩 GNOME-first tray workflow with AppIndicator awareness
- 🚀 One-command diagnostics via `./scripts/utils.sh doctor`
- 📦 Release-based installation with checksum verification
- 🔁 Managed process supervision for ActivityWatch components
- 🛠️ Launcher + autostart helpers for XDG desktop environments
- 🧪 Developer-friendly command set and quality checks

---

## Prerequisites

- ActivityWatch already installed and configured on your system.
- GNOME users: AppIndicator Support extension installed (`appindicatorsupport@rgcjonas.gmail.com`).

---

## Installation

Options below are ordered from easiest to most advanced.

### Option A (easiest): Install from GitHub Release

```bash
./scripts/utils.sh install-release --version latest --autostart --force
```

If you prefer pinning a specific release, use `--version X.Y.Z` or `--version vX.Y.Z`.

### Option B (advanced): Build from source

```bash
cargo build --release
./target/release/aw-tray-control
```

Optional local install from source build:

```bash
./scripts/install-binary.sh --binary-root "$HOME/.local"
./scripts/install-desktop-entry.sh --autostart --force --exec-path "$HOME/.local/bin/aw-tray-control"
```

---

## First-Run Experience

Start in 60 seconds:

1. Install and create launcher:

```bash
./scripts/utils.sh install-release --version latest --autostart --force
```

2. Run diagnostics:

```bash
./scripts/utils.sh doctor
```

3. Launch from your GNOME app menu or run directly:

```bash
aw-tray-control
```

---

## Usage

Unified command entrypoint:

```bash
./scripts/utils.sh help
```

Create desktop icon and autostart launcher:

```bash
./scripts/utils.sh install-desktop --autostart --force --exec-path "$HOME/.local/bin/aw-tray-control"
```

Note:

- The launcher uses the `preferences-system-time` icon name from `desktop/aw-tray-control.desktop`.
- Desktop file path: `~/.local/share/applications/aw-tray-control.desktop`
- Autostart file path: `~/.config/autostart/aw-tray-control.desktop`

Update from latest source:

```bash
git pull
cargo build --release
./scripts/install-binary.sh --binary-root "$HOME/.local"
./scripts/install-desktop-entry.sh --autostart --force --exec-path "$HOME/.local/bin/aw-tray-control"
```

Update from release artifact:

```bash
./scripts/utils.sh install-release --version latest --autostart --force
```

---

## Troubleshooting

First step, always:

```bash
./scripts/utils.sh doctor
```

### Tray icon missing on GNOME

Check extension installation:

```bash
gnome-extensions list | grep appindicatorsupport@rgcjonas.gmail.com
```

If missing, install:

- https://extensions.gnome.org/extension/615/appindicator-support/

Then restart GNOME session.

### Binary installed but command not found

```bash
echo "$PATH" | tr ':' '\n' | grep "$HOME/.local/bin"
```

If absent, add `~/.local/bin` to your shell profile.

### Desktop entry does not launch

```bash
./scripts/install-desktop-entry.sh --autostart --force --exec-path "$HOME/.local/bin/aw-tray-control"
```

---

## Desktop Compatibility

Current validated setup:

- Desktop: GNOME on Wayland
- GNOME Shell: 49.5
- AppIndicator extension: required (`appindicatorsupport@rgcjonas.gmail.com`)

| Environment | Tray support | Validation | Notes |
| --- | --- | --- | --- |
| GNOME (Wayland) | 🟢 Works with extension | Tested | Primary target |
| GNOME (X11) | 🟡 Likely works with extension | Not fully tested | Same extension requirement |
| KDE Plasma | 🟡 Native support expected | Not tested in this project | SNI friendly |
| XFCE/Cinnamon and similar X11 DEs | 🟡 Usually works | Not fully tested | Depends on tray host |

Legend:

- 🟢 tested and verified
- 🟡 expected/likely, needs broader validation

---

## FAQ

### Do I need a GNOME extension for tray icon support?

On GNOME, yes. Install AppIndicator Support:

- https://extensions.gnome.org/extension/615/appindicator-support/

### Is this project replacing ActivityWatch?

No. It improves desktop tray control and process supervision for ActivityWatch workflows, especially on GNOME.

### What should I run first when something breaks?

Run:

```bash
./scripts/utils.sh doctor
```

It checks common installation and environment issues quickly.

---

## Uninstall

Default uninstall (binary + desktop + autostart):

```bash
./scripts/uninstall.sh
```

Only desktop/autostart entries:

```bash
./scripts/uninstall.sh --desktop-only
```

Only binary:

```bash
./scripts/uninstall.sh --keep-desktop
```

---

## Privacy and Data

`aw-tray-control` does not introduce a new telemetry backend. It orchestrates and controls local ActivityWatch components.

- Your activity data lifecycle remains tied to ActivityWatch configuration.
- This project focuses on tray UX, process control, and desktop integration.
- Review your local ActivityWatch setup if you need stricter data retention/privacy policies.

---

## AI Transparency

This project was built with AI assistance during design and implementation.
All generated changes are reviewed by a human before merge, with focus on correctness, security, and license compliance.

---

## Development

Requirements:

- Rust stable
- Bash 4+
- shellcheck
- pkg-config
- libdbus-1-dev (or distro equivalent)

Quality checks:

```bash
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-targets --all-features
cargo check --workspace --all-targets --all-features
shellcheck -x scripts/*.sh
```

Using just:

```bash
just check
just doctor
just run
```

---

## Community

- Contribution guide: [CONTRIBUTING.md](./CONTRIBUTING.md)
- Code of conduct: [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)
- Security policy: [SECURITY.md](./SECURITY.md)
- Release process: [RELEASING.md](./RELEASING.md)
- Roadmap: [ROADMAP.md](./ROADMAP.md)

---

## License

Licensed under GNU Affero General Public License v3 or later.

- SPDX: `AGPL-3.0-or-later`
- See [LICENSE](./LICENSE)
