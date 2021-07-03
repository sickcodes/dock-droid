#!/usr/bin/docker
#     ___              _         ___              _      _             
#    /   \ ___    ___ | | __    /   \ _ __  ___  (_)  __| |  ___  _ __ 
#   / /\ // _ \  / __|| |/ /   / /\ /| '__|/ _ \ | | / _` | / _ \| '__|
#  / /_//| (_) || (__ |   <   / /_// | |  | (_) || || (_| ||  __/| |   
# /___,'  \___/  \___||_|\_\ /___,'  |_|   \___/ |_| \__,_| \___||_|   
#
# Title:            Dock-Droider (Docker Android)
# Author:           Sick.Codes https://twitter.com/sickcodes
# Version:          1.0
# License:          GPLv3+
# Repository:       https://github.com/sickcodes/dock-droider
# Website:          https://sick.codes
#
# All credits for dock-droid and the rest at @Kholia's repo: https://github.com/kholia/dock-droid
# OpenCore support go to https://github.com/Leoyzen/KVM-Opencore
# and https://github.com/thenickdude/KVM-Opencore/
#
# This Dockerfile automates the installation of dock-droid
# It will build a 200GB container. You can change the size using build arguments.
# This Dockerfile builds on top of the work done by Dhiru Kholia, and many others.
#
# Build:
#
#       docker build -t dock-droid .
#       docker build -t dock-droid --build-arg VERSION=10.15.5 --build-arg SIZE=200G .
#
# Basic Run:
#
#       docker run --device /dev/kvm --device /dev/snd -v /tmp/.X11-unix:/tmp/.X11-unix -e "DISPLAY=${DISPLAY:-:0.0}" sickcodes/dock-droid:latest
#
# Run with SSH:
#
#       docker run --device /dev/kvm --device /dev/snd -e RAM=6 -p 50922:10022 -v /tmp/.X11-unix:/tmp/.X11-unix -e "DISPLAY=${DISPLAY:-:0.0}" sickcodes/dock-droid:latest
#       # ssh fullname@localhost -p 50922
#
# Optargs:
#
#       -v $PWD/disk.img:/image
#       -e SIZE=200G
#       -e VERSION=10.15.6
#       -e RAM=5
#       -e SMP=4
#       -e CORES=4
#       -e EXTRA=
#       -e INTERNAL_SSH_PORT=10022
#       -e MAC_ADDRESS=
#
# Extra QEMU args:
#
#       docker run ... -e EXTRA="-usb -device usb-host,hostbus=1,hostaddr=8" ...
#       # you will also need to pass the device to the container

FROM archlinux:base-devel

MAINTAINER 'https://twitter.com/sickcodes' <https://sick.codes>

SHELL ["/bin/bash", "-c"]

ARG SIZE=10G
ARG VERSION=10.15.6
ARG VDI=

# OPTIONAL: Arch Linux server mirrors for super fast builds
# set RANKMIRRORS to any value other that nothing, e.g. -e RANKMIRRORS=true
ARG RANKMIRRORS
ARG MIRROR_COUNTRY=US
ARG MIRROR_COUNT=10

# TEMP-FIX for pacman issue
RUN patched_glibc=glibc-linux4-2.33-4-x86_64.pkg.tar.zst \
    && curl -LO "https://raw.githubusercontent.com/sickcodes/dock-droid/master/${patched_glibc}" \
    && bsdtar -C / -xvf "${patched_glibc}" || echo "Everything is fine."
# TEMP-FIX for pacman issue

RUN if [[ "${RANKMIRRORS}" ]]; then \
        { pacman -Sy wget --noconfirm || pacman -Syu wget --noconfirm ; } \
        ; wget -O ./rankmirrors "https://raw.githubusercontent.com/sickcodes/dock-droid/master/rankmirrors" \
        ; wget -O- "https://www.archlinux.org/mirrorlist/?country=${MIRROR_COUNTRY:-US}&protocol=https&use_mirror_status=on" \
        | sed -e 's/^#Server/Server/' -e '/^#/d' \
        | head -n "$((${MIRROR_COUNT:-10}+1))" \
        | bash ./rankmirrors --verbose --max-time 5 - > /etc/pacman.d/mirrorlist \
        && tee -a /etc/pacman.d/mirrorlist <<< 'Server = http://mirrors.evowise.com/archlinux/$repo/os/$arch' \
        && tee -a /etc/pacman.d/mirrorlist <<< 'Server = http://mirror.rackspace.com/archlinux/$repo/os/$arch' \
        && tee -a /etc/pacman.d/mirrorlist <<< 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' \
        && cat /etc/pacman.d/mirrorlist \
    ; fi

# This fails on hub.docker.com, useful for debugging in cloud
# RUN [[ $(egrep -c '(svm|vmx)' /proc/cpuinfo) -gt 0 ]] || { echo KVM not possible on this host && exit 1; }

# RUN tee -a /etc/pacman.conf <<< '[community-testing]' \
#     && tee -a /etc/pacman.conf <<< 'Include = /etc/pacman.d/mirrorlist'

RUN pacman -Syu git zip vim nano alsa-utils openssh --noconfirm \
    && ln -s /bin/vim /bin/vi \
    && useradd arch -p arch \
    && tee -a /etc/sudoers <<< 'arch ALL=(ALL) NOPASSWD: ALL' \
    && mkdir /home/arch \
    && chown arch:arch /home/arch

# TEMP-FIX for pacman issue
RUN patched_glibc=glibc-linux4-2.33-4-x86_64.pkg.tar.zst \
    && curl -LO "https://raw.githubusercontent.com/sickcodes/dock-droid/master/${patched_glibc}" \
    && bsdtar -C / -xvf "${patched_glibc}" || echo "Everything is fine."
# TEMP-FIX for pacman issue

# allow ssh to container
RUN mkdir -m 700 /root/.ssh

WORKDIR /root/.ssh
RUN touch authorized_keys \
    && chmod 644 authorized_keys

WORKDIR /etc/ssh
RUN tee -a sshd_config <<< 'AllowTcpForwarding yes' \
    && tee -a sshd_config <<< 'PermitTunnel yes' \
    && tee -a sshd_config <<< 'X11Forwarding yes' \
    && tee -a sshd_config <<< 'PasswordAuthentication yes' \
    && tee -a sshd_config <<< 'PermitRootLogin yes' \
    && tee -a sshd_config <<< 'PubkeyAuthentication yes' \
    && tee -a sshd_config <<< 'HostKey /etc/ssh/ssh_host_rsa_key' \
    && tee -a sshd_config <<< 'HostKey /etc/ssh/ssh_host_ecdsa_key' \
    && tee -a sshd_config <<< 'HostKey /etc/ssh/ssh_host_ed25519_key'

USER arch

WORKDIR /home/arch/dock-droid

# optional --build-arg to change branches for testing
ARG BRANCH=master
ARG REPO='https://github.com/sickcodes/dock-droid.git'
RUN git clone --recurse-submodules --depth 1 --branch "${BRANCH}" "${REPO}"

RUN touch ./enable-ssh.sh \
    && chmod +x ./enable-ssh.sh \
    && tee -a enable-ssh.sh <<< '[[ -f /etc/ssh/ssh_host_rsa_key ]] || \' \
    && tee -a enable-ssh.sh <<< '[[ -f /etc/ssh/ssh_host_ed25519_key ]] || \' \
    && tee -a enable-ssh.sh <<< '[[ -f /etc/ssh/ssh_host_ed25519_key ]] || \' \
    && tee -a enable-ssh.sh <<< 'sudo /usr/bin/ssh-keygen -A' \
    && tee -a enable-ssh.sh <<< 'nohup sudo /usr/bin/sshd -D &'

# QEMU CONFIGURATOR
# set optional ram at runtime -e RAM=16
# set optional cores at runtime -e SMP=4 -e CORES=2
# add any additional commands in QEMU cli format -e EXTRA="-usb -device usb-host,hostbus=1,hostaddr=8"

RUN yes | sudo pacman -Syu qemu libvirt dnsmasq virt-manager bridge-utils openresolv jack ebtables edk2-ovmf netctl libvirt-dbus wget --overwrite --noconfirm \
    && yes | sudo pacman -Scc

# TEMP-FIX for pacman issue
RUN patched_glibc=glibc-linux4-2.33-4-x86_64.pkg.tar.zst \
    && curl -LO "https://raw.githubusercontent.com/sickcodes/dock-droid/master/${patched_glibc}" \
    && bsdtar -C / -xvf "${patched_glibc}" || echo "Everything is fine."
# TEMP-FIX for pacman issue

# RUN sudo systemctl enable libvirtd.service
# RUN sudo systemctl enable virtlogd.service

# From a VDI (Virtual Box Image)

RUN [[ -z "${VDI}" ]] && qemu-img convert -f vdi -O qcow2 "${VDI}" android.qcow2


RUN touch Launch.sh \
    && chmod +x ./Launch.sh \
    && tee -a Launch.sh <<< '#!/bin/bash' \
    && tee -a Launch.sh <<< 'set -eux' \
    && tee -a Launch.sh <<< 'sudo chown    $(id -u):$(id -g) /dev/kvm 2>/dev/null || true' \
    && tee -a Launch.sh <<< 'sudo chown -R $(id -u):$(id -g) /dev/snd 2>/dev/null || true' \
    && tee -a Launch.sh <<< 'sudo chown -R $(id -u):$(id -g) /dev/video{0..10} 2>/dev/null || true' \
    && tee -a Launch.sh <<< 'exec qemu-system-x86_64 -m ${RAM:-2}000 \' \
    && tee -a Launch.sh <<< '-cpu ${CPU:-kvm64},+invtsc,vmware-cpuid-freq=on,+pcid,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check,${BOOT_ARGS} \' \
    && tee -a Launch.sh <<< '-machine q35,${KVM-"accel=kvm:tcg"} \' \
    && tee -a Launch.sh <<< '-smp ${CPU_STRING:-${SMP:-4},cores=${CORES:-4}} \' \
    && tee -a Launch.sh <<< '-hda "${IMAGE_PATH}" \' \
    && tee -a Launch.sh <<< '-usb -device usb-kbd -device usb-tablet \' \
    && tee -a Launch.sh <<< '-smbios type=2 \' \
    && tee -a Launch.sh <<< '-audiodev ${AUDIO_DRIVER:-alsa},id=hda -device ich9-intel-hda -device hda-duplex,audiodev=hda \' \
    && tee -a Launch.sh <<< '-device ich9-ahci,id=sata \' \
    && tee -a Launch.sh <<< '-device usb-ehci,id=ehci \' \
    && tee -a Launch.sh <<< '-netdev user,id=net0,hostfwd=tcp::${INTERNAL_SSH_PORT:-10022}-:22,hostfwd=tcp::${SCREEN_SHARE_PORT:-5900}-:5900,hostfwd=tcp::${ADB_PORT:-5555}-:5555,${ADDITIONAL_PORTS} \' \
    && tee -a Launch.sh <<< '-device ${NETWORKING:-vmxnet3},netdev=net0,id=net0,mac=${MAC_ADDRESS:-00:11:22:33:44:55} \' \
    && tee -a Launch.sh <<< '-monitor stdio \' \
    && tee -a Launch.sh <<< '-vga vmware \' \
    && tee -a Launch.sh <<< '${WEBCAM:-}' \
    && tee -a Launch.sh <<< '${EXTRA:-}'

USER arch

ENV USER arch

#### SPECIAL RUNTIME ARGUMENTS BELOW

# env -e ADDITIONAL_PORTS with a comma
# for example, -e ADDITIONAL_PORTS=hostfwd=tcp::23-:23,
ENV ADDITIONAL_PORTS=

# add additional QEMU boot arguments
ENV BOOT_ARGS=

# edit the CPU that is beign emulated
ENV CPU=kvm64

ENV DISPLAY=:0.0

ENV HDA=/

ENV IMAGE_PATH=/home/arch/dock-droid/android.qcow2
ENV IMAGE_FORMAT=qcow2

ENV KVM='accel=kvm:tcg'

# ENV NETWORKING=e1000-82545em
ENV NETWORKING=vmxnet3

# dynamic RAM options for runtime
ENV RAM=3
# ENV RAM=max
# ENV RAM=half

# ENV WEBCAM=/dev/video0
ENV WEBCAM=

VOLUME ["/tmp/.X11-unix"]

# CMD sudo touch /dev/kvm /dev/snd "${IMAGE_PATH}" "${BOOTDISK}" "${ENV}" 2>/dev/null || true \
    # ; sudo chown -R $(id -u):$(id -g) /dev/kvm /dev/snd "${IMAGE_PATH}" "${BOOTDISK}" "${ENV}" 2>/dev/null || true \
CMD ./enable-ssh.sh && /bin/bash -c ./Launch.sh
