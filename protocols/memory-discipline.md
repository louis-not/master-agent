# Memory Discipline

## What Each File Is For

| File | Lives at | Owns | Updated by |
|---|---|---|---|
| `MEMORY.md` | `<project>/memory/MEMORY.md` | Index of all memory files in that project | Master + responsible agent |
| `change_logs.md` | `<project>/memory/change_logs.md` | Append-only log of modifications | The agent that made the change |
| `feature_status.md` | `<project>/memory/feature_status.md` | Planned / in-progress / done features with acceptance criteria | Product agent + Master |
| Topic memory (e.g. `design_system.md`, `endpoints.md`, `models.md`, `architecture.md`) | `<project>/memory/<topic>.md` | Detailed state of that subsystem | The agent that owns the topic |

## Rules

1. **One change, one log entry.** Every code modification produces a `change_logs.md` entry.
2. **Update the index.** Adding a new memory file requires adding an entry to `MEMORY.md`.
3. **Memory is not chat history.** Don't record conversations — record decisions, structure, and constraints.
4. **Memory mirrors code, not intent.** If memory contradicts code, code wins; reconcile by updating memory.
5. **No duplicates.** Before creating a new memory file, search for an existing one to update.
6. **Keep `MEMORY.md` under 200 lines.** Index lines should be one short line each.

## Change Log Entry Format

```markdown
## YYYY-MM-DD — <one-line summary>
- Agent: <role>
- Files: <list of paths>
- Why: <one-paragraph rationale>
- Memory updates: <list of memory files updated, or "none">
```

Append newest at the top.

## Feature Status Entry Format

```markdown
## <feature-name>
- Status: planned | in-progress | done | blocked
- Owner agents: <list>
- User story: As a <role>, I want <X> so that <Y>.
- Acceptance criteria:
  - [ ] criterion 1
  - [ ] criterion 2
- Open questions: <list, or "none">
- Branch: <branch name when in-progress>
```

## Memory Index Format

```markdown
- [Title](filename.md) — one-line hook
```

One line per memory file. Group by topic if many files; otherwise alphabetical.

## What NOT to Put in Memory

- Code patterns derivable by reading the codebase
- Git history / who-changed-what (use `git log`)
- Debugging recipes (the fix is in the code; the commit has the context)
- Transient task state (use `feature_status.md` for in-progress, not free-form notes)
- Anything duplicated in the project's `CLAUDE.md`
