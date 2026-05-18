<!-- audience: user — humans set up and operate the template; the AI does not load this file. -->

# Master Agent — Multi-Agent Orchestration Template

A project-agnostic template for running a software project with **one Master Claude orchestrator** and a roster of specialized subagents in persistent `tmux` sessions.

## The idea

You primarily talk to the **Master**. The Master writes the spec, dispatches **specialized agents** (Frontend, Backend, DB, QA, Reviewer) running in their own `tmux` sessions, tracks each feature on a **kanban board**, coordinates work through memory files + git, and checks in with you at three gates.

State lives on disk (the board, memory files, git) — not in chat. The Master is the one entity with cross-component visibility; workers are tunnel-vision specialists that only see what their dispatch brief contains.

## How you interact with the loop

You have several surfaces, from lightest-weight observation to most direct intervention. Pick the one that matches what you're trying to do:

- **`scripts/agent-status`** — one command, dense output: kanban state, live tmux sessions, latest sentinel of each worker, head entry of each `change_logs.md`. This is your at-a-glance dashboard.
- **Per-component `memory/change_logs.md`** — append-only decision records. `git log -p memory/` reconstructs the entire decision history of a component without opening the code.
- **Gate reports** — the Master writes one at each of the three gates (Interpretation, Spec, Pre-land). They surface decisions, cross-worker disagreements, and open questions; this is where you approve or redirect.
- **Mediated intervention (talk to the Master)** — the recommended path for scope changes, spec amendments, anything you want recorded as a deliberate decision. The Master writes the change into the spec, interrupts the affected worker, and re-dispatches.
- **Direct pane interaction (`tmux attach -t agent-<role>`)** — a documented power-user channel, described in detail below.

### Direct pane interaction (power-user channel)

The Master-mediated path is not the only way in. The technical user MAY attach to any worker's pane and talk to the worker directly. Use it when:

- You want real-time clarification on a guess the worker is making *right now*.
- You want to paste an error log, screenshot, or context the Master couldn't easily inline.
- You want to course-correct a small implementation choice without touching the spec.
- You just want to read what the worker is doing (read-only attach is always fine).

```bash
tmux attach -t agent-frontend    # attach to the Frontend worker's pane
# type at the worker as you would in any Claude Code session
Ctrl-b d                          # detach when done; the worker keeps running
```

**Rules** (so direct input doesn't desync the Master):

- The worker is briefed to **echo the exchange back** in its next sentinel under `USER_PANE_INPUT` — summary of what you said and how it incorporated the input. The Master treats this as first-class input at the next gate.
- You **should also mention the intervention to the Master** at the next gate ("I told `agent-frontend` to reuse the existing `Avatar` component"). Defense in depth: if the worker forgets, your report still keeps the Master's view consistent.
- A few pane-level actions stay off-limits because they would corrupt the substrate:
  - Don't manually write a worker's sentinel file — let the worker write it.
  - Don't ask a worker to commit or push — that remains the Master's job after Gate 3.
  - Don't ask a worker to skip its `change_logs.md` entry — every accepted change must be logged.
  - Don't direct a worker to edit a component it does not own (don't tell Frontend to edit Backend).
  - Don't transition kanban cards yourself — the Master owns the board.

If you find yourself wanting to make the *same* clarification across multiple workers or multiple runs, that's a sign the spec is wrong — fix it in the spec via the Mediated path so future runs don't need the same intervention.

The full contract is in [protocols/lifecycle.md § User intervention contract](protocols/lifecycle.md#user-intervention-contract). The `USER_PANE_INPUT` sentinel field is defined in [protocols/substrate.md § Sentinels](protocols/substrate.md#sentinels).

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
