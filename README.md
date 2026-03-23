# Jira Codex Kit

Portable Claude assets for Jira planning and repository guidance.

## What is included

- `.claude/skills/jira-ticket-planning/`
- `templates/CLAUDE.md`
- `templates/CLAUDE.local.md.example`
- `docs/extracted-practices.md`
- `AGENTS.md`
- `scripts/install-claude-skill.sh`

## Claude Skill Install

For Claude Code, project skills must live under `.claude/skills/` and user-level skills under `~/.claude/skills/`.

This repository now includes a Claude-native project skill at `.claude/skills/jira-ticket-planning/`.

To install the same skill at the user level:

```bash
./scripts/install-claude-skill.sh
```

By default this installs `jira-ticket-planning` into `${CLAUDE_HOME:-$HOME/.claude}/skills/jira-ticket-planning`.

## Claude Template Usage

1. Copy `templates/CLAUDE.md` into the target repository root as `CLAUDE.md`.
2. Optionally copy `templates/CLAUDE.local.md.example` to `CLAUDE.local.md`.
3. Add `CLAUDE.local.md` to the target repository's `.gitignore`.
4. Replace placeholders with project-specific commands, architecture notes, and guardrails.

## Notes

- `docs/extracted-practices.md` separates reusable patterns from company-specific details.
- Keep secrets, private URLs, tenant names, and company-only process details out of the shared template.
