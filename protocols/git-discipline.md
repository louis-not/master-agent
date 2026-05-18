<!-- audience: ai+user — the Master obeys this; users read it to know what branch and commit shape to expect. -->

# Git Discipline

Only rules specific to this multi-agent setup. Standard git safety (no force-push without reason, no `--no-verify`, ask before destructive ops, never push secrets) is assumed.

## Branch naming

`<type>/<feature-slug>` — `feat/`, `fix/`, `refactor/`, `docs/`, `test/`, `chore/`, `perf/`.

## Who commits

**The Master commits, not workers.** Workers write code on the feature branch; the Master commits after Gate 3 with explicit user approval.

## Commit message

```
<type>(<scope>): <one-line summary>

<optional body — why, not what>

Co-Authored-By: <agent-role>
```

One logical change per commit. Pass messages via HEREDOC to preserve formatting. Stage specific files by name — avoid `git add -A` / `git add .`.

## Pushing

- **No push without explicit user OK**, every time.
- Never force-push the default branch.

## Cross-project ordering

When a feature spans schema + backend + frontend:
- Use the same branch name in each project for clarity.
- Land in order: schema → backend → frontend.
- Roll back in reverse: frontend → backend → schema.
