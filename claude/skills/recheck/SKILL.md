---
name: recheck
description: Audit installed Claude Code plugins, skills and MCP servers for newer versions, deprecations, security issues, and better alternatives. Reports only; installs nothing without approval.
disable-model-invocation: true
---

# /recheck

## 1. Inventory
Run and collect: `claude plugin list`, `claude mcp list`, `ls -la ~/.claude/skills ~/.claude/agents`, `npx -y skills ls -g`, `pipx list --short`, `agent-browser --version`, and `~/backup/update-all.sh --check` (pending upstream updates). Read `~/backup/repos.txt`.

## 2. Research (web, recent first)
For each installed item: latest release/activity, open security advisories, whether it's deprecated, archived, renamed or abandoned.
For each need below, search for tools released or rising since the last recheck (check memory for its date):
- research/browsing (current: WebSearch, agent-browser, Claude in Chrome, last30days)
- workflow/token efficiency (current: Ponytail, opusplan)
- codebase understanding (current: Graphify)
- UI/design (current: frontend-design, impeccable, diagram-design)
- security (current: security-audit, /security-review)
- video/launch (current: brag + hyperframes)
Also check whether Claude Code itself gained a built-in feature that makes any plugin redundant.
Verify claims against the primary repo/docs; mark anything unverified. Ignore hype numbers without a source.

## 3. Report (concise)
Table: Item | Status | Verdict (keep / upgrade / replace with X / remove) | Why (1 line) | Source.
Then "New worth trying" (max 3, each with what it replaces and the trade-off), and "Nothing better found" where true — don't invent upgrades.

## 4. After
- Save today's date + verdict summary to memory (update the existing recheck memory, don't duplicate).
- Install/remove only what I approve. When installing a new tool from GitHub, also add its repo to `~/backup/repos.txt` so it gets backed up.
