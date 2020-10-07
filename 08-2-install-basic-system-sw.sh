#!/bin/bash

set -e
set -v

cd /
cd /sources

case "$KVM_LFS_CONTINUE" in
"8.34.2")
	### 8.34. Bash-5.0 Continued
	cd bash-5.0
	cd ..
	rm -rf bash-5.0
;&

"8.35")
	### 8.35. Libtool-2.4.6
	tar -xf libtool-2.4.6.tar.xz
	cd libtool-2.4.6
	./configure --prefix=/usr
	make
	make check TESTSUITEFLAGS=-j$NPROCx4 || true
	make install
	cd ..
	rm -rf libtool-2.4.6
;&

"8.36")
	### 8.36. GDBM-1.18.1
	tar -xf gdbm-1.18.1.tar.gz
	cd gdbm-1.18.1
	sed -r -i '/^char.*parseopt_program_(doc|args)/d' src/parseopt.c
	./configure --prefix=/usr --disable-static --enable-libgdbm-compat
	make
	make check
	make install
	cd ..
	rm -rf gdbm-1.18.1
;&

"8.37")
	### 8.37. Gperf-3.1
	tar -xf gperf-3.1.tar.gz
	cd gperf-3.1
	./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
	make
	make -j1 check
	make install
	cd ..
	rm -rf gperf-3.1
;&

"8.38")
	### 8.38. Expat-2.2.9
	tar -xf expat-2.2.9.tar.xz
	cd expat-2.2.9
	./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/expat-2.2.9
	make
	make check
	make install
	install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.9
	cd ..
	rm -rf expat-2.2.9
;&

"8.39")
	### 8.39. Inetutils-1.9.4
	tar -xf inetutils-1.9.4.tar.xz
	cd inetutils-1.9.4
	./configure --prefix=/usr --localstatedir=/var --disable-logger \
		--disable-whois --disable-rcp --disable-rexec --disable-rlogin \
		--disable-rsh --disable-servers
	make
	make check || true
	make install
	mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
	mv -v /usr/bin/ifconfig /sbin
	cd ..
	rm -rf inetutils-1.9.4
;&

"8.40")
	### 8.40. Perl-5.32.0
	tar -xf perl-5.32.0.tar.xz
	cd perl-5.32.0
	export BUILD_ZLIB=False
	export BUILD_BZIP2=0
	sh Configure -des -Dprefix=/usr -Dvendorprefix=/usr \
		-Dprivlib=/usr/lib/perl5/5.32/core_perl \
		-Darchlib=/usr/lib/perl5/5.32/core_perl \
		-Dsitelib=/usr/lib/perl5/5.32/site_perl \
		-Dsitearch=/usr/lib/perl5/5.32/site_perl \
		-Dvendorlib=/usr/lib/perl5/5.32/vendor_perl \
		-Dvendorarch=/usr/lib/perl5/5.32/vendor_perl \
		-Dman1dir=/usr/share/man/man1 -Dman3dir=/usr/share/man/man3 \
		-Dpager="/usr/bin/less -isR" -Duseshrplib -Dusethreads
	make
	make test
	make install
	unset BUILD_ZLIB BUILD_BZIP2
	cd ..
	rm -rf perl-5.32.0
;&

"8.41")
	### 8.41. XML::Parser-2.46
	tar -xf XML-Parser-2.46.tar.gz
	cd XML-Parser-2.46
	perl Makefile.PL
	make
	make test
	make install
	cd ..
	rm -rf XML-Parser-2.46
;&

"8.42")
	### 8.42. Intltool-0.51.0
	tar -xf intltool-0.51.0.tar.gz
	cd intltool-0.51.0
	sed -i 's:\\\${:\\\$\\{:' intltool-update.in
	./configure --prefix=/usr
	make
	make check
	make install
	install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
	cd ..
	rm -rf intltool-0.51.0
;&

"8.43")
	### 8.43. Autoconf-2.69
	tar -xf autoconf-2.69.tar.xz
	cd autoconf-2.69
	sed -i '361 s/{/\\{/' bin/autoscan.in
	./configure --prefix=/usr
	make
	make check || true
	make install
	cd ..
	rm -rf autoconf-2.69
;&

"8.44")
	### 8.44. Automake-1.16.2
	tar -xf automake-1.16.2.tar.xz
	cd automake-1.16.2
	sed -i "s/''/etags/" t/tags-lisp-space.sh
	./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.2
	make
	make -j$NPROCx4 check || true # test t/subobj.sh fail
	make install
	cd ..
	rm -rf automake-1.16.2
;&

"8.45")
	### 8.45. Kmod-27
	tar -xf kmod-27.tar.xz
	cd kmod-27
	./configure --prefix=/usr --bindir=/bin --sysconfdir=/etc \
		--with-rootlibdir=/lib --with-xz --with-zlib
	make
	make install
	for target in depmod insmod lsmod modinfo modprobe rmmod; do
		ln -sfv ../bin/kmod /sbin/$target
	done
	ln -sfv kmod /bin/lsmod
	cd ..
	rm -rf kmod-27
;&

"8.46")
	### 8.46. Libelf from Elfutils-0.180
	tar -xf elfutils-0.180.tar.bz2
	cd elfutils-0.180
	./configure --prefix=/usr --disable-debuginfod --libdir=/lib
	make
	make check
	make -C libelf install
	install -vm644 config/libelf.pc /usr/lib/pkgconfig
	rm /lib/libelf.a
	cd ..
	rm -rf elfutils-0.180
;&

"8.47")
	### 8.47. Libffi-3.3
	tar -xf libffi-3.3.tar.gz
	cd libffi-3.3
	case $(uname -m) in
		i?86) GCC_ARCH_ARG='i386' ;;
		x86_64) GCC_ARCH_ARG='x86-64' ;;
	esac
	./configure --prefix=/usr --disable-static --with-gcc-arch=$GCC_ARCH_ARG
	make
	make check
	make install
	cd ..
	rm -rf libffi-3.3
;&

"8.48")
	### 8.48. OpenSSL-1.1.1g
	tar -xf openssl-1.1.1g.tar.gz
	cd openssl-1.1.1g
	./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic
	make
	make test || true # test 30-test_afalg.t fail
	sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
	make MANSUFFIX=ssl install
	mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.1g
	cp -vfr doc/* /usr/share/doc/openssl-1.1.1g
	cd ..
	rm -rf openssl-1.1.1g
;&

"8.49")
	### 8.49. Python-3.8.5
	tar -xf Python-3.8.5.tar.xz
	cd Python-3.8.5
	./configure --prefix=/usr --enable-shared --with-system-expat \
		--with-system-ffi --with-ensurepip=yes
	make
	# make test || true # test hang befause no network
	make install
	chmod -v 755 /usr/lib/libpython3.8.so
	chmod -v 755 /usr/lib/libpython3.so
	ln -sfv pip3.8 /usr/bin/pip3
	install -v -dm755 /usr/share/doc/python-3.8.5/html
	tar --strip-components=1 --no-same-owner --no-same-permissions \
		-C /usr/share/doc/python-3.8.5/html \
		-xvf ../python-3.8.5-docs-html.tar.bz2
	cd ..
	rm -rf Python-3.8.5
;&

"8.50")
	### 8.50. Ninja-1.10.0
	tar -xf ninja-1.10.0.tar.gz
	cd ninja-1.10.0
	export NINJAJOBS=$NPROC
	sed -i '/int Guess/a \
	int j = 0;\
	char* jobs = getenv("NINJAJOBS");\
	if (jobs != NULL) j = atoi(jobs);\
	if (j>0) return j;\
	' src/ninja.cc
	python3 configure.py --bootstrap
	./ninja ninja_test
	./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
	install -vm755 ninja /usr/bin/
	install -vDm644 misc/bash-completion \
		/usr/share/bash-completion/completions/ninja
	install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja
	cd ..
	rm -rf ninja-1.10.0
;&

"8.51")
	### 8.51. Meson-0.55.0
	tar -xf meson-0.55.0.tar.gz
	cd meson-0.55.0
	python3 setup.py build
	python3 setup.py install --root=dest
	cp -rv dest/* /
	cd ..
	rm -rf meson-0.55.0
;&

"8.52")
	### 8.52. Coreutils-8.32
	[ -e coreutils-8.32 ] && rm -rfv coreutils-8.32
	tar -xf coreutils-8.32.tar.xz
	cd coreutils-8.32
	patch -Np1 -i ../coreutils-8.32-i18n-1.patch
	sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk
	autoreconf -fiv
	FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr \
		--enable-no-install-program=kill,uptime
	make
	make NON_ROOT_USERNAME=tester check-root
	echo "dummy:x:102:tester" >> /etc/group
	chown -Rv tester .
	su tester -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check" || true # test test-getlogin may fail
	sed -i '/dummy/d' /etc/group
	make install
	mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
	mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
	mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
	mv -v /usr/bin/chroot /usr/sbin
	mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
	sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
	mv -v /usr/bin/{head,nice,sleep,touch} /bin
	cd ..
	rm -rf coreutils-8.32
;&

"8.53")
	### 8.53. Check-0.15.2
	tar -xf check-0.15.2.tar.gz
	cd check-0.15.2
	./configure --prefix=/usr --disable-static
	make
	make check
	make docdir=/usr/share/doc/check-0.15.2 install
	cd ..
	rm -rf check-0.15.2
;&

"8.54")
	### 8.54. Diffutils-3.7
	tar -xf diffutils-3.7.tar.xz
	cd diffutils-3.7
	./configure --prefix=/usr
	make
	make check
	make install
	cd ..
	rm -rf diffutils-3.7
;&

"8.55")
	### 8.55. Gawk-5.1.0
	tar -xf gawk-5.1.0.tar.xz
	cd gawk-5.1.0
	sed -i 's/extras//' Makefile.in
	./configure --prefix=/usr
	make
	make check
	make install
	mkdir -v /usr/share/doc/gawk-5.1.0
	cp -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.1.0
	cd ..
	rm -rf gawk-5.1.0
;&

"8.56")
	### 8.56. Findutils-4.7.0
	tar -xf findutils-4.7.0.tar.xz
	cd findutils-4.7.0
	./configure --prefix=/usr --localstatedir=/var/lib/locate
	make
	chown -Rv tester .
	su tester -c "PATH=$PATH make check"
	make install
	mv -v /usr/bin/find /bin
	sed -i 's|find:={BINDIR}|find:=/bin|' /usr/bin/updatedb
	cd ..
	rm -rf findutils-4.7.0
;&

"8.57")
	### 8.57. Groff-1.22.4
	tar -xf groff-1.22.4.tar.gz
	cd groff-1.22.4
	echo A4 > /etc/papersize
	PAGE=A4 ./configure --prefix=/usr
	make -j1
	make install
	cd ..
	rm -rf groff-1.22.4
;&

"8.58")
	### 8.58. GRUB-2.04
	tar -xf grub-2.04.tar.xz
	cd grub-2.04
	./configure --prefix=/usr --sbindir=/sbin --sysconfdir=/etc --disable-efiemu \
		--disable-werror
	make
	make install
	mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
	cd ..
	rm -rf grub-2.04
;&

"8.59")
	### 8.59. Less-551
	tar -xf less-551.tar.gz
	cd less-551
	./configure --prefix=/usr --sysconfdir=/etc
	make
	make install
	cd ..
	rm -rf less-551
;&

"8.60")
	### 8.60. Gzip-1.10
	tar -xf gzip-1.10.tar.xz
	cd gzip-1.10
	./configure --prefix=/usr
	make
	make check
	make install
	mv -v /usr/bin/gzip /bin
	cd ..
	rm -rf gzip-1.10
;&

"8.61")
	### 8.61. IPRoute2-5.8.0
	tar -xf iproute2-5.8.0.tar.xz
	cd iproute2-5.8.0
	sed -i /ARPD/d Makefile
	rm -fv man/man8/arpd.8
	sed -i 's/.m_ipt.o//' tc/Makefile
	make
	make DOCDIR=/usr/share/doc/iproute2-5.8.0 install
	cd ..
	rm -rf iproute2-5.8.0
;&

"8.62")
	### 8.62. Kbd-2.3.0
	tar -xf kbd-2.3.0.tar.xz
	cd kbd-2.3.0
	patch -Np1 -i ../kbd-2.3.0-backspace-1.patch
	sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
	sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
	./configure --prefix=/usr --disable-vlock
	make
	make check
	make install
	rm -v /usr/lib/libtswrap.{a,la,so*}
	mkdir -v /usr/share/doc/kbd-2.3.0
	cp -R -v docs/doc/* /usr/share/doc/kbd-2.3.0
	cd ..
	rm -rf kbd-2.3.0
;&

"8.63")
	### 8.63. Libpipeline-1.5.3
	tar -xf libpipeline-1.5.3.tar.gz
	cd libpipeline-1.5.3
	./configure --prefix=/usr
	make
	make check
	make install
	cd ..
	rm -rf libpipeline-1.5.3
;&

"8.64")
	### 8.64. Make-4.3
	tar -xf make-4.3.tar.gz
	cd make-4.3
	./configure --prefix=/usr
	make
	make check
	make install
	cd ..
	rm -rf make-4.3
;&

"8.65")
	### 8.65. Patch-2.7.6
	tar -xf patch-2.7.6.tar.xz
	cd patch-2.7.6
	./configure --prefix=/usr
	make
	make check
	make install
	cd ..
	rm -rf patch-2.7.6
;&

"8.66")
	### 8.66. Man-DB-2.9.3
	tar -xf man-db-2.9.3.tar.xz
	cd man-db-2.9.3
	if [ "$KVM_LFS_INIT" == "systemd" ]; then
		sed -i '/find/s@/usr@@' init/systemd/man-db.service.in
	fi
	if [ "$KVM_LFS_INIT" == "sysvinit" ]; then
		KVM_LFS_MANDB_CONF_ARG="--with-systemdtmpfilesdir= --with-systemdsystemunitdir="
	fi
	./configure --prefix=/usr --docdir=/usr/share/doc/man-db-2.9.3 \
		--sysconfdir=/etc --disable-setuid --enable-cache-owner=bin \
		--with-browser=/usr/bin/lynx --with-vgrind=/usr/bin/vgrind \
		--with-grap=/usr/bin/grap $KVM_LFS_MANDB_CONF_ARG
	make
	make check
	make install
	cd ..
	rm -rf man-db-2.9.3
;&

"8.67")
	### 8.67. Tar-1.32
	tar -xf tar-1.32.tar.xz
	cd tar-1.32
	FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --bindir=/bin
	make
	make check || true # test capabilities: binary store/restore fail
	make install
	make -C doc install-html docdir=/usr/share/doc/tar-1.32
	cd ..
	rm -rf tar-1.32
;&

"8.68")
	### 8.68. Texinfo-6.7
	tar -xf texinfo-6.7.tar.xz
	cd texinfo-6.7
	./configure --prefix=/usr --disable-static
	make
	make check
	make install
	make TEXMF=/usr/share/texmf install-tex
	pushd /usr/share/info
	rm -v dir
	for f in * ; do
		install-info $f dir 2>/dev/null
	done
	popd
	cd ..
	rm -rf texinfo-6.7
;&

"8.69")
	### 8.69. Vim-8.2.1361
	tar -xf vim-8.2.1361.tar.gz
	cd vim-8.2.1361
	echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
	./configure --prefix=/usr
	make
	chown -Rv tester .
	su tester -c "LANG=en_US.UTF-8 make -j1 test" &> vim-test.log || true
	grep -F 'ALL DONE' vim-test.log || true
	make install
	ln -sv vim /usr/bin/vi
	for L in /usr/share/man/{,*/}man1/vim.1; do
		ln -sv vim.1 $(dirname $L)/vi.1
	done
	ln -sv ../vim/vim82/doc /usr/share/doc/vim-8.2.1361
	cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
set background=dark
endif

set spelllang=en
set spell
" End /etc/vimrc
EOF
	#vim -c ':options'
	cd ..
	rm -rf vim-8.2.1361
;&

"8.70")
if [ "$KVM_LFS_INIT" == "sysvinit" ]; then
	### 8.70. Eudev-3.2.9
	tar -xf eudev-3.2.9.tar.gz
	cd eudev-3.2.9
	./configure --prefix=/usr --bindir=/sbin --sbindir=/sbin --libdir=/usr/lib \
		--sysconfdir=/etc --libexecdir=/lib --with-rootprefix= \
		--with-rootlibdir=/lib --enable-manpages --disable-static
	make
	mkdir -pv /lib/udev/rules.d
	mkdir -pv /etc/udev/rules.d
	make check
	make install
	tar -xvf ../udev-lfs-20171102.tar.xz
	make -f udev-lfs-20171102/Makefile.lfs install
	udevadm hwdb --update
	cd ..
	rm -rf eudev-3.2.9
elif [ "$KVM_LFS_INIT" == "systemd" ]; then
	### 8.70. Systemd-246
	tar -xf systemd-246.tar.gz
	cd systemd-246
	ln -sf /bin/true /usr/bin/xsltproc
	tar -xf ../systemd-man-pages-246.tar.xz
	sed '177,$ d' -i src/resolve/meson.build
	sed -i 's/GROUP="render", //' rules.d/50-udev-default.rules.in
	mkdir -p build
	cd build
	LANG=en_US.UTF-8 meson --prefix=/usr --sysconfdir=/etc \
		--localstatedir=/var -Dblkid=true -Dbuildtype=release \
		-Ddefault-dnssec=no -Dfirstboot=false -Dinstall-tests=false \
		-Dkmod-path=/bin/kmod -Dldconfig=false -Dmount-path=/bin/mount \
		-Drootprefix= -Drootlibdir=/lib -Dsplit-usr=true \
		-Dsulogin-path=/sbin/sulogin -Dsysusers=false \
		-Dumount-path=/bin/umount -Db_lto=false -Drpmmacrosdir=no \
		-Dhomed=false -Duserdb=false -Dman=true \
		-Ddocdir=/usr/share/doc/systemd-246 ..
	LANG=en_US.UTF-8 ninja
	LANG=en_US.UTF-8 ninja install
	rm -f /usr/bin/xsltproc
	systemd-machine-id-setup
	systemctl preset-all
	systemctl disable systemd-time-wait-sync.service
	rm -f /usr/lib/sysctl.d/50-pid-max.conf
	#TODO:
	cp -v /usr/lib64/pkgconfig/libsystemd.pc /usr/lib/pkgconfig/
	cd ../..
	rm -rf systemd-246

	### 8.71. D-Bus-1.12.20
	tar -xf dbus-1.12.20.tar.gz
	cd dbus-1.12.20
	./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var \
		--disable-static --disable-doxygen-docs --disable-xml-docs \
		--docdir=/usr/share/doc/dbus-1.12.20 \
		--with-console-auth-dir=/run/console
	make
	make install
	mv -v /usr/lib/libdbus-1.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libdbus-1.so) /usr/lib/libdbus-1.so
	ln -sfv /etc/machine-id /var/lib/dbus
	#TODO: install does not install dbus.socket ???
	cp -v bus/dbus.socket /lib/systemd/system/
	sed -i 's:/var/run:/run:' /lib/systemd/system/dbus.socket
	cd ..
	rm -rf dbus-1.12.20.tar.xz
fi
;&

"8.71")
	### 8.71. Procps-ng-3.3.16
	tar -xf procps-ng-3.3.16.tar.xz
	cd procps-ng-3.3.16
	if [ "$KVM_LFS_INIT" == "systemd" ]; then
		KVM_LFS_PROCPSNG_CONF_ARG="--with-systemd"
	fi
	./configure --prefix=/usr --exec-prefix= --libdir=/usr/lib \
		--docdir=/usr/share/doc/procps-ng-3.3.16 --disable-static \
		--disable-kill $KVM_LFS_PROCPSNG_CONF_ARG
	make
	make check
	make install
	mv -v /usr/lib/libprocps.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
	cd ..
	rm -rf procps-ng-3.3.16
;&

"8.72")
	### 8.72. Util-linux-2.36
	tar -xf util-linux-2.36.tar.xz
	cd util-linux-2.36
	mkdir -pv /var/lib/hwclock
	if [ "$KVM_LFS_INIT" == "sysvinit" ]; then
		KVM_LFS_UTILLINUX_CONF_ARG="--without-systemd --without-systemdsystemunitdir"
	fi
	./configure ADJTIME_PATH=/var/lib/hwclock/adjtime \
		--docdir=/usr/share/doc/util-linux-2.36 --disable-chfn-chsh \
		--disable-login --disable-nologin --disable-su --disable-setpriv \
		--disable-runuser --disable-pylibmount --disable-static \
		--without-python $KVM_LFS_UTILLINUX_CONF_ARG
	make
	# to run tests, need to check that kernel config must include CONFIG_SCSI_DEBUG=m (not 'y' or 'n', must be 'm')
	# do not run tests as they may damage the system (if run as root)
	# su tester -c "bash tests/run.sh --srcdir=$PWD --builddir=$PWD"
	chown -Rv tester .
	su tester -c "make -k check"
	make install
	cd ..
	rm -rf util-linux-2.36
;&

"8.73")
	### 8.73. E2fsprogs-1.45.6
	tar -xf e2fsprogs-1.45.6.tar.gz
	cd e2fsprogs-1.45.6
	mkdir -v build
	cd build
	../configure --prefix=/usr --bindir=/bin --with-root-prefix="" \
		--enable-elf-shlibs --disable-libblkid --disable-libuuid \
		--disable-uuidd --disable-fsck
	make
	make check
	make install
	chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
	gunzip -v /usr/share/info/libext2fs.info.gz
	install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
	makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
	install -v -m644 doc/com_err.info /usr/share/info
	install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
	cd ../..
	rm -rf e2fsprogs-1.45.6
;&

"8.74")
if [ "$KVM_LFS_INIT" == "sysvinit" ]; then
	### 8.74. Sysklogd-1.5.1
	tar -xf sysklogd-1.5.1.tar.gz
	cd sysklogd-1.5.1
	sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
	sed -i 's/union wait/int/' syslogd.c
	make
	make BINDIR=/sbin install
	cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
	cd ..
	rm -rf sysklogd-1.5.1

	### 8.75. Sysvinit-2.97
	tar -xf sysvinit-2.97.tar.xz
	cd sysvinit-2.97
	patch -Np1 -i ../sysvinit-2.97-consolidated-1.patch
	make
	make install
	cd ..
	rm -rf sysvinit-2.97
fi
;&

"8.77")
	### 8.77. Stripping Again
	save_lib="ld-2.32.so libc-2.32.so libpthread-2.32.so libthread_db-1.0.so"
	cd /lib
	for LIB in $save_lib; do
		objcopy --only-keep-debug $LIB $LIB.dbg
		strip --strip-unneeded $LIB
		objcopy --add-gnu-debuglink=$LIB.dbg $LIB
	done
	save_usrlib="libquadmath.so.0.0.0 libstdc++.so.6.0.28 libitm.so.1.0.0
			libatomic.so.1.2.0"
	cd /usr/lib
	for LIB in $save_usrlib; do
		objcopy --only-keep-debug $LIB $LIB.dbg
		strip --strip-unneeded $LIB
		objcopy --add-gnu-debuglink=$LIB.dbg $LIB
	done
	unset LIB save_lib save_usrlib
	find /usr/lib -type f -name \*.a -exec strip --strip-debug {} ';'
	find /lib /usr/lib -type f -name \*.so* ! -name \*dbg \
		-exec strip --strip-unneeded {} ';'
	find /{bin,sbin} /usr/{bin,sbin,libexec} -type f -exec strip --strip-all {} ';'
;&

"8.78")
	### 8.78. Cleaning Up
	rm -rf /tmp/*
	echo "SUCCESS - 8.2"
	logout
;&
esac
