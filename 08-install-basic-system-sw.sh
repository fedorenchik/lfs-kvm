#!/bin/bash

set -e
set -v

cd /
cd /sources

case "$KVM_LFS_CONTINUE" in
"8.3")
	### 8.3. Man-pages-5.08
	tar -xf man-pages-5.08.tar.xz
	cd man-pages-5.08
	make install
	cd ..
	rm -rf man-pages-5.08
;&

"8.4")
	### 8.4. Tcl-8.6.10
	tar -xf tcl8.6.10-src.tar.gz
	cd tcl8.6.10
	tar -xf ../tcl8.6.10-html.tar.gz --strip-components=1
	SRCDIR=$(pwd)
	cd unix/
	./configure --prefix=/usr --mandir=/usr/share/man \
		$([ "$(uname -m)" = x86_64 ] && echo --enable-64bit)
	make
	sed -e "s|$SRCDIR/unix|/usr/lib|" -e "s|$SRCDIR|/usr/include|" -i tclConfig.sh
	sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.1|/usr/lib/tdbc1.1.1|" \
		-e "s|$SRCDIR/pkgs/tdbc1.1.1/generic|/usr/include|" \
		-e "s|$SRCDIR/pkgs/tdbc1.1.1/library|/usr/lib/tcl8.6|" \
		-e "s|$SRCDIR/pkgs/tdbc1.1.1|/usr/include|" \
		-i pkgs/tdbc1.1.1/tdbcConfig.sh
	sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.0|/usr/lib/itcl4.2.0|" \
		-e "s|$SRCDIR/pkgs/itcl4.2.0/generic|/usr/include|" \
		-e "s|$SRCDIR/pkgs/itcl4.2.0|/usr/include|" \
		-i pkgs/itcl4.2.0/itclConfig.sh
	unset SRCDIR
	make test
	make install
	chmod -v u+w /usr/lib/libtcl8.6.so
	make install-private-headers
	ln -sfv tclsh8.6 /usr/bin/tclsh
	cd ../..
	rm -rf tcl8.6.10
;&

"8.5")
	### 8.5. Expect-5.45.4
	tar -xf expect5.45.4.tar.gz
	cd expect5.45.4
	./configure --prefix=/usr --with-tcl=/usr/lib --enable-shared \
		--mandir=/usr/share/man --with-tclinclude=/usr/include
	make
	make test
	make install
	ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
	cd ..
	rm -rf expect5.45.4
;&

"8.6")
	### 8.6. DejaGNU-1.6.2
	tar -xf dejagnu-1.6.2.tar.gz
	cd dejagnu-1.6.2
	./configure --prefix=/usr
	makeinfo --html --no-split -o doc/dejagnu.html doc/dejagnu.texi
	makeinfo --plaintext -o doc/dejagnu.txt doc/dejagnu.texi
	make install
	install -v -dm755 /usr/share/doc/dejagnu-1.6.2
	install -v -m644 doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.2
	make check
	cd ..
	rm -rf dejagnu-1.6.2
;&

"8.7")
	### 8.7. Iana-Etc-20200821
	tar -xf iana-etc-20200821.tar.gz
	cd iana-etc-20200821
	cp services protocols /etc
	cd ..
	rm -rf iana-etc-20200821
;&

"8.8")
	### 8.8. Glibc-2.32
	tar -xf glibc-2.32.tar.xz
	cd glibc-2.32
	patch -Np1 -i ../glibc-2.32-fhs-1.patch
	[ -e build ] && rm -r build
	mkdir -v build
	cd build
	../configure --prefix=/usr --disable-werror --enable-kernel=3.2 \
		--enable-stack-protector=strong --with-headers=/usr/include \
		libc_cv_slibdir=/lib
	make
	case $(uname -m) in
		i?86)
			ln -sfnv $PWD/elf/ld-linux.so.2 /lib
			;;
		x86_64)
			ln -sfnv $PWD/elf/ld-linux-x86-64.so.2 /lib
			;;
	esac
	make check || true
	touch /etc/ld.so.conf
	sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
	make install
	cp -v ../nscd/nscd.conf /etc/nscd.conf
	mkdir -pv /var/cache/nscd
	if [ "$KVM_LFS_INIT" == "systemd" ]; then
		install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
		install -v -Dm644 ../nscd/nscd.service /lib/systemd/system/nscd.service
	fi
	mkdir -pv /usr/lib/locale
	localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
	localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
	localedef -i de_DE -f ISO-8859-1 de_DE
	localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
	localedef -i de_DE -f UTF-8 de_DE.UTF-8
	localedef -i el_GR -f ISO-8859-7 el_GR
	localedef -i en_GB -f UTF-8 en_GB.UTF-8
	localedef -i en_HK -f ISO-8859-1 en_HK
	localedef -i en_PH -f ISO-8859-1 en_PH
	localedef -i en_US -f ISO-8859-1 en_US
	localedef -i en_US -f UTF-8 en_US.UTF-8
	localedef -i es_MX -f ISO-8859-1 es_MX
	localedef -i fa_IR -f UTF-8 fa_IR
	localedef -i fr_FR -f ISO-8859-1 fr_FR
	localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
	localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
	localedef -i it_IT -f ISO-8859-1 it_IT
	localedef -i it_IT -f UTF-8 it_IT.UTF-8
	localedef -i ja_JP -f EUC-JP ja_JP
	localedef -i ja_JP -f SHIFT_JIS ja_JP.SIJS 2> /dev/null || true
	localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
	localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
	localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
	localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
	localedef -i zh_CN -f GB18030 zh_CN.GB18030
	localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
	make localedata/install-locales
	cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF
	tar -xf ../../tzdata2020a.tar.gz
	ZONEINFO=/usr/share/zoneinfo
	mkdir -pv $ZONEINFO/{posix,right}
	for tz in etcetera southamerica northamerica europe africa antarctica asia \
			australasia backward pacificnew systemv; do
		zic -L /dev/null -d $ZONEINFO ${tz}
		zic -L /dev/null -d $ZONEINFO/posix ${tz}
		zic -L leapseconds -d $ZONEINFO/right ${tz}
	done
	cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
	zic -d $ZONEINFO -p America/New_York
	unset ZONEINFO
	ln -sfv /usr/share/zoneinfo/America/New_York /etc/localtime
	cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF
	cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
	mkdir -pv /etc/ld.so.conf.d
	cd ../..
	rm -rf glibc-2.32
;&

"8.9")
	### 8.9. Zlib-1.2.11
	tar -xf zlib-1.2.11.tar.xz
	cd zlib-1.2.11
	./configure --prefix=/usr
	make
	make check
	make install
	mv -v /usr/lib/libz.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
	cd ..
	rm -rf zlib-1.2.11
;&

"8.10")
	### 8.10. Bzip2-1.0.8
	tar -xf bzip2-1.0.8.tar.gz
	cd bzip2-1.0.8
	patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
	sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
	sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
	make -f Makefile-libbz2_so
	make clean
	make
	make PREFIX=/usr install
	cp -v bzip2-shared /bin/bzip2
	cp -av libbz2.so* /lib
	ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
	rm -v /usr/bin/{bunzip2,bzcat,bzip2}
	ln -sv bzip2 /bin/bunzip2
	ln -sv bzip2 /bin/bzcat
	cd ..
	rm -rf bzip2-1.0.8
;&

"8.11")
	### 8.11. Xz-5.2.5
	tar -xf xz-5.2.5.tar.xz
	cd xz-5.2.5
	./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/xz-5.2.5
	make
	make check
	make install
	mv -v /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
	mv -v /usr/lib/liblzma.so.* /lib
	ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
	cd ..
	rm -rf xz-5.2.5
;&

"8.12")
	### 8.12. Zstd-1.4.5
	tar -xf zstd-1.4.5.tar.gz
	cd zstd-1.4.5
	make
	make prefix=/usr install
	rm -v /usr/lib/libzstd.a
	mv -v /usr/lib/libzstd.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libzstd.so) /usr/lib/libzstd.so
	cd ..
	rm -rf zstd-1.4.5
;&

"8.13")
	### 8.13. File-5.39
	tar -xf file-5.39.tar.gz
	cd file-5.39
	./configure --prefix=/usr
	make
	make check
	make install
	cd ..
	rm -rf file-5.39
;&

"8.14")
	### 8.14. Readline-8.8
	tar -xf readline-8.0.tar.gz
	cd readline-8.0
	sed -i '/MV.*old/d' Makefile.in
	sed -i '/{OLDSUFF}/c:' support/shlib-install
	./configure --prefix=/usr --disable-static --with-curses \
		--docdir=/usr/share/doc/readline-8.0
	make SHLIB_LIBS="-lncursesw"
	make SHLIB_LIBS="-lncursesw" install
	mv -v /usr/lib/lib{readline,history}.so.* /lib
	chmod -v u+w /lib/lib{readline,history}.so.*
	ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
	ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so) /usr/lib/libhistory.so
	install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.0
	cd ..
	rm -rf readline-8.0
;&

"8.15")
	### 8.15. M4-1.4.18
	tar -xf m4-1.4.18.tar.xz
	cd m4-1.4.18
	sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
	echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
	./configure --prefix=/usr
	make
	make check
	make install
	cd ..
	rm -rf m4-1.4.18
;&

"8.16")
	### 8.16. Bc-3.1.5
	tar -xf bc-3.1.5.tar.xz
	cd bc-3.1.5
	PREFIX=/usr CC=gcc CFLAGS="-std=c99" ./configure.sh -G -O3
	make
	make test
	make install
	cd ..
	rm -rf bc-3.1.5
;&

"8.17")
	### 8.17. Flex-2.6.4
	tar -xf flex-2.6.4.tar.gz
	cd flex-2.6.4
	./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4
	make
	make check
	make install
	ln -sv flex /usr/bin/lex
	cd ..
	rm -rf flex-2.6.4
;&

"8.18")
	### 8.18. Binutils-2.35
	tar -xf binutils-2.35.tar.xz
	cd binutils-2.35
	expect -c "spawn ls" | grep -F 'spawn ls'
	sed -i '/@\tincremental_copy/d' gold/testsuite/Makefile.in
	mkdir -v build
	cd build
	../configure --prefix=/usr --enable-gold --enable-ld=default --enable-plugins \
		--enable-shared --disable-werror --enable-64-bit-bfd --with-system-zlib
	make tooldir=/usr
	make -k check
	make tooldir=/usr install
	cd ../..
	rm -rf binutils-2.35
;&

"8.19")
	### 8.19. GMP-6.2.0
	tar -xf gmp-6.2.0.tar.xz
	cd gmp-6.2.0
	cp -v configfsf.guess config.guess
	cp -v configfsf.sub config.sub
	./configure --prefix=/usr --enable-cxx --disable-static \
		--docdir=/usr/share/doc/gmp-6.2.0
	make
	make html
	make check 2>&1 | tee gmp-check-log
	awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log | grep -F '197'
	make install
	make install-html
	cd ..
	rm -rf gmp-6.2.0
;&

"8.20")
	### 8.20. MPFR-4.1.0
	tar -xf mpfr-4.1.0.tar.xz
	cd mpfr-4.1.0
	./configure --prefix=/usr --disable-static --enable-thread-safe \
		--docdir=/usr/share/doc/mpfr-4.1.0
	make
	make html
	make check
	make install
	make install-html
	cd ..
	rm -rf mpfr-4.1.0
;&

"8.21")
	### 8.21. MPC-1.1.0
	tar -xf mpc-1.1.0.tar.gz
	cd mpc-1.1.0
	./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/mpc-1.1.0
	make
	make html
	make check
	make install
	make install-html
	cd ..
	rm -rf mpc-1.1.0
;&

"8.22")
	### 8.22. Attr-2.4.48
	tar -xf attr-2.4.48.tar.gz
	cd attr-2.4.48
	if [ "$KVM_LFS_INIT" == "sysvinit" ]; then
		KVM_LFS_ATTR_CONFIGURE_BINDIR_ARG="--bindir=/bin"
	fi
	./configure --prefix=/usr $KVM_LFS_ATTR_CONFIGURE_BINDIR_ARG --disable-static \
		--sysconfdir=/etc --docdir=/usr/share/doc/attr-2.4.48
	make
	make check
	make install
	mv -v /usr/lib/libattr.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
	cd ..
	rm -rf attr-2.4.48
;&

"8.23")
	### 8.23. Acl-2.2.53
	tar -xf acl-2.2.53.tar.gz
	cd acl-2.2.53
	if [ "$KVM_LFS_INIT" == "sysvinit" ]; then
		KVM_LFS_ACL_CONFIGURE_BINDIR_ARG="--bindir=/bin"
	fi
	./configure --prefix=/usr $KVM_LFS_ACL_CONFIGURE_BINDIR_ARG --disable-static \
		--libexecdir=/usr/lib --docdir=/usr/share/doc/acl-2.2.53
	make
	make install
	mv -v /usr/lib/libacl.so.* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
	cd ..
	rm -rf acl-2.2.53
;&

"8.24")
	### 8.24 Libcap-2.42
	tar -xf libcap-2.42.tar.xz
	cd libcap-2.42
	sed -i '/install -m.*STACAPLIBNAME/d' libcap/Makefile
	make lib=lib
	make test
	make lib=lib PKGCONFIGDIR=/usr/lib/pkgconfig install
	chmod -v 755 /lib/libcap.so.2.42
	mv -v /lib/libpsx.a /usr/lib
	rm -v /lib/libcap.so
	ln -sfv ../../lib/libcap.so.2 /usr/lib/libcap.so
	cd ..
	rm -rf libcap-2.42
;&

"8.25")
	### 8.25 Shadow-4.8.1
	tar -xf shadow-4.8.1.tar.xz
	cd shadow-4.8.1
	sed -i 's/groups$(EXEEXT) //' src/Makefile.in
	find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
	find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
	find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;
	sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD SHA512:' \
		-e 's:/var/spool/mail:/var/mail:' -i etc/login.defs
	sed -i 's/1000/999/' etc/useradd
	touch /usr/bin/passwd
	./configure --sysconfdir=/etc --with-group-name-max-length=32
	make
	make install
	pwconv
	grpconv
	sed -i 's/yes/no/' /etc/default/useradd
	echo "root:root" | chpasswd
	cd ..
	rm -rf shadow-4.8.1
;&

"8.26")
	### 8.26. GCC-10.2.0
	tar -xf gcc-10.2.0.tar.xz
	cd gcc-10.2.0
	case $(uname -m) in
		x86_64)
			sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
			;;
	esac
	[ -e build ] && rm -r build
	mkdir -v build
	cd build
	../configure --prefix=/usr LD=ld --enable-languages=c,c++ --disable-multilib \
		--disable-bootstrap --with-system-zlib
	make
	ulimit -s 32768
	chown -Rv tester .
	su tester -c "PATH=$PATH make -k check" || true
	../contrib/test_summary
	../contrib/test_summary | grep -A7 Summ
	make install
	rm -rf /usr/lib/gcc/$(gcc -dumpmachine)/10.2.0/include-fixed/bits/
	chown -v -R root:root /usr/lib/gcc/*linux-gnu/10.2.0/include{,-fixed}
	ln -sv ../usr/bin/cpp /lib
	install -v -dm755 /usr/lib/bfd-plugins
	ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/10.2.0/liblto_plugin.so \
		/usr/lib/bfd-plugins/
	echo 'int main(){}' > dummy.c
	cc dummy.c -v -Wl,--verbose &> dummy.log
	readelf -l a.out | grep ': /lib' | \
		grep -F '[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]'
	grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log | wc -l | grep -F '3'
	grep -B4 '^ /usr/include' dummy.log | grep -F 'search starts here:'
	grep 'SEARCH.*/usr/lib' dummy.log | sed 's|; |\n|g' | grep -F 'SEARCH_DIR'
	grep "/lib.*/libc.so.6 " dummy.log | \
		grep -F 'attempt to open /lib/libc.so.6 succeeded'
	grep found dummy.log | \
		grep -F 'found ld-linux-x86-64.so.2 at /lib/ld-linux-x86-64.so.2'
	rm -v dummy.c a.out dummy.log
	mkdir -pv /usr/share/gdb/auto-load/usr/lib
	mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
	cd ../..
	rm -rf gcc-10.2.0
;&

"8.27")
	### 8.27. Pkg-config-0.29.2
	tar -xf pkg-config-0.29.2.tar.gz
	cd pkg-config-0.29.2
	./configure --prefix=/usr --with-internal-glib --disable-host-tool \
		--docdir=/usr/share/doc/pkg-config-0.29.2
	make
	make check
	make install
	cd ..
	rm -rf pkg-config-0.29.2
;&

"8.28")
	### 8.28. Ncurses-6.2
	tar -xf ncurses-6.2.tar.gz
	cd ncurses-6.2
	sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
	./configure --prefix=/usr --mandir=/usr/share/man --with-shared \
		--without-debug --without-normal --enable-pc-files --enable-widec
	make
	make install
	mv -v /usr/lib/libncursesw.so.6* /lib
	ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
	for lib in ncurses form panel menu ; do
		rm -vf /usr/lib/lib${lib}.so
		echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
		ln -sfv ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
	done
	rm -vf /usr/lib/libcursesw.so
	echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
	ln -sfv libncurses.so /usr/lib/libcurses.so
	mkdir -v /usr/share/doc/ncurses-6.2
	cp -v -R doc/* /usr/share/doc/ncurses-6.2
	if [ "$NEED_NON_WIDE_CHAR_SUPORT" == "true" ]; then
		make distclean
		./configure --prefix=/usr --with-shared --without-normal \
			--without-debug --without-cxx-binding --with-abi-version=5
		make sources libs
		cp -av lib/lib*.so.5* /usr/lib
	fi
	cd ..
	rm -rf ncurses-6.2
;&

"8.29")
	### 8.29. Sed-4.8
	tar -xf sed-4.8.tar.xz
	cd sed-4.8
	./configure --prefix=/usr --bindir=/bin
	make
	make html
	chown -Rv tester .
	su tester -c "PATH=$PATH make check"
	make install
	install -d -m755 /usr/share/doc/sed-4.8
	install -m644 doc/sed.html /usr/share/doc/sed-4.8
	cd ..
	rm -rf sed-4.8
;&

"8.30")
	### 8.30. Psmisc-23.3
	tar -xf psmisc-23.3.tar.xz
	cd psmisc-23.3
	./configure --prefix=/usr
	make
	make install
	mv -v /usr/bin/fuser /bin
	mv -v /usr/bin/killall /bin
	cd ..
	rm -rf psmisc-23.3
;&

"8.31")
	### 8.31.Gettext-0.21
	tar -xf gettext-0.21.tar.xz
	cd gettext-0.21
	./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/gettext-0.21
	make
	make check
	make install
	chmod -v 0755 /usr/lib/preloadable_libintl.so
	cd ..
	rm -rf gettext-0.21
;&

"8.32")
	### 8.32. Bison-3.7.1
	tar -xf bison-3.7.1.tar.xz
	cd bison-3.7.1
	./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.7.1
	make
	make check || make check
	make install
	cd ..
	rm -rf bison-3.7.1
;&

"8.33")
	### 8.33. Grep-3.4
	tar -xf grep-3.4.tar.xz
	cd grep-3.4
	./configure --prefix=/usr --bindir=/bin
	make
	make check
	make install
	cd ..
	rm -rf grep-3.4
;&

"8.34")
	### 8.34. Bash-5.0
	tar -xf bash-5.0.tar.gz
	cd bash-5.0
	patch -Np1 -i ../bash-5.0-upstream_fixes-1.patch
	./configure --prefix=/usr --docdir=/usr/share/doc/bash-5.0 \
		--without-bash-malloc --with-installed-readline
	make
	chown -Rv tester .
	su tester << EOF
PATH=$PATH make tests < $CURRENT_TTY
EOF
	make install
	mv -vf /usr/bin/bash /bin
	echo "SUCCESS - 8.1"
	exit
;&
esac
