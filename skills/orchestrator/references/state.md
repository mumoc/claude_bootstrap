# Shared State Reference

Loaded by the `orchestrator` skill to manage pipeline state.

---

## What shared state is

Shared state is the single object the orchestrator maintains for the entire pipeline run.
It is the only way information flows between stages. Agents never read or write it
directly — the orchestrator extracts slices for dispatch and writes outputs back after
each stage completes.

---

## State schema

```json
{
  "pipeline_id": "<uuid>",
  "ticket_ref": "<Jira ticket ID or description hash>",
  "started_at": "<ISO timestamp>",
  "status": "running | paused | failed | complete",

  "context": {
    "glossary_loaded": true,
    "service_contexts_loaded": ["contracts", "billing"],
    "setup_hash": "<hash from manifest>"
  },

  "stages": {
    "extract": {
      "status": "pending | running | complete | failed",
      "output": null,
      "attempts": 0,
      "completed_at": null
    },
    "analyze": {
      "status": "pending | running | complete | failed",
      "output": null,
      "attempts": 0,
      "completed_at": null
    },
    "challenge": {
      "status": "pending | running | complete | failed",
      "output": null,
      "attempts": 0,
      "completed_at": null
    },
    "risk_assessment": {
      "status": "pending | running | complete | failed",
      "output": null,
      "attempts": 0,
      "completed_at": null
    },
    "merge": {
      "status": "pending | complete",
      "output": null,
      "completed_at": null
    },
    "plan": {
      "status": "pending | running | complete | failed",
      "output": null,
      "attempts": 0,
      "completed_at": null
    },
    "validate": {
      "status": "pending | running | complete | failed",
      "output": null,
      "attempts": 0,
      "completed_at": null
    }
  },

  "gates": {
    "history": [
      {
        "gate_code": "GATE-S1",
        "stage_transition": "pre-flight → extract",
        "result": "proceed",
        "warnings": [],
        "evaluated_at": "<ISO timestamp>"
      }
    ],
    "active_warnings": [],
    "human_pauses": []
  },

  "approvals": {
    "plan_approved": false,
    "plan_approved_at": null,
    "delivery_approved": false,
    "delivery_approved_at": null
  },

  "history": [
    {
      "event": "stage_dispatched | stage_complete | gate_evaluated | human_paused | resumed | looped_back",
      "stage": "string",
      "detail": "string",
      "at": "<ISO timestamp>"
    }
  ]
}
```

---

## Mutation rules

**Initialize once.** State is created at pipeline start with all stages set to `pending`.
Never re-initialize mid-run.

**Stage outputs are append-only.** Once a stage writes its output to `stages.{stage}.output`,
that slot is not overwritten. If a stage is retried, increment `attempts` and write the new
output to `stages.{stage}.output` only after the retry completes successfully. On failure,
write `null` and record the error in `history`.

**Gate history is append-only.** Every gate evaluation appends to `gates.history`. Never
remove or modify past entries.

**Active warnings accumulate.** When a soft gate fires, its warning is added to
`gates.active_warnings`. It is only removed when explicitly resolved (human gate resolution
or clean stage re-run). Never clear warnings automatically.

**Approvals are set once.** `plan_approved` and `delivery_approved` are set to `true` only
when the user provides explicit confirmation. They are never reset to `false` during a run.

---

## State access patterns

**Reading for dispatch:**
The orchestrator extracts only the fields a specific agent needs. It never passes the
full state object to an agent. See `references/dispatch.md` for payload construction.

**Checking gate preconditions:**
Before dispatching any stage, the orchestrator checks:
1. All prerequisite stages have `status: complete`.
2. No active strict gate failure blocks the transition.
3. Required approvals are present if the transition requires them.

**Resuming after human pause:**
When the pipeline resumes after a human gate, the orchestrator reads the user's response
from `gates.human_pauses[last]`, updates state accordingly, and re-evaluates the gate
that triggered the pause.
