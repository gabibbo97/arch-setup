#!/usr/bin/env sh

# Cleanups
PartitionCleanDevice() {
  # Wipe device signatures from $1
  wipefs --all "$1"
}

# Partitions
PartitionESP() {
  # Create ESP as first partition of $1
  sgdisk --new=0:0:+512M --typecode=0:EF00 "$1"
}

PartitionLargestNewAsLUKS() {
  # Fill $1 remaining space with LUKS
  sgdisk --largest-new=0 --typecode=0:8309 "$1"
}

# Partition recipes
PartitionESPandLUKS () {
  # Partition $1 as a ESP+LUKS partition
  PartitionCleanDevice "$1"
  PartitionESP "$1"
  PartitionLargestNewAsLUKS "$1"
}