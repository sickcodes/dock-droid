#!/usr/bin/docker
# Title:            blissos_x86 builder
# Author:           Sick.Codes https://twitter.com/sickcodes
# Version:          1.0
# License:          GPLv3+
# Website:          https://blissos.org
# Usage:            https://github.com/sickcodes/dock-droid/build

FROM ubuntu:latest

RUN apt update -y \
    && apt upgrade -y \
    && apt install openjdk-8-jdk-headless -y \
    && update-alternatives --config java \
    && update-alternatives --config javac

RUN apt install git-core gnupg flex bison maven gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386  lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip squashfs-tools python-mako libssl-dev ninja-build lunzip syslinux syslinux-utils gettext genisoimage gettext bc xorriso libncurses5 xmlstarlet build-essential git imagemagick lib32readline-dev lib32z1-dev liblz4-tool libncurses5-dev libsdl1.2-dev libxml2 lzop pngcrush rsync schedtool python-enum34 python3-mako libelf-dev -y

RUN git config --global user.name "John Doe"
RUN git config --global user.email johndoe@example.com

# RUN mkdir /blissos-r36

WORKDIR /blissos-r36
# VOLUME ["/blissos-r36"]

CMD repo init -u https://github.com/BlissRoms-x86/manifest.git -b r11-r36 \
    && repo sync -c --force-sync --no-tags --no-clone-bundle -j$(nproc --all) --optimized-fetch --prune
