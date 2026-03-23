# Extracted Practices For Claude

This document distills the reusable patterns found in the assistant configuration files under `/Users/mumoc/projects`.

## What repeated across repositories

### 1. Start with context, not rules alone

The strongest files begin with:

- a short repository overview
- stack and runtime versions
- the main commands needed to work safely
- a map of the important directories or subsystems

This keeps the assistant grounded in the codebase before it starts making changes.

### 2. Put real commands in the config

The most useful files include copy-pastable commands for:

- setup
- local development
- testing
- linting
- regeneration steps
- single-test execution

This pattern is worth preserving because it turns the config into an execution guide instead of a style memo.

### 3. Make boundaries explicit

Across projects, the configs repeatedly call out:

- generated files that must not be edited by hand
- environment files that are committed versus local-only
- legacy surfaces that should only be maintained, not expanded
- high-risk files that require extra caution before editing

Claude performs better when these boundaries are named directly.

### 4. Prefer codebase truth over assumptions

Several configs emphasize the same operating rule:

- search the codebase before implementing
- reuse existing patterns
- keep changes minimal and localized
- prefer the owning repository when behavior spans multiple repos
- say when an API or behavior is uncertain

This is one of the strongest reusable practices and should stay near the top of any shared Claude config.

### 5. Treat testing as part of completion

The configs repeatedly require:

- regression tests for new behavior or bug fixes
- targeted test commands before broad suites when the repo is large
- lint plus relevant tests before calling work done
- exact test commands in PR summaries
- acceptance criteria mapped to test cases when tickets provide AC

This is more reusable than any single framework-specific test rule.

### 6. Separate shared guidance from local overrides

The best example here is OpenProject's local override pattern:

- commit a shared `CLAUDE.md`
- allow a gitignored `CLAUDE.local.md` for personal or machine-specific preferences

This keeps the shared file portable while still allowing local tuning.

### 7. Encode communication style

There is a consistent preference for assistants that are:

- direct
- concise
- explicit about uncertainty
- resistant to empty corporate phrasing
- focused on actionable output

This is not specific to Dealerware and belongs in the shared Claude template.

## What should be generalized

These patterns are useful, but the proprietary details should be removed:

- company names
- internal service names
- private URLs
- bundle IDs, tenant names, environment labels, and deployment workflow names
- vendor-specific secret locations
- product-specific branch coupling rules unless they represent a generic dependency pattern

Generalize them into placeholders such as:

- `<project-name>`
- `<service-name>`
- `<secret-manager>`
- `<primary-dev-command>`
- `<single-test-command>`

## What should stay out of the shared template

- personal biography or brand voice that only applies to one site or persona
- internal compliance language tied to a single employer
- exact cloud account structure, private dashboards, or internal runbooks
- secret values, tokens, or hidden operational identifiers

## Recommended shared Claude structure

This structure appeared most consistently and is the one used in `templates/CLAUDE.md`:

1. Overview
2. Working rules
3. Commands
4. Architecture and key paths
5. Generated code boundaries
6. Testing and verification
7. Environment and secrets
8. Cross-repo or source-of-truth rules
9. PR expectations

## Reusable rules that survived normalization

- Search before assuming.
- Reuse existing patterns before inventing new ones.
- Keep diffs minimal and focused.
- Challenge unclear assumptions directly.
- Prefer targeted tests over full suites when the repo is large.
- Do not edit generated files by hand.
- Use translation keys for user-facing text.
- Ask before changing migrations, dependency manifests, CI workflows, or infrastructure files.
- Keep controllers and UI layers thin when the project already follows service or presenter patterns.
- State exactly how changes were verified.

## Optional local override pattern

Recommended in consuming repositories:

1. Commit `CLAUDE.md`.
2. Add `CLAUDE.local.md` to `.gitignore`.
3. Use `CLAUDE.local.md` for machine-local ports, local tool preferences, or temporary workflow notes.

That gives you portability without losing flexibility.
