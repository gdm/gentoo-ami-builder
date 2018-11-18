#!/bin/bash


# parted /dev/nvme2n1
# mklabel msdos
# mkpart primary ext4 1 100%
# set 1 boot on

# todo: automate fdisk/parted
mkfs.ext4 /dev/nvme2n1p1 -L root
mkdir /mnt/gentoo2
mount -o noatime /dev/nvme2n1p1 /mnt/gentoo2


cat > /root/exclude-rsync.txt <<EOF
/dev/*
/proc/*
/sys/*
/usr/portage/*
/usr/src/*
/lost+found
EOF

# remove everything if any content exits (not sure that --delete from rsync works good enough )
#if [ -d /mnt/gentoo2/boot ]; then
#  rm -rf /mnt/gentoo2/*
#fi

rsync -avxHAX --delete --numeric-ids --info=progress2 --exclude-from=/root/exclude-rsync.txt /mnt/gentoo/ /mnt/gentoo2/

ROOT=/mnt/gentoo2
echo  "Mounting proc/sys/dev/pts..."
mount -t proc none ${ROOT}/proc
mount -o bind /sys ${ROOT}/sys
mount -o bind /dev ${ROOT}/dev
mount -o bind /dev/pts ${ROOT}/dev/pts


# now perform grub installation
chroot /mnt/gentoo2 /bin/bash -c ". /etc/profile; env-update; grub-install /dev/nvme2n1; grub-mkconfig -o /boot/grub/grub.cfg"
sed -i -e 's/\/dev\/nvme2n1p1/\/dev\/nvme0n1p1/g' /mnt/gentoo2/boot/grub/grub.cfg

umount ${ROOT}/dev/pts
umount ${ROOT}/dev
umount ${ROOT}/sys
umount ${ROOT}/proc
umount $ROOT

exit 0 
# now parted

[root@bigben mnt]# parted /dev/nvme2n1
GNU Parted 3.1
Using /dev/nvme2n1
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) p
Model: NVMe Device (nvme)
Disk /dev/nvme2n1: 4295MB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags:

Number  Start   End     Size    File system  Name    Flags
 1      1049kB  3146kB  2097kB               grub    bios_grub
 2      3146kB  137MB   134MB   ext2         boot    boot
 3      137MB   4294MB  4157MB  ext4         rootfs

