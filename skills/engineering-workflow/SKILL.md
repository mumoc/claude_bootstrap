---
name: engineering-workflow
description: Mandatory end-to-end engineering workflow for any implementation, bug fix, refactor, or test-writing task. Enforces ticket analysis, clarifying questions, pattern review, planning and approval, TDD-first execution, minimal design, verification, PR preparation, and review-comment follow-up. Load this skill before touching any code.
---

# Engineering Workflow

Use this skill for any task that changes code or tests.

## Example invocations

- "Work this ticket end to end."
- "Use the engineering workflow."
- "Analyze the ticket, ask questions, propose a plan before coding."
- "Follow TDD: specs first, then implementation, then verification."
- "Full delivery flow: analysis, plan, approval, implementation, verification, PR, review follow-up."

## References

Load these only when the relevant phase is active — do not preload all of them:

- [references/delegation.md](references/delegation.md) — multi-agent delegation rules and patterns
- [references/tdd.md](references/tdd.md) — TDD execution steps and RSpec guardrails
- [references/completion_bar.md](references/completion_bar.md) — pre-done checklist and gate conditions

---

## Lifecycle

```
1. Analyze          → read ticket, identify ambiguities
2. Clarify          → ask questions until scope is safe to implement
3. Inspect          → find nearest existing patterns in the codebase
4. Plan             → propose the smallest coherent action path
5. Approval gate    → wait for explicit approval before any code change
6. Execute (TDD)    → red → approval if needed → commit → green → commit → refactor → commit
7. Verify           → run /verify, confirm all checks pass
8. Delivery gate    → wait for explicit approval before push or PR
9. Deliver          → push and open PR
10. Review loop     → evaluate feedback, apply worthwhile changes, verify, commit, push
```

**Hard gates at steps 5 and 8.** Do not cross either gate without explicit user approval in the
conversation. No exceptions.

---

## Analysis phase

- If the task comes from Jira, read the ticket first. Do not rely on the user's summary alone.
- Identify open product or technical ambiguities before asking anything.
- Confirm acceptance criteria, edge cases, and out-of-scope behavior.
- Inspect the nearest existing code and tests before forming a plan.
- If the codebase has a `context/` grounding document, read the relevant service context before
  inspecting code. It answers most domain questions without a full codebase scan.

## Clarification phase

- Ask all clarifying questions in one batch. Do not drip questions one at a time.
- Ask only what is needed to implement safely. Do not ask what can be inferred from the code.
- If new ambiguity surfaces during implementation, stop and re-clarify instead of guessing.

## Planning phase

- Propose the smallest coherent implementation plan after analysis and clarification.
- Include: files to change, test strategy, any pattern deviations and their justification.
- Get explicit approval on the plan before writing any code.

## TDD execution

Read [references/tdd.md](references/tdd.md) for the full execution steps and RSpec guardrails.

Summary:
1. Write failing specs that express the intended behavior.
2. Confirm the red state when the change is high-impact or ambiguous.
3. Commit red state once failing tests clearly express intent.
4. Write only enough production code to make the specs pass.
5. Commit green state.
6. Refactor only when tests show a clear need. Keep refactors local.
7. Commit refactor state.

## Design guardrails

- Prefer adapting an existing service or object over creating a new one.
- Keep orchestration thin. Push behavior into focused objects only when responsibility is clearly split.
- Avoid speculative flexibility for future tickets.
- Preserve existing naming and file layout unless there is a concrete reason to change.
- Apply YAGNI, KISS, and SOLID with bias toward the smallest coherent change.

## Verification

- Run the `verify` skill after every TDD cycle and before declaring done.
- Work is never done until verify passes clean.
- Check whether the nearest existing documentation should be updated before calling work complete.
  See global `CLAUDE.md` documentation rules for when updates are required.

## Delivery

- Do not push or open a PR until the delivery gate is cleared.
- After approval, prepare delivery artifacts cleanly: push and open PR.
- PR summary must include: what changed, why, how it was verified, and any follow-up risks or
  skipped assumptions.

## Review feedback loop

- When review comments arrive, evaluate whether each comment is correct and valuable.
- Do not apply feedback mechanically — preserve correctness and scope.
- For each valuable comment: implement the change, run verify, commit the update, push.
- For comments you disagree with: state your reasoning clearly and ask for resolution.

## Multi-agent usage

Read [references/delegation.md](references/delegation.md) for the full delegation rules and
patterns.

Summary:
- The main agent owns analysis, clarification, planning, approval gates, integration, final
  verification, and PR/review decisions. These are never delegated.
- Delegate only after the action path is approved.
- Delegate only bounded tasks with explicit ownership and disjoint write scopes.

## Non-negotiables

- **TDD first.** Add or update the relevant spec before changing behavior unless the task is
  strictly non-testable.
- **Minimal design.** Do not introduce abstractions, layers, or helpers unless tests make
  duplication or coupling obvious.
- **Reuse first.** Search the codebase before inventing a new structure.
- **Commit at each checkpoint.** Red, green, refactor, and worthwhile review-feedback updates
  each get their own commit. History must show the process, not only the final state.
- **Documentation is not optional.** When a change materially alters behavior, flow, integration
  contracts, or operational setup — update the nearest existing doc in the same change.
- **Never skip hooks.** No `--no-verify`, `--no-gpg-sign`, or equivalent unless explicitly
  requested by the user.

## Completion bar

Before declaring work done, load and run [references/completion_bar.md](references/completion_bar.md).

All gate conditions must pass. If any fail, resolve them before proceeding.
