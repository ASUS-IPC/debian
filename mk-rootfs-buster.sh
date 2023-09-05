#!/bin/bash -e

#VERSION_NUMBER=1.0.0
#VERSION=DEBUG

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="binary"

if [ -e ${TARGET_ROOTFS_DIR} ]; then
	sudo rm -rf ${TARGET_ROOTFS_DIR}
fi

mkdir ${TARGET_ROOTFS_DIR}

if [ ! $VERSION ]; then
	VERSION="debug"
fi

if [ ! -e debian-buster-base.tar.gz ]; then
	echo "\033[36m Run mk-base-debian.sh first \033[0m"
fi

finish() {
	sudo umount ${TARGET_ROOTFS_DIR}/dev
	exit -1
}
trap finish ERR

echo -e "\033[36m Extract image \033[0m"
sudo tar -C ${TARGET_ROOTFS_DIR} -xpf debian-buster-base.tar.gz

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

#glmark2
sudo cp -rf packages/${NXP_SOC}/glmark2/2017.07+AUTOINC+ed20c633f1-r0/image/* ${TARGET_ROOTFS_DIR}

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

# gstreamer packages folder
sudo mkdir -p $TARGET_ROOTFS_DIR/packages
sudo cp -rf packages/${NXP_SOC}/gstreamer1.0 $TARGET_ROOTFS_DIR/packages
sudo cp -rf packages/${NXP_SOC}/imx-parser $TARGET_ROOTFS_DIR/packages
sudo cp -rf packages/${NXP_SOC}/imx-codec $TARGET_ROOTFS_DIR/packages
sudo cp -rf packages/${NXP_SOC}/imx-vpu $TARGET_ROOTFS_DIR/packages
sudo cp -rf packages/${NXP_SOC}/imx-vpuwrap $TARGET_ROOTFS_DIR/packages

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev
cat <<EOF | HOME=/root sudo chroot $TARGET_ROOTFS_DIR

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get -y install \
  sudo ssh net-tools network-manager iputils-ping iperf3 \
  rsyslog bash-completion htop resolvconf dialog vim wget \
  can-utils kbd gdisk parted exfat-utils exfat-fuse ntfs-3g \
  netplan.io whiptail i2c-tools

DEBIAN_FRONTEND=noninteractive apt-get -y install \
v4l-utils alsa-utils git gcc less autoconf autopoint libtool \
bison flex gtk-doc-tools glib-2.0 libglib2.0-dev libpango1.0-dev \
libatk1.0-dev kmod pciutils libjpeg-dev

DEBIAN_FRONTEND=noninteractive apt-get -y install \
libudev-dev libinput-dev libxkbcommon-dev libpam0g-dev libx11-xcb-dev \
libxcb-xfixes0-dev libxcb-composite0-dev libxcursor-dev libxcb-shape0-dev \
libdbus-1-dev libdbus-glib-1-dev libffi-dev libxml2-dev

DEBIAN_FRONTEND=noninteractive apt-get -y install \
  modemmanager ppp libqmi-utils libmbim-utils libxml2-utils usbutils bluez

# Install Docker Engine
dpkg -i /etc/EdgeX/EdgeX_deb/*.deb

# Install Docker Compose
chmod +x /etc/EdgeX/docker-compose
ln -s -f /etc/EdgeX/docker-compose /usr/bin/docker-compose

# Install Gstreamer Package
dpkg -i --force-overwrite /packages/imx-codec/*.deb
dpkg -i --force-overwrite /packages/imx-parser/*.deb
dpkg -i --force-overwrite /packages/imx-vpu/*.deb
dpkg -i --force-overwrite /packages/imx-vpuwrap/*.deb
dpkg -i --force-overwrite /packages/gstreamer1.0/*.deb

DEBIAN_FRONTEND=noninteractive apt-get -y install -f
DEBIAN_FRONTEND=noninteractive apt-get -y install gstreamer1.0-alsa

echo "deb http://security.debian.org/debian-security/ buster/updates main contrib non-free" >> /etc/apt/sources.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get --only-upgrade -y install ssh

# Add User
useradd -s '/bin/bash' -m -G adm,sudo asus
echo "asus:asus" | chpasswd
echo "root:root" | chpasswd

# Set Hostname
echo "${NXP_HOSTNAME}" > /etc/hostname
echo 127.0.0.1$'\t'${NXP_HOSTNAME} >> /etc/hosts

# Switching iptables/ip6tables to the legacy version
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

#--------------- Set image version ---------------
echo $VERSION_NUMBER-$VERSION > /etc/version

# Set DNS server
echo nameserver 8.8.8.8 > /etc/resolv.conf

# Enable weston service
systemctl enable weston.service

systemctl enable resize-helper.service
systemctl enable adbd.service

# Enable Connectivity Manager related service
systemctl enable asus_failover.service
systemctl enable mm_keepalive.service

systemctl enable mcu_daemon.service

# Disable serivce that occupy ttymxc0
systemctl disable serial-getty@ttymxc0.service
# Enable EdgeX service
systemctl enable EdgeX.service

update-rc.d adbd.sh defaults
update-rc.d rtcinit.sh defaults
update-rc.d rc.local defaults

apt-get clean
history -c
EOF

sudo umount $TARGET_ROOTFS_DIR/dev

