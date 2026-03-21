# codex-app-switcher

A macOS utility to quickly switch Codex accounts and launch Codex.

<p align="center">
  <img src="docs/app-window-screenshot.png" alt="codex-app-switcher screenshot" width="390" />
</p>

## What It Does

- Keeps a local list of Codex accounts and lets you switch between them.
- Launches or relaunches the Codex desktop app after switching.
- Tracks 5-hour and 1-week usage windows for each account.
- Supports signing in a new account, importing/exporting account JSON, and clearing saved accounts.
- Supports Chinese and English UI, plus light and dark themes.

## Quick Start

Requirements:

- macOS
- Xcode

Clone the repository and enter the project directory:

```bash
git clone <repo-url>
cd codex-app-switcher
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
