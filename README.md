# Master Agent — Multi-Agent Orchestration Template

A project-agnostic template for running a software project with **one master Claude orchestrator** and a roster of specialized subagents in persistent `tmux` sessions.

## The Idea

You talk only to the **Master**. The Master dispatches **specialized agents** (Product, Design, Frontend, Backend, DB, QA, Review) running in their own `tmux` sessions, coordinates them through shared memory files and git, and checks in with you at defined gates.

Subagents never address you directly. State lives on disk (memory + git), not in chat.

## Structure

- [agent.md](agent.md) — Master orchestrator charter (start here)
- [agents/](agents/) — Per-role charters (Product, Designer, Frontend, Backend, DB, QA, Reviewer)
- [protocols/](protocols/) — Communication, lifecycle, memory, git rules
- [bootstrap/](bootstrap/) — Tmux commands the Master uses to spawn/dispatch/capture
- [templates/](templates/) — Empty memory file scaffolds (`MEMORY.md`, `change_logs.md`, `feature_status.md`)

## Applying to a New Project

1. Copy this directory into the target project as `agent-orchestrator/` (or symlink it).
2. Drop a pointer in the project's `CLAUDE.md`:
   ```markdown
   ## Agent Orchestration
   Master orchestrator charter at `agent-orchestrator/agent.md`. Subagents in `agent-orchestrator/agents/`.
   ```
3. For each subproject (frontend, backend, schema, etc.), create a `memory/` directory and seed it from `templates/`.
4. Open Claude Code at the project root and ask it to read `agent-orchestrator/agent.md`. From there, you talk only to that session — it becomes the Master.

## When This Pays Off

- Multi-component projects (frontend + backend + db) where roles map cleanly to subagents
- Long-running workstreams where you want persistent context across conversations
- Cases where you want the Master to keep an audit trail (memory + git) of every decision

## When To Skip This

- One-shot tasks — use Claude Code's built-in `Agent` tool, not tmux. Cheaper, cleaner, no auth overhead.
- Solo, single-component projects — the orchestration overhead exceeds the benefit.

## Trade-Offs

- Each tmux-claude is a **separate auth/billing session**. Spawn lazily, retire idle.
- Inter-agent state via files is **eventually consistent** — the Master waits on sentinel files, not pane scraping.
- Tmux sessions are fragile to terminal restarts; the Master must be able to respawn and re-brief from memory.
