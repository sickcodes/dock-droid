#!/usr/bin/docker
# Title:            blissos_x86 builder
# Author:           Sick.Codes https://twitter.com/sickcodes
# Version:          1.1
# License:          GPLv3+
# Website:          https://blissos.org
# Usage:            https://github.com/sickcodes/dock-droid/build

FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

RUN apt update -y \
    && apt upgrade -y \
    && apt install openjdk-8-jdk-headless -y \
    && update-alternatives --config java \
    && update-alternatives --config javac

RUN apt install git-core gnupg flex bison maven gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386  lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip squashfs-tools python-mako libssl-dev ninja-build lunzip syslinux syslinux-utils gettext genisoimage gettext bc xorriso libncurses5 xmlstarlet build-essential git imagemagick lib32readline-dev lib32z1-dev liblz4-tool libncurses5-dev libsdl1.2-dev libxml2 lzop pngcrush rsync schedtool python-enum34 python3-mako libelf-dev -y

RUN git config --global user.name "John Doe"
RUN git config --global user.email johndoe@example.com

RUN apt install curl wget python -y

# install repo command
RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /bin/repo \
    && chmod a+x /bin/repo

WORKDIR /root

ENV CMDLINE_TOOLS_VERSION=commandlinetools-linux-6858069_latest.zip
RUN wget -O cmdline-tools.zip "https://dl.google.com/android/repository/${CMDLINE_TOOLS_VERSION}" \
    && unzip cmdline-tools.zip \
    && cp -r ./cmdline-tools/lib /lib

ENV PATH="/root/cmdline-tools/bin:${PATH}"

# RUN mkdir /blissos-r36

ENV REVISION=r11-r36

ENV MANIFEST_REPO=https://github.com/BlissRoms-x86/manifest.git

ENV MODE=init
# ENV MODE=sync

WORKDIR /blissos-r36
# VOLUME ["/blissos-r36"]

CMD { [ "${MODE}" = init ] && { yes | repo init -u "${MANIFEST_REPO}" -b "${REVISION}" ; } \
    ; [ "${MODE}" = sync ] && { yes | repo sync -c --force-sync --no-tags --no-clone-bundle -j$(nproc --all) --optimized-fetch --prune ; } \
    ; }


