# BlissOS Image Builder

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

wget https://raw.githubusercontent.com/sickcodes/dock-droid/master/build/Dockerfile

docker build -t blissos-builder .

docker run -it \
    -e REVISION=r11-r36 \
    -e MANIFEST_REPO=https://github.com/BlissRoms-x86/manifest.git \
    -v "${BUILD_DIRECTORY}/blissos-r36:/blissos-r36" \
    blissos-builder

```

