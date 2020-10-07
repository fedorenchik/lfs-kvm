#!/bin/bash

set -e
set -v

cd /
cd /sources

if [ "$KVM_LFS_INIT" == "sysvinit" ]; then
	tar -xf lfs-bootscripts-20200818.tar.xz
	cd lfs-bootscripts-20200818
	make install
	bash /lib/udev/init-net-rules.sh
	cat /etc/udev/rules.d/70-persistent-net.rules
	cd ..
	rm -rf lfs-bootscripts-20200818
	udevadm test /sys/block/nbd0
	cd /etc/sysconfig/
	cat > ifconfig.eth0 << "EOF"
ONBOOT=yes
IFACE=ens3
SERVICE=ipv4-static
IP=192.168.122.12
GATEWAY=192.168.122.1
PREFIX=24
BROADCAST=192.168.122.255
EOF
elif [ "$KVM_LFS_INIT" == "systemd" ]; then
	mkdir -vp /etc/systemd/network
	cat > /etc/systemd/network/10-eth-static.network << "EOF"
[Match]
Name=ens0

[Network]
Address=192.168.122.12
Gateway=192.168.122.1
Domains=lfs10
EOF
	cat > /etc/systemd/network/10-eth-dhcp.network << "EOF"
[Match]
Name=ens0

[Network]
DHCP=ipv4

[DHCP]
UseDomains=true
EOF
	#ln -sfv /run/systemd/resolve/resolv.conf /etc/resolv.conf
fi
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

nameserver 1.1.1.1
nameserver 1.0.0.1

# End /etc/resolv.conf
EOF
echo "lfs10" > /etc/hostname
cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost.localdomain localhost
127.0.1.1 lfs10.example.org lfs10
192.168.122.12 lfs10.example.org lfs10
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

# End /etc/hosts
EOF
mkdir -pv /etc/modprobe.d
echo "blacklist forte" >> /etc/modprobe.d/blacklist.conf
if [ "$KVM_LFS_INIT" == "sysvinit" ]; then
	cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S016:once:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF
	cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF
cat > /etc/profile << "EOF"
# Begin /etc/profile

export LANG=en_US.ISO-8859-1

# End /etc/profile
EOF
elif [ "$KVM_LFS_INIT" = "systemd" ]; then
	cat > /etc/locale.conf << "EOF"
LANG=en_US.ISO-8859-1
EOF
fi
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF
cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF
if [ "$KVM_LFS_INIT" == "systemd" ]; then
	mkdir -pv /etc/systemd/coredump.conf.d
	cat > /etc/systemd/coredump.conf.d/maxuse.conf << EOF
[Coredump]
MaxUse=5G
EOF
	#loginctl enable-linger
	echo "KillUserProcesses=no" >> /etc/systemd/logind.conf
fi
cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type      options               dump  fsck
#                                                                 order

/dev/vda1      /            ext4      defaults              1     1
/dev/vda2      swap         swap      pri=1                 0     0
EOF
if [ "$KVM_LFS_INIT" == "sysvinit" ]; then
	cat >> /etc/fstab << "EOF"
proc           /proc        proc      nosuid,noexec,nodev   0     0
sysfs          /sys         sysfs     nosuid,noexec,nodev   0     0
devpts         /dev/pts     devpts    gid=5,mode=620        0     0
tmpfs          /run         tmpfs     defaults              0     0
devtmpfs       /dev         devtmpfs  mode=0755,nosuid      0     0
EOF
fi
cat >> /etc/fstab << "EOF"

# End /etc/fstab
EOF
cd /
cd /sources
tar -xf linux-5.8.3.tar.xz
cd linux-5.8.3
make mrproper
zcat /proc/config.gz > .config
yes '' | make oldconfig
sed -e 's/.*\bCONFIG_UEVENT_HELPER\b.*/# CONFIG_UEVENT_HELPER is not set (required by LFS)/' -i .config
sed -e 's/.*\bCONFIG_DEVTMPFS\b.*/CONFIG_DEVTMPFS=y/' -i .config
sed -e 's/.*\bCONFIG_EFI_STUB\b.*/CONFIG_EFI_STUB=y/' -i .config
sed -e 's/.*\bCONFIG_EXT4_FS\b.*/CONFIG_EXT4_FS=y/' -i .config
sed -e 's/.*\bCONFIG_VIRTIO_BLK\b.*/CONFIG_VIRTIO_BLK=y/' -i .config
sed -e 's/.*\bCONFIG_SCSI_VIRTIO\b.*/CONFIG_SCSI_VIRTIO=y/' -i .config
sed -e 's/.*\bCONFIG_VIRTIO_CONSOLE\b.*/CONFIG_VIRTIO_CONSOLE=y/' -i .config
sed -e 's/.*\bCONFIG_VIRTIO_PCI\b.*/CONFIG_VIRTIO_PCI=y/' -i .config
if [ "$KVM_LFS_INIT" == "systemd" ]; then
	sed -e 's/.*\bCONFIG_CGROUPS\b.*/CONFIG_CGROUPS=y/' -i .config
	sed -e 's/.*\bCONFIG_SYSFS_DEPRECATED\b.*/# CONFIG_SYSFS_DEPRECATED is not set (required by LFS)/' -i .config
	sed -e 's/.*\bCONFIG_EXPERT\b.*/CONFIG_EXPERT=y/' -i .config
	sed -e 's/.*\bCONFIG_FHANDLE\b.*/CONFIG_FHANDLE=y/' -i .config
	sed -e 's/.*\bCONFIG_AUDIT\b.*/# CONFIG_AUDIT is not set (required by LFS)/' -i .config
	sed -e 's/.*\bCONFIG_SECCOMP\b.*/CONFIG_SECCOMP=y/' -i .config
	sed -e 's/.*\bCONFIG_DMIID\b.*/CONFIG_DMIID=y/' -i .config
	sed -e 's/.*\bCONFIG_IPV6\b.*/CONFIG_IPV6=y/' -i .config
	sed -e 's/.*\bCONFIG_FW_LOADER_USER_HELPER\b.*/# CONFIG_FW_LOADER_USER_HELPER is not set (required by LFS)/' -i .config
	sed -e 's/.*\bCONFIG_INOTIFY_USER\b.*/CONFIG_INOTIFY_USER=y/' -i .config
	sed -e 's/.*\bCONFIG_AUTOFS_FS\b.*/CONFIG_AUTOFS_FS=y/' -i .config
	sed -e 's/.*\bCONFIG_TMPFS_POSIX_ACL\b.*/CONFIG_TMPFS_POSIX_ACL=y/' -i .config
	sed -e 's/.*\bCONFIG_TMPFS_XATTR\b.*/CONFIG_TMPFS_XATTR=y/' -i .config
fi
make kernelversion
make kernelrelease
make
make modules_install
cp -iv arch/x86_64/boot/bzImage /boot/vmlinuz-5.8.3-lfs-10.0
cp -iv System.map /boot/System.map-5.8.3
cp -iv .config /boot/config-5.8.3
install -d /usr/share/doc/linux-5.8.3
cp -r Documentation/* /usr/share/doc/linux-5.8.3
chown -R 0:0 .
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF
grub-install --target i386-pc --force /dev/nbd0
cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg

set default=0
set timeout=5

insmod ext2
set root=(hd0,gpt1)

menuentry "GNU/Linux, Linux 5.8.3-lfs-10.0" {
        linux   /boot/vmlinuz-5.8.3-lfs-10.0 loglevel=7 root=/dev/vda1 ro
}
EOF

echo 10.0 > /etc/lfs-release
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="10.0"
DISTRIB_CODENAME="KVM Edition"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF

cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="10.0"
ID=lfs
PRETTY_NAME="Linux From Scratch 10.0"
VERSION_CODENAME="KVM Edition"
EOF

logout
