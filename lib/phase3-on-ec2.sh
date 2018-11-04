# supposed to be run interactively after chroot /mnt/gentoo /bin/bash

env-update
. /etc/profile
cat /etc/portage/make.conf
CPU_COUNT=$(cat /proc/cpuinfo | grep processor | wc -l)
MAKE_THREADS=$(expr $CPU_COUNT + 1)
MAKE_OPTS="-j$MAKE_THREADS"
cat >> /etc/portage/make.conf << END
CFLAGS="-O2 -pipe -mtune=generic"
CXXFLAGS="$CFLAGS"
MAKEOPTS="$MAKE_OPTS"
END


echo 'GENTOO_MIRRORS="http://mirror.netcologne.de/gentoo"' >> /etc/portage/make.conf


emerge -a $EMERGE_OPTS --update --deep --newuse -a --with-bdeps=y @world
emerge app-portage/gentoolkit
emerge -a $EMERGE_OPTS --depclean
emerge -av sys-kernel/gentoo-sources

