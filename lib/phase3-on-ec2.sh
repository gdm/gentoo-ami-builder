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

