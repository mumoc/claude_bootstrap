#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

# --- Global CLAUDE.md ---
if [[ -e "$CLAUDE_HOME/CLAUDE.md" && ! -L "$CLAUDE_HOME/CLAUDE.md" ]]; then
  printf 'Backing up existing CLAUDE.md to %s/CLAUDE.md.bak\n' "$CLAUDE_HOME"
  mv "$CLAUDE_HOME/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md.bak"
fi
ln -sf "$REPO_ROOT/global/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
printf 'Linked CLAUDE.md\n'

# --- settings.json ---
if [[ -e "$CLAUDE_HOME/settings.json" && ! -L "$CLAUDE_HOME/settings.json" ]]; then
  printf 'Backing up existing settings.json to %s/settings.json.bak\n' "$CLAUDE_HOME"
  mv "$CLAUDE_HOME/settings.json" "$CLAUDE_HOME/settings.json.bak"
fi
ln -sf "$REPO_ROOT/global/settings.json" "$CLAUDE_HOME/settings.json"
printf 'Linked settings.json\n'

# --- Skills ---
mkdir -p "$CLAUDE_HOME/skills"
for skill_dir in "$REPO_ROOT/skills"/*/; do
  skill_name="$(basename "$skill_dir")"
  rm -rf "$CLAUDE_HOME/skills/$skill_name"
  cp -R "$skill_dir" "$CLAUDE_HOME/skills/$skill_name"
  printf 'Installed skill: %s\n' "$skill_name"
done

printf '\nBootstrap complete. Claude home: %s\n' "$CLAUDE_HOME"
