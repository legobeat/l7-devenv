# move history file to mount
HISTFILE=${HOME}/.local/histfile
HISTSIZE=100000
SAVEHIST=100000
REPORTTIME=15
WORDCHARS='*?.[]~=&;!#$%^(){}<>'

plugins=(git man)

set -o emacs

fpath+=($HOME/.zsh/pure)
autoload -Uz compinit promptinit
compinit
promptinit
prompt pure
zstyle :prompt:pure:git:fetch only_upstream yes

# sudo autocomplete
zstyle ':completion::complete:*' gain-privileges 1
setopt notify incappendhistory autocd extendedglob sharehistory extendedhistory HIST_REDUCE_BLANKS interactive_comments HIST_IGNORE_SPACE HIST_IGNORE_DUPS
unsetopt beep nomatch

# full history: https://stackoverflow.com/a/26848769
alias history='fc -l 1'
alias g='git'
alias ll='ls -laF'

# Source common shell env
if [ -f ~/.env ]; then
  . ~/.env
fi

# Source user mutable config
if [ -f ~/.config/zshrc ]; then
  . ~/.config/zshrc
fi
if [ -f ~/.local/zshrc ]; then
  . ~/.local/zshrc
fi
