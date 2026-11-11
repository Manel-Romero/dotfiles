#!/usr/bin/env bash
# ==============================================================================
# install-dotfiles.sh - Modular Automated Bootstrap & Dotfiles Installer
# ==============================================================================
#
# Supports modular installation with automated dependency resolution,
# Git sparse-checkout (--no-cone), conflict backup, and system package mapping.
#
# Repository: https://github.com/Manel-Romero/dotfiles.git
# ==============================================================================

set -eo pipefail

# --- Color Formatting ---
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    C_RESET="\033[0m"
    C_BOLD="\033[1m"
    C_DIM="\033[2m"
    C_RED="\033[31m"
    C_GREEN="\033[32m"
    C_YELLOW="\033[33m"
    C_BLUE="\033[34m"
    C_MAGENTA="\033[35m"
    C_CYAN="\033[36m"
else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_RED=""
    C_GREEN=""
    C_YELLOW=""
    C_BLUE=""
    C_MAGENTA=""
    C_CYAN=""
fi

info()    { echo -e "${C_CYAN}[INFO]${C_RESET} $1"; }
success() { echo -e "${C_GREEN}[OK]${C_RESET} $1"; }
warn()    { echo -e "${C_YELLOW}[WARN]${C_RESET} $1"; }
error()   { echo -e "${C_RED}[ERROR]${C_RESET} $1" >&2; }

# ==============================================================================
# 1. Module Registry & Dependency Graph
# ==============================================================================

readonly ALL_MODULES=(
    core
    git
    shell
    system
    terminal
    desktop
    waybar
    nvim
    cli-tools
)

declare -A MODULE_DESC=(
    [core]="Security suite, .gitignore, doctor, and machine-local templates"
    [git]="Global Git configuration (.gitconfig)"
    [shell]="Zsh, Oh My Zsh, Tmux, profile, aliases, and custom completions"
    [system]="PipeWire/WirePlumber, XDG portals, user dirs, and MIME apps"
    [terminal]="Kitty terminal emulator configuration"
    [desktop]="Niri Wayland window manager, SwayNC, Fuzzel, and wallpapers"
    [waybar]="Waybar status bar and bat_power utility"
    [nvim]="Neovim LazyVim-based development environment"
    [cli-tools]="Yazi, Btop, Fastfetch, MPV, TheFuck, w-disc UPV utility"
)

# Direct module dependencies (Directed Acyclic Graph)
declare -A MODULE_DEPS=(
    [core]=""
    [git]="core"
    [shell]="core git"
    [terminal]="shell"
    [system]="core"
    [desktop]="system terminal"
    [waybar]="desktop"
    [nvim]="git shell"
    [cli-tools]="shell"
)

# Arch Linux package recommendations per module
declare -A MODULE_PKGS=(
    [core]="base-devel git"
    [git]="git github-cli"
    [shell]="zsh tmux zoxide fzf thefuck"
    [terminal]="kitty ttf-jetbrains-mono-nerd"
    [system]="xdg-desktop-portal-wlr wireplumber pipewire"
    [desktop]="niri swaybg swaync fuzzel cliphist wl-clipboard"
    [waybar]="waybar gcc"
    [nvim]="neovim ripgrep fd"
    [cli-tools]="yazi btop fastfetch mpv"
)

# Sparse-checkout patterns for each module (for git sparse-checkout set --no-cone)
declare -A MODULE_PATTERNS=(
    [core]="
/.gitignore
/README.md
/install-dotfiles.sh
/.local/bin/dotfiles-doctor
"
    [git]="
/.gitconfig
"
    [shell]="
/.bashrc
/.zshrc
/.zprofile
/.tmux.conf
/.zfunc/
"
    [terminal]="
/.config/kitty/
"
    [system]="
/.config/wireplumber/
/.config/xdg-desktop-portal/
/.config/user-dirs.dirs
/.config/user-dirs.locale
/.config/mimeapps.list
/.config/systemd/user/obex.service.d/
"
    [desktop]="
/.config/niri/
/.config/swaync/
/.config/fuzzel/
/Wallpapers/
"
    [waybar]="
/.config/waybar/
"
    [nvim]="
/.config/nvim/
"
    [cli-tools]="
/.config/yazi/
/.config/btop/
/.config/fastfetch/
/.config/mpv/
/.config/thefuck/
/.config/wayspot-lyrics/
/.local/bin/w-disc
/.jc141rc
"
)

# Presets mapping
declare -A PRESETS=(
    [all]="core git shell system terminal desktop waybar nvim cli-tools"
    [minimal]="core git shell"
    [dev]="core git shell terminal nvim cli-tools"
    [desktop]="core git shell system terminal desktop waybar nvim cli-tools"
)

# ==============================================================================
# 2. Dependency Resolution Engine (Topological Sort & Cycle Detection)
# ==============================================================================

is_valid_module() {
    local mod="$1"
    for m in "${ALL_MODULES[@]}"; do
        [[ "$m" == "$mod" ]] && return 0
    done
    return 1
}

expand_presets() {
    local raw_inputs=("$@")
    local tokens=()
    local item token

    for item in "${raw_inputs[@]}"; do
        item="${item//,/ }"
        for token in $item; do
            token="$(echo "$token" | xargs)"
            [[ -z "$token" ]] && continue
            
            if [[ "$token" =~ ^preset:(.+)$ ]]; then
                local p_name="${BASH_REMATCH[1]}"
                if [[ -n "${PRESETS[$p_name]:-}" ]]; then
                    tokens+=(${PRESETS[$p_name]})
                else
                    error "Unknown preset '$p_name'"
                    return 1
                fi
            elif [[ -n "${PRESETS[$token]:-}" && "$token" != "desktop" ]]; then
                tokens+=(${PRESETS[$token]})
            else
                tokens+=("$token")
            fi
        done
    done
    echo "${tokens[*]}"
}

resolve_dependencies() {
    local raw_args=("$@")
    [[ $# -eq 0 ]] && raw_args=("all")

    local expanded_tokens
    if ! expanded_tokens=$(expand_presets "${raw_args[@]}"); then
        return 1
    fi

    read -r -a requested_modules <<< "$expanded_tokens"

    if [[ ${#requested_modules[@]} -eq 0 ]]; then
        error "No modules specified."
        return 1
    fi

    for mod in "${requested_modules[@]}"; do
        if ! is_valid_module "$mod"; then
            error "Unknown module '$mod'. Available modules: ${ALL_MODULES[*]}"
            return 1
        fi
    done

    # Collect needed modules (direct + transitive)
    declare -A needed=()
    collect_needed() {
        local m="$1"
        [[ -n "${needed[$m]:-}" ]] && return 0
        needed[$m]=1
        for prereq in ${MODULE_DEPS[$m]:-}; do
            collect_needed "$prereq"
        done
    }

    for mod in "${requested_modules[@]}"; do
        collect_needed "$mod"
    done

    # DFS topological sort with cycle detection
    declare -A visit_state=()
    local resolved=()

    dfs_sort() {
        local node="$1"
        local st="${visit_state[$node]:-0}"
        if [[ "$st" -eq 1 ]]; then
            error "Circular dependency detected at '$node'"
            return 2
        fi
        [[ "$st" -eq 2 ]] && return 0

        visit_state[$node]=1
        for prereq in ${MODULE_DEPS[$node]:-}; do
            dfs_sort "$prereq" || return 2
        done
        visit_state[$node]=2
        resolved+=("$node")
    }

    for mod in "${ALL_MODULES[@]}"; do
        if [[ -n "${needed[$mod]:-}" && "${visit_state[$mod]:-0}" -eq 0 ]]; then
            dfs_sort "$mod" || return 1
        fi
    done

    echo "${resolved[*]}"
}

get_packages_for_modules() {
    local mods=("$@")
    local pkgs=()
    declare -A seen=()
    for m in "${mods[@]}"; do
        for p in ${MODULE_PKGS[$m]:-}; do
            if [[ -z "${seen[$p]:-}" ]]; then
                seen[$p]=1
                pkgs+=("$p")
            fi
        done
    done
    echo "${pkgs[*]}"
}

get_patterns_for_modules() {
    local mods=("$@")
    local patterns=()
    for m in "${mods[@]}"; do
        while IFS= read -r line; do
            line="$(echo "$line" | xargs)"
            [[ -n "$line" ]] && patterns+=("$line")
        done <<< "${MODULE_PATTERNS[$m]:-}"
    done
    echo "${patterns[*]}"
}

# ==============================================================================
# 3. CLI Configuration & Defaults
# ==============================================================================

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/Manel-Romero/dotfiles.git}"
GIT_DIR="${DOTFILES_DIR:-$HOME/.dotfiles.git}"
WORK_TREE="${DOTFILES_WORK_TREE:-$HOME}"
SKIP_COMPILE=0
INSTALL_PKGS=0
DRY_RUN=0
ADD_MODE=0
REQUESTED_INPUTS=()
INTERACTIVE_REQUESTED=0
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${WORK_TREE}/.dotfiles-backup-${TIMESTAMP}"

show_help() {
    cat << EOF
${C_BOLD}install-dotfiles.sh${C_RESET} - Modular Automated Dotfiles Installer

${C_BOLD}USAGE:${C_RESET}
    ./install-dotfiles.sh [OPTIONS]

${C_BOLD}MODULE & PROFILE SELECTION:${C_RESET}
    -m, --modules=<m1,m2>    Install specific modules (comma-separated)
    -p, --profile=<name>     Use a preset profile: minimal, dev, desktop, all
    -a, --add-module=<mod>   Add module(s) to current installation without removing existing
    -i, --interactive        Launch interactive selection menu
    -l, --list-modules       Show all modules, descriptions, dependencies and packages

${C_BOLD}GENERAL OPTIONS:${C_RESET}
    --packages               Prompt/install missing system packages on Arch Linux
    --dry-run                Simulate dependency resolution and file patterns without modifying disk
    --repo=<url>             Git repository URL (default: https://github.com/Manel-Romero/dotfiles.git)
    --git-dir=<path>         Bare git repository location (default: ~/.dotfiles.git)
    --work-tree=<path>       Working tree destination (default: ~)
    --no-compile             Skip compilation of helper binaries (bat_power.c)
    -h, --help               Show this help message and exit

${C_BOLD}AVAILABLE MODULES:${C_RESET}
    core, git, shell, system, terminal, desktop, waybar, nvim, cli-tools

${C_BOLD}AVAILABLE PROFILES:${C_RESET}
    minimal                  core, git, shell
    dev                      core, git, shell, terminal, nvim, cli-tools
    desktop / all            Full desktop environment (all modules)
EOF
}

list_modules_info() {
    echo -e "${C_BOLD}${C_BLUE}=================================================================${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE}                  Available Dotfiles Modules                     ${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE}=================================================================${C_RESET}\n"

    for mod in "${ALL_MODULES[@]}"; do
        local deps="${MODULE_DEPS[$mod]:-none}"
        local pkgs="${MODULE_PKGS[$mod]:-none}"
        echo -e "${C_BOLD}${C_CYAN}● ${mod}${C_RESET} - ${MODULE_DESC[$mod]}"
        echo -e "  ${C_DIM}Prerequisites:${C_RESET} ${C_YELLOW}${deps}${C_RESET}"
        echo -e "  ${C_DIM}Arch Packages:${C_RESET} ${pkgs}"
        echo
    done

    echo -e "${C_BOLD}Preset Profiles:${C_RESET}"
    for p in minimal dev desktop all; do
        echo -e "  ${C_GREEN}${p}:${C_RESET} ${PRESETS[$p]}"
    done
}

# ==============================================================================
# 4. Parse Arguments
# ==============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m=*|--modules=*)
            REQUESTED_INPUTS+=("${1#*=}")
            shift
            ;;
        -m|--modules)
            REQUESTED_INPUTS+=("$2")
            shift 2
            ;;
        -p=*|--profile=*)
            REQUESTED_INPUTS+=("${1#*=}")
            shift
            ;;
        -p|--profile)
            REQUESTED_INPUTS+=("$2")
            shift 2
            ;;
        -a=*|--add-module=*)
            ADD_MODE=1
            REQUESTED_INPUTS+=("${1#*=}")
            shift
            ;;
        -a|--add-module)
            ADD_MODE=1
            REQUESTED_INPUTS+=("$2")
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE_REQUESTED=1
            shift
            ;;
        -l|--list-modules)
            list_modules_info
            exit 0
            ;;
        --packages)
            INSTALL_PKGS=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
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

BACKUP_DIR="${WORK_TREE}/.dotfiles-backup-${TIMESTAMP}"

# ==============================================================================
# 5. Interactive Menu (if requested or run in TTY without parameters)
# ==============================================================================

if [[ $INTERACTIVE_REQUESTED -eq 1 || (${#REQUESTED_INPUTS[@]} -eq 0 && -t 0 && -t 1) ]]; then
    echo -e "${C_BOLD}${C_BLUE}====================================================${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE}         Dotfiles Modular Installation Menu         ${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE}====================================================${C_RESET}"
    echo -e "Choose an installation preset or custom selection:\n"
    echo -e "  ${C_CYAN}1)${C_RESET} ${C_BOLD}Full Desktop${C_RESET}      All modules (Niri, Waybar, Kitty, Neovim, CLI tools)"
    echo -e "  ${C_CYAN}2)${C_RESET} ${C_BOLD}Developer${C_RESET}         Shell, Git, Kitty, Neovim, CLI tools (Headless/Dev)"
    echo -e "  ${C_CYAN}3)${C_RESET} ${C_BOLD}Minimal / Server${C_RESET}  Shell, Git, Core only"
    echo -e "  ${C_CYAN}4)${C_RESET} ${C_BOLD}Custom Selection${C_RESET}  Pick specific modules individually"
    echo -e "  ${C_CYAN}q)${C_RESET} Quit\n"

    read -r -p "Enter choice [1-4, q]: " CHOICE
    case "$CHOICE" in
        1) REQUESTED_INPUTS=("desktop") ;;
        2) REQUESTED_INPUTS=("dev") ;;
        3) REQUESTED_INPUTS=("minimal") ;;
        4)
            echo -e "\n${C_BOLD}Available modules:${C_RESET}"
            for i in "${!ALL_MODULES[@]}"; do
                echo -e "  ${C_CYAN}$((i+1)))${C_RESET} ${ALL_MODULES[$i]} - ${MODULE_DESC[${ALL_MODULES[$i]}]}"
            done
            echo
            read -r -p "Enter module numbers or names separated by spaces (e.g. 1 2 7 8 or nvim waybar): " USER_SELECTION
            CHOSEN_MODS=()
            for item in $USER_SELECTION; do
                if [[ "$item" =~ ^[0-9]+$ ]] && [[ "$item" -ge 1 && "$item" -le ${#ALL_MODULES[@]} ]]; then
                    CHOSEN_MODS+=("${ALL_MODULES[$((item-1))]}")
                elif is_valid_module "$item"; then
                    CHOSEN_MODS+=("$item")
                else
                    warn "Ignoring invalid module selection: $item"
                fi
            done
            [[ ${#CHOSEN_MODS[@]} -eq 0 ]] && { error "No valid modules chosen."; exit 1; }
            REQUESTED_INPUTS=("${CHOSEN_MODS[@]}")
            ;;
        q|Q)
            echo "Installation cancelled."
            exit 0
            ;;
        *)
            error "Invalid choice."
            exit 1
            ;;
    esac
fi

# Fallback default if still empty (non-interactive default)
if [[ ${#REQUESTED_INPUTS[@]} -eq 0 ]]; then
    REQUESTED_INPUTS=("all")
fi

# ==============================================================================
# 6. Resolve Dependencies & Patterns
# ==============================================================================

dotfiles() {
    git --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" "$@"
}

# If adding to existing installation, read current sparse-checkout list
CURRENT_ACTIVE_MODULES=()
if [[ $ADD_MODE -eq 1 && -d "$GIT_DIR" ]]; then
    CURRENT_PATTERNS="$(dotfiles sparse-checkout list 2>/dev/null || true)"
    for mod in "${ALL_MODULES[@]}"; do
        FIRST_PATTERN="$(echo "${MODULE_PATTERNS[$mod]}" | xargs | awk '{print $1}')"
        if [[ -n "$FIRST_PATTERN" && "$CURRENT_PATTERNS" == *"$FIRST_PATTERN"* ]]; then
            CURRENT_ACTIVE_MODULES+=("$mod")
        fi
    done
    REQUESTED_INPUTS+=("${CURRENT_ACTIVE_MODULES[@]}")
fi

RESOLVED_STR="$(resolve_dependencies "${REQUESTED_INPUTS[@]}")"
read -r -a RESOLVED_MODULES <<< "$RESOLVED_STR"

NEEDED_PACKAGES="$(get_packages_for_modules "${RESOLVED_MODULES[@]}")"
PATTERNS_STR="$(get_patterns_for_modules "${RESOLVED_MODULES[@]}")"
read -r -a SPARSE_PATTERNS <<< "$PATTERNS_STR"

echo -e "${C_BOLD}${C_BLUE}====================================================${C_RESET}"
echo -e "${C_BOLD}${C_BLUE}       Dotfiles Modular Installer & Bootstrap       ${C_RESET}"
echo -e "${C_BOLD}${C_BLUE}====================================================${C_RESET}"
echo -e "Target Work Tree:    ${C_CYAN}${WORK_TREE}${C_RESET}"
echo -e "Bare Git Directory:  ${C_CYAN}${GIT_DIR}${C_RESET}"
echo -e "Requested Selection: ${C_YELLOW}${REQUESTED_INPUTS[*]}${C_RESET}"
echo -e "Resolved Modules:    ${C_GREEN}${RESOLVED_MODULES[*]}${C_RESET}"

# Display dependency breakdown if dependencies were automatically added
ADDED_DEPS=()
for mod in "${RESOLVED_MODULES[@]}"; do
    if [[ ! " ${REQUESTED_INPUTS[*]} " =~ " ${mod} " ]]; then
        ADDED_DEPS+=("$mod")
    fi
done
if [[ ${#ADDED_DEPS[@]} -gt 0 ]]; then
    echo -e "Auto-included Deps:  ${C_MAGENTA}${ADDED_DEPS[*]}${C_RESET}"
fi
echo

# Dry run exit
if [[ $DRY_RUN -eq 1 ]]; then
    info "DRY-RUN MODE ENABLED: No files or repositories will be touched."
    echo -e "\n${C_BOLD}Sparse-checkout patterns that would be applied:${C_RESET}"
    for pat in "${SPARSE_PATTERNS[@]}"; do
        echo "  $pat"
    done
    echo -e "\n${C_BOLD}Required Arch Linux packages:${C_RESET}"
    echo "  $NEEDED_PACKAGES"
    exit 0
fi

# ==============================================================================
# 7. Optional Package Installation (Arch Linux)
# ==============================================================================

if [[ $INSTALL_PKGS -eq 1 ]] || [[ -t 0 && -t 1 && $(command -v pacman) ]]; then
    if [[ $INSTALL_PKGS -ne 1 ]]; then
        read -r -p "Do you want to check and install missing packages with pacman/yay? [y/N]: " INSTALL_ANSWER
        [[ "$INSTALL_ANSWER" =~ ^[Yy]$ ]] && INSTALL_PKGS=1
    fi

    if [[ $INSTALL_PKGS -eq 1 ]]; then
        echo -e "\n${C_BOLD}Checking system package prerequisites...${C_RESET}"
        PKG_MGR="sudo pacman -S --needed"
        if command -v yay >/dev/null 2>&1; then
            PKG_MGR="yay -S --needed"
        fi

        MISSING_PKGS=()
        for pkg in $NEEDED_PACKAGES; do
            if ! pacman -Qi "$pkg" >/dev/null 2>&1; then
                MISSING_PKGS+=("$pkg")
            fi
        done

        if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
            info "Installing missing packages: ${MISSING_PKGS[*]}"
            $PKG_MGR "${MISSING_PKGS[@]}" || warn "Some packages could not be installed. Continuing with dotfiles."
        else
            success "All required system packages are already installed."
        fi
    fi
fi

# ==============================================================================
# 8. Set Up Bare Git Repository
# ==============================================================================

echo -e "\n${C_BOLD}Step 1: Setting up bare git repository...${C_RESET}"
if ! command -v git >/dev/null 2>&1; then
    error "git is not installed. Please install git and re-run."
    exit 1
fi

if [[ -d "$GIT_DIR" ]]; then
    info "Bare repository exists at '${GIT_DIR}'. Fetching updates..."
    dotfiles fetch --all --prune || true
else
    info "Cloning bare repository from ${REPO_URL}..."
    git clone --bare "$REPO_URL" "$GIT_DIR"
    success "Cloned bare repository to ${GIT_DIR}."
fi

# Configure repository flags
dotfiles config status.showUntrackedFiles no
dotfiles config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
dotfiles branch --set-upstream-to=origin/main main 2>/dev/null || true

# ==============================================================================
# 9. Apply Sparse Checkout Patterns & Safely Checkout
# ==============================================================================

echo -e "\n${C_BOLD}Step 2: Configuring sparse checkout for selected modules...${C_RESET}"
dotfiles sparse-checkout set --no-cone "${SPARSE_PATTERNS[@]}"

echo -e "\n${C_BOLD}Step 3: Checking out files into ${WORK_TREE}...${C_RESET}"
HAS_BACKUPS=0

if dotfiles checkout 2>/dev/null; then
    success "Files checked out successfully without conflicts."
else
    warn "Pre-existing files in ${WORK_TREE} would conflict. Backing them up..."
    mkdir -p "$BACKUP_DIR"

    # Identify conflicting files
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

        # Retry checkout
        if dotfiles checkout; then
            success "Dotfiles checked out successfully after backing up conflicting files."
        else
            error "Checkout failed even after conflict backup. Please check git status manually."
            exit 1
        fi
    else
        error "Git checkout failed unexpectedly. Detailed output:"
        dotfiles checkout
        exit 1
    fi
fi

# ==============================================================================
# 10. Machine-Local Templates Provisioning
# ==============================================================================

if [[ " ${RESOLVED_MODULES[*]} " =~ " core " || " ${RESOLVED_MODULES[*]} " =~ " shell " ]]; then
    echo -e "\n${C_BOLD}Step 4: Ensuring machine-local configuration templates...${C_RESET}"

    ZSHRC_LOCAL="${WORK_TREE}/.zshrc.local"
    if [[ ! -f "$ZSHRC_LOCAL" ]]; then
        cat << 'EOF' > "$ZSHRC_LOCAL"
# ~/.zshrc.local - Machine-Specific Shell Overrides & Private Tokens (Untracked)
# export OPENAI_API_KEY=""
# export GITHUB_TOKEN=""
EOF
        chmod 600 "$ZSHRC_LOCAL"
        success "Created ${ZSHRC_LOCAL} template."
    fi

    GITCONFIG_LOCAL="${WORK_TREE}/.gitconfig.local"
    if [[ ! -f "$GITCONFIG_LOCAL" ]]; then
        cat << 'EOF' > "$GITCONFIG_LOCAL"
# ~/.gitconfig.local - Machine-Specific Git Identity (Untracked)
[user]
	name = Manel-Romero
	email = manel.romero.alv@gmail.com
EOF
        chmod 600 "$GITCONFIG_LOCAL"
        success "Created ${GITCONFIG_LOCAL} template."
    fi
fi

# ==============================================================================
# 11. Post-Install Module Hooks & Compilation
# ==============================================================================

# Compile bat_power only if waybar module was installed
if [[ " ${RESOLVED_MODULES[*]} " =~ " waybar " ]]; then
    echo -e "\n${C_BOLD}Step 5: Post-install hooks (Waybar helper binary)...${C_RESET}"
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
            warn "gcc is not installed. Install gcc to compile bat_power later."
        fi
    fi
fi

# Make scripts executable
if [[ -d "${WORK_TREE}/.local/bin" ]]; then
    chmod +x "${WORK_TREE}"/.local/bin/* 2>/dev/null || true
fi

# ==============================================================================
# 12. Security Audit with dotfiles-doctor
# ==============================================================================

echo -e "\n${C_BOLD}Step 6: Running security auditor (dotfiles-doctor)...${C_RESET}"
DOCTOR_BIN="${WORK_TREE}/.local/bin/dotfiles-doctor"
if [[ -x "$DOCTOR_BIN" ]]; then
    "$DOCTOR_BIN" --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" || {
        warn "dotfiles-doctor detected security or configuration warnings."
    }
else
    warn "dotfiles-doctor not found or not executable. Skipping automated security audit."
fi

# ==============================================================================
# 13. Summary & Next Steps
# ==============================================================================

echo -e "\n${C_BOLD}${C_GREEN}====================================================${C_RESET}"
echo -e "${C_BOLD}${C_GREEN}         Dotfiles Installation Complete!            ${C_RESET}"
echo -e "${C_BOLD}${C_GREEN}====================================================${C_RESET}"
echo -e "Installed Modules: ${C_CYAN}${RESOLVED_MODULES[*]}${C_RESET}"

if [[ $HAS_BACKUPS -eq 1 ]]; then
    echo -e "\n${C_YELLOW}Note: Pre-existing conflicting files were moved to:${C_RESET}"
    echo -e "   ${C_CYAN}${BACKUP_DIR}${C_RESET}"
fi

echo -e "\n${C_BOLD}Useful Commands:${C_RESET}"
echo -e " • Check status:           ${C_CYAN}dotfiles status${C_RESET}"
echo -e " • Add another module:     ${C_CYAN}./install-dotfiles.sh --add-module=<name>${C_RESET}"
echo -e " • List installed patterns:${C_CYAN}dotfiles sparse-checkout list${C_RESET}"
echo -e " • Run security doctor:    ${C_CYAN}dotfiles-doctor${C_RESET}\n"
