export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(git)

if [ -n "$CONTAINER_ID" ]; then
    zstyle ':omz:update' mode disabled
fi

source $ZSH/oh-my-zsh.sh

# UPV
prompt_distrobox() {
    if [ -n "$CONTAINER_ID" ]; then
        prompt_segment 202 white " "
    fi
}

build_prompt() {
    RETVAL=$?
    prompt_status
    prompt_distrobox
    prompt_virtualenv
    prompt_context
    prompt_dir
    prompt_git
    prompt_bzr
    prompt_hg
    prompt_end
}

# CUSTOM
export EDITOR=nvim
export VISUAL=nvim

export XCURSOR_THEME="cruz"
export XCURSOR_SIZE="24"

alias clear='clear && printf "\e[3J"'

export GOPATH=$HOME/.local/share/go
export PATH=$PATH:$GOPATH/bin
export PATH="$PATH:$HOME/.local/bin"

export ANDROID_HOME=$HOME/.android/sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

eval "$(zoxide init zsh)"

if [ -z "$CONTAINER_ID" ]; then
    source <(fzf --zsh)
    eval $(thefuck --alias)
fi
export GPG_TTY=$(tty)
export PATH="$HOME/.cargo/bin:$PATH"

[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env

# Dotfiles bare git repository management alias
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'

# Local shell overrides & private variables (not tracked in dotfiles)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"