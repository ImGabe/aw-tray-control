# Packaging Templates

This directory contains templates and preparation for distributing `aw-tray-control` across multiple package managers.

**Status:** Preparatory phase (v0.2 milestone)

## Current Structure

```
packaging/
├── aur/              # Arch User Repository
│   └── PKGBUILD.template
├── debian/           # Debian/Ubuntu packages  
│   ├── control.template
│   └── rules.template
└── README.md         # This file
```

## Templates

### AUR (Arch User Repository)

**File:** `aur/PKGBUILD.template`  
**Purpose:** Template for building aw-tray-control package for Arch Linux  
**When ready:** Copy to `PKGBUILD`, fill in placeholders, submit to AUR

**Checklist before submission:**
- [ ] Update `pkgver` and `pkgrel`
- [ ] Verify `sha256sums` with actual release checksum
- [ ] Test locally: `makepkg -si`
- [ ] Ensure all dependencies are correct
- [ ] Create AUR account and SSH key
- [ ] Push to `ssh://aur@aur.archlinux.org/aw-tray-control.git`

### Debian/Ubuntu

**Files:** `debian/control.template`, `debian/rules.template`  
**Purpose:** Templates for building `.deb` packages for Debian-based distros  
**When ready:** Copy to `control` and `rules` in project root or dedicated branch

**Checklist before build:**
- [ ] Ensure all Debian build tools are installed
- [ ] Update version in `control` file
- [ ] Test locally: `dpkg-buildpackage -us -uc`
- [ ] Verify binary and desktop entries are correctly installed
- [ ] Coordinate with official Debian maintainers or PPA

---

## Next Steps

1. **v0.1.0 release** — Validate binary on GitHub Releases (`release.yml` workflow)
2. **Gather feedback** — Collect community preferences (AUR vs Debian first)
3. **v0.2.0 planning** — Implement highest-priority package first
4. **Finalize templates** — Fill in placeholders, test builds locally
5. **Submit/publish** — Launch on AUR and/or Debian

---

## Resources

- [AUR: How to Use](https://wiki.archlinux.org/title/AUR)
- [Debian: New Maintainers Guide](https://www.debian.org/doc/manuals/debmake-doc/)
- [Ubuntu: PPA Setup](https://wiki.ubuntu.com/PPA)
