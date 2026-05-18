<!-- audience: ai+user — the Master obeys this; users read it when something on disk looks wrong (sentinel format, memory layout). -->

# Substrate

How the Master talks to workers and how state persists.

## Channels

1. **User ↔ Master** — the only conversational channel.
2. **Master → Worker** — `tmux send-keys` with self-contained prompts. Workers have no chat context.
3. **Worker → Master** — workers write to memory files and drop a sentinel. Master reads files, not panes.

Workers never message each other.

## Tmux sessions

One persistent session per role, named `agent-<role>`, running `claude` in the role's working directory. Spawn lazily, retire on long idle. Pane capture is debugging-only — never a source of truth.

## Sentinels

Workers signal completion by creating a sentinel file:

```
<project>/memory/.ready-<role>
```

The sentinel is the worker → Master handoff record. It must carry enough signal that the Master never needs to scrape the pane or guess. Format (key=value, one per line; multi-line values use `<<<` … `>>>` fences):

```
STATUS=done|pass|fail|block|approve
SUMMARY=<one line — what the worker actually accomplished>
DECISIONS=<<<
- <choice made> — <why> (alt considered: <X>)
- ...
>>>
AMBIGUITIES=<<<
- <thing the worker had to guess or punt on, for Master to resolve>
- ... (or: none)
>>>
FILES_TOUCHED=<<<
- <path>
- ...
>>>
NEXT_SUGGESTED=<optional one-liner pointing at what should happen next, or: none>
```

Rules:

- **DECISIONS is non-optional for non-trivial work.** A `done` sentinel with no decisions is a smell — either the work was trivial (say so in SUMMARY) or the worker didn't surface what it chose.
- **AMBIGUITIES is the worker's escape hatch.** Anything guessed must appear here so the Master can confirm with the user at the next gate. Empty only if the brief was exhaustively unambiguous.
- **FILES_TOUCHED enables async inspection** — `git diff` against this list tells the story without re-reading the brief.
- `STATUS=block` requires `AMBIGUITIES` to name the blocker; the Master cannot unblock from a one-line note.
- `STATUS=fail` (QA only) requires `DECISIONS` to enumerate which acceptance criteria failed and the evidence (test name, output).

The Master:

- Always **clears the sentinel** before re-dispatching.
- Watches for the file's appearance — not pane text.
- Reads the full sentinel, then opens the memory files the worker wrote.
- Treats `DECISIONS` + `AMBIGUITIES` as the primary input to the next gate report — these are what the user needs to see.

## Worker focus

Workers are tunnel-visioned. Each worker sees only:

- Its dispatch brief (one paragraph + everything the Master decided is relevant).
- Its charter (`agents/<role>.md`).
- The topic-memory files the Master named in the brief.
- Its own component's source code and `change_logs.md` (Backend doesn't read Frontend's, etc.).

Workers do **not** read `board.md`, `MEMORY.md` indexes, other workers' charters, other workers' sentinels, or other components' memory. If a worker needs information from another component, the Master extracts it and inlines it in the brief — the worker never fishes.

The Master is the only entity with cross-component visibility.

## Briefing discipline

Every dispatch prompt MUST include:

1. The worker's charter file path.
2. The specific topic-memory files (already chosen by the Master) the worker should read — by absolute or project-relative path. Do not send a worker to browse.
3. The task in one paragraph, with any cross-component context already inlined (API contracts, schema deltas, design tokens — whatever the worker needs that doesn't live in its own component).
4. The expected output location (specific file path).
5. The completion sentinel to write.
6. Explicit "report blockers — do not guess" language.

A bad brief produces shallow work. The Master synthesizes context; the worker executes. Never delegate understanding.

## Memory layout

| File | Lives at | Owns | Updated by |
|---|---|---|---|
| `board.md` | `<orchestrator>/board.md` | Kanban of all features across all components | Master only |
| `MEMORY.md` | `<project>/memory/MEMORY.md` | Index of that project's memory files | Master + owning agent |
| `change_logs.md` | `<project>/memory/change_logs.md` | Append-only modification log | The agent making the change |
| Topic memory | `<project>/memory/<topic>.md` | Detailed state of a subsystem (architecture, endpoints, design system, etc.) | Owning agent |

Rules:

- **One change, one log entry.** Newest at top.
- **Memory mirrors code.** If memory contradicts code, code wins — reconcile.
- **No duplicates.** Search existing memory before adding a new file.
- **MEMORY.md stays under 200 lines** — it's an index, not content.
- **Don't record chat.** Record decisions, structure, and constraints.

### change_logs.md entry format

Each entry is a decision record, not a diff summary. `git diff` already tells you what changed; the log tells you *why* and what else was considered.

```
## YYYY-MM-DD HH:MM — <feature-slug> — <agent-role>
- Files: <paths, comma-separated>
- Decision: <one sentence — what was done>
- Why: <one or two sentences — the motivating constraint, spec line, or prior decision>
- Alternative considered: <what else was on the table and why it lost — or: none>
- Follow-ups: <bullets for things deferred — or: none>
```

Entries are append-only at the top. If a later change reverts or supersedes an earlier one, write a new entry that names the prior entry's timestamp; do not edit the prior entry. A reader scanning `git log -p memory/change_logs.md` should be able to reconstruct the project's decision history without opening the code.
