# Changelog

All notable changes to aw-tray-control are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-13

### Added
- **Typed Status API:** `ProcessStatus` enum (`Running | Stopped(ExitKind) | Error`) eliminates stringly-typed internal state
- **Cached Health Snapshots:** `Arc<RwLock<HealthSnapshot>>` reduces syscalls from O(n) per render to O(1)
- **AppRuntime Lifecycle Extraction:** Explicit `start()`, `wait()`, `stop()` methods for clear separation of concerns
- **Shell Script Library (lib.sh):** Consolidated logging and validation helpers (`log_info`, `log_error`, `die`, `require_executable`, `run_or_echo`)
- **Justfile for Development:** Single entry point for build recipes (`just check`, `just run`, `just install`)
- **Config Validation Limits:** Maximum health check interval (3600s) prevents misconfiguration
- **Enhanced CI/CD:**
  - ShellCheck linting in quality job (Bash 4+ compliance)
  - Cached security tool installations (cargo-audit, cargo-deny)
  - Formal Bash 4+ requirement in README

### Changed
- **Main.rs Architecture:** Refactored `run()` into orchestrator pattern with `AppRuntime` struct encapsulating lifecycle state
- **Tray.rs Health Monitoring:** Moved from repeated polling per render to cached snapshot updates
- **Error Handling:** Comprehensive config validation with clear error messages
- **CI Workflow Optimization:** Security tools now cached between runs (-1.5 min per CI execution)

### Improved
- **Code Quality:** 100% clippy -D warnings compliance, 12 unit tests (config, process, tray modules)
- **Developer Experience:** Bash scripts standardized via `scripts/lib.sh`, single dispatcher `scripts/utils.sh`
- **Documentation:**
  - README: Added Requirements section (Bash 4+)
  - Inline documentation in `scripts/lib.sh` with function signatures
  - Clear safety comments in main.rs signal handling

### Technical Debt Deferred (v2.0+)
- Structured logging (slog/tracing)
- Metrics export (Prometheus `/metrics`)
- Config hot-reload without restart
- Channel-based shutdown (vs AtomicBool polling)

## Version Goals

### Stability ✓
- No panics on invalid configuration
- Graceful shutdown of child processes
- Single-instance enforcement via file lock

### Correctness ✓
- Typed state machines (no runtime string parsing)
- Safe concurrency via Arc/RwLock/AtomicBool
- Comprehensive validation of config boundaries

### Simplicity ✓
- Minimal dependencies (ksni, signal-hook, serde, thiserror, nix, fs2)
- No async runtime (threads sufficient for <5 processes)
- ~700 lines of core Rust, ~100 lines of shell utilities

---

For future releases, see [ROADMAP.md](ROADMAP.md) (planned).
