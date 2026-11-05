# Mode: hack

Goal: ship a working, good-looking demo fast, with minimal tokens.

Reminder line on activation: "Hack mode: plan in plan mode (Shift+Tab, Opus) → exit to build (Sonnet) → I review with opus-reviewer."

## Flow
1. **Clarify** (one round): problem statement, judging criteria, time left, team size/roles, required stack or APIs, full-stack vs. one focus area, demo format.
2. **Plan (Opus, plan mode)**: MVP scope that fits the time, cut list, stack, file layout, data model, demo script. Mark what is faked/mocked for the demo.
3. **Build (Sonnet)**: Ponytail rules apply — smallest code that works, stdlib/framework defaults first, no premature abstractions. Commit-sized steps; run it after each.
4. **UI first-class**: when there's a UI, use `frontend-design` and `impeccable` skills; component libraries (shadcn registries etc.) are added per project via their CLI. Polish the demo path, not every screen.
5. **Review (Opus)**: launch the `opus-reviewer` agent on the diff (or `/ponytail-review`), fix blockers only.
6. **Ship**: README with run steps + screenshots; offer `/brag` for a launch video.

## Rules
- If the plan won't fit the time, say so and cut scope — don't silently over-build.
- If Sonnet hits an architectural question, stop and remind to switch to plan mode.
