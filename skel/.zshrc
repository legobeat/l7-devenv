# if this is a terminal in a graphical environment and not already in tmux, start it
if [ -t ] && [[ -z "$TMUX" ]] && ([[ ! -z "$DISPLAY" ]] || [[ ! -z "$L7_DISPLAY" ]] || [[ ! -z "$WAYLAND_DISPLAY" ]]) && command -pv tmux >/dev/null; then
  exec tmux -2
fi

# move history file to mount
HISTFILE=${HOME}/.local/histfile
HISTSIZE=100000
SAVEHIST=100000
REPORTTIME=15
WORDCHARS='*?.[]~=&;!#$%^(){}<>'

plugins=(
  git
  man
)

set -o emacs

fpath+=($HOME/.zsh/pure)
autoload -Uz compinit promptinit
promptinit
prompt pure
# prevent git auto fetch from prompt
export PURE_GIT_PULL=0
zstyle :prompt:pure:git:fetch only_upstream yes

if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
fi

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

source /usr/share/zsh/plugins/zsh-completions/zsh-completions.plugin.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/fzf/fzf.plugin.zsh

compinit

# Source user mutable config
if [ -f ~/.config/zshrc ]; then
  . ~/.config/zshrc
fi
if [ -f ~/.local/zshrc ]; then
  . ~/.local/zshrc
fi
