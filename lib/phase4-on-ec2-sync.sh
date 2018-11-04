

echo > /root/exclude-rsync.txt <<EOF
/boot/*
/dev/*
/proc/*
/sys/*
/usr/portage/*
EOF

rsync -avxHAX  --numeric-ids --info=progress2 --exclude-from=/root/exclude-rsync.txt /mnt/gentoo/ /mnt/gentoo2/


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

