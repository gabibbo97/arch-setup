#!/usr/bin/env sh
set -e

SCRIPTPATH=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPTPATH")
LIBDIR="${SCRIPTDIR}/lib"

. "${LIBDIR}/LUKS.sh"
. "${LIBDIR}/partition.sh"

# Dual device
#
# LUKS (Integrity) -> LVM (Raid1) -> XFS
#
# /boot with RAID1
#

# Ask informations
while [ "$FIRST_DEVICE" = "$SECOND_DEVICE" ]; do
  # First
  while [ -z "$FIRST_DEVICE" ]; do
    lsblk
    printf 'Select first device: '
    read FIRST_DEVICE

    if [ -b "/dev/${FIRST_DEVICE}" ]; then
      FIRST_DEVICE="/dev/$FIRST_DEVICE"
      printf 'Corrected path to %s\n' "$FIRST_DEVICE"
    fi

    if ! [ -b "$FIRST_DEVICE" ]; then
      printf 'Device not found!\n'
      unset FIRST_DEVICE
    fi
  done
  # Second
  while [ -z "$SECOND_DEVICE" ]; do
    lsblk
    printf 'Select second device: '
    read SECOND_DEVICE

    if [ -b "/dev/${SECOND_DEVICE}" ]; then
      SECOND_DEVICE="/dev/$SECOND_DEVICE"
      printf 'Corrected path to %s\n' "$SECOND_DEVICE"
    fi

    if ! [ -b "$SECOND_DEVICE" ]; then
      printf 'Device not found!\n'
      unset SECOND_DEVICE
    fi
  done
  # Equal
  if [ "$FIRST_DEVICE" = "$SECOND_DEVICE" ]; then
    unset FIRST_DEVICE
    unset SECOND_DEVICE
    printf 'Select two different devices!\n'
  fi
done

# Partition the drives
for DEVICE in $FIRST_DEVICE $SECOND_DEVICE
do
  PartitionESPandLUKS "$DEVICE"
done

# Setup LUKS
for DEVICE in $FIRST_DEVICE $SECOND_DEVICE
do
  LUKSFormatWithIntegrity "${DEVICE}2"
done

# Open LUKS
LUKSOpen "${FIRST_DEVICE}2" 'cryptlvm1'
LUKSOpen "${SECOND_DEVICE}2" 'cryptlvm2'

# Setup LVM raid on LUKS
pvcreate /dev/mapper/cryptlvm1
pvcreate /dev/mapper/cryptlvm2

vgcreate Arch \
  /dev/mapper/cryptlvm1 /dev/mapper/cryptlvm2

lvcreate -L 8G \
  --mirrors 1 \
  Arch --name Swap
lvcreate -l 100%FREE \
  --mirrors 1 \
  Arch --name Root

# RAID boot partition
mdadm \
  --create \
  --verbose \
  --metadata=1.0 \
  --raid-devices=2 \
  --level=raid1 \
  /dev/md/mdboot \
  "${FIRST_DEVICE}1" \
  "${SECOND_DEVICE}1"

# Create filesystems
mkfs.fat -F32 -n ARCHBOOT /dev/md/mdboot
mkswap -f -L ARCHSWAP /dev/Arch/Swap
mkfs.xfs -f -m reflink=1 -L ARCHROOT /dev/Arch/Root

# Write scripts
cat > mount_fs.sh <<EOF
swapon /dev/Arch/Swap
mount /dev/Arch/Root /mnt
mkdir -p /mnt/boot
mount /dev/md/mdboot /mnt/boot
EOF

cat > bootopts.txt <<EOF
rd.luks.name=$(blkid -o value -s UUID ${FIRST_DEVICE}2)=cryptlvm1
rd.luks.name=$(blkid -o value -s UUID ${SECOND_DEVICE}2)=cryptlvm2
resume=/dev/Arch/Swap
root=/dev/Arch/Root
EOF
