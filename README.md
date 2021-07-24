# Dock-Droid · [Follow @sickcodes on Twitter](https://twitter.com/sickcodes)

![Running Android x86 & Android ARM in a Docker container](/dock-droid-docker-android.png?raw=true "ANDROID KVM IN DOCKER CONTAINER")

Docker Android - Run QEMU Android x86 and Android ARM in a Docker! X11 Forwarding! CI/CD for Android!

## Capabilities
- SSH enabled (`localhost:50922`)
- SCRCPY enabled (`localhost:5555`)
- WebCam forwarding enabled (`/dev/video0`)
- Audio forwarding enabled (`/dev/snd`)
- GPU passthrough (`/dev/dri`)
- X11 forwarding is enabled
- runs on top of QEMU + KVM
- supports BlissOS, custom images, VDI files, any Android x86 image, Xvfb headless mode
- you can clone your container with `docker commit`

## Author

This project is maintained by @sickcodes [Sick.Codes](https://sick.codes/). [(Twitter)](https://twitter.com/sickcodes)

Additional credits can be found here: https://github.com/sickcodes/dock-droid/blob/master/CREDITS.md

Epic thanks to [@BlissRoms](https://github.com/BlissRoms) who maintain absolutely incredible Android x86 images. If you love their images, consider donating to the project: [https://blissos.org/](https://blissos.org/)!

Special thanks to [@zhouziyang](https://github.com/zhouziyang) who maintains an even more native fork [Redroid](https://github.com/remote-android/redroid-doc)!

This project is heavily based on Docker-OSX: https://github.com/sickcodes/Docker-OSX

<a href="https://hub.docker.com/r/sickcodes/dock-droid"><img src="https://dockeri.co/image/sickcodes/dock-droid"/></a>

### Requirements

- 4GB disk space for bare minimum installation
- virtualization should be enabled in your BIOS settings
- a kvm-capable host (not required, but slow otherwise)

## Initial setup
Before you do anything else, you will need to turn on hardware virtualization in your BIOS. Precisely how will depend on your particular machine (and BIOS), but it should be straightforward.

Then, you'll need QEMU and some other dependencies on your host:

```bash
# ARCH
sudo pacman -S qemu libvirt dnsmasq virt-manager bridge-utils flex bison iptables-nft edk2-ovmf

# UBUNTU DEBIAN
sudo apt install qemu qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager

# CENTOS RHEL FEDORA
sudo yum install libvirt qemu-kvm
```

Then, enable libvirt and load the KVM kernel module:

```bash
sudo systemctl enable --now libvirtd
sudo systemctl enable --now virtlogd

echo 1 | sudo tee /sys/module/kvm/parameters/ignore_msrs

sudo modprobe kvm
```

## Quick Start Dock-Droid

You can run the Live OS image, or install to disk.

Connect to the WiFi network called `VirtWifi`.

### BlissOS x86 Image [![https://img.shields.io/docker/image-size/sickcodes/dock-droid/latest?label=sickcodes%2Fdock-droid%3Alatest](https://img.shields.io/docker/image-size/sickcodes/dock-droid/latest?label=sickcodes%2Fdock-droid%3Alatest)](https://hub.docker.com/r/sickcodes/dock-droid/tags?page=1&ordering=last_updated)

```bash
docker run -it \
    --device /dev/kvm \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -p 5555:5555 \
    sickcodes/dock-droid:latest
```

### No Image (:naked) [![https://img.shields.io/docker/image-size/sickcodes/dock-droid/naked?label=sickcodes%2Fdock-droid%3Anaked](https://img.shields.io/docker/image-size/sickcodes/dock-droid/naked?label=sickcodes%2Fdock-droid%3Anaked)](https://hub.docker.com/r/sickcodes/dock-droid/tags?page=1&ordering=last_updated)

```bash
docker run -it \
    --device /dev/kvm \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -v "${PWD}/android.qcow2:/home/arch/dock-droid/android.qcow2" \
    -p 5555:5555 \
    sickcodes/dock-droid:naked

```

### Run without KVM (Work in Progress)

This will boot, but currently does not "work". 

Change `CPU` to `Penryn`, which is normally `host`

Change `ENABLE_KVM`, which is normally `-enable-kvm`
    
Change `KVM`, which is normally `accel=kvm:tcg`

Change `CPUID_FLAGS`, which is normally very long.

```
# use a spacebar in quotes
-e CPU=qemu64 \
-e ENABLE_KVM=' ' \
-e KVM=' ' \
-e CPUID_FLAGS=' ' \
```

For example **(Work in Progress)**:

```bash
docker run -it \
    -e CPU=Penryn \
    -e ENABLE_KVM=' ' \
    -e KVM=' ' \
    -e CPUID_FLAGS=' ' \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -p 5555:5555 \
    sickcodes/dock-droid:latest
```

### Increase RAM

Increase RAM by adding this line: `-e RAM=10 \` for 10GB.

## Docker Virtual Machine WebCam

![Android WebCam Passthrough SPICE USBREDIR QEMU Android x86](/Android-WebCam-Passthrough-QEMU-Android-x86.png?raw=true "Android WebCam Passthrough SPICE USBREDIR QEMU Android x86")

Want to use your Laptop/USB WebCam and Audio too?

There are two options: **usb passthrough**, or **usb redirect (network)**.

`v4l2-ctl --list-devices`

`lsusb`

Find the `hostbus` and `hostaddr`:

```console
Bus 003 Device 003: ID 13d3:56a2 IMC Networks USB2.0 HD UVC WebCam
```
Would be `-device usb-host,hostbus=3,hostaddr=3`

### Passthrough Android Camera over USB

```bash
docker run -it \
    --device /dev/kvm \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -p 5555:5555 \
    -e EXTRA='-device usb-host,hostbus=3,hostaddr=3' \
    sickcodes/dock-droid:latest
```

### Passthrough Android WebCam Camera over the Network!

```console
lsusb
# Bus 003 Device 003: ID 13d3:56a2 IMC Networks USB2.0 HD UVC WebCam
```

Vendor ID is `13d3`
Product ID is `56a2`

In one Terminal on host:
```bash
sudo usbredirserver -p 7700 13d3:56a2
```

In another Terminal on host:

```bash
# 172.17.0.1 is the IP of the Docker Bridge, usually the host, but you can change this to anything.
PORT=7700
IP_ADDRESS=172.17.0.1

docker run -it \
    --device /dev/kvm \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -p 5555:5555 \
    -e EXTRA="-chardev socket,id=usbredirchardev1,port=${PORT},host=${IP_ADDRESS} -device usb-redir,chardev=usbredirchardev1,id=usbredirdev1,bus=ehci.0,debug=4" \
    sickcodes/dock-droid:latest
```

### Android x86 Docker GPU & Hardware Acceleration

Currently in development by BlissOS team: mesa graphics card + OpenGL3.2.

Want to use SwiftShader acceleration?

```bash
docker run -it \
    --privileged \
    --device /dev/kvm \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -p 5555:5555 \
    -p 50922:10022 \
    --device=/dev/dri \
    --group-add video \
    -e EXTRA='-display sdl,gl=on' \
    sickcodes/dock-droid:latest
```

### Use your own image/naked version

```bash

# get container name from 
docker ps -a

# copy out the image
docker cp container_name:/home/arch/dock-droid/android.qcow2 .
```

Use any generic ISO or use your own Android AOSP raw image or qcow2

Where, `"${PWD}/disk.qcow2"` is your image in the host system.
```bash
docker run -it \
    -v "${PWD}/android.qcow2:/home/arch/dock-droid/android.qcow2" \
    --privileged \
    --device /dev/kvm \
    --device /dev/video0 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -p 5555:5555 \
    -p 50922:10022 \
    -e EXTRA='-device usb-host,hostbus=3,hostaddr=3' \
    sickcodes/dock-droid:latest
```

### UEFI BOOT

Add the following: `--bios /usr/share/OVMF/x64/OVMF.fd \` to Launch.sh

Or as a `docker run` argument:

UEFI Boot
```bash
docker run -it \
    --device /dev/kvm \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -p 5555:5555 \
    -e EXTRA='--bios /usr/share/OVMF/x64/OVMF.fd' \
    sickcodes/dock-droid:latest
```

### Custom Build

To use an alternative `CDROM`, you have two choices: runtime or buildtime.

You can add your image to the Dockerfile during the build:

```bash

CDROM_IMAGE_URL='https://sourceforge.net/projects/blissos-x86/files/Official/bleeding_edge/Generic%20builds%20-%20Pie/11.13/Bliss-v11.13--OFFICIAL-20201113-1525_x86_64_k-k4.19.122-ax86-ga-rmi_m-20.1.0-llvm90_dgc-t3_gms_intelhd.iso'

docker build \
    -t dock-droid-custom \
    -e CDROM_IMAGE_URL="${CDROM_IMAGE_URL}" .

```

**OR** you can add it during runtime to the docker hub images as follows.

```console
    -v "${CDROM}:/cdrom" \
    -e CDROM=/cdrom \

```
For example:

```bash
# full path to your image on the host
CDROM="${HOME}/Downloads/image.iso"

docker run -it \
    --device /dev/kvm \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -p 5555:5555 \
    -v "${CDROM}:/cdrom" \
    -e CDROM=/cdrom \
    sickcodes/dock-droid:latest
```


### Force Boot CDROM QEMU

`-boot d ` will force QEMU to boot from the CDROM.

`-e EXTRA='-boot d ' \`

### Naked Container

Reduces the image size by 600Mb if you are using a local directory disk image:
```
docker cp  image_name /home/arch/dock-droid/android.qcow2 .
```

### Modify image

Mount the main `qcow2` file using `libguestfstools`

Then, mount other Android related disks, from inside that image.

GRUB is also in there.

```bash
# on the host
# enable qemu-nbd for network device mounting
sudo modprobe nbd
sudo qemu-nbd --connect=/dev/nbd0 android.qcow2 -f qcow2
sudo fdisk /dev/nbd0 -l

# make a folder to mount the whole resizable image 
# make another to mount the raw Android image within that resizable image.
mkdir -p /tmp/image /tmp/system /tmp/ramdisk
sudo mount /dev/nbd0p1 /tmp/image

# put some keys in the box and copy to your host ~/.android folder

mkdir -p /tmp/image/bliss-x86-11.13/data/.android
mkdir -p /tmp/image/bliss-x86-11.13/data/misc/adb

KEYNAME=adbkey
adb keygen ~/.android/"${KEYNAME}"
touch ~/.android/"${KEYNAME}.pub"
adb pubkey ~/.android/"${KEYNAME}" > ~/.android/"${KEYNAME}.pub"

tee /tmp/image/bliss-x86-11.13/data/misc/adb/adb_keys < ~/.android/"${KEYNAME}.pub"

# if you want to mount system.img, for example, to disable adb security
sudo mount /tmp/image/bliss-x86-11.13/system.img /tmp/system
# sudo mount /tmp/image/bliss-x86-11.13/ramdisk.img /tmp/ramdisk
sudo tee \
    -a /tmp/system/build.prop \
    -a /tmp/system/product/build.prop \
    -a /tmp/system/vendor/build.prop \
    <<< 'ro.adb.secure=0'

sudo tee \
    -a /tmp/system/build.prop \
    -a /tmp/system/product/build.prop \
    -a /tmp/system/vendor/build.prop \
    <<< 'persist.service.adb.enable=1'

sudo tee \
    -a /tmp/system/build.prop \
    -a /tmp/system/product/build.prop \
    -a /tmp/system/vendor/build.prop \
    <<< 'persist.service.debuggable=1'

sudo tee \
    -a /tmp/system/build.prop \
    -a /tmp/system/product/build.prop \
    -a /tmp/system/vendor/build.prop \
    <<< 'persist.sys.usb.config=mtp,adb'

# unmount both disks when you're done
sudo umount /tmp/system
sudo umount /tmp/image
sudo qemu-nbd -d /dev/nbd0
```

Boot the container.

Open `Terminal Emulator` in the Android:
```bash
# on android
su
start adbd
```

Use the new key to `adb` into the guest:

```bash
# on the host
export ADB_VENDOR_KEYS=~/.android/id_dockdroid
adb kill-server
adb connect localhost
adb root
adb -s localhost:5555 shell
```

### How to connect using ADB

Boot into DEBUG MODE from the GRUB boot menu.

In the Android terminal emulator:

Edit `/default.prop`

Change `ro.adb.secure=1` to `ro.adb.secure=0`

E.g.

```bash
su
sed -i -e 's/ro\.adb\.secure\=1/ro\.adb\.secure\=0/' /default.prop

```

In the Android terminal emulator, run `adbd`

Then from the host, you can can connect using either:
`adb connect localhost:5555`

`adb connect 172.17.0.2:5555`



### Professional support

For more sophisticated endeavours, we offer the following support services:

- Enterprise support, business support, or casual support.
- Custom images, custom scripts, consulting (per hour available!)
- One-on-one conversations with you or your development team.

In case you're interested, contact [@sickcodes on Twitter](https://twitter.com/sickcodes) or submit a contact form [here](https://sick.codes/contact).

![How to Install Bliss OS](/bliss_os_installation_instructions_docker.gif?raw=true "How to Install Bliss OS")

## License/Contributing

dock-droid is licensed under the [GPL v3+](LICENSE), also known as the GPL v3 or later License. Contributions are welcomed and immensely appreciated.

Don't be shy, [the GPLv3+](https://www.gnu.org/licenses/quick-guide-gplv3.html) allows you to use Dock-Droid as a tool to create proprietary software, as long as you follow any other license within the software.

## Disclaimer

This is a Dockerized Android setup/tutorial for conducting Android Security Research.

Product names, logos, brands and other trademarks referred to within this project are the property of their respective trademark holders. These trademark holders are not affiliated with our repository in any capacity. They do not sponsor or endorse this project in any way.


### Other cool Docker/QEMU based projects

- [Run macOS in a Docker container with Docker-OSX](https://github.com/sickcodes/Docker-OSX) - [https://github.com/sickcodes/Docker-OSX](https://github.com/sickcodes/Docker-OSX)
- [Run iOS in a Docker container with Docker-eyeOS](https://github.com/sickcodes/Docker-eyeOS) - [https://github.com/sickcodes/Docker-eyeOS](https://github.com/sickcodes/Docker-eyeOS)

# Passthrough your WebCam to the Android container.

Identify your webcam:

```bash
lsusb | grep -i cam
```

```console
Bus 003 Device 003: ID 13d3:56a2 IMC Networks USB2.0 HD UVC WebCam
```

Using `Bus` and `Device` as `hostbus` and `hostaddr`, include the following docker command:

## VFIO Passthrough

*Waiting for public `mesa` builds: https://blissos.org/*

When these hardware accelerated images are released, you can follow the Issue opened by: [@M1cha](https://github.com/M1cha)

See [https://github.com/sickcodes/dock-droid/issues/2](https://github.com/sickcodes/dock-droid/issues/2)

> the online documentation for that is very bad and mostly outdated(due to kernel and qemu updates). But here's some references that helped me set it up several times:
> 
[https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Plain_QEMU_without_libvirt](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Plain_QEMU_without_libvirt)
> 
[https://www.kernel.org/doc/Documentation/vfio.txt](https://www.kernel.org/doc/Documentation/vfio.txt)
> 
> 
> the general summary:
> 
>     * make sure your hardware supports VT-d/AMD-VI and UEFI and linux have it enabled
> 
>     * figure out which devices are in the same iommu group
> 
>     * detach all drivers from those devices
> 
>     * attach vfio-pci to those devices

Add the following lines when you are ready:

```bash
    --privileged \
    -e EXTRA="-device vfio-pci,host=04:00.0' \
```

## GPU Sharing

Work in progress

```bash

sudo tee -a /etc/libvirt/qemu.conf <<'EOF'
cgroup_device_acl = [
    "/dev/null", "/dev/full", "/dev/zero",
    "/dev/random", "/dev/urandom",
    "/dev/ptmx", "/dev/kvm",
    "/dev/vfio/vfio",
    "/dev/dri/card0",
    "/dev/dri/card1",
    "/dev/dri/renderD128"
]
EOF

# --device /dev/video0 \
# --device /dev/video1 \

grep "video\|render" /etc/group

# render:x:989:
# video:x:986:sddm

sudo usermod -aG video "${USER}"

sudo systemctl restart libvirtd

docker run -it \
    -v "${PWD}/android.qcow2:/home/arch/dock-droid/android.qcow2" \
    --privileged \
    --device /dev/kvm \
    --device /dev/video1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -p 5555:5555 \
    -p 50922:10022 \
    --user 1000:1000 \
    --group-add=966 \
    --group-add=989 \
    --device /dev/dri/renderD128:/dev/dri/renderD128 \
    --device /dev/dri/card0:/dev/dri/card0 \
    --device /dev/dri/card1:/dev/dri/card1 \
    sickcodes/dock-droid:naked

# pick which graphics card
# --device /dev/dri/card0:/dev/dri/card0 \

```





## Building a headless container to run remotely with secure VNC

Add the following line:

`-e EXTRA="-display none -vnc 0.0.0.0:99,password=on"`

In the Docker terminal, press `enter` until you see `(qemu)`.

Type `change vnc password someusername`

Enter a password for your new vnc username^.

You also need the container IP: `docker inspect <containerid> | jq -r '.[0].NetworkSettings.IPAddress'`

Or `ip n` will usually show the container IP first.

Now VNC connect using the Docker container IP, for example `172.17.0.2:5999`

Remote VNC over SSH: `ssh -N root@1.1.1.1 -L  5999:172.17.0.2:5999`, where `1.1.1.1` is your remote server IP and `172.17.0.2` is your LAN container IP.

Now you can direct connect VNC to any container built with this command!


# BlissOS Image Builder Using Platform Manifests

**This requires 250GB of REAL space.**

This was previously at `./build`, but due to Docker Hub using the wrong README.md file, I have added these instructions below:

Make and add a non-root user
```bash

USERADD=user
useradd "${USERADD}" -p "${USERADD}"
tee -a /etc/sudoers <<< "${USERADD} ALL=(ALL) NOPASSWD: ALL"
mkdir -p "/home/${USERADD}"
chown "${USERADD}:${USERADD}" "/home/${USERADD}"

# passwd user <<EOF
# 1000
# 1000
# EOF

chsh -s /bin/bash "${USERADD}"

usermod -aG docker "${USERADD}"

su user

```

```bash

BUILD_DIRECTORY=/mnt/volume_nyc3_01

# create a persistent folder on the host for building stuff
mkdir "${BUILD_DIRECTORY}/blissos-r36"

cd "${BUILD_DIRECTORY}/blissos-r36"

wget https://raw.githubusercontent.com/sickcodes/dock-droid/master/Dockerfile.build

docker build -t blissos-builder .

docker run -it \
    -e REVISION=r11-r36 \
    -e MANIFEST_REPO=https://github.com/BlissRoms-x86/manifest.git \
    -v "${BUILD_DIRECTORY}/blissos-r36:/blissos-r36" \
    blissos-builder

```

