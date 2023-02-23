#!/bin/bash -e

TARGET_ROOTFS_DIR="binary"

if [ ! ${RELEASE} ]; then
	RELEASE='buster'
fi

if [ ! ${NXP_ARCH} ]; then
	NXP_ARCH='arm64'
fi

if [ -e ../rootfs-base/debian-${RELEASE}-*.tar.gz ]; then
	rm ../rootfs-base/debian-${RELEASE}-*.tar.gz
fi

if [ -e ${TARGET_ROOTFS_DIR} ]; then
        sudo rm -rf ${TARGET_ROOTFS_DIR}
fi

sudo apt -y install debian-archive-keyring
sudo apt-key add /usr/share/keyrings/debian-archive-keyring.gpg
sudo qemu-debootstrap --arch=${NXP_ARCH} \
	--keyring /usr/share/keyrings/debian-archive-keyring.gpg \
	--variant=buildd \
	--exclude=debfoster ${RELEASE} ${TARGET_ROOTFS_DIR} http://ftp.debian.org/debian

sudo tar zcvf ../rootfs-base/debian-${RELEASE}-$(date +%Y%m%d).tar.gz -C ${TARGET_ROOTFS_DIR} .
