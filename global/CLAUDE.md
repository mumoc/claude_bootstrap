# CLAUDE.md — Global Defaults

This file provides cross-project behavioral rules. It intentionally contains no company-specific or project-specific content.

---

## Workflow Rules

- **TDD is mandatory.** All features are developed test-first, grounded in business requirements —
  never derived from implementation paths.
  1. **Clarify first.** If the task lacks clear business requirements or expected behavior, ask
     before writing any test or code. Do not assume intent.
  2. **Red.** Write a failing test describing one business scenario. Order: happy path first,
     error paths second, alternate/edge paths last.
  3. **Green.** Write the minimal implementation to make the test pass — nothing more.
  4. **Refactor.** Improve the code applying YAGNI, SOLID, KISS, and DRY without changing behavior.
  5. Repeat until all scenarios are covered. Run `/verify` after each cycle. **Work is never done
     until `/verify` passes clean** — this is a hard gate, not a suggestion.
- **Never skip hooks** (`--no-verify`, `--no-gpg-sign`, etc.) unless explicitly requested.
- **Read before modifying.** Do not propose changes to code you haven't read.
- **Avoid over-engineering.** Only make changes that are directly requested or clearly necessary.
  Don't add error handling or abstractions that weren't asked for. Don't add inline comments for
  code that already explains itself. Documentation is an exception — see the Documentation section.
- **Confirm before destructive or shared-state actions** (force push, dropping tables, deleting
  branches, posting to external services, sending messages).

---

## Code Conventions

### Universal

These apply regardless of stack.

- Public interface first, private methods and helpers at the bottom.
- Each function or method does one thing. If you need "and" to describe it, split it.
- Prefer names that explain intent over comments that explain what the code does.
- Structured key-value logging only — no string interpolation. Always include an `event:` key.
- Eager-load associations in loops — no N+1 queries.
- Batch large datasets — never iterate over an unbounded collection in one shot.
- Validate at system boundaries (user input, external APIs). Trust internal code and framework guarantees.
- Never hardcode credentials or secrets — use environment variables or secrets managers.
- Sanitize user input used in raw SQL or shell commands.
- Watch for IDOR vulnerabilities when resource IDs appear in URLs or request params.

### Ruby / Rails

- `!` suffix for methods that raise on failure; `?` for boolean predicates.
- Class methods for stateless operations; instance methods when you need injected dependencies
  or internal state.
- `exists?` over `any?`; `pluck` over `map` when fetching attributes only.
- `find_each` / `find_in_batches` for large tables — never `all.each`.
- Use queues by job duration: `default` (< 30s), `long_running`, `critical`, `low_priority`.
- Sidekiq jobs: pass IDs not objects, design for idempotency, re-raise for retry and don't
  re-raise for permanent failures.
- Tests: `build` / `build_stubbed` over `create` when persistence is not required. Use `before`
  blocks for stubs and mocks, not for data setup. Check `spec/factories` before defining new ones.
- Use trace spans for custom APM instrumentation.

### JavaScript / TypeScript

- `const` over `let`; never `var`.
- Explicit types over `any` in TypeScript. If you reach for `any`, the design needs reconsideration.
- Pure functions for business logic; push side effects to the edges.
- `async/await` over raw Promise chains.
- Named exports over default exports — easier to grep and refactor.
- Avoid mutation; prefer immutable patterns (`Object.freeze`, spread, `Array.from`).
- Always handle Promise rejections — never swallow errors silently.
- Tests: mock at the boundary (network, filesystem, clock), not inside the domain. Prefer
  integration tests for HTTP handlers.

### Python

- Type hints on all public functions and methods — inputs and return value.
- Dataclasses or Pydantic for structured data; plain dicts only for truly ad hoc payloads.
- Raise exceptions for error paths; don't return `None` or error codes from domain functions.
- Use context managers for all resource management (files, connections, logs).
- List comprehensions over `map`/`filter` when the logic fits in one line.
- Prefer explicit imports over wildcard imports.
- Tests: use `pytest` fixtures for setup, not `setUp`/`tearDown`. Prefer `monkeypatch` and
  `httpx` / `respx` for boundary mocking.

---

## Documentation

Documentation is a default, not an afterthought. Apply it whenever you implement or meaningfully
touch code.

**Docblocks** — add to every public method/function where any of the following is true:
- A business rule drives branching, fallback, or validation behavior.
- Parameters, return value, or side effects are non-obvious from the method name alone.
- The method is part of a public interface (service object, job, model concern, public API, etc.)

Docblock rules:
- Use the documentation tool of the stack (YARD for Ruby, JSDoc for JS/TS, docstrings for Python,
  etc.) — follow that stack's conventions.
- Lead with the business rule or intent in plain English — never restate the method name.
- Document params/return types only when shape, constraints, or type are non-obvious.
- Document raise/throw/exceptions when failure modes matter to the caller.
- Never add a docblock that says nothing beyond what the signature already communicates.

**Markdown domain docs** — create a `README.md` co-located with the code when:
- Two or more classes/objects in the same namespace collaborate on a domain concept (a flow,
  lifecycle, policy, etc.)
- The rules governing their interaction are not obvious from reading any single class.

Place the `README.md` inside the namespace folder. README structure:
1. **What** — the domain concept in one paragraph
2. **Objects involved** — list with one-line roles
3. **Business rules** — the rules governing behavior, not implementation steps
4. **Usage** — a realistic code example covering the happy path, plus edge cases if rules require it

Never create a README for a single class. Never repeat per-method detail already covered by docblocks.

---

## Skills

### gates

**Used by the orchestrator only.** Individual agents do not load this skill.
Defines gate types, conditions, routing logic, and stage contracts for agentic pipelines.

Skill: `~/.claude/skills/gates/SKILL.md`

Load when:
- Running any multi-stage agentic pipeline.
- The orchestrator needs to evaluate stage output before advancing.
- A stage transition requires a routing decision (proceed, loop-back, human, fail).

Do not load in individual agent contexts. Gates are orchestrator responsibility.

### orchestrator

**Pipeline coordinator.** Owns shared state, dispatches agents, evaluates gates, handles
parallel execution, and routes between stages. Load when running a full ticket pipeline.

Skill: `~/.claude/skills/orchestrator/SKILL.md`

Load when:
- Running any full ticket pipeline (extract → analyze → challenge → plan → validate → deliver).
- Coordinating parallel agents (Challenge + Risk Assessment).
- Managing pipeline recovery, loop-backs, or human pause/resume.

Requires `gates` skill and `setup` skill (context must be current) before first dispatch.
Do not load in individual agent contexts — orchestrator responsibility only.

### setup

**Run before any agentic pipeline.** Scans the repository, harvests existing documentation,
conducts a short business logic interview, and writes grounding documents to `context/`.
All agents read from `context/` — setup is what makes them accurate.

Skill: `~/.claude/skills/setup/SKILL.md`

Run when:
- Starting an agentic workflow on a repo for the first time.
- The repo has changed structurally (new services, major new namespaces).
- `context/.setup_manifest.json` reports a structural hash drift.

Skip when `context/` exists and the manifest hash matches the current repo structure.
The skill checks this automatically.

### engineering-workflow

**Hard gate.** Use for any task that changes code or tests — implementation, bug fix, refactor,
or test writing.

Skill: `~/.claude/skills/engineering-workflow/SKILL.md`

Required sequence:
1. Read the ticket or task description directly — do not rely on a summary.
2. Ask clarifying questions in one batch until scope is safe to implement.
3. If `context/` grounding documents exist, read the relevant ones before inspecting code.
4. Inspect existing code and test patterns.
5. Propose an action path and wait for explicit approval — this is a hard gate.
6. Implement with TDD: red → commit → green → commit → refactor → commit.
7. Run the `verify` skill. Work is never done until it passes clean — this is a hard gate.
8. Wait for explicit delivery approval before pushing or opening a PR — this is a hard gate.
9. After review comments: evaluate, apply worthwhile changes, verify, commit, push.

### agents

Dispatched exclusively by the orchestrator. Each agent receives a scoped payload,
does one job, and returns a structured output. Do not load agent skills directly —
the orchestrator manages dispatch.

| Agent | Skill | Role |
|---|---|---|
| Extractor | `~/.claude/skills/agents/extractor/SKILL.md` | Structures raw ticket into typed object |
| Analyzer | `~/.claude/skills/agents/analyzer/SKILL.md` | Interprets intent and maps to domain |
| Challenger | `~/.claude/skills/agents/challenger/SKILL.md` | Business/product adversarial review |
| Risk Assessment | `~/.claude/skills/agents/risk-assessment/SKILL.md` | Technical risk review (parallel with Challenger) |
| Planner | `~/.claude/skills/agents/planner/SKILL.md` | Produces ordered implementation plan |
| Validator | `~/.claude/skills/agents/validator/SKILL.md` | Verifies plan against ticket before delivery |

### jira-ticket-planning

Use for all initiative-to-ticket work. Source of truth for ticket structure, classification,
and sprint placement.

Skill: `~/.claude/skills/jira-ticket-planning/SKILL.md`

Invoke when turning a plan into Jira tickets, classifying or sequencing tickets, or creating
approved tickets in Jira. Do not apply Jira field structure or classification logic without
this skill active.

### verify

**Hard gate.** Run after every TDD cycle and before any "done" declaration.

Skill: `~/.claude/skills/verify/SKILL.md`

Reads `/verify` from the project `CLAUDE.md`. Falls back to stack auto-detection.
Work is never done until verify passes clean.

---

## Per-Project CLAUDE.md

Each repo gets its own `CLAUDE.md` checked into the codebase. It must contain:

- Stack overview and local port
- Dev / test / lint commands (with Docker/Make/etc. wrappers)
- **`/verify` must be defined** — the exact command(s) to run lint and the relevant test suite.
  If absent, the `verify` skill auto-detects the stack, but an explicit definition is preferred.
- Architecture overview (key directories, patterns used)
- Performance-sensitive areas requiring extra care (e.g. large tables)
- Common linter violations to avoid for this codebase
- Inter-service connections and environment variables

---

## MCP Integrations

MCP servers are configured in `~/.claude/settings.json` (tracked in this bootstrap repo).
Do not add MCP config directly to project-level CLAUDE.md files.
