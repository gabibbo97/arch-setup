#!/usr/bin/env sh
set -e

# Variables
ARCH_MIRROR='http://mirrors.evowise.com/archlinux/iso'
ARCH_VERSION='2019.08.01'
TEMP_PREFIX='/run/media/giacomo/Lentone'

# Calculated variables
ARCH_ISO="archlinux-${ARCH_VERSION}-x86_64.iso"

ARCH_ISO_URL="${ARCH_MIRROR}/${ARCH_VERSION}/${ARCH_ISO}"

# Download
dl() {
  if [ -f "$2" ]; then return; fi
  printf 'Downloading from %s\n' "$1"
  curl -L "$1" -o "$2"
}
dl "${ARCH_ISO_URL}" "${ARCH_ISO}"

# Create drives
cleanup() {
  [ -n "$QEMU_DISK_DIR" ] || exit
  rm -rf "$QEMU_DISK_DIR"
}
trap cleanup EXIT HUP ERR
QEMU_DISK_DIR="$(mktemp -d -p $TEMP_PREFIX)"

qemu-img create -f qcow2 "${QEMU_DISK_DIR}/slow1.qcow2" 20G
qemu-img create -f qcow2 "${QEMU_DISK_DIR}/slow2.qcow2" 20G
qemu-img create -f qcow2 "${QEMU_DISK_DIR}/fast1.qcow2" 10G
qemu-img create -f qcow2 "${QEMU_DISK_DIR}/fast2.qcow2" 10G

# Find OVMF
OVMF_PATH=''
if [ -f /usr/share/OVMF/OVMF_CODE.fd ]; then
  OVMF_PATH='/usr/share/OVMF/OVMF_CODE.fd'
fi
if [ -z "$OVMF_PATH" ]; then
  printf 'Could not find OVMF\n' > /dev/stderr
  exit 1
fi

# Launch Arch
## mkdir /opt/arch-setup
## mount -t 9p -o trans=virtio archsetup /opt/arch-setup
qemu-system-x86_64 \
  -cpu host \
  -accel kvm \
  -smp 2 \
  -m 2048 \
  -cdrom "${ARCH_ISO}" \
  -drive "file=${QEMU_DISK_DIR}/slow1.qcow2,format=qcow2,id=slow1,if=virtio" \
  -drive "file=${QEMU_DISK_DIR}/slow2.qcow2,format=qcow2,id=slow2,if=virtio" \
  -drive "file=${QEMU_DISK_DIR}/fast1.qcow2,format=qcow2,id=fast1,if=virtio" \
  -drive "file=${QEMU_DISK_DIR}/fast2.qcow2,format=qcow2,id=fast2,if=virtio" \
  -netdev user,id=network -device virtio-net,netdev=network \
  -device AC97 \
  -virtfs "local,path=$PWD,mount_tag=archsetup,security_model=mapped-xattr" \
  -bios "$OVMF_PATH"
