#!/bin/bash

set -e
set -v

cd /
cd /sources

### 7.6. Creating Essential Files and Symlinks Continued
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664 /var/log/lastlog
chmod -v 600 /var/log/btmp

### 7.7. Libstdc++ from GCC-10.2.0, Pass 2
tar -xf gcc-10.2.0.tar.xz
cd gcc-10.2.0
ln -s gthr-posix.h libgcc/gthr-default.h
mkdir -v build
cd build
../libstdc++-v3/configure CXXFLAGS="-g -O2 -D_GNU_SOURCE" --prefix=/usr \
	--disable-multilib --disable-nls --host=$(uname -m)-lfs-linux-gnu \
	--disable-libstdcxx-pch
make
make install
cd ../..
rm -rf gcc-10.2.0

### 7.8. Gettext-0.21
tar -xf gettext-0.21.tar.xz
cd gettext-0.21
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
cd ..
rm -rf gettext-0.21

### 7.9. Bison-3.7.1
tar -xf bison-3.7.1.tar.xz
cd bison-3.7.1
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.7.1
make
make install
cd ..
rm -rf bison-3.7.1

### 7.10. Perl-5.32.0
tar -xf perl-5.32.0.tar.xz
cd perl-5.32.0
sh Configure -des -Dprefix=/usr -Dvendorprefix=/usr \
	-Dprivlib=/usr/lib/perl5/5.32/core_perl \
	-Darchlib=/usr/lib/perl5/5.32/core_perl \
	-Dsitelib=/usr/lib/perl5/5.32/site_perl \
	-Dsitearch=/usr/lib/perl5/5.32/site_perl \
	-Dvendorlib=/usr/lib/perl5/5.32/vendor_perl \
	-Dvendorarch=/usr/lib/perl5/5.32/vendor_perl
make
make install
cd ..
rm -rf perl-5.32.0

### 7.11. Python-3.8.5
tar -xf Python-3.8.5.tar.xz
cd Python-3.8.5
./configure --prefix=/usr --enable-shared --without-ensurepip
make
make install
cd ..
rm -rf Python-3.8.5

### 7.12. Texinfo-6.7
tar -xf texinfo-6.7.tar.xz
cd texinfo-6.7
./configure --prefix=/usr
make
make install
cd ..
rm -rf texinfo-6.7

### 7.13. Util-linux-2.36
tar -xf util-linux-2.36.tar.xz
cd util-linux-2.36
mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime \
	--docdir=/usr/share/doc/util-linux-2.36 --disable-chfn-chsh \
	--disable-login --disable-nologin --disable-su --disable-setpriv \
	--disable-runuser --disable-pylibmount --disable-static --without-python
make
make install
cd ..
rm -rf util-linux-2.36

### 7.14. Cleaning up and Saving the Temporary System
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /usr/share/{info,man,doc}/*
echo "SUCCESS - 7.2"
exit
