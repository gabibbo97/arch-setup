#!/usr/bin/env sh

set -e

if ! [ -x "$(command -v sudo)" ] && [ $UID -eq 0 ]; then pacman -Sy && pacman -S --noconfirm sudo; fi
if ! [ -x "$(command -v ansible)" ]; then sudo pacman -Sy && sudo pacman -S --noconfirm ansible; fi

exec ansible-playbook arch.yml "$@"
