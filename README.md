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
- Xcode, or Command Line Tools for Xcode

Clone the repository and enter the project directory:

```bash
git clone https://github.com/refanbanzhang/codex-app-switcher.git
cd codex-app-switcher
```

Build the `.app` from the repository root:

```bash
./scripts/package-app.sh
```

If full Xcode is installed, the script uses `xcodebuild`.
If only Command Line Tools are available, it falls back to `swiftc` and creates the app bundle manually.

Build output:

```bash
./dist/codex-app-switcher.app
```

Build a `.dmg` installer:

```bash
./scripts/package-dmg.sh
```

DMG output:

```bash
./dist/codex-app-switcher.dmg
```

Launch:

```bash
open ./dist/codex-app-switcher.app
```
