---
name: orchestrator
description: Pipeline coordinator for multi-stage agentic ticket workflows. Owns shared state, dispatches agents, evaluates gates, coordinates parallel execution, and routes between stages. Load this skill when running a full ticket pipeline from extraction through delivery. Do not load in individual agent contexts.
---

# Orchestrator

The orchestrator runs the pipeline. It owns shared state, dispatches agents one at a
time or in parallel, evaluates gates between stages, and routes the pipeline forward,
backward, or to a human based on gate results.

Individual agents do not know the orchestrator exists. They receive a scoped payload
and return a structured output. The orchestrator does everything in between.

## References

- [references/state.md](references/state.md) — shared state schema and mutation rules
- [references/dispatch.md](references/dispatch.md) — how to dispatch agents and build their payloads
- [references/parallel.md](references/parallel.md) — parallel execution and merge logic
- [references/recovery.md](references/recovery.md) — loop-back handling, error recovery, pipeline repair

---

## Skills this skill depends on

Before running any pipeline stage, these skills must be loaded:

- `gates` skill — for all gate evaluations between stages
- `setup` skill — already run, `context/` must be current before dispatch begins

Individual agent skills are loaded per-dispatch, not upfront. See
[references/dispatch.md](references/dispatch.md).

---

## Pipeline lifecycle

```
1. Pre-flight        → verify setup, load gates skill, initialize state
2. Extract           → dispatch Extractor, evaluate GATE-S2
3. Analyze           → dispatch Analyzer, evaluate GATE-W2
4. Parallel branch   → dispatch Challenger + Risk Assessment concurrently
5. Merge             → merge parallel outputs, evaluate GATE-S3
6. Plan              → dispatch Planner, evaluate GATE-W3
7. Validate          → dispatch Validator, evaluate GATE-W4 + GATE-S4
8. Deliver           → dispatch delivery steps after GATE-S4 passes
```

At each step: dispatch → receive output → evaluate gate → route.
Never advance without gate evaluation. Never skip a stage.

---

## Orchestrator responsibilities

**Always the orchestrator's job:**
- Initializing and mutating shared state.
- Deciding which agent to dispatch next.
- Building each agent's scoped payload from shared state.
- Evaluating gates after each stage output.
- Routing: proceed, loop-back, human pause, or fail.
- Merging parallel agent outputs.
- Surfacing human gate questions.
- Recording pipeline history in state.

**Never the orchestrator's job:**
- Domain reasoning (what does this ticket mean?).
- Fixing agent output directly (route back to the agent instead).
- Patching `context/` files (request a setup update instead).
- Making approval decisions on behalf of the user.

---

## Hard rules

- **One gate evaluation per stage transition.** No exceptions, no skips.
- **Shared state is the only communication channel.** Agents never receive another
  agent's raw output — only the orchestrator-curated slice from state.
- **Human gates pause everything.** When GATE-H* fires, the orchestrator stops,
  surfaces the question, and waits. It does not proceed on a guess.
- **Loop limit is enforced here.** The orchestrator tracks loop counts in state and
  converts a third failure into a human gate rather than dispatching again.
- **Parallel branches are fully isolated.** Agents in parallel never share a write
  scope or receive each other's in-progress output.
- **State is append-only during a run.** Completed stage outputs are never overwritten.
  If a stage is retried, its new output is written to a versioned slot.
