#!/bin/bash

# requirements: sudo nproc qemu-img qemu-nbd parted partprobe

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 2
fi

set -e
set -x

IMAGE_SIZE=512
IMAGE_DIR=$(pwd)
IMAGE_NAME=lfs-10-0.qcow2
IMAGE_PATH=${IMAGE_DIR}/${IMAGE_NAME}
export NPROC=$(nproc)
let NPROCx4=$NPROC*4
export NPROCx4
# KVM_LFS_INIT can be systemd or sysvinit
KVM_LFS_INIT="systemd"
export KVM_LFS_INIT
CURRENT_TTY=$(tty)

export LFS=/mnt/lfs

KVM_LFS_CONTINUE="$1"
if [ "$KVM_LFS_CONTINUE" == "" ]; then
	KVM_LFS_CONTINUE="2.4"
fi
export KVM_LFS_CONTINUE

case "$KVM_LFS_CONTINUE" in
"2.4")
	# create qcow2 image
	if [ ! -e ${IMAGE_PATH} ]; then
		qemu-img create -f qcow2 ${IMAGE_PATH} ${IMAGE_SIZE}G
	fi

	# create ext4 fs
	if ! lsmod | grep -q nbd; then
		sudo modprobe nbd max_part=16
	fi
	if [ ! -e /sys/class/block/nbd0/pid ]; then
		sudo qemu-nbd -c /dev/nbd0 ${IMAGE_PATH}
	fi
	if [ ! -e /dev/nbd0p1 ]; then
		sudo parted /dev/nbd0 mklabel gpt mkpart lfs_root ext4 1MiB 128GiB mkpart lfs_swap linux-swap 496GiB 511GiB
		sudo partprobe /dev/nbd0
		sudo mkfs -v -t ext4 /dev/nbd0p1
		sudo mkswap /dev/nbd0p2
	fi
;&

"2.7")
	if [ ! -e $LFS ]; then
		sudo mkdir -pv $LFS
	fi
	if ! mount -t ext4 | grep -q /dev/nbd0p1; then
		sudo mount -v -t ext4 /dev/nbd0p1 $LFS
	fi
;&

"3.1")
	# download packages
	if [ ! -e $LFS/sources/md5sums-all-OK ]; then
		sudo mkdir -pv $LFS/sources
		sudo chmod -v a+wt $LFS/sources
		LFS_PKG_URL="http://ftp.lfs-matrix.net/pub/lfs/lfs-packages/10.0/"
		wget --continue --directory-prefix=$LFS/sources \
			"$LFS_PKG_URL"/wget-list
		wget --continue --directory-prefix=$LFS/sources \
			"$LFS_PKG_URL"/md5sums
		while [ ! -e $LFS/sources/md5sums-all-OK ]; do
			#wget -nv --input-file=$LFS/sources/wget-list --continue --directory-prefix=$LFS/sources
			for pkg in $(cat $LFS/sources/wget-list); do
				wget --continue --directory-prefix=$LFS/sources \
					"$LFS_PKG_URL"/$(basename $pkg)
			done
			pushd $LFS/sources
			md5sum -c md5sums && touch md5sums-all-OK || true
			popd
		done
	fi
;&

"4.2")
	# create directory layout
	sudo mkdir -pv $LFS/{bin,etc,lib,sbin,usr,var}
	case $(uname -m) in
		x86_64) sudo mkdir -pv $LFS/lib64 ;;
	esac
	sudo mkdir -pv $LFS/tools
;&

"4.3")
	# create lfs user
	if ! id lfs &>/dev/null; then
		groupadd lfs
		useradd -s /bin/bash -g lfs -m -k /dev/null lfs
		echo "lfs:lfs" | chpasswd
	fi
	sudo chown -v lfs $LFS/{usr,lib,var,etc,bin,sbin,tools}
	case $(uname -m) in
		x86_64) sudo chown -v lfs $LFS/lib64 ;;
	esac
	sudo chown -v lfs $LFS/sources
;&

"4.4")
	sudo su -c 'cat > ~lfs/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM KVM_LFS_CONTINUE=$KVM_LFS_CONTINUE PS1='"'"'\u:\w\$ '"'"' /bin/bash
EOF' lfs
	sudo su -c 'cat > ~lfs/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
export LFS LC_ALL LFS_TGT PATH
EOF' lfs
	sudo su -c "echo \"export MAKEFLAGS='-j$NPROC'\" >> ~lfs/.bashrc" lfs
	sudo su -c "echo \"export NPROC=$NPROC\" >> ~lfs/.bashrc" lfs
	sudo su -c "echo \"export NPROCx4=$NPROCx4\" >> ~lfs/.bashrc" lfs
	sudo su -c "echo \"export KVM_LFS_INIT=$KVM_LFS_INIT\" >> ~lfs/.bashrc" lfs

	# rename /etc/bash.bashrc
	[ ! -e /etc/bash.bashrc ] || sudo mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
	KVM_LFS_CONTINUE="5.2"
;&

5.*)
	# as user lfs
	sudo -u lfs KVM_LFS_CONTINUE=$KVM_LFS_CONTINUE -i < ./05-compile-cross-toolchain.sh
	KVM_LFS_CONTINUE="6.2"
;&

6.*)
	sudo -u lfs KVM_LFS_CONTINUE=$KVM_LFS_CONTINUE -i < ./06-cross-compile-tmp-tools.sh
;&

"7.2")
	### 7.2. Changing Ownership
	sudo chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
	case $(uname -m) in
		x86_64)
			sudo chown -R root:root $LFS/lib64
			;;
	esac
;&

"7.3")
	### 7.3. Preparing Virtual Kernel File Systems
	sudo mkdir -pv $LFS/{dev,proc,sys,run}
	if [ ! -e $LFS/dev/console ]; then
		sudo mknod -m 600 $LFS/dev/console c 5 1
	fi
	if [ ! -e $LFS/dev/null ]; then
		sudo mknod -m 666 $LFS/dev/null c 1 3
	fi
	if ! mount -t devtmpfs | grep $LFS/dev; then
		sudo mount -v --bind /dev $LFS/dev
	fi
	if ! mount -t devpts | grep $LFS/dev/pts; then
		sudo mount -v --bind /dev/pts $LFS/dev/pts
	fi
	if ! mount -t proc | grep $LFS/proc; then
		sudo mount -vt proc proc $LFS/proc
	fi
	if ! mount -t sysfs | grep $LFS/sys; then
		sudo mount -vt sysfs sysfs $LFS/sys
	fi
	if ! mount -t tmpfs | grep $LFS/run; then
		sudo mount -vt tmpfs tmpfs $LFS/run
	fi
	if [ -h $LFS/dev/shm ]; then
		sudo mount -pv $LFS/$(readlink $LFS/dev/shm)
	fi
	KVM_LFS_CONTINUE="7.4"
;&

"7.4")
	### 7.4. Entering the Chroot Environment
	sudo chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" \
		PS1='(lfs chroot) \u:\w\$ ' PATH=/bin:/usr/bin:/sbin:/usr/sbin \
		KVM_LFS_INIT="$KVM_LFS_INIT" KVM_LFS_CONTINUE="$KVM_LFS_CONTINUE" \
		NPROC="$NPROC" NPROCx4="$NPROCx4" MAKEFLAGS="-j$NPROC" \
		/bin/bash --login +h < 07-build-additional-tmp-tools.sh

	sudo chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" \
		PS1='(lfs chroot) \u:\w\$ ' PATH=/bin:/usr/bin:/sbin:/usr/sbin \
		KVM_LFS_INIT="$KVM_LFS_INIT" KVM_LFS_CONTINUE="$KVM_LFS_CONTINUE" \
		NPROC="$NPROC" NPROCx4="$NPROCx4" MAKEFLAGS="-j$NPROC" \
		/bin/bash --login +h < 07-2-build-additional-tmp-tools.sh

	sudo umount $LFS/dev{/pts,}
	sudo umount $LFS/{sys,proc,run}
;&

"7.14.1")
	sudo strip --strip-debug $LFS/usr/lib/* || true
	sudo strip --strip-unneeded $LFS/usr/{,s}bin/* || true
	sudo strip --strip-unneeded $LFS/tools/bin/* || true
;&

"7.14.2")
	cd $LFS
	sudo tar -czpf $IMAGE_DIR/lfs-temp-tools-10.0.tar.gz .
;&

"7.14.3")
	function restore()
	{
		cd $LFS
		rm -rf ./*
		sudo tar -xpf $HOME/lfs-temp-tools-10.0.tar.gz
	}

	sudo mount -v --bind /dev $LFS/dev
	sudo mount -v --bind /dev/pts $LFS/dev/pts
	sudo mount -vt proc proc $LFS/proc
	sudo mount -vt sysfs sysfs $LFS/sys
	sudo mount -vt tmpfs tmpfs $LFS/run
	if [ -h $LFS/dev/shm ]; then
		sudo mount -pv $LFS/$(readlink $LFS/dev/shm)
	fi
	KVM_LFS_CONTINUE="8.3"
;&

8.[1-9]) ;&
8.2[0-9]) ;&
8.3[0-4])
	cd $IMAGE_DIR
	sudo chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" \
		PS1='(lfs chroot) \u:\w\$ ' PATH=/bin:/usr/bin:/sbin:/usr/sbin \
		KVM_LFS_INIT="$KVM_LFS_INIT" KVM_LFS_CONTINUE="$KVM_LFS_CONTINUE" \
		NPROC="$NPROC" NPROCx4="$NPROCx4" MAKEFLAGS="-j$NPROC" \
		CURRENT_TTY="$CURRENT_TTY" \
		/bin/bash --login +h < 08-install-basic-system-sw.sh
	KVM_LFS_CONTINUE="8.34.2"
;&

8.*)
	sudo chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" \
		PS1='(lfs chroot) \u:\w\$ ' PATH=/bin:/usr/bin:/sbin:/usr/sbin \
		KVM_LFS_INIT="$KVM_LFS_INIT" KVM_LFS_CONTINUE="$KVM_LFS_CONTINUE" \
		NPROC="$NPROC" NPROCx4="$NPROCx4" MAKEFLAGS="-j$NPROC" \
		/bin/bash --login +h < 08-2-install-basic-system-sw.sh

	sudo chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" \
		PS1='(lfs chroot) \u:\w\$ ' PATH=/bin:/usr/bin:/sbin:/usr/sbin \
		KVM_LFS_INIT="$KVM_LFS_INIT" KVM_LFS_CONTINUE="$KVM_LFS_CONTINUE" \
		NPROC="$NPROC" NPROCx4="$NPROCx4" MAKEFLAGS="-j$NPROC" \
		/bin/bash --login < 08-3-install-basic-system-sw.sh
	KVM_LFS_CONTINUE="9.1"
;&

"9.1")
	sudo chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" \
		PS1='(lfs chroot) \u:\w\$ ' PATH=/bin:/usr/bin:/sbin:/usr/sbin \
		KVM_LFS_INIT="$KVM_LFS_INIT" KVM_LFS_CONTINUE="$KVM_LFS_CONTINUE" \
		NPROC="$NPROC" NPROCx4="$NPROCx4" MAKEFLAGS="-j$NPROC" \
		/bin/bash --login < 09-system-config.sh
;&

"11.3")
	sudo umount -v $LFS/dev/pts
	sudo umount -v $LFS/dev
	sudo umount -v $LFS/run
	sudo umount -v $LFS/proc
	sudo umount -v $LFS/sys
	cd
	sudo umount -v $LFS

	### END
	[ ! -e /etc/bash.bashrc.NOUSE ] || sudo mv -v /etc/bash.bashrc.NOUSE /etc/bash.bashrc
	sudo qemu-nbd -d /dev/nbd0
	#sudo modprobe -r nbd
;&
esac
