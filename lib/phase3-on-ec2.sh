# supposed to be run interactively after chroot /mnt/gentoo /bin/bash
# some steps were taken from https://www.artembutusov.com/gentoo-on-aws/

env-update
. /etc/profile

# TODO: add options for kernel / config files / installed software
KERNEL_VERSION=5.1.4
function step1 () {
  # install make.conf
  cd /root
  mv /etc/portage/make.conf /etc/portage/make.conf.bak
  cp /root/configs/make.conf /etc/portage

  echo -e "\nen_US ISO-8859-1\nen_US.UTF-8 UTF-8" >> /etc/locale.gen
  locale-gen
  eselect locale set en_US.utf8
  . /etc/profile

  eselect python set python2.7

  # set timezone
  echo "UTC" >  /etc/timezone
  cp /usr/share/zoneinfo/UTC /etc/localtime

  # optional (long) emerge -av --exclude sys-devel/gcc @world
  # or
  # optional (suppose to be quick) emerge -a $EMERGE_OPTS --update --deep --newuse -a --with-bdeps=y @world

  # todo(properly): emerge --unmerge nano

  emerge app-portage/gentoolkit
  emerge -a $EMERGE_OPTS --depclean

  # for newer kernel
  echo "=sys-kernel/gentoo-sources-${KERNEL_VERSION} ~amd64" >>  /etc/portage/package.accept_keywords
  emerge -av =sys-kernel/gentoo-sources-${KERNEL_VERSION}
  #echo "Try to configure new kernel !! "
  #exit 0

  cp /root/configs/kernel-config-5.1.4-kvm-noxen-noipv6-ena-nosystemd.txt /usr/src/linux/.config
  # cp /root/configs/config-4.14.78-no-ipv6-no-selinux-intel.txt  /usr/src/linux/.config

  # old standard kernel
  # install config
  # cp /root/configs/config-4.14.78-no-ipv6-no-selinux-intel.txt  /usr/src/linux/.config
  # emerge -av sys-kernel/gentoo-sources
}

step1
cd /usr/src/linux
make -j5 && make install && make modules_install

# install packages
#echo "app-editors/vim minimal" > /etc/portage/package.use/vim.use
echo "sys-boot/grub -fonts -themes" > /etc/portage/package.use/grub.use
emerge -av vim grub syslog-ng logrotate vixie-cron monit mailx chrony openssh htop sudo tmux app-text/tree pciutils

eselect editor set /usr/bin/vi

cat <<HERE >> /etc/portage/package.accept_keywords
# for awscli
dev-python/botocore ~amd64
dev-python/s3transfer ~amd64
dev-python/awscli ~amd64
dev-java/openjdk-bin ~amd64
# for docker we need latest perl
#dev-lang/perl ~amd64
#perl-core/* ~amd64
#virtual/perl-* ~amd64
HERE

# don't use this (new) version of cloud-init because it spoils /etc/locale.gen
#echo "=app-emulation/cloud-init-18.4 ~amd64" >> /etc/portage/package.accept_keywords
emerge -av app-emulation/cloud-init awscli app-crypt/gnupg

# when we want to setup docker (in case python 36 only is in use
#echo "dev-vcs/git -python" >> /etc/portage/package.use/git.use
#echo "app-emulation/containerd -btrfs" >> /etc/portage/package.use/containerd.use
# emerge -av app-emulation/docker (see todo.txt for resolving requirements in kernel)

# change startup script (to run before urandom)
sed -i '/after localmount/a  \ \ before urandom' /etc/init.d/cloud-init-local

# some cleanup
cd /
rm portage-latest.tar.xz  stage3-amd64-*

rc-update delete keymaps boot

emerge -av dhcpcd audit postgresql
rc-update add auditd boot


# no need if cloud-init exist
# ln -s /etc/init.d/net.lo /etc/init.d/net.eth0
# rc-update add net.eth0 default
# ln -s /etc/init.d/net.lo /etc/init.d/net.ens5
# rc-update add net.ens5 default

rc-update add sshd default
rc-update add hostname default

sed -i "s/^pool/#pool/" /etc/chrony/chrony.conf
sed -i "3iserver 169.254.169.123 prefer iburst" /etc/chrony/chrony.conf
rc-update add chronyd default

rc-update add cloud-init-local boot
rc-update add cloud-init default
rc-update add cloud-config default
rc-update add cloud-final default

rc-update add vixie-cron
rc-update add syslog-ng boot

cat <<HERE >> /etc/default/grub
GRUB_TIMEOUT=1
GRUB_DISABLE_SUBMENU=true
GRUB_CMDLINE_LINUX="crashkernel=auto console=ttyS0,28800n8 console=tty0"
GRUB_DISABLE_RECOVERY=true
GRUB_TERMINAL=console
HERE

# for java (for experiments with hosting ?)
echo ">=dev-java/oracle-jre-bin-1.8.0.192:1.8 Oracle-BCLA-JavaSE" >> /etc/portage/package.license
echo "dev-java/oracle-jre-bin jce" >> /etc/portage/package.use/oracle-java.use
echo "emerge -av oracle-jre-bin"
# deliver binary
emerge -av oracle-jre-bin

# install mail clients (for experiments)
echo "mail-client/neomutt idn lmdb gpg_classic qdbm sasl smime_classic" > /etc/portage/package.use/mutt.use
echo "sys-fs/squashfs-tools -xz -debug lz4 lzma lzo -static -xattr" > /etc/portage/package.use/squashfs-tools.use
echo "mail-filter/procmail mbox" >> /etc/portage/package.use/mutt.use
emerge -av neomutt procmail fetchmail squashfs-tools

# make portage.sq
cd /usr/portage
mksquashfs  . /portage.sq -e distfiles -comp lz4

echo <<HERE
about postgres:
* If you need a global psqlrc-file, you can place it in:
 *     /etc/postgresql-10/
 * 
 * Gentoo specific documentation:
 * https://wiki.gentoo.org/wiki/PostgreSQL
 * 
 * Official documentation:
 * https://www.postgresql.org/docs/10/static/index.html
 * 
 * The default location of the Unix-domain socket is:
 *     /run/postgresql/
 * 
 * Before initializing the database, you may want to edit PG_INITDB_OPTS
 * so that it contains your preferred locale in:
 *     /etc/conf.d/postgresql-10
 * 
 * Then, execute the following command to setup the initial database
 * environment:
 *     emerge --config =dev-db/postgresql-10.6

HERE

# now rebuild

# for rebuilding python 2.7
chmod 1777 /dev/shm
emerge --ask --update --newuse --tree --deep --with-bdeps=y @world
echo "device-mapper" > /etc/portage/package.use/docker.use
emerge -av app-emulation/docker
