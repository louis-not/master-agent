<!-- audience: user — humans set up and operate the template; the AI does not load this file. -->

# Master Agent — Multi-Agent Orchestration Template

A project-agnostic template for running a software project with **one Master Claude orchestrator** and a roster of specialized subagents in persistent `tmux` sessions.

## The idea

You talk only to the **Master**. The Master writes the spec, dispatches **specialized agents** (Frontend, Backend, DB, QA, Reviewer) running in their own `tmux` sessions, tracks each feature on a **kanban board**, coordinates work through memory files + git, and checks in with you at three gates.

Subagents never address you directly. State lives on disk (the board, memory files, git) — not in chat.

## File audience map

Every markdown file in this repo has an `<!-- audience: ... -->` banner at the top. The taxonomy:

- **`user`** — humans read or run this. The AI does not load it into context.
- **`ai`** — Claude (Master or worker) loads this as part of its operating context. Humans rarely need to read it.
- **`ai+user`** — both. Loaded by Claude during execution; read by humans during onboarding or debugging.

| Path | Audience | When you (the user) touch it |
|---|---|---|
| [README.md](README.md) | `user` | Once, when setting up the template |
| [install.sh](install.sh) | `user` | Once, to verify host dependencies |
| [agent.md](agent.md) | `ai+user` | The Master loads it every run. You read it during onboarding to understand the system, or when debugging. |
| [agents/](agents/) | `ai` | Each worker loads its own charter. You can skim during onboarding but don't edit casually — workers depend on the wording. |
| [protocols/substrate.md](protocols/substrate.md) | `ai+user` | The Master obeys it. You consult it when something on disk looks wrong (sentinel format, memory layout). |
| [protocols/lifecycle.md](protocols/lifecycle.md) | `ai+user` | The Master obeys it. You read it to understand gate reports, conflict resolution, worker resume, and intervention rules. |
| [protocols/git-discipline.md](protocols/git-discipline.md) | `ai+user` | The Master obeys it. You read it to know what branch/commit shape to expect. |
| [templates/](templates/) | `user` | You copy these into your project once per setup. The Master populates the copies. |
| [scripts/agent-status](scripts/agent-status) | `user` | You run it any time you want an at-a-glance view of the loop. |
| [examples/](examples/) | `user` | You read these to see what real artifacts (sentinels, gate reports, change logs) look like. |

The artifacts the Master produces at runtime (gate reports, sentinels, populated `change_logs.md`, `board.md` cards) are written for **both** audiences — they are the conversation between you and the system.

## Structure

- [agent.md](agent.md) — Master orchestrator charter (start here)
- [agents/](agents/) — Per-role charters (Frontend, Backend, DB, QA, Reviewer)
- [protocols/substrate.md](protocols/substrate.md) — tmux topology, sentinel contract, memory layout
- [protocols/lifecycle.md](protocols/lifecycle.md) — kanban columns, gates, conflict resolution, worker resume, intervention contract
- [protocols/git-discipline.md](protocols/git-discipline.md) — branch/commit rules
- [templates/](templates/) — Skeletons for `board.md`, per-project `MEMORY.md`, and `change_logs.md`
- [scripts/agent-status](scripts/agent-status) — At-a-glance inspection of the running loop
- [examples/](examples/) — Worked reference runs
- [install.sh](install.sh) — Dependency check for git, tmux, and the `claude` CLI

## Requirements

The orchestrator depends on three host tools:

- **git** — Master and subagents commit through it
- **tmux** — Subagents run in persistent panes the Master spawns and dispatches to
- **claude** — The CLI the Master launches inside each tmux session ([install docs](https://docs.claude.com/claude-code))

Verify them with the bundled script:

```bash
./install.sh             # check only
./install.sh --install   # attempt to install missing git/tmux via brew/apt/dnf/pacman
```

The `claude` CLI is not handled by system package managers — install it separately with `npm i -g @anthropic-ai/claude-code`.

## Applying to a new project

1. Copy this directory into the target project as `agent-orchestrator/` (or symlink it).
2. Drop a pointer in the project's `CLAUDE.md`:
   ```markdown
   ## Agent Orchestration
   Master orchestrator charter at `agent-orchestrator/agent.md`. Subagents in `agent-orchestrator/agents/`.
   ```
3. Copy `templates/board.md` to `agent-orchestrator/board.md` — the global kanban.
4. For each subproject (frontend, backend, schema, etc.), create a `memory/` directory and seed it from the per-project templates (`MEMORY.md`, `change_logs.md`).
5. Open Claude Code at the project root and ask it to read `agent-orchestrator/agent.md`. From there, you talk only to that session — it becomes the Master.

## When this pays off

- Multi-component projects (frontend + backend + db) where roles map cleanly to subagents.
- Long-running workstreams where you want persistent context across conversations.
- Cases where you want an audit trail (kanban + memory + git) of every decision.

## When to skip this

- One-shot tasks — use Claude Code's built-in `Agent` tool, not tmux. Cheaper, cleaner, no auth overhead.
- Solo, single-component projects — the orchestration overhead exceeds the benefit.

## Trade-offs

- Each tmux-claude is a **separate auth/billing session**. Spawn lazily, retire idle.
- Inter-agent state via files is **eventually consistent** — the Master waits on sentinel files, not pane scraping.
- Tmux sessions are fragile to terminal restarts; the Master must be able to respawn and re-brief from memory.
