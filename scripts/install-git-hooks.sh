#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT_DIR}"

if [ ! -d ".git" ]; then
  echo "ERROR: Please run this script from inside the git repository."
  exit 1
fi

if [ ! -f ".githooks/pre-commit" ]; then
  echo "ERROR: .githooks/pre-commit not found."
  exit 1
fi

chmod +x .githooks/pre-commit
git config core.hooksPath .githooks

echo "Git hooks installed."
echo "Current hooks path: $(git config --get core.hooksPath)"
