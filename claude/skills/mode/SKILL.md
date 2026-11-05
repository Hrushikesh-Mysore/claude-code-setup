---
name: mode
description: Switch working mode — research, hack, study, project, real. No argument shows a picker.
argument-hint: "[research|hack|study|project|real]"
disable-model-invocation: true
---

# /mode

Requested mode: `$ARGUMENTS`

1. If the requested mode is empty or not one of `research`, `hack`, `study`, `project`, `real`, call AskUserQuestion with one single-select question, header "Mode", options:
   - **research** — Deep research with live examples, case studies, sources (not only code)
   - **hack** — Hackathon: Opus plans → Sonnet builds → Opus reviews, UI-first, token-lean
   - **study** — Code with Claude: you code, I mentor with hints. Never full solutions
   - **project** — Serious GitHub project: understand codebase via graphify, continue it properly
   (`real` — brutal-honesty critique — is reachable via "Other" or `/mode real`.)
2. Read `~/.claude/skills/mode/modes/<mode>.md` and follow it for the rest of the session, until I run `/mode` again.
3. Confirm in one line: `Mode: <mode>` plus that mode's one-line reminder, if any.

The global rules in `~/.claude/CLAUDE.md` (honesty, concise, ask-don't-assume) apply in every mode. Mode rules win over plugin defaults (e.g. Ponytail) where they conflict.
