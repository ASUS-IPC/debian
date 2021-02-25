#!/bin/bash -e

TARGET_ROOTFS_DIR="binary"

if [ ! ${DEBIAN_RELEASE} ]; then
	DEBIAN_RELEASE='buster'
fi

if [ ! ${NXP_ARCH} ]; then
	NXP_ARCH='arm64'
fi

if [ -e debian-${DEBIAN_RELEASE}-*.tar.gz ]; then
	rm debian-${DEBIAN_RELEASE}-*.tar.gz
fi

sudo apt -y install debian-archive-keyring
sudo apt-key add /usr/share/keyrings/debian-archive-keyring.gpg
sudo qemu-debootstrap --arch=${NXP_ARCH} \
	--keyring /usr/share/keyrings/debian-archive-keyring.gpg \
	--variant=buildd \
	--exclude=debfoster ${DEBIAN_RELEASE} ${TARGET_ROOTFS_DIR} http://ftp.debian.org/debian

sudo tar zcvf debian-${DEBIAN_RELEASE}-$(date +%Y%m%d).tar.gz -C ${TARGET_ROOTFS_DIR} .
