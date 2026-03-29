# Dispatch Reference

Loaded by the `orchestrator` skill when preparing to run a stage.

---

## What dispatch does

Dispatch is how the orchestrator activates an agent. It:
1. Loads the agent's skill file.
2. Builds a scoped payload from shared state — only what the agent needs.
3. Hands the payload to the agent.
4. Receives the agent's output.
5. Writes the output back to shared state.
6. Triggers gate evaluation.

The agent sees only its payload. It never sees shared state directly.

---

## Dispatch sequence

```
1. Confirm prerequisites         → all upstream stages complete, no blocking gates
2. Load agent skill              → read the agent's SKILL.md
3. Build scoped payload          → extract only required fields from state
4. Set stage status: running     → update state before dispatch
5. Dispatch agent                → pass payload, await output
6. Validate output shape         → confirm required fields are present
7. Write output to state         → set stage status: complete
8. Evaluate gate                 → load gates skill, run transition gate
9. Route                         → advance, loop-back, human, or fail
10. Append history event         → record what happened
```

If step 6 fails (output malformed): set stage `status: failed`, do not write to output,
trigger loop-back with a shape-error context block.

---

## Agent payloads by stage

Each agent receives only the slice of state it needs. Build payloads exactly as defined
here — do not add fields not listed, do not omit required fields.

### Extractor payload

```json
{
  "task": "extract",
  "ticket": {
    "raw": "<full ticket text or Jira content>",
    "source": "jira | text"
  },
  "context": {
    "domain_glossary": "<contents of context/domain_glossary.md>"
  }
}
```

### Analyzer payload

```json
{
  "task": "analyze",
  "ticket": "<state.stages.extract.output.ticket>",
  "context": {
    "domain_glossary": "<contents of context/domain_glossary.md>",
    "service_context": "<contents of relevant context/{service}_context.md>"
  },
  "gate_metadata": "<state.gates.active_warnings if any>"
}
```

Service context selection: read `ticket.title` and `ticket.description` to identify
which service namespace is most relevant. Load that context file. If multiple services
are involved, load all relevant ones. If uncertain, load the glossary only and note it
in the dispatch log.

### Challenger payload

```json
{
  "task": "challenge",
  "ticket": "<state.stages.extract.output.ticket>",
  "analysis": "<state.stages.analyze.output>",
  "context": {
    "domain_glossary": "<contents of context/domain_glossary.md>",
    "service_context": "<relevant service context>"
  },
  "gate_metadata": "<state.gates.active_warnings if any>"
}
```

### Risk Assessment payload

```json
{
  "task": "risk_assessment",
  "ticket": "<state.stages.extract.output.ticket>",
  "analysis": "<state.stages.analyze.output>",
  "context": {
    "domain_glossary": "<contents of context/domain_glossary.md>",
    "service_context": "<relevant service context>"
  },
  "gate_metadata": "<state.gates.active_warnings if any>"
}
```

Note: Challenger and Risk Assessment receive the same payload snapshot. Neither receives
the other's output during execution.

### Planner payload

```json
{
  "task": "plan",
  "ticket": "<state.stages.extract.output.ticket>",
  "analysis": "<state.stages.analyze.output>",
  "critique": "<state.stages.merge.output.critique>",
  "context": {
    "domain_glossary": "<contents of context/domain_glossary.md>",
    "service_context": "<relevant service context>"
  },
  "approval": {
    "plan_approved": "<state.approvals.plan_approved>",
    "approved_at": "<state.approvals.plan_approved_at>"
  },
  "gate_metadata": "<state.gates.active_warnings if any>"
}
```

### Validator payload

```json
{
  "task": "validate",
  "ticket": "<state.stages.extract.output.ticket>",
  "plan": "<state.stages.plan.output>",
  "context": {
    "domain_glossary": "<contents of context/domain_glossary.md>"
  },
  "gate_metadata": "<state.gates.active_warnings if any>"
}
```

---

## Output shape validation

Before writing any output to state, confirm these fields are present:

| Stage | Required output fields |
|---|---|
| Extract | `ticket.id`, `ticket.title`, `ticket.actors`, `ticket.acceptance_signals`, `status` |
| Analyze | `intent`, `acceptance_criteria`, `gaps`, `ambiguous_terms`, `confidence` |
| Challenge | `issues[]`, `open_questions[]`, `recommendation` |
| Risk Assessment | `issues[]`, `open_questions[]`, `recommendation` |
| Plan | `tasks[]`, `coverage_summary` |
| Validate | `result`, `contradictions[]`, `documentation_delta`, `verify_result` |

If any required field is missing: treat as malformed output, trigger loop-back with a
shape-error context block listing exactly which fields are absent.

---

## Loop-back dispatch

When routing a loop-back, rebuild the payload with an additional `_loop_context` block:

```json
{
  "_loop_context": {
    "loop_count": "<state.stages.{stage}.attempts>",
    "gate_code": "<gate that triggered the loop>",
    "reason": "<specific reason for the loop>",
    "instruction": "<targeted fix instruction for the agent>"
  }
}
```

Keep `instruction` specific. Bad: "try again". Good: "Re-analyze with focus on resolving
the ambiguous terms: [term1, term2]. If they cannot be resolved from context, mark them
explicitly with `ambiguous: true` on the relevant acceptance criterion."
