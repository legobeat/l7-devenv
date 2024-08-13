# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return;;
esac

# move history file to mount
HISTFILE="${HOME}/.local/bash_history"
HISTSIZE=100000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth

shopt -s checkwinsize
shopt -s globstar
shopt -s histappend

if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
fi

alias ll='ls -laF'
alias g='git'


# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Source common shell env
if [ -f ~/.env ]; then
  . ~/.env
fi

# Source user mutable config
if [ -f ~/.config/bashrc ]; then
  . ~/.config/bashrc
fi
if [ -f ~/.local/bashrc ]; then
  . ~/.local/bashrc
fi

# if this is a terminal in a graphical environment and not already in tmux, start it
if [ -t ] && [[ -z "$TMUX" ]] && ([[ ! -z "$DISPLAY" ]] || [[ ! -z "$L7_DISPLAY" ]] || [[ ! -z "$WAYLAND_DISPLAY" ]]) && command -pv tmux >/dev/null; then
  exec tmux -2
fi
