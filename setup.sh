#!/usr/bin/env sh

set -e

if ! [ -x "$(command -v ansible)" ]; then sudo pacman -Sy && sudo pacman -S ansible; fi

exec ansible-playbook arch.yml "$@"
