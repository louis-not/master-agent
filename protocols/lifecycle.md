# Lifecycle

A feature moves left-to-right across the kanban board (`board.md`). The Master moves the card; sentinels gate the moves.

## Columns

| Column | Entered when | Exited when |
|---|---|---|
| **Plan** | Master creates the card from a user brief | Product sentinel arrives; spec is on the card or in linked topic memory |
| **Design** | Card needs UI work (skip otherwise) | Designer sentinel arrives; screen spec is written |
| **Develop** | Spec approved at Gate 2; branch created | All required dev sentinels arrive (db, backend, frontend) |
| **Test & Review** | Dev sentinels in | QA sentinel + Reviewer sentinel both arrive |
| **Ship** | Gate 3 passed; user OK'd commit/push | Code lands on the target branch |
| **Done** | Lands on target (dev or prod) | (terminal) |
| **Blocked** | Any column flips a card here when stuck | Master unblocks (re-brief or escalate) |

## Flow

1. **Intake.** Master writes a one-paragraph brief and creates the card in **Plan**.
2. **Gate 1 — Interpretation.** Master confirms the brief with the user.
3. **Product.** Dispatch `agent-product`. Spec lands in the card or linked topic memory.
4. **Design (if UI).** Dispatch `agent-designer`. Card → **Design** → done.
5. **Gate 2 — Spec.** Master shows product + design output. User approves or redirects. *(Cheapest gate to fail; spend it here, not later.)*
6. **Branch.** Master creates the feature branch. Card → **Develop**.
7. **Implement.** Dispatch dev agents:
   - DB first if schema changes (others wait on its sentinel).
   - Backend next if API changes (frontend waits on the contract).
   - Frontend in parallel with backend once the contract is stable.
8. **Test & Review.** Once all dev sentinels are in, dispatch QA + Reviewer in parallel. Card → **Test & Review**.
9. **Gate 3 — Pre-land.** Master reports QA + reviewer outcome. User OK's commit / push.
10. **Ship.** Master commits per [git-discipline.md](git-discipline.md). Card → **Ship**. Push only with explicit user OK.
11. **Done.** After landing on the target branch, card → **Done**. Verify `change_logs.md` and memory indexes are current.

## Parallelism

- **Parallel:** independent components (frontend + backend with stable contract); QA + Reviewer (both read-only).
- **Sequential:** schema → backend → frontend; implementation → QA; anything touching the same files.

## When a card moves to Blocked

- Worker sentinel returns `STATUS=block`.
- Ambiguity not resolvable from existing memory.
- External-system side effect needed (push, deploy, send message, post to PR).
- Hung agent (no sentinel past threshold + no pane activity).
- Schema migration on a populated table, credential change, or other destructive op surfaced mid-work.

QA `STATUS=fail` usually sends the card back to **Develop** with a note — not to **Blocked**, unless the fix path is unclear.

## Re-dispatch on failure

1. Inspect the sentinel + the memory the worker wrote.
2. Decide: corrected brief, or escalate to user.
3. Clear the sentinel.
4. Re-dispatch.
