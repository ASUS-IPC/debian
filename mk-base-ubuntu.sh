#!/bin/bash

if [ ! ${RELEASE} ]; then
	RELEASE='18.04'
fi

if [ ! ${NXP_ARCH} ]; then
	NXP_ARCH='arm64'
fi

if [ -e ubuntu-*.tar.gz ]; then
	rm ubuntu-*.tar.gz
fi

if [ ${RELEASE} = "18.04" ]; then
	link="cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04.5-base-arm64.tar.gz"
elif [ ${RELEASE} = "20.04" ]; then
	link="cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.2-base-arm64.tar.gz"
fi
wget $link
