#!/usr/bin/env bash
# ==============================================================================
# Comprehensive System, CLI, IDE, ADE & App Update & Cleanup Tool
# Location: ~/.local/bin/update
# ==============================================================================

set -uo pipefail

# Colors for terminal output
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
DIM="\033[2m"
RESET="\033[0m"

log_section() {
    printf "\n%b=== [%s] %s ===%b\n" "$BOLD$CYAN" "$1" "$2" "$RESET"
}

log_info() {
    printf "  %bℹ%b %s\n" "$BLUE" "$RESET" "$1"
}

log_success() {
    printf "  %b✔%b %s\n" "$GREEN" "$RESET" "$1"
}

log_warn() {
    printf "  %b⚠%b %s\n" "$YELLOW" "$RESET" "$1"
}

FAILS=0
log_error() {
    printf "  %b✖%b %s\n" "$RED" "$RESET" "$1"
    FAILS=$((FAILS + 1))
}

export PATH="$HOME/.local/bin:$HOME/.local/share/npm/bin:$PATH"

REPORT_CLIS=()
REPORT_IDES=()
REPORT_SYS=()
REPORT_CLEAN=()

printf "%b" "$BOLD$BLUE"
cat << 'EOF'
  _    _           _       _       
 | |  | |         | |     | |      
 | |  | |_ __   __| | __ _| |_ ___ 
 | |  | | '_ \ / _` |/ _` | __/ _ \
 | |__| | |_) | (_| | (_| | ||  __/
  \____/| .__/ \__,_|\__,_|\__\___|
        | |                        
        |_|                        
 Universal System & AI Environment Updater
EOF
printf "%b\n" "$RESET"

# ------------------------------------------------------------------------------
# STEP 1: AI Agents & CLI Tools
# ------------------------------------------------------------------------------
log_section "1/4" "Updating AI Agents & CLI Tools"

# 1.1 Antigravity CLI (agy)
if command -v agy &>/dev/null; then
    log_info "Updating Antigravity CLI (agy)..."
    if agy update 2>&1 | sed 's/^/    /'; then
        REPORT_CLIS+=("Antigravity CLI (agy): Updated")
    else
        log_warn "Antigravity CLI update encountered a notice."
        REPORT_CLIS+=("Antigravity CLI (agy): Checked")
    fi
else
    log_warn "agy CLI not found in PATH."
fi

# 1.2 Claude Code CLI
if command -v npm &>/dev/null; then
    log_info "Updating Claude Code CLI..."
    if npm install -g @anthropic-ai/claude-code@latest 2>&1 | tail -n 3 | sed 's/^/    /'; then
        cl_ver=$(claude --version 2>/dev/null || echo "latest")
        log_success "Claude Code is at $cl_ver"
        REPORT_CLIS+=("Claude Code: $cl_ver")
    else
        log_error "Failed to update Claude Code"
        REPORT_CLIS+=("Claude Code: Update failed")
    fi

    # 1.3 OpenAI Codex CLI
    log_info "Updating OpenAI Codex CLI..."
    if npm install -g @openai/codex@latest 2>&1 | tail -n 3 | sed 's/^/    /'; then
        codex_ver=$(codex --version 2>/dev/null || echo "latest")
        log_success "Codex CLI is at $codex_ver"
        REPORT_CLIS+=("Codex CLI: $codex_ver")
    else
        log_error "Failed to update Codex CLI"
        REPORT_CLIS+=("Codex CLI: Update failed")
    fi

    # 1.4 agent-browser CLI
    log_info "Updating agent-browser CLI..."
    if npm install -g --allow-scripts=agent-browser agent-browser@latest 2>&1 | tail -n 3 | sed 's/^/    /'; then
        agent-browser install 2>&1 | sed 's/^/    /' || true
        ab_ver=$(agent-browser --version 2>/dev/null || echo "latest")
        log_success "agent-browser is at $ab_ver"
        REPORT_CLIS+=("agent-browser: $ab_ver")
    fi
fi

# 1.5 Pipx packages (graphify, git-filter-repo, etc.)
if command -v pipx &>/dev/null; then
    log_info "Upgrading pipx applications..."
    pipx upgrade-all 2>&1 | sed 's/^/    /'
    if command -v graphify &>/dev/null; then
        graphify install --platform claude >/dev/null 2>&1 || true
    fi
    REPORT_CLIS+=("Pipx (graphify, etc.): Upgraded")
fi

# 1.6 Claude Code Plugins, Skills & Tool Backups (if setup script exists)
if [[ -f "$HOME/backup/update-all.sh" ]]; then
    log_info "Running Claude Code plugins and tool repos update..."
    bash "$HOME/backup/update-all.sh" 2>&1 | sed 's/^/    /' || log_warn "Claude tool script finished with warnings"
    REPORT_CLIS+=("Claude plugins & skills: Refreshed")
elif command -v npx &>/dev/null; then
    log_info "Updating global agent skills..."
    npx -y skills update -g -y 2>&1 | sed 's/^/    /' || true
fi

# Ensure ~/.local/bin symlinks remain intact
ln -sf "$HOME/.local/share/npm/bin/claude" "$HOME/.local/bin/claude" 2>/dev/null || true
ln -sf "$HOME/.local/share/npm/bin/codex" "$HOME/.local/bin/codex" 2>/dev/null || true
ln -sf "$HOME/.local/share/npm/bin/agent-browser" "$HOME/.local/bin/agent-browser" 2>/dev/null || true

# ------------------------------------------------------------------------------
# STEP 2: IDEs, ADEs & Desktop Applications
# ------------------------------------------------------------------------------
log_section "2/4" "Checking & Updating IDEs, ADEs & Desktop Apps"

# Latest GitHub release asset matching regex $2 in repo $1, printed as "version url sha256"
gh_latest() {
    curl -fsS --connect-timeout 5 "https://api.github.com/repos/$1/releases/latest" 2>/dev/null |
        python3 -I -c 'import json, re, sys
r = json.load(sys.stdin)
for a in r["assets"]:
    if re.fullmatch(sys.argv[1], a["name"]):
        print(r["tag_name"].lstrip("v"), a["browser_download_url"], (a.get("digest") or "").removeprefix("sha256:"))
        break' "$2" 2>/dev/null
}

# Download $1 to $3; refuse it unless its sha256 equals $2
fetch_verified() {
    [[ -n "$2" ]] || { echo "    no published checksum, refusing to install"; return 1; }
    curl -fSL --progress-bar --connect-timeout 10 "$1" -o "$3" &&
        echo "$2  $3" | sha256sum -c --quiet - && chmod +x "$3" || { rm -f "$3"; return 1; }
}

# True if any process is running a binary from inside directory $1
running_from() {
    local p
    for p in /proc/[0-9]*/exe; do
        [[ "$(readlink "$p" 2>/dev/null)" == "$1"/* ]] && return 0
    done
    return 1
}

# Install AppImage ($1 url, $2 sha) extracted at $3/squashfs-root.
# The previous copy is renamed to squashfs-root.old so an instance that is running now keeps working until restarted.
install_extracted() {
    local dir=$3 stage ok=1
    if [[ -d "$dir/squashfs-root.old" ]]; then
        if running_from "$dir/squashfs-root.old"; then
            echo "    previous version is still running; restart the app, then run update again"
            return 1
        fi
        rm -rf "$dir/squashfs-root.old"
    fi
    stage=$(mktemp -d "$dir/.stage.XXXXXX") || return 1
    if fetch_verified "$1" "$2" "$stage/app.AppImage" &&
        (cd "$stage" && ./app.AppImage --appimage-extract >/dev/null 2>&1) &&
        [[ -x "$stage/squashfs-root/AppRun" ]]; then
        if mv -T "$dir/squashfs-root" "$dir/squashfs-root.old"; then
            mv -T "$stage/squashfs-root" "$dir/squashfs-root" && ok=0 ||
                mv -T "$dir/squashfs-root.old" "$dir/squashfs-root"   # put the old copy back
        fi
    fi
    rm -rf "$stage"
    return $ok
}

# Replace single-file AppImage $3 with a verified download ($1 url, $2 sha)
install_file() {
    fetch_verified "$1" "$2" "$3.new" && mv -f "$3.new" "$3"
}

# update_app NAME CURRENT LATEST URL SHA INSTALLER TARGET
update_app() {
    local name=$1 cur=$2 ver=$3
    if [[ -z "$ver" ]]; then
        log_error "$name: could not read latest release from GitHub"
        REPORT_IDES+=("$name: v${cur:-?} (update check FAILED)")
    elif [[ "$cur" == "$ver" ]]; then
        log_success "$name is up to date (v$cur)"
        REPORT_IDES+=("$name: v$cur (Up to date)")
    else
        log_info "Updating $name: v${cur:-?} -> v$ver"
        if "$6" "$4" "$5" "$7"; then
            log_success "$name updated to v$ver (restart it if it is open)"
            REPORT_IDES+=("$name: Updated to v$ver")
        else
            log_error "$name update failed, kept v${cur:-?}"
            REPORT_IDES+=("$name: v${cur:-?} (update FAILED)")
        fi
    fi
}

# 2.1 Orca IDE (extracted AppImage)
dir="$HOME/.local/opt/orca"
if [[ -d "$dir/squashfs-root" ]]; then
    cur=$(grep -m1 '^X-AppImage-Version=' "$dir/squashfs-root/orca-ide.desktop" 2>/dev/null | cut -d= -f2)
    read -r ver url sha <<< "$(gh_latest stablyai/orca 'orca-linux\.AppImage')"
    update_app "Orca IDE" "$cur" "$ver" "$url" "$sha" install_extracted "$dir"
    ln -sf "$dir/squashfs-root/AppRun" "$HOME/.local/bin/orca"
    ln -sf "$dir/squashfs-root/AppRun" "$HOME/.local/bin/orca-ide"
fi

# 2.2 ArtCraft Launcher (extracted AppImage; version from the binary, the .desktop file goes stale after self-updates)
dir="$HOME/.local/opt/artcraft"
if [[ -d "$dir/squashfs-root" ]]; then
    cur=$("$dir/squashfs-root/usr/bin/artcraft-launcher" --version 2>/dev/null | awk '{print $2}')
    read -r ver url sha <<< "$(gh_latest storytold/craft-launcher 'artcraft-launcher-[0-9.]+-linux-x86_64\.AppImage')"
    update_app "ArtCraft Launcher" "$cur" "$ver" "$url" "$sha" install_extracted "$dir"
fi

# 2.3 GitHub Copilot App (single AppImage file; it has no version metadata, so compare its checksum to the release)
file="$HOME/.local/opt/github-copilot/GitHub-Copilot.AppImage"
if [[ -f "$file" ]]; then
    read -r ver url sha <<< "$(gh_latest github/app 'GitHub-Copilot-linux-x64\.AppImage')"
    cur="older"
    [[ -n "$sha" && "$(sha256sum "$file" | cut -d' ' -f1)" == "$sha" ]] && cur=$ver
    update_app "GitHub Copilot App" "$cur" "$ver" "$url" "$sha" install_file "$file"
fi

# ------------------------------------------------------------------------------
# STEP 3: System, AUR & Native Packages (VS Code, Antigravity, ChatGPT, Discord)
# ------------------------------------------------------------------------------
log_section "3/4" "Updating System, AUR & Native Apps"

# The system package manager updates:
# - code / code-oss (VS Code)
# - antigravity (Antigravity IDE Platform)
# - chatgpt-desktop-bin (ChatGPT Desktop)
# - discord (Discord)
# - Base CachyOS / Arch packages & libraries
if command -v paru &>/dev/null; then
    log_info "Updating system packages and AUR apps with paru..."
    if paru -Syu --noconfirm 2>&1 | sed 's/^/    /'; then
        log_success "System & AUR packages successfully updated."
        REPORT_SYS+=("System & AUR (paru): Updated")
    else
        log_error "paru exited with an error, please check output."
        REPORT_SYS+=("System & AUR (paru): FAILED, check output")
    fi
elif command -v pacman &>/dev/null; then
    log_info "Updating system packages with pacman..."
    if sudo pacman -Syu --noconfirm 2>&1 | sed 's/^/    /'; then
        log_success "System packages updated."
        REPORT_SYS+=("System (pacman): Updated")
    else
        log_error "pacman exited with an error, please check output."
        REPORT_SYS+=("System (pacman): FAILED, check output")
    fi
fi

# ------------------------------------------------------------------------------
# STEP 4: Cleanup, Orphaned Files & Package Caches
# ------------------------------------------------------------------------------
log_section "4/4" "Removing Orphaned Files & Cleaning Caches"

# 4.1 Remove orphaned packages (pacman/paru)
log_info "Checking for orphaned packages..."
orphans=$(pacman -Qtdq 2>/dev/null || true)
if [[ -n "$orphans" ]]; then
    log_info "Removing orphaned packages: $orphans"
    if sudo pacman -Rns $orphans --noconfirm 2>&1 | sed 's/^/    /'; then
        log_success "Orphaned packages removed."
        REPORT_CLEAN+=("Orphaned packages: Cleaned")
    fi
else
    log_success "No orphaned packages found."
    REPORT_CLEAN+=("Orphaned packages: None")
fi

# 4.2 Pacman package cache cleanup
if command -v paccache &>/dev/null; then
    log_info "Cleaning pacman package cache (keeping last 2 versions)..."
    if sudo paccache -rk2 2>&1 | sed 's/^/    /' && sudo paccache -ruk0 2>&1 | sed 's/^/    /'; then
        REPORT_CLEAN+=("Package cache: Cleaned")
    else
        log_error "paccache failed"
        REPORT_CLEAN+=("Package cache: FAILED")
    fi
fi

# 4.3 Npm cache verification & log cleanup
if command -v npm &>/dev/null; then
    log_info "Verifying npm cache and cleaning stale logs..."
    npm cache verify 2>&1 | sed 's/^/    /' || true
    find "$HOME/.npm/_logs" -name "*.log" -mtime +7 -delete 2>/dev/null || true
    REPORT_CLEAN+=("NPM cache & logs: Verified")
fi

# 4.4 Remove broken symlinks in ~/.local/bin
log_info "Checking for broken symlinks in ~/.local/bin..."
find "$HOME/.local/bin" -xtype l -delete 2>/dev/null || true
REPORT_CLEAN+=("Broken symlinks: Cleaned")

# 4.5 Clean orphaned temporary orca cache if present
if [[ -d "$HOME/.cache/orca/appimage" ]]; then
    rm -rf "$HOME/.cache/orca/appimage" 2>/dev/null || true
    REPORT_CLEAN+=("Orca AppImage cache: Removed")
fi

# 4.6 List installer leftovers in ~/Downloads; never deletes (your call). Workspace is never touched.
log_info "Inspecting ~/Downloads..."
mapfile -t leftovers < <(find "$HOME/Downloads" -maxdepth 1 \( -name "*.AppImage" -o -name "*.deb" -o -name "*.tar.gz" -o -name "squashfs-root" \) 2>/dev/null)
if (( ${#leftovers[@]} )); then
    log_warn "Installer leftovers in ~/Downloads (not deleted, remove them yourself if unneeded):"
    printf '      %s\n' "${leftovers[@]}"
    REPORT_CLEAN+=("Downloads: ${#leftovers[@]} installer file(s) to review")
else
    log_success "Downloads directory is clean."
    REPORT_CLEAN+=("Downloads: Clean")
fi

# ------------------------------------------------------------------------------
# STEP 5: Concise Summary Report
# ------------------------------------------------------------------------------
printf "\n%b%b================================================================%b\n" "$BOLD" "$GREEN" "$RESET"
printf "%b                      UPDATE SUMMARY REPORT                     %b\n" "$BOLD" "$RESET"
printf "%b%b================================================================%b\n" "$BOLD" "$GREEN" "$RESET"

printf "\n%b[ CLI & AI Agents ]%b\n" "$BOLD$CYAN" "$RESET"
for item in "${REPORT_CLIS[@]}"; do
    printf "  • %s\n" "$item"
done

printf "\n%b[ IDEs, ADEs & Desktop Apps ]%b\n" "$BOLD$CYAN" "$RESET"
for item in "${REPORT_IDES[@]}"; do
    printf "  • %s\n" "$item"
done

printf "\n%b[ System & Repositories ]%b\n" "$BOLD$CYAN" "$RESET"
for item in "${REPORT_SYS[@]}"; do
    printf "  • %s\n" "$item"
done

printf "\n%b[ Cleanup & Housekeeping ]%b\n" "$BOLD$CYAN" "$RESET"
for item in "${REPORT_CLEAN[@]}"; do
    printf "  • %s\n" "$item"
done

if (( FAILS == 0 )); then
    printf "\n%b✔ All tasks completed successfully!%b\n\n" "$BOLD$GREEN" "$RESET"
else
    printf "\n%b✖ %d step(s) failed. Scroll up to the ✖ lines.%b\n\n" "$BOLD$RED" "$FAILS" "$RESET"
    exit 1
fi
