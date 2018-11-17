# supposed to be run interactively after chroot /mnt/gentoo /bin/bash
# some steps were taken from https://www.artembutusov.com/gentoo-on-aws/

env-update
. /etc/profile

# install make.conf
cd /root
mv /etc/portage/make.conf /etc/portage/make.conf.bak
cp /root/configs/make.conf /etc/portage

echo -e "\nen_US ISO-8859-1\nen_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set en_US.utf8
. /etc/profile

# set timezone
echo "UTC" >  /etc/timezone
cp /usr/share/zoneinfo/UTC /etc/localtime

# optional (long) emerge -av --exclude sys-devel/gcc @world
# or
# optional (suppose to be quick) emerge -a $EMERGE_OPTS --update --deep --newuse -a --with-bdeps=y @world

# todo(properly): emerge --unmerge nano

emerge app-portage/gentoolkit
emerge -a $EMERGE_OPTS --depclean

# newer kernel
echo "=sys-kernel/gentoo-sources-4.19.2 ~amd64" >>  /etc/portage/package.accept_keywords
emerge -av =sys-kernel/gentoo-sources-4.19.2
cp /root/configs/config-4.19.2.txt  /usr/src/linux/.config

# standard kernel
# install config
# cp /root/configs/config-4.14.78-no-ipv6-no-selinux-intel.txt  /usr/src/linux/.config
# emerge -av sys-kernel/gentoo-sources

cd /usr/src/linux
make -j5 && make install && make modules_install

# install packages
#echo "app-editors/vim minimal" > /etc/portage/package.use/vim.use
echo "sys-boot/grub -fonts -themes" > /etc/portage/package.use/grub.use
emerge -av vim grub syslog-ng logrotate vixie-cron monit mailx chrony openssh htop sudo tmux app-text/tree

eselect editor set /usr/bin/vi

echo "=app-emulation/cloud-init-18.4 ~amd64" >> /etc/portage/package.accept_keywords
emerge -av =app-emulation/cloud-init-18.4

# some cleanup
cd /
rm portage-latest.tar.xz  stage3-amd64-*

rc-update delete keymaps boot

emerge -av dhcpcd

# no need if cloud-init exist
# ln -s /etc/init.d/net.lo /etc/init.d/net.eth0
# rc-update add net.eth0 default
# ln -s /etc/init.d/net.lo /etc/init.d/net.ens5
# rc-update add net.ens5 default

rc-update add sshd default

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
GRUB_CMDLINE_LINUX="crashkernel=auto console=ttyS0,28800n8 console=tty0 net.ifnames=0"
GRUB_DISABLE_RECOVERY=true
GRUB_TERMINAL=console
HERE
