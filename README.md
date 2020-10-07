# lfs-kvm

## Description

Create qcow2 image for KVM (QEMU) of LFS 10.0 x86_64 systemd or sysvinit.

The scripts mimics the LFS 10.0 book as close as possible.

## Features

* Downloads all code automatically
* Creates qcow2 image
* Builds LFS 10.0
* Supports systemd or sysvinit
* Can be resumed from almost every step

## Prerequisites

* Linux
* QEMU

## Usage

* First run 02-version-check.sh and confirm all software with the book.
* Then run lfs-kvm.sh to make lfs qcow2 image.

```
02-version-check.sh
./lfs-builder.sh [start-chapter]
```
`start-chapter` - from which chapter (to continue) building

### How to choose init system:

Modify variable KVM_LFS_INIT in lfs-kvm.sh.

Supported values:
```
systemd
sysvinit
```

## Side Effects

### Permanent:

* Creates lfs user
* Creates lfs group
* Creates `/mnt/lfs` directory

### Temporary:

During build:

* Mounts `/mnt/lfs`
* Mounts temporary filesystems
* Connects nbd device to qcow2 image

## Difference compared to ALFS

* Builds version 10.0 (latest version ALFS supports is 8.0)
* Uses shell scripts directly (ALFS extracts build instructions from LFS
    sources)

## Contributing

Send PR or open an issue.
