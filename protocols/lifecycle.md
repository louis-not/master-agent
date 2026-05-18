<!-- audience: ai+user — the Master obeys this; users read it to understand gates, conflict resolution, worker resume, and the intervention contract. -->

# Lifecycle

A feature moves left-to-right across the kanban board (`board.md`). The Master moves the card; sentinels gate the moves.

## Columns

| Column | Entered when | Exited when |
|---|---|---|
| **Plan** | Master creates the card from a user brief; writes the spec | Spec approved at Gate 2 |
| **Develop** | Branch created | All required dev sentinels arrive (db, backend, frontend) |
| **Test & Review** | Dev sentinels in | QA sentinel + Reviewer sentinel both arrive |
| **Ship** | Gate 3 passed; user OK'd commit/push | Code lands on the target branch |
| **Done** | Lands on target (dev or prod) | (terminal) |
| **Blocked** | Any column flips a card here when stuck | Master unblocks (re-brief or escalate) |

Frontend handles design thinking (screen flow, component breakdown, design-system updates) inside its Develop work — there is no separate Design column.

## Flow

1. **Intake.** Master writes a one-paragraph brief and creates the card in **Plan**.
2. **Gate 1 — Interpretation.** Master confirms the brief with the user.
3. **Spec.** Master writes `<project>/memory/specs/<feature>.md`: user story, acceptance criteria, affected components, open questions. No dispatch — the Master owns this.
4. **Gate 2 — Spec.** Master shows the spec. User approves or redirects. *(Cheapest gate to fail; spend it here, not later.)*
5. **Branch.** Master creates the feature branch. Card → **Develop**.
6. **Implement.** Dispatch dev agents:
   - DB first if schema changes (others wait on its sentinel).
   - Backend next if API changes (frontend waits on the contract).
   - Frontend in parallel with backend once the contract is stable. Frontend's brief includes the relevant design-system pointers and the API contract — Frontend does not need to read other components.
7. **Test & Review.** Once all dev sentinels are in, dispatch QA + Reviewer in parallel. Card → **Test & Review**.
8. **Gate 3 — Pre-land.** Master reports QA + reviewer outcome. User OK's commit / push.
9. **Ship.** Master commits per [git-discipline.md](git-discipline.md). Card → **Ship**. Push only with explicit user OK.
10. **Done.** After landing on the target branch, card → **Done**. Verify `change_logs.md` and memory indexes are current.

## Gate reports

The gate report is the user-facing artifact for each gate. It is the *only* place the user is asked to approve or redirect, so it must surface decisions and dissent — not a transcript of what each worker did.

Every gate report has the same shape:

```
# Gate <n> — <name> — <feature-slug>

## What's being approved
<one paragraph: scope of this gate, in user terms>

## Decisions made since last gate
- <agent>: <decision> — <one-line why> (alt: <X>)
- ...

## Disagreements reconciled
- <where workers diverged> → <how Master resolved> (or: none)

## Open questions for you
- <ambiguity from sentinel AMBIGUITIES, mapped to a yes/no or A/B question>
- ... (or: none)

## What happens if you approve
- <concrete next steps the Master will take>
```

Per-gate specifics:

- **Gate 1 — Interpretation.** "What's being approved" = the brief. Decisions are usually empty (no agents have run yet). Open questions are clarifications the Master could not resolve from memory.
- **Gate 2 — Spec.** "What's being approved" = the spec written to `<project>/memory/specs/<feature>.md`. The Master writes the spec directly (no agent dispatch). Decisions are the Master's interpretation choices; open questions are spec ambiguities the Master could not resolve from existing memory.
- **Gate 3 — Pre-land.** "What's being approved" = commit + (optionally) push. Decisions span all dev agents' DECISIONS blocks. Disagreements are where Backend/Frontend/DB diverged on contracts and how the Master reconciled. Open questions include reviewer's Blocking and Suggestions buckets and QA's pass/fail per criterion.

Keep gate reports under one screen where possible. Link to memory files for detail rather than inlining; the user can drill down if they want.

## Parallelism

- **Parallel:** independent components (frontend + backend with stable contract); QA + Reviewer (both read-only).
- **Sequential:** schema → backend → frontend; implementation → QA; anything touching the same files.

## When a card moves to Blocked

- Worker sentinel returns `STATUS=block`.
- Ambiguity not resolvable from the spec or existing memory.
- External-system side effect needed (push, deploy, send message, post to PR).
- Hung agent (no sentinel past threshold + no pane activity).
- Schema migration on a populated table, credential change, or other destructive op surfaced mid-work.

QA `STATUS=fail` usually sends the card back to **Develop** with a note — not to **Blocked**, unless the fix path is unclear.

## Re-dispatch on failure

1. Inspect the sentinel + the memory the worker wrote.
2. Decide: corrected brief, or escalate to user.
3. Clear the sentinel.
4. Re-dispatch.

## Conflict resolution between workers

Cross-component disagreement is the most common silent failure mode: Backend ships endpoint `POST /v1/foo`, Frontend's brief contained an earlier draft saying `POST /foo`, neither knows the other is wrong until Gate 3 (or production).

**Detection.** When dev sentinels arrive, the Master diffs them against each other before moving the card to Test & Review:

- Compare `FILES_TOUCHED` across workers — any shared file is a flag.
- Compare API contracts: the contract the Backend wrote (in its sentinel DECISIONS or its endpoints memory) against the contract the Frontend was briefed with.
- Compare schema deltas the DB shipped against assumptions in Backend's DECISIONS.
- Check each worker's `AMBIGUITIES` for items that should have been resolved by another worker's output.

**Resolution loop** (do not jump straight to user):

1. Identify the divergence in one sentence. Write it into the spec file as `## Reconciliation <timestamp>`.
2. Decide which side wins based on the spec, security, or backward compatibility — in that order.
3. Clear the losing side's sentinel. Re-dispatch with an addendum brief: original brief + "your prior output assumed X; the correct contract is Y, source: <pointer>; rework only what depends on this".
4. The winning worker is not re-dispatched but the Master appends a `## Cross-worker context` note to the winner's change_logs entry so the decision is recorded.

**Escalate to user** only if:

- The spec is silent on the disputed point.
- Both sides have shipped destructive work that would need rollback to converge.
- The divergence implies a spec change, not just an implementation correction.

The Gate 3 report's "Disagreements reconciled" section names every divergence detected, even if resolved silently — transparency is the point.

## Worker resume after pane loss

Tmux sessions die: terminal restart, OOM, accidental `tmux kill-session`. The Master must be able to respawn a worker and resume mid-feature without re-doing committed work or losing in-flight decisions.

**Detection.** A worker is considered lost when: its tmux session no longer exists, OR its pane shows the shell prompt with no claude process. The sentinel may or may not exist (it exists if work completed before the crash; it doesn't if the crash interrupted work).

**Resume brief contract.** When re-spawning a lost worker, the dispatch brief must be the standard brief plus three extra blocks:

```
## Resume context — you are resuming mid-feature, not starting fresh

Prior sentinel (may be absent if you crashed before writing one):
<paste the sentinel contents, or "none — crashed before completion">

Last change_logs.md entry you wrote (may be absent):
<paste the top entry of your component's change_logs.md if its agent field matches you>

Files already committed by you on this branch:
<git diff --name-only $base..HEAD, filtered to your component>

Do not redo work that is already committed. If the prior sentinel marked done,
your job is to address the addendum below; otherwise, complete the original
brief from where the change_logs entry left off.
```

If no prior sentinel and no change_logs entry exist, the worker is treated as a fresh dispatch — no resume context needed. If only a partial change_logs entry exists, the Master inlines it verbatim and asks the worker to continue.

**The Master never tries to recover the worker's chat history.** That context is gone. Memory files and git history are the substrate for resumption — by design.

## User intervention contract

The user has exactly one canonical way to redirect work: **talk to the Master**. The Master is the only entity that can write briefs, clear sentinels, and re-dispatch.

**Mid-flight redirect** (user wants to change direction while a worker is running):

1. User tells the Master what to change.
2. Master writes the addendum into the relevant spec or memory file (so the change is durable, not just in the brief).
3. Master interrupts the worker (`tmux send-keys` of `Ctrl-C` or `/clear` as appropriate for the worker's state).
4. Master clears the sentinel.
5. Master re-dispatches with the standard brief + an `## Addendum <timestamp>` block naming what changed and why.
6. Master appends a `## User intervention <timestamp>` note to the feature's spec file so the audit trail captures that the redirect was user-driven, not Master-driven.

**Pane-attach is debug only.** A user *can* `tmux attach -t agent-frontend` and read what the worker is doing. Typing into that pane is forbidden under the protocol — it creates an out-of-band channel the Master cannot see, and the Master's state will diverge from reality. If the user finds themselves wanting to type into a pane, that is a signal that the Master is not exposing the right intervention surface; treat it as a bug in the brief or gate report, not as a workaround.

**Aborting a feature.** User tells the Master "stop work on `<feature>`". Master interrupts all live workers on that feature, clears their sentinels, moves the card to **Blocked** with a `Why blocked: user-aborted <timestamp>` line, and waits for further instruction. No code is reverted unless the user explicitly asks — the branch is left as-is for later inspection.
