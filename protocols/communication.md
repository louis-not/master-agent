# Communication Protocol

## Three channels, three rules

1. **User ↔ Master** — the only conversational channel.
2. **Master → Worker** (tmux dispatch) — self-contained prompts sent via `tmux send-keys`. The worker has no conversation context.
3. **Worker → Master** (file substrate) — workers write to memory files and emit a sentinel file. The Master reads files, not panes.

Workers never message each other. The Master is the only coordinator.

## Tmux Topology

- One persistent session per role, named `agent-<role>`
- Each session runs the `claude` CLI in the role's working directory
- Sessions persist across user conversations; the Master spawns lazily and retires on long idle

## Dispatch Format

```bash
tmux send-keys -t agent-<role> 'PROMPT' Enter
```

Every dispatch prompt MUST include:
1. The agent's charter file to read (`agent-orchestrator/agents/<role>.md`)
2. Project memory files to read first (`memory/MEMORY.md` + topic-specific files)
3. The task in one paragraph
4. The expected output location (specific file path)
5. The completion sentinel to write
6. Explicit "report blockers — do not guess" language

## Sentinel Files

Workers signal completion by creating a sentinel file:

```
<project>/memory/.ready-<role>
```

Sentinels may contain status:

```
STATUS=pass|fail|block|approve|done
NOTES=<one-line summary>
```

The Master watches for sentinel files, not for pane text. Pane text is for debugging hung agents only.

## Capture (Debugging Only)

```bash
tmux capture-pane -t agent-<role> -p -S -300
```

Use only when:
- A sentinel hasn't appeared in the expected time window
- An agent reported a blocker and the Master needs detail
- Investigating a failure

**Never** use pane capture as the source of truth for what an agent produced. Memory files + sentinels are.

## Briefing Discipline

A bad brief produces shallow work. Every dispatch:
- States the goal in one sentence
- Lists what's already known or ruled out
- Gives enough context for judgment calls
- Names file paths and line numbers when applicable
- Caps the response when verbose output isn't needed ("cap at 200 words")

Never delegate understanding to the worker. The Master synthesizes; the worker executes.

## Clearing Sentinels

Always clear before re-dispatch so a stale sentinel from a prior run doesn't fool the Master:

```bash
rm -f "$PROJECT_ROOT/memory/.ready-<role>"
```
