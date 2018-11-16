#!/bin/bash

DEVICE=/dev/nvme2n1
cat | parted ${DEVICE} << END
mklabel msdos
mkpart primary ext4 1 100%
set 1 boot on
quit
END
