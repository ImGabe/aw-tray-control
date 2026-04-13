# Contributing

Thanks for your interest in contributing to aw-tray-control.

## Ground Rules

- Be respectful and collaborative.
- Keep pull requests focused and small when possible.
- Prefer issues for discussion before large changes.

## Development Setup

1. Install Rust (stable toolchain).
2. Clone the repository.
3. Run:

```bash
cargo check
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-targets --all-features
```

## Coding Standards

- Follow idiomatic Rust patterns.
- Keep log and error messages in English.
- Avoid unrelated refactors in bug-fix PRs.

## Commit and PR Guidelines

- Use clear commit messages.
- Include rationale and testing notes in PR descriptions.
- Update docs when behavior/config changes.

## Reporting Bugs

Please include:

- Expected behavior
- Actual behavior
- Reproduction steps
- OS and Rust version
- Relevant logs or screenshots

## Feature Requests

Open an issue first with:

- Problem statement
- Proposed solution
- Alternatives considered
