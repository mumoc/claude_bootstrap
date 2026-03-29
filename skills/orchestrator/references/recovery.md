# Recovery Reference

Loaded by the `orchestrator` skill when handling failures, loop-backs, and pipeline repair.

---

## Recovery principles

Recovery is about routing correctly, not fixing problems directly. The orchestrator
never patches agent output, invents missing fields, or skips a gate to make progress.
It routes to the right place and waits for a clean result.

---

## Loop-back recovery

### Triggering conditions

Route to loop-back when:
- Stage output is structurally malformed (missing required fields).
- A soft gate fires and the issue is one the agent could fix with more targeted context.
- The agent explicitly sets `status: needs_retry` in its output.

### Loop limit enforcement

Track `state.stages.{stage}.attempts`. Maximum is 2 retries (3 total attempts).

```
Attempt 1 (first dispatch):    normal payload
Attempt 2 (first loop-back):   payload + _loop_context with specific instruction
Attempt 3 (second loop-back):  payload + _loop_context with more specific instruction
Attempt 4:                      DO NOT dispatch — escalate to human gate instead
```

When escalating from a third failure:
- Set `state.stages.{stage}.status: failed`.
- Trigger GATE-H3 with the accumulated failure details.
- Surface to the user: what the agent was asked to do, what failed, and what decision
  is needed.

### What to include in loop-back instructions

The `_loop_context.instruction` must be specific to the failure. Generic instructions
do not improve output quality.

| Failure type | Instruction approach |
|---|---|
| Missing output field | "Your output was missing `{field}`. Include it with this shape: `{schema}`." |
| Confidence too low | "Confidence was low due to unresolved terms: {terms}. If they cannot be resolved from context, mark each with `ambiguous: true` — do not guess." |
| Ambiguous terms > threshold | "Focus resolution on: {terms}. For each, either resolve from the domain glossary or mark explicitly as unresolvable." |
| Partial plan coverage | "Tasks {ids} have `coverage: partial` but no `deferred_reason`. Add explicit reasons or change coverage to `full`." |

---

## Human pause recovery

### Triggering conditions

Route to human gate when:
- A loop limit is reached.
- A strict gate fails and no automatic recovery path exists.
- A soft gate accumulates 3+ unresolved warnings.
- The pipeline encounters a decision that requires domain or business judgment.

### Pausing the pipeline

When routing to a human gate:
1. Set `state.status: paused`.
2. Record the pause in `state.gates.human_pauses`:
   ```json
   {
     "gate_code": "GATE-H2",
     "triggered_at": "<ISO timestamp>",
     "question": "<the single question surfaced to the user>",
     "context": "<minimum context needed to answer>",
     "resolved": false,
     "resolution": null
   }
   ```
3. Surface the question to the user. Do not proceed.
4. Wait for explicit user response.

### Resuming after human response

When the user responds:
1. Record the resolution in `human_pauses[last].resolution`.
2. Set `human_pauses[last].resolved: true`.
3. Update state based on the resolution (e.g. mark critical issue as accepted,
   add clarification to the ticket object, set approval flag).
4. Re-evaluate the gate that triggered the pause.
5. If the gate now passes: set `state.status: running`, continue pipeline.
6. If the gate still fails after resolution: escalate to `fail`.

---

## Pipeline fail recovery

### When to fail

Fail the pipeline (not loop-back, not human) when:
- The user explicitly declines to run setup and no context exists.
- A human gate received a response that makes continuation logically impossible.
- A strict gate has failed after all recovery paths were exhausted.
- The user explicitly instructs the pipeline to stop.

### Fail state

```json
{
  "status": "failed",
  "failed_at": "<ISO timestamp>",
  "failed_stage": "<stage name>",
  "failed_gate": "<gate code>",
  "reason": "<specific reason>",
  "partial_outputs_available": true
}
```

Always preserve partial outputs in state when failing. The user may want to inspect
what was completed before the failure.

### Re-starting after fail

A failed pipeline is not automatically restartable. The user must either:
- Fix the root cause (e.g. run setup, clarify the ticket) and start a fresh pipeline.
- Request a targeted restart from a specific stage if partial outputs are valid.

For targeted restarts: confirm that all stages before the restart point have
`status: complete` and their outputs are present. Re-initialize only the failed stage
and all downstream stages to `pending`. Preserve all upstream outputs.

---

## State repair

If state becomes inconsistent (e.g. a stage shows `status: running` but no output
and no active dispatch), treat it as a failed dispatch:

1. Set stage `status: failed`.
2. Increment `attempts`.
3. Append a `dispatch_lost` event to `history`.
4. Attempt loop-back if under the loop limit.
5. Trigger human gate if at or over the limit.

Never assume a `running` stage will self-resolve.
