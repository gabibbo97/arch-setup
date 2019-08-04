#!/usr/bin/env sh

# Fail on error
set -e

# Utilities
compareAndCopy() {
  # $1 src $2 dst
  CHECK_SRC=$(sha512sum "$1" 2> /dev/null | awk '{ print $1 }')
  CHECK_DST=$(sha512sum "$2" 2> /dev/null | awk '{ print $1 }')

  if [ "$CHECK_SRC" = "$CHECK_DST" ]; then
    return
  fi
  cp "$1" "$2"
  printf 'Configured "%s"\n' "$2"
}

# Load settings or set defaults
if [ -z "$ENABLE_EDITOR" ]; then ENABLE_EDITOR='yes'; fi

# Configure boot loader
LOADER_CONF_TEMP=$(mktemp)

(
  printf '%s\n' \
    'auto-entries 1' \
    'auto-firmware 1' \
    'default arch' \
    'timeout 3'
  if [ "$ENABLE_EDITOR" = "yes" ]; then
    printf '%s\n' 'editor 1'
  fi
) > "$LOADER_CONF_TEMP"

compareAndCopy "$LOADER_CONF_TEMP" '/boot/loader/loader.conf'

rm -f "$LOADER_CONF_TEMP"

# Configure boot loader entries
mkdir -p /boot/loader/entries

genEntry() {
  # $1 filename
  # $2 name
  # $3 kernel
  # $4 initrd

  if ! [ -f "/boot${3}" ]; then return; fi
  if ! [ -f "/boot${4}" ]; then return; fi

  ENTRY_TEMP=$(mktemp)

  (
    printf '%s %s\n' \
      'title' 'Arch Linux' \
      'version' "$2" \
      'linux' "$3" \
      'initrd' "$4"

    if [ -f /boot/amd-ucode.img ]; then
      printf '%s %s\n' 'initrd' 'amd-ucode.img'
    fi
    if [ -f /boot/intel-ucode.img ]; then
      printf '%s %s\n' 'initrd' 'intel-ucode.img'
    fi

    if [ -f /boot/loader/cmdline.conf ]; then
      printf 'options '
      while IFS= read -r line; do
        printf '%s ' "$line"
      done < /boot/loader/cmdline.conf
      printf '\n'
    fi

  ) > "$ENTRY_TEMP"

  compareAndCopy "$ENTRY_TEMP" "/boot/loader/entries/${1}.conf"

  rm -f "$ENTRY_TEMP"
}

genEntry 'arch' 'Linux' '/vmlinuz-linux' '/initramfs-linux.img'
genEntry 'arch-fallback' 'Linux (fallback)' '/vmlinuz-linux' '/initramfs-linux-fallback.img'
genEntry 'arch-lts' 'Linux' '/vmlinuz-linux-lts' '/initramfs-linux-lts.img'
genEntry 'arch-lts-fallback' 'Linux (fallback)' '/vmlinuz-linux-lts' '/initramfs-linux-lts-fallback.img'
