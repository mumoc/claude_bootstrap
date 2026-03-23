# claude-bootstrap

Portable Claude Code configuration. Clone this repo on a new machine and run one command to get your global rules, permissions, MCP servers, and skills in place.

## Bootstrap a new machine

```bash
git clone <this-repo> ~/Projects/ai
cd ~/Projects/ai
./scripts/bootstrap.sh
```

This will:

- Symlink `~/.claude/CLAUDE.md` → `global/CLAUDE.md`
- Symlink `~/.claude/settings.json` → `global/settings.json`
- Copy all skills from `skills/` into `~/.claude/skills/`

Existing files are backed up before being replaced (`.bak` suffix).

## Stay up to date

```bash
./scripts/update.sh
```

Pulls the latest changes and re-runs the bootstrap.

## What's tracked

| Path | Purpose |
|---|---|
| `global/CLAUDE.md` | Global rules, conventions, and workflows applied across all projects |
| `global/settings.json` | Allowed commands, MCP server config (secrets via env vars) |
| `skills/jira-ticket-planning/` | Jira initiative-to-ticket planning skill |
| `templates/CLAUDE.md` | Starter template for per-project `CLAUDE.md` files |
| `docs/extracted-practices.md` | Distilled patterns worth reusing across projects |

## Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with the skill frontmatter and instructions.
2. Run `./scripts/bootstrap.sh` to install it.

## MCP authentication

After bootstrapping, some servers need a one-time login per machine. See [`docs/mcp-setup.md`](docs/mcp-setup.md) for details.

**GitHub** — set in your shell profile:

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=...
```

**Atlassian** — OAuth browser login on first use, no env var needed.
