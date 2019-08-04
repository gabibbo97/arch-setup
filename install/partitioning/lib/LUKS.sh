#!/usr/bin/env sh

LUKSAskPass() {
  # Ask LUKS password
  while [ -z "$LUKS_PASSPHRASE" ]; do
    printf 'LUKS password:          '
    read LUKS_PASSPHRASE

    printf 'LUKS password (repeat): '
    read LUKS_PASSPHRASE_2

    if [ "$LUKS_PASSPHRASE" != "$LUKS_PASSPHRASE_2" ]; then
      unset LUKS_PASSPHRASE
      unset LUKS_PASSPHRASE_2

      printf 'Passwords does not match!\n'
    fi

  done
}

LUKSFormat() {
  # Format $1 as LUKS device
  LUKSAskPass
  printf '%s' "$LUKS_PASSPHRASE" \
    | cryptsetup luksFormat "$1" \
        --key-file - \
        --type luks2
}

LUKSFormatWithIntegrity() {
  # Format $1 as LUKS device, installing also dm-integrity
  LUKSAskPass
  LUKSFormat "$1"
  return
  # TODO
  printf '%s' "$LUKS_PASSPHRASE" \
    | cryptsetup luksFormat "$1" \
        --key-file - \
        --integrity hmac-sha512
        --type luks2
}

LUKSOpen() {
  # Open $1 with $2 as its name
  LUKSAskPass
  printf '%s' "$LUKS_PASSPHRASE" \
    | cryptsetup open "$1" "$2" \
        --type luks2 \
        --key-file -
}