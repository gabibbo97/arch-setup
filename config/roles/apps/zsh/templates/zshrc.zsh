# Plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Completions
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1

setopt COMPLETE_ALIASES

# Prompt
autoload -Uz promptinit
promptinit
prompt fade red

# Aliases
## Colors
alias diff='diff --color=auto'
alias egrep='egrep --colour=auto'
alias fgrep='fgrep --colour=auto'
alias grep='grep --color=auto'
alias ls='ls --color=auto'
## Functions
alias cp='cp --reflink=auto'
alias rm='rm --preserve-root'
alias top='htop'
alias swayreload='swaymsg reload'
