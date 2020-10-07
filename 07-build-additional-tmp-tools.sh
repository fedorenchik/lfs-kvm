#!/bin/bash

set -e
set -v

cd /
cd /sources

### 7.5. Creating Directories
mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}
ln -sfv /run /var/run
ln -sfv /run/lock /var/lock
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

### 7.6. Creating Essential Files and Symlinks
ln -sfv /proc/self/mounts /etc/mtab
echo "127.0.0.1 localhost lfs10" > /etc/hosts
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
EOF
if [ "$KVM_LFS_INIT" == "systemd" ]; then
	cat >> /etc/passwd << "EOF"
systemd-bus-proxy:x:72:72:systemd Bus Proxy:/:/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/bin/false
systemd-network:x:76:76:systemd Network Management:/:/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/bin/false
EOF
fi
cat >> /etc/passwd << "EOF"
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF
cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
EOF
if [ "$KVM_LFS_INIT" == "systemd" ]; then
cat >> /etc/group << "EOF"
systemd-journal:x:23:
EOF
fi
cat >> /etc/group << "EOF"
input:x:24:
mail:x:34:
kvm:x:61:
EOF
if [ "$KVM_LFS_INIT" == "systemd" ]; then
cat >> /etc/group << "EOF"
systemd-bus-proxy:x:72:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
EOF
fi
cat >> /etc/group << "EOF"
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF
echo 'tester:x:1000:101::/home/tester:/bin/bash' >> /etc/passwd
echo 'tester:x:101:' >> /etc/group
install -o tester -d /home/tester
echo "SUCCESS - 7.1"
logout
