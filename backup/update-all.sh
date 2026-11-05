#!/usr/bin/env bash
# Back up every tool repo locally, then update all installed Claude Code tooling in one go.
#   ./update-all.sh            backup + update everything
#   ./update-all.sh --check    report what's new, change nothing
#   ./update-all.sh --backup   only refresh the local repo copies
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS="$DIR/repos" LIST="$DIR/repos.txt" LOGS="$DIR/logs"
MODE="${1:-all}"
export PATH="$HOME/.local/bin:$HOME/.local/share/npm/bin:$PATH"
mkdir -p "$REPOS" "$LOGS"
LOG="$LOGS/update-$(date +%F_%H%M).log"
exec > >(tee -a "$LOG") 2>&1

say()  { printf '\n\033[1m== %s\033[0m\n' "$*"; }
warn() { printf '\033[33m!! %s\033[0m\n' "$*"; WARNINGS+=("$*"); }
WARNINGS=()
check() { [[ "$MODE" == "--check" ]]; }

# ---------- 1. local backups ----------
say "Repo backups ($REPOS)"
while read -r repo; do
  dest="$REPOS/${repo//\//__}"
  if [[ ! -d "$dest/.git" ]]; then
    if check; then echo "[new] $repo (would clone)"; continue; fi
    git clone --quiet "https://github.com/$repo.git" "$dest" && echo "[cloned] $repo" || warn "$repo: clone failed"
    continue
  fi
  if ! git -C "$dest" fetch --quiet --tags origin 2>/dev/null; then
    warn "$repo: fetch failed — upstream may be deleted or private. Local copy kept as-is."
    continue
  fi
  branch=$(git -C "$dest" rev-parse --abbrev-ref HEAD)
  new=$(git -C "$dest" rev-list --count "HEAD..origin/$branch" 2>/dev/null || echo 0)
  if [[ "$new" == 0 ]]; then echo "[ok] $repo up to date"; continue; fi
  echo "[$new new] $repo:"; git -C "$dest" log --oneline -n 5 "HEAD..origin/$branch" | sed 's/^/    /'
  check && continue
  if ! git -C "$dest" merge --quiet --ff-only "origin/$branch" 2>/dev/null; then
    keep="pre-rewrite-$(date +%F)"
    git -C "$dest" branch -f "$keep" HEAD
    git -C "$dest" reset --quiet --hard "origin/$branch"
    warn "$repo: upstream history was rewritten. Old history saved in branch '$keep'."
  fi
done < <(grep -v '^\s*#' "$LIST" | awk 'NF{print $1}')

[[ "$MODE" == "--backup" ]] && { say "Done (backup only). Log: $LOG"; exit 0; }

# ---------- 2. installed tools ----------
say "Claude Code"
check && claude --version || claude update

say "Claude plugins"
if check; then claude plugin list 2>&1 | grep -E '❯|Version'
else
  claude plugin marketplace update
  claude plugin list 2>/dev/null | awk '/❯/{print $2}' | grep '@' | grep -v '@synced' | while read -r p; do
    claude plugin update "$p" 2>&1 | tail -1
  done
fi

say "Skills (skills.sh: agent-browser, security-audit, brag)"
check && npx -y skills ls -g || npx -y skills update -g -y

say "agent-browser CLI"
cur=$(agent-browser --version 2>/dev/null | awk '{print $2}'); lat=$(npm view agent-browser version 2>/dev/null)
echo "installed $cur, latest $lat"
if ! check && [[ -n "$lat" && "$cur" != "$lat" ]]; then
  npm install -g --allow-scripts=agent-browser agent-browser@latest && agent-browser install
fi

say "Graphify (pipx)"
if check; then pipx list --short 2>/dev/null | grep graphifyy; echo "latest: $(pip index versions graphifyy 2>/dev/null | head -1)"
else pipx upgrade graphifyy && graphify install --platform claude >/dev/null && echo "skill refreshed"; fi

say "Impeccable"
check && echo "(skipped in --check)" || (cd "$HOME" && npx -y impeccable update -y --global --no-hooks)

say "REA MCP (pinned version)"
pinned=$(claude mcp get rea 2>/dev/null | grep -oE 'rea-agents@[0-9.]+' | cut -d@ -f2); lat=$(npm view rea-agents version 2>/dev/null)
echo "pinned $pinned, latest $lat"
if ! check && [[ -n "$pinned" && -n "$lat" && "$pinned" != "$lat" ]]; then
  (cd "$HOME" && claude mcp remove rea >/dev/null && claude mcp add rea -- npx -y "rea-agents@$lat" mcp) && echo "REA -> $lat"
fi

say "Summary"
((${#WARNINGS[@]})) && printf '!! %s\n' "${WARNINGS[@]}" || echo "No warnings."
echo "Restart Claude Code to load updated plugins/skills. Log: $LOG"
