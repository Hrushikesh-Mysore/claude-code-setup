#!/usr/bin/env bash
# Install this Claude Code setup into ~/.claude. Safe to re-run.
#   ./install.sh                  config + all tools
#   ./install.sh --config-only    only CLAUDE.md, skills, agent, settings
#   ./install.sh --with-rea       also add the REA reverse-engineering MCP server
#   ./install.sh --clone-backups  also clone every tool repo into $BACKUP_DIR (~2.5 GB)
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backup}"
CONFIG_ONLY=0 WITH_REA=0 CLONE=0
for a in "$@"; do case "$a" in
  --config-only) CONFIG_ONLY=1 ;; --with-rea) WITH_REA=1 ;; --clone-backups) CLONE=1 ;;
  -h|--help) sed -n 2,6p "$0"; exit 0 ;; *) echo "unknown option: $a"; exit 1 ;;
esac; done

FAILED=()
say()  { printf '\n\033[1m== %s\033[0m\n' "$*"; }
run()  { echo "+ $*"; "$@" || { FAILED+=("$*"); echo "!! failed: $*"; }; }
need() { command -v "$1" >/dev/null || { echo "missing required command: $1"; exit 1; }; }

need claude; need git; need python3
if (( ! CONFIG_ONLY )); then need node; need npx; need pipx; fi
export PATH="$HOME/.local/bin:$(npm config get prefix 2>/dev/null)/bin:$PATH"

# ---------- 1. back up what's there ----------
SAVE="$CLAUDE_DIR/backups/pre-claude-code-setup-$(date +%F_%H%M%S)"
say "Backing up existing config to $SAVE"
mkdir -p "$SAVE" "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents"
for f in CLAUDE.md settings.json skills/mode skills/recheck agents/opus-reviewer.md; do
  [[ -e "$CLAUDE_DIR/$f" ]] && mkdir -p "$SAVE/$(dirname "$f")" && cp -r "$CLAUDE_DIR/$f" "$SAVE/$f" && echo "saved $f"
done

# ---------- 2. config ----------
say "Installing CLAUDE.md, /mode, /recheck, opus-reviewer"
MARK="# How to work with me"
if [[ -f "$CLAUDE_DIR/CLAUDE.md" ]] && grep -qF "$MARK" "$CLAUDE_DIR/CLAUDE.md"; then
  # replace our section, keep anything after it (e.g. graphify's block)
  python3 -I - "$CLAUDE_DIR/CLAUDE.md" "$SRC/claude/CLAUDE.md" <<'EOF'
import sys, re
cur, new = open(sys.argv[1]).read(), open(sys.argv[2]).read().rstrip() + "\n\n"
start = cur.index("# How to work with me")
m = re.search(r"^# (?!How to work with me)", cur[start:], re.M)
rest = cur[start + m.start():] if m else ""
open(sys.argv[1], "w").write(cur[:start] + new + rest)
EOF
elif [[ -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
  { cat "$SRC/claude/CLAUDE.md"; echo; cat "$SAVE/CLAUDE.md"; } > "$CLAUDE_DIR/CLAUDE.md"
else
  cp "$SRC/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
fi
rm -rf "$CLAUDE_DIR/skills/mode" "$CLAUDE_DIR/skills/recheck"
cp -r "$SRC/claude/skills/mode" "$SRC/claude/skills/recheck" "$CLAUDE_DIR/skills/"
cp "$SRC/claude/agents/opus-reviewer.md" "$CLAUDE_DIR/agents/"

say "Settings: model=opusplan, permissions.defaultMode=auto"
python3 -I - "$CLAUDE_DIR/settings.json" <<'EOF'
import json, os, sys
p = sys.argv[1]
s = json.load(open(p)) if os.path.exists(p) else {}
s["model"] = "opusplan"
s.setdefault("permissions", {})["defaultMode"] = "auto"
json.dump(s, open(p, "w"), indent=2)
EOF

say "Backup folder: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp "$SRC/backup/update-all.sh" "$BACKUP_DIR/" && chmod +x "$BACKUP_DIR/update-all.sh"
[[ -f "$BACKUP_DIR/repos.txt" ]] || cp "$SRC/backup/repos.txt" "$BACKUP_DIR/"

if (( CONFIG_ONLY )); then say "Done (config only). Restart Claude Code."; exit 0; fi

# ---------- 3. plugins ----------
say "Claude Code plugins"
for m in DietrichGebert/ponytail mvanhorn/last30days-skill heygen-com/hyperframes cathrynlavery/diagram-design; do
  run claude plugin marketplace add "$m"
done
for p in ponytail@ponytail last30days@last30days-skill hyperframes@hyperframes \
         diagram-design@diagram-design frontend-design@claude-plugins-official; do
  run claude plugin install "$p"
done

# ---------- 4. skills + CLIs ----------
say "Skills (skills.sh)"
run npx -y skills add vercel-labs/agent-browser -g -y
run npx -y skills add https://github.com/cloudflare/security-audit-skill --skill security-audit -g -y
run npx -y skills add latent-spaces/brag -g -y

say "agent-browser CLI + Chrome for Testing"
run npm install -g --allow-scripts=agent-browser agent-browser
run agent-browser install

say "Graphify"
if command -v graphify >/dev/null; then run pipx upgrade graphifyy; else run pipx install graphifyy; fi
run graphify install --platform claude

say "Impeccable (skill only, no global design hook)"
pushd "$HOME" >/dev/null; run npx -y impeccable install --providers=claude --global --no-hooks -y; popd >/dev/null

if (( WITH_REA )); then
  say "REA MCP"
  v=$(npm view rea-agents version 2>/dev/null)
  [[ -n "$v" ]] && run claude mcp add -s user rea -- npx -y "rea-agents@$v" mcp
fi

if (( CLONE )); then say "Cloning tool repos into $BACKUP_DIR"; run "$BACKUP_DIR/update-all.sh" --backup; fi

# ---------- 5. summary ----------
say "Summary"
if ((${#FAILED[@]})); then printf '!! %s\n' "${FAILED[@]}"; echo "Re-run ./install.sh after fixing the above."; else echo "All steps succeeded."; fi
cat <<EOF

Next:
  1. Restart Claude Code (or run /reload-plugins).
  2. Type /mode to pick a mode. In study mode, also type /ponytail off.
  3. Keep things current: $BACKUP_DIR/update-all.sh --check, then without --check. Or /recheck inside Claude.
Previous config saved in: $SAVE
EOF
