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

# optional (long) emerge -av --exclude sys-devel/gcc @world
# or
# optional (suppose to be quick) emerge -a $EMERGE_OPTS --update --deep --newuse -a --with-bdeps=y @world

emerge app-portage/gentoolkit
emerge -a $EMERGE_OPTS --depclean
emerge -av sys-kernel/gentoo-sources

# install config
cp /root/configs/config-4.14.78-no-ipv6-no-selinux-intel.txt  /usr/src/linux/.config
cd /usr/src/linux
make -j5

# install packages
echo "app-editors/vim minimal" > /etc/portage/package.use/vim.use
echo "sys-boot/grub -fonts -themes" > /etc/portage/package.use/grub.use
emerge -av vim grub

# some cleanup
cd /
rm portage-latest.tar.xz  stage3-amd64-*

rc-update delete keymaps boot

emerge -av dhcpcd
ln -s /etc/init.d/net.lo /etc/init.d/net.eth0
rc-update add net.eth0 default
rc-update add net.ens5 default




