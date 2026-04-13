# Packaging Strategy

This document outlines the planned packaging and distribution strategy for `aw-tray-control`.

## Installation Methods

### Current (v0.1.x)
- Manual compilation from source via Cargo
- Binary download from [GitHub Releases](https://github.com/ImGabe/aw-tray-control/releases)

### Planned (v0.2.x)
- **AUR (Arch User Repository)** — Community-maintained package for Arch Linux and derivatives
- **Debian/Ubuntu (.deb)** — Official `.deb` package for Debian-based distributions

### Future (v0.3.x)
- Flatpak universal package
- AppImage portable binary
- Official Debian repository mirror

---

## AUR Packaging (v0.2 Milestone)

**Status:** Planned  
**Responsible:** Community or project maintainer  

### Prerequisites
- PKGBUILD template (template provided in `packaging/aur/PKGBUILD.template`)
- Test build environment (Arch Linux or ArchVM)
- AUR account with SSH key setup

### Implementation Steps
1. Create dedicated `aw-tray-control` package in AUR
2. Use Git-based workflow (AUR git repository)
3. Automate version bumps and builds on new releases
4. Set up CI/CD hook to sync AUR on GitHub tag

### Key Commands (when ready)
```bash
git clone ssh://aur@aur.archlinux.org/aw-tray-control.git
cd aw-tray-control
# Edit PKGBUILD, .SRCINFO
git push
```

### Timeline
- **v0.2.0:** Manual AUR submission
- **v0.2.1+:** Auto-sync via CI hook

---

## Debian/Ubuntu Packaging (v0.2 Milestone)

**Status:** Planned  
**Responsible:** Project maintainer  

### Prerequisites
- `debhelper` / `dh-make` tools for local testing
- Debian packaging standards documentation
- PPA (Personal Package Archive) account or official repo coordination

### Implementation Steps
1. Create `debian/` subdirectory with packaging metadata
2. Define `debian/control`, `debian/rules`, `debian/changelog`
3. Test `.deb` build locally with `dpkg-buildpackage`
4. Publish to PPA or coordinate with official Debian maintainers

### Key Structure
```
debian/
  control       # Package metadata, dependencies
  rules         # Build and packaging instructions
  changelog     # Version history
  copyright     # License information
  compat        # debhelper compatibility level
```

### Timeline
- **v0.2.0:** Manual `.deb` build and test
- **v0.2.1+:** Integrate into CI/CD pipeline for automatic `.deb` generation on releases

---

## Distribution Channel Decisions

### AUR (Recommended for v0.2)
- **Pros:** Easy community contributions, automatic makepkg integration, large Arch user base
- **Cons:** Requires AUR maintainer account, relies on community for updates
- **Decision:** Prioritize AUR first (simpler, larger Linux audience in aw-community)

### Debian (Recommended for v0.2)
- **Pros:** Covers Ubuntu, Debian, derivatives; standard Linux installation method
- **Cons:** Stricter packaging standards, requires more testing
- **Decision:** Implement after AUR basics are solid

### Flatpak (v0.3)
- **Pros:** Works across distributions, isolated sandbox, easy auto-updates
- **Cons:** overkill for system tray integration, may cause permission issues with dbus
- **Decision:** Revisit later; assess community demand

### AppImage (v0.3)
- **Pros:** Portable, zero-dependency binary
- **Cons:** Tray integration complexities on some DMs
- **Decision:** Revisit later; lower priority than Flatpak

---

## Next Actions

1. **v0.1.0 release:** Validate binary packaging via GitHub Releases ([workflow ready](/.github/workflows/release.yml))
2. **Gather feedback:** Collect user installation pain points
3. **v0.2.0 planning:** Prioritize AUR vs Debian based on community demand
4. **Create packaging templates:** Store in `packaging/aur/`, `packaging/debian/` subdirectories

---

## Resources

- [AUR Packaging](https://wiki.archlinux.org/title/AUR)
- [Debian New Maintainers Guide](https://www.debian.org/doc/manuals/debmake-doc/)
- [Ubuntu PPA Documentation](https://wiki.ubuntu.com/PPA)
- [Flatpak Documentation](https://docs.flatpak.org/)
- [AppImage Documentation](https://appimage.org/)
