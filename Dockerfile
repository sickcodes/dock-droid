#!/usr/bin/docker
#     ___              _         ___              _      _             
#    /   \ ___    ___ | | __    /   \ _ __  ___  (_)  __| |
#   / /\ // _ \  / __|| |/ /   / /\ /| '__|/ _ \ | | / _` |
#  / /_//| (_) || (__ |   <   / /_// | |  | (_) || || (_| |
# /___,'  \___/  \___||_|\_\ /___,'  |_|   \___/ |_| \__,_|
#
# Title:            Dock-Droid (Docker Android)
# Author:           Sick.Codes https://twitter.com/sickcodes
# Version:          1.0
# License:          GPLv3+
# Repository:       https://github.com/sickcodes/dock-droid
# Website:          https://sick.codes
#
# This Dockerfile is a wrapper for Android x86 raw or qcow2 images.
# 
# Build:
#
#       docker build -t dock-droid .
#

FROM archlinux:base-devel

MAINTAINER 'https://twitter.com/sickcodes' <https://sick.codes>

SHELL ["/bin/bash", "-c"]

# OPTIONAL: Arch Linux server mirrors for super fast builds
# set RANKMIRRORS to any value other that nothing, e.g. -e RANKMIRRORS=true
ARG RANKMIRRORS
ARG MIRROR_COUNTRY=US
ARG MIRROR_COUNT=10

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

RUN pacman -Syu git zip vim nano alsa-utils openssh unzip usbutils --noconfirm \
    && ln -s /bin/vim /bin/vi \
    && useradd arch -p arch \
    && tee -a /etc/sudoers <<< 'arch ALL=(ALL) NOPASSWD: ALL' \
    && mkdir /home/arch \
    && chown arch:arch /home/arch

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

ENV USER arch

WORKDIR /home/arch

RUN git clone https://aur.archlinux.org/android-sdk-platform-tools.git \
    && cd android-sdk-platform-tools \
    && makepkg -si --nocheck --force --noconfirm \
    ; source /etc/profile.d/android-sdk-platform-tools.sh || exit 1

RUN git clone https://aur.archlinux.org/binfmt-qemu-static.git \
    && cd binfmt-qemu-static \
    && makepkg -si --nocheck --force --noconfirm || exit 1

RUN git clone https://aur.archlinux.org/qemu-user-static-bin.git \
    && cd qemu-user-static-bin \
    && makepkg -si --nocheck --force --noconfirm || exit 1


WORKDIR /home/arch

# optional --build-arg to change branches for testing
ARG BRANCH=master
ARG REPO='https://github.com/sickcodes/dock-droid.git'
RUN git clone --recurse-submodules --depth 1 --branch "${BRANCH}" "${REPO}"

WORKDIR /home/arch/dock-droid

RUN touch ./enable-ssh.sh \
    && chmod +x ./enable-ssh.sh \
    && tee -a enable-ssh.sh <<< '[[ -f /etc/ssh/ssh_host_rsa_key ]] || \' \
    && tee -a enable-ssh.sh <<< '[[ -f /etc/ssh/ssh_host_ed25519_key ]] || \' \
    && tee -a enable-ssh.sh <<< '[[ -f /etc/ssh/ssh_host_ed25519_key ]] || \' \
    && tee -a enable-ssh.sh <<< 'sudo /usr/bin/ssh-keygen -A' \
    && tee -a enable-ssh.sh <<< 'nohup sudo /usr/bin/sshd -D &'

RUN yes | sudo pacman -Syu qemu virglrenderer libvirt dnsmasq virt-manager bridge-utils openresolv jack ebtables edk2-ovmf netctl libvirt-dbus wget --overwrite --noconfirm \
    && yes | sudo pacman -Scc

ARG LINUX=true

# # required to use libguestfs inside a docker container, to create bootdisks for docker-osx on-the-fly
# RUN if [[ "${LINUX}" == true ]]; then \
#         sudo pacman -Syu linux libguestfs --overwrite --noconfirm \
#     ; fi

ARG COMPLETE=true

ARG CDROM_IMAGE_URL=https://sourceforge.net/projects/blissos-x86/files/Official/bleeding_edge/Generic%20builds%20-%20Pie/11.13/Bliss-v11.13--OFFICIAL-20201113-1525_x86_64_k-k4.19.122-ax86-ga-rmi_m-20.1.0-llvm90_dgc-t3_gms_intelhd.iso
# ARG CDROM_IMAGE_URL=https://sourceforge.net/projects/blissos-dev/files/Android-Generic/PC/bliss/R/gapps/BlissOS-14.3-x86_64-202106261907_k-android12-5.10.46-ax86_m-21.1.3_r-x86_emugapps_cros-hd.iso
# ARG CDROM_IMAGE_URL=https://sourceforge.net/projects/blissos-dev/files/Android-Generic/PC/bliss/R/gapps/BlissOS-14.3-x86_64-202106181339_k-google-5.4.112-lts-ax86_m-r_emugapps_cros-hd_gearlock.iso

ENV CDROM_IMAGE_URL="${CDROM_IMAGE_URL}"

# use the COMPLETE arg, for a complete image, ready to boot.
# otherwise use your own image: -v "$PWD/disk.img":/image
ARG WGET_OPTIONS=
# ARG WGET_OPTIONS='--no-verbose'

RUN if [[ "${COMPLETE}" ]]; then \
        echo "Downloading 1GB image... This step might take a while... Press Ctrl+C if you want to abort." \
        && wget ${WGET_OPTIONS} "${CDROM_IMAGE_URL}" || exit 1 \
    ; fi

ARG QCOW_SIZE=50G

RUN qemu-img create -f qcow2 /home/arch/dock-droid/android.qcow2 "${QCOW_SIZE}"

# RUN [[ -z "${VDI}" ]] && qemu-img convert -f vdi -O qcow2 "${VDI}" android.qcow2
# RUN [[ -z "${ISO}" ]] && -cdrom \

#### Mount disk inside container

# sudo modprobe nbd \
# sudo qemu-nbd --connect=/dev/nbd0 android2.qcow2 -f qcow2 \
# sudo fdisk /dev/nbd0 -l\
# mkdir /tmp/image /tmp/system
# sudo mount /dev/nbd0p1 /tmp/image

# sudo mount /tmp/image/bliss-x86-11.13/system.img /tmp/system
# sudo tee -a /tmp/system/build.prop <<< 'ro.adb.secure=0'
# sudo umount /tmp/system
# sudo umount /tmp/image
# sudo qemu-nbd -d /dev/nbd0

RUN wget -O supergrub2.iso https://telkomuniversity.dl.sourceforge.net/project/supergrub2/2.04s2-beta2/super_grub2_disk_2.04s2-beta2/supergrub2-2.04s2-beta2-multiarch-CD.iso

# RUN sudo guestfish -a /home/user/bliss/android2.qcow2 \  

# sudo guestmount -a android.qcow2 -m /dev/vg0 /mnt

#### SPECIAL RUNTIME ARGUMENTS BELOW

# env -e ADDITIONAL_PORTS with a comma
# for example, -e ADDITIONAL_PORTS=hostfwd=tcp::23-:23,
ENV ADDITIONAL_PORTS=

# add additional QEMU boot arguments
ENV BOOT_ARGS=

# edit the CPU that is beign emulated
ENV CPU=host
ENV CPUID_FLAGS='+invtsc,vmware-cpuid-freq=on,+pcid,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check,'

ENV DISPLAY=:0.0
ENV DISPLAY_ARGUMENTS='-vga vmware'

ENV ENABLE_KVM='-enable-kvm'

ENV IMAGE_PATH=/home/arch/dock-droid/android.qcow2
ENV IMAGE_FORMAT=qcow2

ENV KVM='accel=kvm:tcg'

# ENV NETWORKING=e1000-82545em
ENV NETWORKING=vmxnet3

# add libguestfs debug output
ENV LIBGUESTFS_DEBUG=1
ENV LIBGUESTFS_TRACE=1

ENV PATH="${PATH}:/opt/android-sdk/platform-tools"

# dynamic RAM options for runtime
ENV RAM=4
# ENV RAM=max
# ENV RAM=half

# ENV WEBCAM=/dev/video0
ENV WEBCAM=

RUN touch Launch.sh \
    && chmod +x ./Launch.sh \
    && tee -a Launch.sh <<< '#!/bin/bash' \
    && tee -a Launch.sh <<< 'set -eux' \
    && tee -a Launch.sh <<< 'source /etc/profile.d/android-sdk-platform-tools.sh' \
    && tee -a Launch.sh <<< 'sudo chown    $(id -u):$(id -g) /dev/kvm 2>/dev/null || true' \
    && tee -a Launch.sh <<< 'sudo chown -R $(id -u):$(id -g) /dev/snd 2>/dev/null || true' \
    && tee -a Launch.sh <<< 'sudo chown -R $(id -u):$(id -g) /dev/video{0..10} 2>/dev/null || true' \
    && tee -a Launch.sh <<< 'sudo qemu-system-x86_64 -m ${RAM:-4}000 \' \
    && tee -a Launch.sh <<< '${ENABLE_KVM-"-enable-kvm"} \' \
    && tee -a Launch.sh <<< '-cpu ${CPU-host},${CPUID_FLAGS-"+invtsc,vmware-cpuid-freq=on,+pcid,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check,"}${BOOT_ARGS} \' \
    && tee -a Launch.sh <<< '-smp ${CPU_STRING:-$(nproc)} \' \
    && tee -a Launch.sh <<< '-machine q35,${KVM-"accel=kvm:tcg"} \' \
    && tee -a Launch.sh <<< '-smp ${CPU_STRING:-${SMP:-4},cores=${CORES:-4}} \' \
    && tee -a Launch.sh <<< '-hda "${IMAGE_PATH:=/home/arch/dock-droid/android.qcow2}" \' \
    && tee -a Launch.sh <<< '-usb -device usb-kbd -device usb-tablet \' \
    && tee -a Launch.sh <<< '-smbios type=2 \' \
    && tee -a Launch.sh <<< '-audiodev ${AUDIO_DRIVER:-alsa},id=hda -device ich9-intel-hda -device hda-duplex,audiodev=hda \' \
    && tee -a Launch.sh <<< '-device usb-ehci,id=ehci \' \
    && tee -a Launch.sh <<< '-netdev user,id=net0,hostfwd=tcp::${INTERNAL_SSH_PORT:-10022}-:22,hostfwd=tcp::${SCREEN_SHARE_PORT:-5900}-:5900,hostfwd=tcp::${ADB_PORT:-5555}-:5555,${ADDITIONAL_PORTS} \' \
    && tee -a Launch.sh <<< '-device ${NETWORKING:-vmxnet3},netdev=net0,id=net0,mac=${MAC_ADDRESS:-00:11:22:33:44:55} \' \
    && tee -a Launch.sh <<< '-monitor stdio \' \
    && tee -a Launch.sh <<< '-boot menu=on \' \
    && tee -a Launch.sh <<< '-cdrom "${CDROM:-${CDROM}}" \' \
    && tee -a Launch.sh <<< '${DISPLAY_ARGUMENTS:=-vga vmware} \' \
    && tee -a Launch.sh <<< '${WEBCAM:-} \' \
    && tee -a Launch.sh <<< '${EXTRA:-}'

VOLUME ["/tmp/.X11-unix"]

CMD export CDROM="${CDROM:="$(basename "${CDROM_IMAGE_URL}")"}" \
    && touch ./android.qcow2 "${CDROM}" \
    && ./enable-ssh.sh \
    && /bin/bash -c ./Launch.sh

