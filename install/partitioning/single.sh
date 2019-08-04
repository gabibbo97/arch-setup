#!/usr/bin/env sh
set -e

SCRIPTPATH=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPTPATH")
LIBDIR="${SCRIPTDIR}/lib"

. "${LIBDIR}/LUKS.sh"
. "${LIBDIR}/partition.sh"

# Single device
#
# LUKS -> LVM -> XFS
#

# Ask informations
while [ -z "$ROOT_DEVICE" ]; do
  lsblk
  printf 'Select root device: '
  read ROOT_DEVICE

  if [ -b "/dev/${ROOT_DEVICE}" ]; then
    ROOT_DEVICE="/dev/$ROOT_DEVICE"
    printf 'Corrected path to %s\n' "$ROOT_DEVICE"
  fi

  if ! [ -b "$ROOT_DEVICE" ]; then
    printf 'Device not found!\n'
    unset ROOT_DEVICE
  fi
done

# Partition the drive
PartitionESPandLUKS "$ROOT_DEVICE"

# Setup LUKS
LUKSFormat "${ROOT_DEVICE}2"

# Open LUKS
LuksOpen "${ROOT_DEVICE}2" 'cryptlvm'

# Setup LVM on LUKS
pvcreate /dev/mapper/cryptlvm
vgcreate Arch /dev/mapper/cryptlvm
lvcreate -L 8G Arch --name Swap
lvcreate -l 100%FREE Arch --name Root

# Format filesystems
mkfs.fat -F32 -n ARCHBOOT "${ROOT_DEVICE}1"
mkswap -f -L ARCHSWAP /dev/Arch/Swap
mkfs.xfs -f -m reflink=1 -L ARCHROOT /dev/Arch/Root

# Write scripts
cat > mount_fs.sh <<EOF
swapon /dev/Arch/Swap
mount /dev/Arch/Root /mnt
mkdir -p /mnt/boot
mount ${ROOT_DEVICE}1 /mnt/boot
EOF

cat > bootopts.txt <<EOF
rd.luks.name=$(blkid -o value -s UUID ${ROOT_DEVICE}2)=cryptlvm
resume=/dev/Arch/Swap
root=/dev/Arch/Root
EOF
