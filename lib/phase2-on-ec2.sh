
# preparation of partition (move to the copy stage)

#eexec mkfs.ext4 -q "$DISK2P1"
#eexec e2label "$DISK2P1" aux-root
#eexec mkdir -p /mnt/gentoo
##eexec mount "$DISK2P1" /mnt/gentoo

cd /mnt/gentoo

GENTOO_MIRROR=http://ftp.snt.utwente.nl/pub/os/linux/gentoo
GENTOO_ARCH=amd64
GENTOO_STAGE3=amd64
STAGE3_PATH_URL="$GENTOO_MIRROR/releases/$GENTOO_ARCH/autobuilds/latest-stage3-$GENTOO_STAGE3.txt"
STAGE3_PATH="$(curl -s "$STAGE3_PATH_URL" | grep -v "^#" | cut -d" " -f1)"
STAGE3_URL="$GENTOO_MIRROR/releases/$GENTOO_ARCH/autobuilds/$STAGE3_PATH"
STAGE3_FILE="$(basename "$STAGE3_URL")"

# download and unpack 
# from http://ftp.snt.utwente.nl/pub/os/linux/gentoo/releases/amd64/autobuilds/current-stage3-amd64/
wget "$STAGE3_URL"
wget "$STAGE3_URL.DIGESTS"
sha512sum $STAGE3_FILE


tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

# install portage
mkdir -p /mnt/gentoo/etc/portage/repos.conf 
cp -f /mnt/gentoo/usr/share/portage/config/repos.conf \
      /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

PORTAGE_URL="$GENTOO_MIRROR/snapshots/portage-latest.tar.xz"
PORTAGE_FILE="$(basename "$PORTAGE_URL")"
wget "$PORTAGE_URL"
tar xpf "$PORTAGE_FILE" -C usr --xattrs-include='*.*' --numeric-owner


cat >> /mnt/gentoo/etc/fstab << END
LABEL=root / ext4 noatime 0 1
END

echo "Copying network options..."
cp -f /etc/resolv.conf /mnt/gentoo/etc/

echo  "Mounting proc/sys/dev/pts..."
mount -t proc none /mnt/gentoo/proc
mount -o bind /sys /mnt/gentoo/sys
mount -o bind /dev /mnt/gentoo/dev
mount -o bind /dev/pts /mnt/gentoo/dev/pts


