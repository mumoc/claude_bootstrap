# Jira Codex Kit

This repository contains reusable Claude assets for Jira planning and shared repository guidance.

## Contents

- `.claude/skills/jira-ticket-planning`: self-contained Jira planning skill for Claude Code
- `templates/CLAUDE.md`: portable Claude repository template
- `templates/CLAUDE.local.md.example`: local override example
- `docs/extracted-practices.md`: normalized patterns worth reusing
- `scripts/install-claude-skill.sh`: installs the Jira skill into `${CLAUDE_HOME:-$HOME/.claude}/skills`

## Usage

- Use `jira-ticket-planning` when asked to turn a plan into Jira tickets, classify tickets for sequencing, or create approved tickets in Jira.
- Use `templates/CLAUDE.md` as the starting point for repository-level Claude guidance.
- Keep company-specific details, secrets, private URLs, and local-only preferences out of the shared template.
