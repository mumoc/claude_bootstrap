# Strict Gates Reference

Loaded by the `gates` skill when evaluating hard-stop conditions.

---

## What a strict gate does

A strict gate blocks the pipeline entirely when its condition fails. There is no
degraded mode, no warning, no continuation. The pipeline stops and the condition
must be resolved before anything proceeds.

---

## Strict gate definitions

### GATE-S1: Setup complete

**Position:** Before any pipeline stage on a repo.
**Blocks:** Everything.

Conditions (all must pass):
- `context/.setup_manifest.json` exists.
- `schema_version` in manifest matches current skill version.
- `structural_hash` in manifest matches computed hash of current repo state.
- No `[NEEDS INPUT: ...]` gaps exist in `context/domain_glossary.md` for entities
  referenced by the current ticket.

Failure action:
```
GATE-S1 FAILED: Context is missing or stale.
Reason: {specific condition that failed}
Required: Run the setup skill before proceeding.
  → setup skill: ~/.claude/skills/setup/SKILL.md
```

Recovery: run setup skill, then re-evaluate this gate.

---

### GATE-S2: Ticket minimum viable

**Position:** Extract → Analyze.
**Blocks:** Analysis and all downstream stages.

Conditions (all must pass):
- Ticket has at least one identifiable actor or subject.
- Ticket has at least one observable outcome or acceptance signal.
- Ticket is not a duplicate of another ticket currently in the pipeline state.

Failure action:
```
GATE-S2 FAILED: Ticket does not meet minimum requirements for analysis.
Missing: {list what is absent}
Required: {one of}
  → Enrich the ticket with the missing fields, then re-run.
  → Clarify with the user what the expected outcome is.
```

Recovery: human provides missing fields, re-run extract stage, re-evaluate gate.

---

### GATE-S3: Plan approval

**Position:** Challenge → Plan.
**Blocks:** Implementation planning.

Conditions (all must pass):
- Challenge stage produced a `critique` object with no `status: unresolved_critical` items.
- If critical items exist: a human gate (GATE-H2) was evaluated and the user resolved
  or explicitly accepted each critical item.
- Explicit user approval was received for the action path.

Failure action:
```
GATE-S3 FAILED: Unresolved critical issues block planning.
Critical issues:
  - {issue}
  - {issue}
Required: Resolve these issues before a plan can be produced.
  → Trigger GATE-H2 to surface them to the user.
```

Recovery: human resolves critical issues, re-evaluate this gate.

---

### GATE-S4: Delivery approval

**Position:** Validate → Deliver.
**Blocks:** Push and PR creation.

Conditions (all must pass):
- Validate stage produced no `status: contradiction` items.
- Verify skill passed clean (no lint violations, no test failures).
- Explicit user delivery approval was received in the conversation.

Failure action:
```
GATE-S4 FAILED: Work is not ready for delivery.
Reason: {specific condition that failed}
  → Lint/test failures: fix and re-run verify.
  → Validation contradictions: loop back to plan stage.
  → Missing approval: request explicit delivery approval.
```

Recovery: fix the specific failure, re-evaluate this gate.

---

## Strict gate evaluation checklist

When evaluating any strict gate, confirm:

- [ ] All conditions for this gate are checked — not just the first one that passes.
- [ ] Failure output names the specific condition that failed, not a generic error.
- [ ] Recovery path is stated explicitly in the failure output.
- [ ] Pipeline state is not advanced until all conditions pass.
