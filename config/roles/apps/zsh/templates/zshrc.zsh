# Autostart Sway
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
  exec sway
fi

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

alias docker-clean='docker system prune --all --force --volumes'
alias docker-kill='docker ps -aq | xargs -r docker rm --force'

## Containers
__docker_alias() {
  # Run $1 with $2 as entrypoint
  IMAGE="$1"
  ENTRYPOINT="$2"

  shift && shift

  docker run --rm -it \
    --volume "$PWD:/run/docker-host-pwd" \
    --workdir /run/docker-host-pwd \
    --network host \
    --entrypoint "$ENTRYPOINT" \
    "$IMAGE" "$@"
}
alias bsondump='__docker_alias "mongo" "bsondump"'
alias mongo='__docker_alias "mongo" "mongo"'
alias mongod='__docker_alias "mongo" "mongod"'
alias mongodump='__docker_alias "mongo" "mongodump"'
alias mongoexport='__docker_alias "mongo" "mongoexport"'
alias mongofiles='__docker_alias "mongo" "mongofiles"'
alias mongoimport='__docker_alias "mongo" "mongoimport"'
alias mongoreplay='__docker_alias "mongo" "mongoreplay"'
alias mongorestore='__docker_alias "mongo" "mongorestore"'
alias mongos='__docker_alias "mongo" "mongos"'
alias mongostat='__docker_alias "mongo" "mongostat"'
alias mongotop='__docker_alias "mongo" "mongotop"'

# User defined functions
{% for fun in
  [
    'functions/ksmstatus.zsh',
    'functions/ksmtoggle.zsh'
  ]
%}
{% include fun %}

{% endfor %}
