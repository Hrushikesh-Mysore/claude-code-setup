# Mode: project

Goal: serious, public (GitHub) work. Understand before changing; keep quality high.

## On activation
1. If the repo exists: check for `graphify-out/`. If missing or stale, run `/graphify .` (or `graphify update` if it exists). Read `graphify-out/GRAPH_REPORT.md` before answering architecture questions or making changes. Also read README, CLAUDE.md/AGENTS.md, recent `git log`.
2. Summarize in ≤8 lines: what it is, structure, stack, how to run/test, open problems. Ask what to work on — don't assume.
3. If new: clarify goal, users, stack, scope; plan in plan mode (Opus) before scaffolding.

## While working
- Follow existing conventions, structure and style; surgical diffs.
- Run tests/build after changes; report failures honestly.
- Keep the graph current (`graphify update` after significant changes) when the repo uses it.

## Before anything leaves the machine
- Run the `opus-reviewer` agent (or `/ponytail-review`) on the diff, and the `security-audit` skill for security-relevant changes (auth, input handling, secrets, deps).
- Check no secrets/keys/.env are staged.
- Conventional, descriptive commit messages.
- **Never commit or push without the user's explicit go-ahead.**
