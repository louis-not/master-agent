# Git Discipline

## Branch Naming

`<type>/<feature-slug>` — examples:
- `feat/auto-accept-mode`
- `fix/login-401`
- `refactor/api-client`
- `chore/upgrade-compose`

## Branch Lifecycle

1. **Master creates** the branch from the project's default (`main` / `master` / `develop`) at the Plan step
2. **Dev agents commit** to the feature branch — never directly to the default branch
3. **Branch is merged** (squash, rebase, or merge per project convention) only **after Gate 3** with user approval

## Commit Format

```
<type>(<scope>): <one-line summary>

<optional body explaining why, not what>

Co-Authored-By: <agent-role>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`.

## Master's Commit Discipline

- **The Master commits, not workers.** Workers write code; Master commits after Gate 3.
- One logical change per commit. Don't bundle unrelated changes.
- Never amend a pushed commit — create a new commit instead.
- Never `--no-verify`. Fix the hook failure.
- Pass commit messages via HEREDOC to preserve formatting.
- Stage specific files by name — avoid `git add -A` / `git add .`.

## Push Rules

- **Never push without explicit user OK.** Each push asks.
- Never force-push to `main` / `master` / default branch.
- Never force-push at all without an explicit user request and a clear reason.
- Never push secrets — pre-commit check for `.env`, `credentials*`, `*.pem`, `*.key`.

## Cross-Project Coordination

When a feature touches schema + backend + frontend:
- One feature branch per project (use the same name across projects for clarity)
- Schema lands first (Gate 3 per project)
- Backend lands second
- Frontend lands third
- If rollback is needed, reverse order: frontend → backend → schema

## Destructive Ops — Always Ask First

The Master refuses to run any of these without explicit user instruction in the current conversation:

- `git reset --hard`
- `git push --force` (any branch)
- `git branch -D`
- `git clean -fd`
- Rebase that rewrites pushed history
- Dropping a remote branch
- Discarding uncommitted changes

## PR Etiquette

- Title under 70 chars; details in body
- Body sections: `## Summary`, `## Test plan` (checklist)
- Open PR only after Gate 3 + user OK
- Don't post review comments from the Master — review notes go in memory, not GitHub
