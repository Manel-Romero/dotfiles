#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Dotfiles bare git repository management alias
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'

# Local shell overrides & private variables (not tracked in dotfiles)
[ -f "$HOME/.bashrc.local" ] && source "$HOME/.bashrc.local"
