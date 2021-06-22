#!/bin/bash -e

VERSION_NUMBER=1.0.0
VERSION=DEBUG

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="binary"

if [ -e ${TARGET_ROOTFS_DIR} ]; then
	sudo rm -rf ${TARGET_ROOTFS_DIR}
fi

mkdir ${TARGET_ROOTFS_DIR}

if [ ! $VERSION ]; then
	VERSION="debug"
fi

if [ ! -e debian-*.tar.gz ]; then
	echo "\033[36m Run mk-base-debian.sh first \033[0m"
fi

finish() {
	sudo umount ${TARGET_ROOTFS_DIR}/dev
	exit -1
}
trap finish ERR

echo -e "\033[36m Extract image \033[0m"
sudo tar -C ${TARGET_ROOTFS_DIR} -xpf debian-*.tar.gz

# packages folder
# imx-gpu-viv
sudo cp -rf packages/${NXP_SOC}/imx-gpu-viv/1_6.2.4.p4.0-aarch64-r0/image/* ${TARGET_ROOTFS_DIR}
# libdrm
sudo cp -rf packages/${NXP_SOC}/libdrm/2.4.91.imx-r0/image/* ${TARGET_ROOTFS_DIR}
# systemd-serialgetty
sudo cp -rf packages/${NXP_SOC}/systemd-serialgetty/1.0-r5/image/* ${TARGET_ROOTFS_DIR}
# weston-init
sudo cp -rf packages/${NXP_SOC}/weston-init/1.0-r0/image/* ${TARGET_ROOTFS_DIR}
# kernel module
if [ "$(ls -A packages/${NXP_SOC}/linux-imx/modules/lib/modules)" ];then
	sudo cp -rf packages/${NXP_SOC}/linux-imx/modules/lib/modules/ ${TARGET_ROOTFS_DIR}/lib/
fi
# wayland
sudo cp -rf packages/${NXP_SOC}/wayland-debian/* ${TARGET_ROOTFS_DIR}
# wayland-protocols
sudo cp -rf packages/${NXP_SOC}/wayland-protocols-debian/* ${TARGET_ROOTFS_DIR}
# weston
sudo cp -rf packages/${NXP_SOC}/weston-debian/* ${TARGET_ROOTFS_DIR}

# overlay folder
if [ "$(ls overlay/${NXP_SOC}/common)" ];then
	sudo cp -rf overlay/${NXP_SOC}/common/* $TARGET_ROOTFS_DIR/
fi
if [ "$(ls overlay/${NXP_SOC}/${NXP_TARGET_PRODUCT})" ];then
	sudo cp -rf overlay/${NXP_SOC}/${NXP_TARGET_PRODUCT}/* $TARGET_ROOTFS_DIR/
fi

# overlay-debug folder
if [ "$VERSION" == "debug" ] || [ "$VERSION" == "DEBUG" ]; then
	if [ "$(ls overlay-debug/${NXP_SOC}/common)" ];then
		sudo cp -rf overlay-debug/${NXP_SOC}/common/* $TARGET_ROOTFS_DIR/
	fi
	if [ "$(ls overlay-debug/${NXP_SOC}/${NXP_TARGET_PRODUCT})" ];then
		sudo cp -rf overlay-debug/${NXP_SOC}/${NXP_TARGET_PRODUCT}/* $TARGET_ROOTFS_DIR/
	fi
fi

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev
cat <<EOF | HOME=/root sudo chroot $TARGET_ROOTFS_DIR

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get -y install \
  sudo \
  ssh \
  net-tools \
  network-manager \
  iputils-ping \
  rsyslog \
  bash-completion \
  htop \
  resolvconf \
  dialog \
  vim \
  wget \
  can-utils \
  kbd \
  lsb-release

DEBIAN_FRONTEND=noninteractive apt-get -y install \
v4l-utils alsa-utils git gcc less autoconf autopoint libtool \
bison flex gtk-doc-tools glib-2.0 libglib2.0-dev libpango1.0-dev \
libatk1.0-dev kmod pciutils libjpeg-dev

DEBIAN_FRONTEND=noninteractive apt-get -y install \
libudev-dev libinput-dev libxkbcommon-dev libpam0g-dev libx11-xcb-dev \
libxcb-xfixes0-dev libxcb-composite0-dev libxcursor-dev libxcb-shape0-dev \
libdbus-1-dev libdbus-glib-1-dev libffi-dev libxml2-dev

# Add User
useradd -s '/bin/bash' -m -G adm,sudo asus
echo "asus:asus" | chpasswd
echo "root:root" | chpasswd

# Set Hostname
echo "${NXP_HOSTNAME}" > /etc/hostname
echo 127.0.0.1$'\t'${NXP_HOSTNAME} >> /etc/hosts

#--------------- Set image version ---------------
echo $VERSION_NUMBER-$VERSION > /etc/version

# Set DNS server
echo nameserver 8.8.8.8 > /etc/resolv.conf

# Enable weston service
systemctl enable weston.service

apt-get clean
history -c
EOF

sudo umount $TARGET_ROOTFS_DIR/dev

