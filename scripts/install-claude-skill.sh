#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
TARGET_DIR="$CLAUDE_HOME/skills/jira-ticket-planning"

mkdir -p "$CLAUDE_HOME/skills"
rm -rf "$TARGET_DIR"
cp -R "$REPO_ROOT/.claude/skills/jira-ticket-planning" "$TARGET_DIR"

printf 'Installed jira-ticket-planning to %s\n' "$TARGET_DIR"
