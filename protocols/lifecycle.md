# Lifecycle

The flow from user request to landed change.

## Steps

1. **Intake.** Master reads user request and restates as a one-paragraph brief.
2. **GATE 1 — Interpretation.** Master confirms the brief with the user before spending agent cycles.
3. **Product.** Master dispatches `agent-product`. Spec lands in `feature_status.md`.
4. **Design (if UI involved).** Master dispatches `agent-designer`. Screen + component spec lands in design memory.
5. **GATE 2 — Spec.** Master shows the product + design output and gets user approval. **This is the cheapest gate to fail; spend it here, not later.**
6. **Plan.** Master picks which dev agents are needed and creates a feature branch.
7. **Implement.** Master dispatches dev agents:
   - DB agent first if schema changes (others wait on its sentinel)
   - Backend next if API changes (frontend waits on contract)
   - Frontend in parallel with backend if API contract is stable
8. **Test.** Once all dev sentinels are in, Master dispatches `agent-qa`.
9. **Review.** In parallel with QA, Master dispatches `agent-reviewer`.
10. **GATE 3 — Pre-land.** Master reports QA + review outcome to the user and asks whether to commit / push / open PR.
11. **Land.** Master commits per [git-discipline.md](git-discipline.md). No push without explicit user OK.
12. **Log.** Master verifies `change_logs.md`, `feature_status.md`, and memory indexes are current. Marks feature as done.

## Gates Recap

| Gate | When | What user sees |
|---|---|---|
| 1 — Interpretation | Before any agent runs | One-paragraph brief |
| 2 — Spec | After Product + Design | Spec summary with open questions |
| 3 — Pre-land | After QA + Review | Pass/fail summary + reviewer verdict |

## Ad-Hoc Escalations (don't wait for a gate)

- Ambiguous requirements not resolvable from existing memory
- Destructive ops requested or implied by a worker (drops, force-push, mass-delete)
- Scope creep — worker wants to do more than the spec
- Cross-component breaking changes not anticipated in the spec
- Hung agents (no sentinel + no pane activity past threshold)
- Schema migrations on populated tables
- Credential or config-secret changes
- Any external-system side effect (push, deploy, send message, post to PR)

## Parallelism Rules

**Run in parallel when:**
- Independent components (frontend + backend with stable contract)
- QA + Review on the same branch (read-only operations)

**Run sequentially when:**
- Schema → backend → frontend (each consumes the previous)
- Implementation → QA (QA needs code to test)
- Anything that touches the same files

## Re-Dispatch on Failure

If a worker reports a blocker or QA fails:
1. Master inspects the sentinel + memory output
2. Decides: re-dispatch with a corrected brief, or escalate to user
3. Clears the sentinel before re-dispatch
4. Logs the failure mode for future briefing improvements
