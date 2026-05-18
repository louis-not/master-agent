<!-- audience: user — worked reference runs you read to understand what real artifacts look like. The AI does not load these. -->

# Examples

Worked reference runs of the multi-agent loop. Each example is a complete set of artifacts a real run would have produced — spec, gate reports, sentinels, change-log entries, final board state, and a narrative timeline tying them together.

Use these to:

- See what "good" looks like for every artifact the protocols define.
- Stress-test the protocols against realistic edge cases (cross-worker conflict, pane loss, mid-flight user intervention).
- Bootstrap a real project by copying the artifact shapes and adapting them.

## Reference runs

- [avatar-upload/](avatar-upload/) — A multi-component feature (schema + backend + frontend). Exercises Gate 1/2/3, surfaces a backend↔frontend API contract conflict and resolves it, simulates a tmux pane loss with a resume, and handles a mid-flight user intervention.
