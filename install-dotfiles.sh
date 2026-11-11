#!/usr/bin/env bash
# ==============================================================================
# install-dotfiles.sh - Automated Bootstrap & Restoration Script
# ==============================================================================
#
# Clones and installs dotfiles from a bare git repository into the user's home,
# safely backs up conflicting files, provisions machine-local templates, and
# compiles necessary system helper binaries.
#
# Repository: https://github.com/Manel-Romero/dotfiles.git
# ==============================================================================

set -eo pipefail

# --- Color Formatting ---
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    C_RESET="\033[0m"
    C_BOLD="\033[1m"
    C_RED="\033[31m"
    C_GREEN="\033[32m"
    C_YELLOW="\033[33m"
    C_BLUE="\033[34m"
    C_CYAN="\033[36m"
else
    C_RESET=""
    C_BOLD=""
    C_RED=""
    C_GREEN=""
    C_YELLOW=""
    C_BLUE=""
    C_CYAN=""
fi

info()    { echo -e "${C_CYAN}[INFO]${C_RESET} $1"; }
success() { echo -e "${C_GREEN}[OK]${C_RESET} $1"; }
warn()    { echo -e "${C_YELLOW}[WARN]${C_RESET} $1"; }
error()   { echo -e "${C_RED}[ERROR]${C_RESET} $1" >&2; }

# --- Default Settings ---
REPO_URL="${DOTFILES_REPO_URL:-https://github.com/Manel-Romero/dotfiles.git}"
GIT_DIR="${DOTFILES_DIR:-$HOME/.dotfiles.git}"
WORK_TREE="${DOTFILES_WORK_TREE:-$HOME}"
SKIP_COMPILE=0
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${WORK_TREE}/.dotfiles-backup-${TIMESTAMP}"

show_help() {
    printf "%b\n" "${C_BOLD}install-dotfiles.sh${C_RESET} - Automated Dotfiles Installer

${C_BOLD}USAGE:${C_RESET}
    ./install-dotfiles.sh [OPTIONS]

${C_BOLD}OPTIONS:${C_RESET}
    --repo=<url>        Git repository URL (default: https://github.com/Manel-Romero/dotfiles.git)
    --git-dir=<path>    Bare git repository location (default: ~/.dotfiles.git)
    --work-tree=<path>  Working tree destination (default: ~)
    --no-compile        Skip compilation of helper binaries (e.g. bat_power)
    -h, --help          Show this help message and exit
"
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo=*)
            REPO_URL="${1#*=}"
            shift
            ;;
        --repo)
            REPO_URL="$2"
            shift 2
            ;;
        --git-dir=*)
            GIT_DIR="${1#*=}"
            shift
            ;;
        --git-dir)
            GIT_DIR="$2"
            shift 2
            ;;
        --work-tree=*)
            WORK_TREE="${1#*=}"
            shift
            ;;
        --work-tree)
            WORK_TREE="$2"
            shift 2
            ;;
        --no-compile)
            SKIP_COMPILE=1
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 2
            ;;
    esac
done

# Recalculate BACKUP_DIR with final WORK_TREE
BACKUP_DIR="${WORK_TREE}/.dotfiles-backup-${TIMESTAMP}"

echo -e "${C_BOLD}${C_BLUE}====================================================${C_RESET}"
echo -e "${C_BOLD}${C_BLUE}       Dotfiles Installer & Bootstrap Setup         ${C_RESET}"
echo -e "${C_BOLD}${C_BLUE}====================================================${C_RESET}"
echo -e "Target Work Tree: ${C_CYAN}${WORK_TREE}${C_RESET}"
echo -e "Bare Git Dir:     ${C_CYAN}${GIT_DIR}${C_RESET}"
echo -e "Remote Repo:      ${C_CYAN}${REPO_URL}${C_RESET}\n"

# Verify git presence
if ! command -v git >/dev/null 2>&1; then
    error "git is not installed. Please install git and re-run this script."
    exit 1
fi

dotfiles() {
    git --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" "$@"
}

# --- 1. Clone Bare Repository ---
echo -e "${C_BOLD}Step 1: Setting up bare git repository...${C_RESET}"
if [[ -d "$GIT_DIR" ]]; then
    warn "Bare repository '${GIT_DIR}' already exists. Fetching updates from origin..."
    dotfiles fetch --all --prune || true
else
    info "Cloning bare repository from ${REPO_URL}..."
    git clone --bare "$REPO_URL" "$GIT_DIR"
    success "Cloned bare repository to ${GIT_DIR}."
fi

# --- 2. Checkout files with automated collision backup ---
echo -e "\n${C_BOLD}Step 2: Checking out files into ${WORK_TREE}...${C_RESET}"

HAS_BACKUPS=0
if dotfiles checkout 2>/dev/null; then
    success "Dotfiles checked out successfully without conflicts."
else
    warn "Untracked files in ${WORK_TREE} would be overwritten. Preparing backup..."
    mkdir -p "$BACKUP_DIR"

    # Extract conflicted files list from checkout stderr
    CONFLICTS=$(dotfiles checkout 2>&1 | grep -E "^\s+" | awk '{$1=$1};1' || true)

    if [[ -n "$CONFLICTS" ]]; then
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            SRC="${WORK_TREE}/${file}"
            DEST="${BACKUP_DIR}/${file}"
            if [[ -e "$SRC" || -L "$SRC" ]]; then
                mkdir -p "$(dirname "$DEST")"
                mv "$SRC" "$DEST"
                info "Moved conflicting file: ${file} -> ${BACKUP_DIR}/${file}"
                HAS_BACKUPS=1
            fi
        done <<< "$CONFLICTS"

        # Retry checkout after conflicts moved
        if dotfiles checkout; then
            success "Dotfiles checked out successfully after backing up conflicting files."
        else
            error "Checkout failed even after moving identified conflicts. Please inspect git status manually."
            exit 1
        fi
    else
        error "Git checkout failed for an unexpected reason. Output:"
        dotfiles checkout
        exit 1
    fi
fi

# --- 3. Configure bare repository settings ---
echo -e "\n${C_BOLD}Step 3: Configuring repository settings...${C_RESET}"
dotfiles config --local status.showUntrackedFiles no
success "Configured 'status.showUntrackedFiles no' (home directory untracked files hidden)."

# --- 4. Ensure machine-local templates exist ---
echo -e "\n${C_BOLD}Step 4: Ensuring machine-local configuration templates...${C_RESET}"

# ~/.zshrc.local
ZSHRC_LOCAL="${WORK_TREE}/.zshrc.local"
if [[ ! -f "$ZSHRC_LOCAL" ]]; then
    info "Creating default template for ${ZSHRC_LOCAL}..."
    cat << 'EOF' > "$ZSHRC_LOCAL"
# ==============================================================================
# ~/.zshrc.local - Machine-Specific Shell Overrides & Private Tokens
# ==============================================================================
# This file is ignored by the dotfiles repository and is NOT tracked in git.
# Place host-specific exports, aliases, credentials, and API keys here.

# Machine-specific PATH additions
# export PATH="$HOME/.local/bin:$PATH"

# Environment variables & API tokens
# export OPENAI_API_KEY=""
# export GITHUB_TOKEN=""
EOF
    chmod 600 "$ZSHRC_LOCAL"
    success "Created ${ZSHRC_LOCAL} template."
else
    success "${ZSHRC_LOCAL} already exists (preserving current configuration)."
fi

# ~/.gitconfig.local
GITCONFIG_LOCAL="${WORK_TREE}/.gitconfig.local"
if [[ ! -f "$GITCONFIG_LOCAL" ]]; then
    info "Creating default template for ${GITCONFIG_LOCAL}..."
    cat << 'EOF' > "$GITCONFIG_LOCAL"
# ==============================================================================
# ~/.gitconfig.local - Machine-Specific Git Identity & Credentials
# ==============================================================================
# This file is ignored by the dotfiles repository.

[user]
	name = Manel-Romero
	email = manel.romero.alv@gmail.com
EOF
    chmod 600 "$GITCONFIG_LOCAL"
    success "Created ${GITCONFIG_LOCAL} template."
else
    success "${GITCONFIG_LOCAL} already exists (preserving current configuration)."
fi

# --- 5. Compile helper binaries ---
echo -e "\n${C_BOLD}Step 5: Compiling helper binaries...${C_RESET}"
BAT_POWER_SRC="${WORK_TREE}/.config/waybar/scripts/bat_power.c"
BAT_POWER_BIN="${WORK_TREE}/.config/waybar/scripts/bat_power"

if [[ $SKIP_COMPILE -eq 1 ]]; then
    info "Skipping compilation (--no-compile specified)."
elif [[ -f "$BAT_POWER_SRC" ]]; then
    if command -v gcc >/dev/null 2>&1; then
        info "Compiling ${BAT_POWER_SRC} with gcc -O2..."
        gcc -O2 "$BAT_POWER_SRC" -o "$BAT_POWER_BIN"
        chmod +x "$BAT_POWER_BIN"
        success "Compiled binary: ${BAT_POWER_BIN}"
    else
        warn "gcc is not installed. Skipping compilation of bat_power.c."
        warn "Install build-essential or gcc to compile it later."
    fi
else
    info "No bat_power.c found at ${BAT_POWER_SRC}. Skipping compilation."
fi

# Ensure executable permissions for custom scripts
if [[ -d "${WORK_TREE}/.local/bin" ]]; then
    chmod +x "${WORK_TREE}"/.local/bin/* 2>/dev/null || true
fi

# --- 6. Security Audit with dotfiles-doctor ---
echo -e "\n${C_BOLD}Step 6: Running security auditor (dotfiles-doctor)...${C_RESET}"
DOCTOR_BIN=""
if [[ -x "${WORK_TREE}/.local/bin/dotfiles-doctor" ]]; then
    DOCTOR_BIN="${WORK_TREE}/.local/bin/dotfiles-doctor"
elif command -v dotfiles-doctor >/dev/null 2>&1; then
    DOCTOR_BIN="$(command -v dotfiles-doctor)"
elif [[ -x "$HOME/.local/bin/dotfiles-doctor" ]]; then
    DOCTOR_BIN="$HOME/.local/bin/dotfiles-doctor"
fi

if [[ -n "$DOCTOR_BIN" ]]; then
    "$DOCTOR_BIN" --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" || {
        warn "dotfiles-doctor detected security or configuration warnings. Please review the output above."
    }
else
    warn "dotfiles-doctor not found or not executable. Skipping automated security audit."
fi

# --- 7. Final Summary & Next Steps ---
echo -e "\n${C_BOLD}${C_GREEN}====================================================${C_RESET}"
echo -e "${C_BOLD}${C_GREEN}         Dotfiles Installation Complete!            ${C_RESET}"
echo -e "${C_BOLD}${C_GREEN}====================================================${C_RESET}"

if [[ $HAS_BACKUPS -eq 1 ]]; then
    echo -e "\n${C_YELLOW}Note: Pre-existing files that conflicted were backed up to:${C_RESET}"
    echo -e "   ${C_CYAN}${BACKUP_DIR}${C_RESET}"
fi

echo -e "\n${C_BOLD}Next Steps:${C_RESET}"
echo -e " 1. Reload your shell or restart your terminal:"
echo -e "    ${C_CYAN}source ~/.zshrc${C_RESET} (or ${C_CYAN}exec zsh${C_RESET})"
echo -e " 2. Review and fill machine-specific credentials:"
echo -e "    ${C_CYAN}${ZSHRC_LOCAL}${C_RESET}"
echo -e "    ${C_CYAN}${GITCONFIG_LOCAL}${C_RESET}"
echo -e " 3. Manage your dotfiles using the alias:"
echo -e "    ${C_CYAN}dotfiles status${C_RESET}"
echo -e "    ${C_CYAN}dotfiles add <file>${C_RESET}"
echo -e "    ${C_CYAN}dotfiles commit -m \"Update config\"${C_RESET}"
echo -e "    ${C_CYAN}dotfiles push${C_RESET}"
echo -e " 4. Re-run security auditor anytime:"
echo -e "    ${C_CYAN}dotfiles-doctor${C_RESET}\n"
