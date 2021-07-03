# Dock-Droid · [Follow @sickcodes on Twitter](https://twitter.com/sickcodes)

![Running Android x86 & Android ARM in a Docker container](/running-mac-inside-docker-qemu.png?raw=true "OSX KVM DOCKER")

Docker Android - Run QEMU Android x86 and Android ARM in a Docker! X11 Forwarding! CI/CD for Android!

## Capabilities
- SSH enabled (`localhost:50922`)
- SCRCPY enabled (`localhost:5555`)
- WebCam forwarding enabled (`/dev/video0`)
- Audio forwarding enabled (`/dev/snd`)
- X11 forwarding is enabled
- runs on top of QEMU + KVM
- supports BlissOS, custom images, VDI files, any Android x86 image, Xvfb headless mode
- you can clone your container with `docker commit`

### Requirements

- 20GB disk space for bare minimum installation
- virtualization should be enabled in your BIOS settings
- a kvm-capable host
- at least 50 GBs for `:auto` (half for the base image, half for your runtime image

### TODO

- documentation for security researchers
- gpu acceleration
- support for virt-manager


## Author

This project is maintained by @sickcodes [Sick.Codes](https://sick.codes/). [(Twitter)](https://twitter.com/sickcodes)

Additional credits can be found here: https://github.com/sickcodes/dock-droid/blob/master/CREDITS.md

Epic thanks to [@BlissRoms](https://github.com/BlissRoms) who maintain absolutely incredible Android x86 images.

Special thanks to [@zhouziyang](https://github.com/zhouziyang) who maintains an even more native fork [Redroid](https://github.com/remote-android/redroid-doc)!

This project is heavily based on Docker-OSX: https://github.com/sickcodes/Docker-OSX

<a href="https://hub.docker.com/r/sickcodes/dock-droid"><img src="https://dockeri.co/image/sickcodes/dock-droid"/></a>

## Quick Start Dock-Droid

### BlissOS x86 Image [![https://img.shields.io/docker/image-size/sickcodes/dock-droid/latest?label=sickcodes%2Fdock-droid%3Alatest](https://img.shields.io/docker/image-size/sickcodes/dock-droid/latest?label=sickcodes%2Fdock-droid%3Alatest)](https://hub.docker.com/r/sickcodes/dock-droid/tags?page=1&ordering=last_updated)

```bash
docker run -it \
    --device /dev/kvm \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -p 5555:5555 \
    -p 50922:10022 \
    sickcodes/dock-droid:latest
```

Want to use your WebCam and Audio too?

```bash
docker run -it \
    --device /dev/kvm \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -p 5555:5555 \
    -p 50922:10022 \
    --device /dev/video0 \
    -e EXTRA='-device usb-host,hostbus=3,hostaddr=3' \
    --device /dev/snd \
    sickcodes/dock-droid:latest
```

### Professional support

For more sophisticated endeavours, we offer the following support services:

- Enterprise support, business support, or casual support.
- Custom images, custom scripts, consulting (per hour available!)
- One-on-one conversations with you or your development team.

In case you're interested, contact [@sickcodes on Twitter](https://twitter.com/sickcodes) or submit a contact form [here](https://sick.codes/contact).

## License/Contributing

Docker-OSX is licensed under the [GPL v3+](LICENSE), also known as the GPL v3 or later License. Contributions are welcomed and immensely appreciated. You are allowd to use Dock-Droid as a tool to create proprietary software, as long as you follow any other license within the software..

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

