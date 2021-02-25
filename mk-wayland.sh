#!/bin/bash -e

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
sudo cp -rf packages/imx-gpu-viv/1_6.2.4.p4.0-aarch64-r0/image/* ${TARGET_ROOTFS_DIR}
# libdrm
sudo cp -rf packages/libdrm/2.4.91.imx-r0/image/* ${TARGET_ROOTFS_DIR}
# systemd-serialgetty
sudo cp -rf packages/systemd-serialgetty/1.0-r5/image/* ${TARGET_ROOTFS_DIR}
# weston-init
sudo cp -rf packages/weston-init/1.0-r0/image/* ${TARGET_ROOTFS_DIR}
# kernel module
sudo cp -rf packages/linux-imx/modules/lib/modules/ ${TARGET_ROOTFS_DIR}/lib/
# wayland
# wayland-protocols
# weston

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
  locales \
  kbd 

DEBIAN_FRONTEND=noninteractive apt-get -y install \
v4l-utils alsa-utils git gcc less autoconf autopoint libtool \
bison flex gtk-doc-tools glib-2.0 libglib2.0-dev libpango1.0-dev \
libatk1.0-dev kmod pciutils libjpeg-dev

DEBIAN_FRONTEND=noninteractive apt-get -y install \
libudev-dev libinput-dev libxkbcommon-dev libpam0g-dev libx11-xcb-dev \
libxcb-xfixes0-dev libxcb-composite0-dev libxcursor-dev libxcb-shape0-dev \
libdbus-1-dev libdbus-glib-1-dev libffi-dev libxml2-dev libsystemd-dev

# Build wayland
cd ~
mkdir wayland
wget https://wayland.freedesktop.org/releases/wayland-1.16.0.tar.xz
tar -xvf ./wayland-1.16.0.tar.xz
cd wayland-1.16.0/
./configure --disable-documentation prefix=/usr
make
make install
make DESTDIR=~/wayland install
ldconfig

# Build wayland-protocols
cd ~
mkdir wayland-protocols
git clone https://source.codeaurora.org/external/imx/wayland-protocols-imx.git
cd wayland-protocols-imx/
git checkout e05c19d9520f0b1289cf0844d6e2f877114f39d5
./autogen.sh --prefix=/usr
make install
make DESTDIR=~/wayland-protocols install
ldconfig

# Build weston
cd ~
mkdir weston
git clone https://source.codeaurora.org/external/imx/weston-imx.git
cd weston-imx
git checkout fb563901657b296c7c7c86d26602a622429e334f
./autogen.sh --prefix=/usr --disable-silent-rules --disable-dependency-tracking \
--enable-setuid-install --disable-rdp-compositor --enable-clients \
--enable-simple-clients --enable-demo-clients-install --disable-colord \
--enable-egl --enable-simple-egl-clients --enable-fbdev-compositor \
--disable-headless-compositor --enable-drm-compositor --enable-weston-launch \
--disable-lcms --disable-libunwind --with-pam --disable-vaapi-recorder \
--enable-wayland-compositor --without-webp --disable-x11-compositor \
--enable-xwayland --disable-imxg2d --enable-dbus --enable-systemd-login \
--enable-systemd-notify

make -j4 COMPOSITOR_LIBS="-lGLESv2 -lEGL -lGAL -lwayland-server -lxkbcommon -lpixman-1"
make install
make DESTDIR=~/weston install
ldconfig

apt-get clean
history -c
EOF

sudo umount $TARGET_ROOTFS_DIR/dev

