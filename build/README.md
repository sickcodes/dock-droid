# BlissOS Image Builder

```bash
BUILD_DIRECTORY=/mnt/volume_nyc3_01

# create a persistent folder on the host for building stuff
mkdir "${BUILD_DIRECTORY}/blissos-r36"

cd "${BUILD_DIRECTORY}/blissos-r36"

wget https://raw.githubusercontent.com/sickcodes/dock-droid/master/build/Dockerfile

docker build -t blissos-builder .

docker run -it \
    -v /mnt/volume_nyc3_01/blissos-r36:/blissos-r36 \
    blissos-builder

```

