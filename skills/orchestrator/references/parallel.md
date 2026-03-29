# Parallel Execution Reference

Loaded by the `orchestrator` skill when coordinating the Challenge and Risk Assessment
stages.

---

## When parallel execution applies

Challenge and Risk Assessment are the only stages that run in parallel in the standard
pipeline. Both depend only on Analyze output, and neither depends on the other.

Do not parallelize any other stages without explicit design — sequential stages have
output dependencies that make parallelism incorrect, not just risky.

---

## Parallel dispatch sequence

```
1. Confirm Analyze is complete and GATE-W2 passed (or passed-with-warnings).
2. Build Challenger payload from state.
3. Build Risk Assessment payload from state.
4. Confirm both payloads are built from the same state snapshot.
5. Dispatch both agents concurrently.
6. Await both outputs — do not advance until both are received.
7. Validate both output shapes independently.
8. Run merge.
9. Evaluate GATE-S3 on the merged output.
```

Both agents receive the same `analysis` snapshot from step 2-3. If Analyze output
changes for any reason between payload builds, rebuild both payloads from the same
version before dispatching.

---

## Isolation rules

- Challenger and Risk Assessment share no write scope.
- Neither receives the other's output during execution.
- Neither receives in-progress state updates from any other stage during execution.
- If one agent fails or produces malformed output, do not cancel the other. Let both
  complete, then handle the failure in merge.

---

## Merge logic

After both outputs are received and shape-validated, the orchestrator runs merge.
Merge produces a single `critique` object written to `state.stages.merge.output`.

### Deduplication

An issue appearing in both outputs is the same issue if:
- The description references the same acceptance criterion or ticket section.
- The nature of the concern is the same (ambiguity, missing rule, technical risk).

Deduplicated issues are merged into one entry with `source: ["challenge", "risk_assessment"]`.

### Conflict resolution

If the same issue appears in both outputs but with different severity:
- Use the higher severity.
- Record both original severities in the issue's `source_severities` field.

```json
{
  "description": "Billing rule not specified for cancelled reservations",
  "severity": "critical",
  "source": ["challenge", "risk_assessment"],
  "source_severities": {
    "challenge": "major",
    "risk_assessment": "critical"
  },
  "status": "unresolved"
}
```

### Open questions deduplication

Questions from both outputs that address the same uncertainty are merged into one.
Use the more specific phrasing.

### Recommendation

After merging, set `recommendation` based on the merged issue list:

| Condition | Recommendation |
|---|---|
| Any issue with `severity: critical` and `status: unresolved` | `blocked` |
| Issues present but none critical | `proceed-with-caution` |
| No issues | `proceed` |

---

## Handling one failed parallel agent

If one parallel agent produces malformed output and the other completes successfully:

1. Attempt a loop-back for the failed agent (up to loop limit).
2. Do not block the merge on a second failure — proceed with the available output.
3. Add a GATE-W* warning noting that merge used only one source.
4. Record the failure in `gates.active_warnings` and `history`.

If both agents fail: do not attempt merge. Trigger GATE-H3 with accumulated failures
and ask the user how to proceed.
