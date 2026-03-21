# codex-app-switcher

A macOS utility to quickly switch Codex accounts and launch Codex.

## Quick Start

Requirements:

- macOS
- Xcode

Open the project in Xcode:

```bash
open ./codex-app-switcher.xcodeproj
```

Build the `.app` from the repository root:

```bash
./scripts/package-app.sh
```

Build output:

```bash
./dist/codex-app-switcher.app
```

Launch:

```bash
open ./dist/codex-app-switcher.app
```

## Privacy Guard (Recommended)

Install the built-in `pre-commit` hook to scan staged files for common secrets before commit:

```bash
./scripts/install-git-hooks.sh
```

If a commit is blocked, unstage suspicious files first:

```bash
git restore --staged <file>
```
