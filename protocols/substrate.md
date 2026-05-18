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

Contents:

```
STATUS=pass|fail|block|approve|done
NOTES=<one-line summary>
```

The Master:
- Always **clears the sentinel** before re-dispatching.
- Watches for the file's appearance — not pane text.
- Reads STATUS + NOTES, then reads the memory files the worker wrote.

## Briefing discipline

Every dispatch prompt MUST include:

1. The worker's charter file path.
2. Project memory files to read first (`memory/MEMORY.md`, the board card, topic memory).
3. The task in one paragraph.
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
