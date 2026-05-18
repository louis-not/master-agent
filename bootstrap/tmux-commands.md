# Tmux Bootstrap Commands

Reference commands the Master uses to manage worker sessions.

## Per-Project Configuration

Set these once per project (the Master keeps them in scope for a session):

```bash
PROJECT_ROOT=/path/to/project
FRONTEND_DIR=$PROJECT_ROOT/<frontend-subdir>
BACKEND_DIR=$PROJECT_ROOT/<backend-subdir>
SCHEMA_DIR=$PROJECT_ROOT/<schema-subdir>
```

## Spawn a Session (Idempotent)

```bash
spawn_agent() {
  local role=$1
  local cwd=$2
  if ! tmux has-session -t "agent-$role" 2>/dev/null; then
    tmux new-session -d -s "agent-$role" -c "$cwd"
    tmux send-keys -t "agent-$role" 'claude' Enter
    sleep 2  # let claude initialize
  fi
}

# Example invocations
spawn_agent product   "$PROJECT_ROOT"
spawn_agent designer  "$FRONTEND_DIR"
spawn_agent frontend  "$FRONTEND_DIR"
spawn_agent backend   "$BACKEND_DIR"
spawn_agent db        "$SCHEMA_DIR"
spawn_agent qa        "$PROJECT_ROOT"
spawn_agent reviewer  "$PROJECT_ROOT"
```

## Dispatch a Prompt

```bash
dispatch() {
  local role=$1
  local prompt=$2
  tmux send-keys -t "agent-$role" "$prompt" Enter
}
```

The Master writes self-contained prompts per the dispatch templates in each `agents/<role>.md` charter.

## Wait for Sentinel

```bash
wait_for_sentinel() {
  local sentinel=$1
  local timeout=${2:-600}   # default 10 min
  local elapsed=0
  while [ ! -f "$sentinel" ] && [ $elapsed -lt $timeout ]; do
    sleep 5
    elapsed=$((elapsed + 5))
  done
  [ -f "$sentinel" ]
}

# Example
wait_for_sentinel "$PROJECT_ROOT/memory/.ready-product" 600
```

The Master does NOT poll panes for completion — only sentinel files.

## Read Sentinel Status

```bash
cat "$PROJECT_ROOT/memory/.ready-qa"
# STATUS=pass
# NOTES=all 12 criteria pass; 2 flaky tests retried
```

## Clear Sentinel Before Re-Dispatch

```bash
rm -f "$PROJECT_ROOT/memory/.ready-<role>"
```

**Always** clear before dispatch so a stale sentinel from a prior run doesn't fool the Master.

## Capture Pane (Debugging Only)

```bash
tmux capture-pane -t agent-<role> -p -S -300
```

Use only when:
- Sentinel hasn't appeared past timeout
- Agent reported a blocker and the Master needs detail

Never use as source of truth.

## List / Kill Sessions

```bash
tmux ls | grep '^agent-'
tmux kill-session -t agent-<role>
tmux kill-server  # nuclear — kills all sessions, use sparingly
```

## Sanity Checks Before Dispatch

Run these in order before every dispatch:

1. **Session exists?**
   `tmux has-session -t agent-<role>`
2. **Claude is at a prompt?**
   `tmux capture-pane -t agent-<role> -p -S -20` and look for the prompt indicator
3. **Sentinel is cleared?**
   `[ ! -f "$PROJECT_ROOT/memory/.ready-<role>" ]`
4. **Project root has expected memory files?**
   `ls "$PROJECT_ROOT/memory/MEMORY.md"`

If any check fails, the Master fixes it before dispatching — not after.

## Failure Recovery

| Symptom | Likely cause | Recovery |
|---|---|---|
| `has-session` returns no | Session died or never started | Re-spawn via `spawn_agent` |
| Sentinel never appears | Agent hung or task too large | Capture pane, diagnose, possibly kill + respawn |
| Sentinel STATUS=block | Agent hit a blocker | Read agent's notes; re-brief with corrected info or escalate |
| Pane shows error loop | Repeated tool failures | Send `/clear` to reset context, re-brief |
| Multiple agents block on same file | Coordination breakdown | Master serializes work, re-dispatches |
