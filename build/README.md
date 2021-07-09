# BlissOS Image Builder

```bash
# create a persistent folder on the host for building stuff
mkdir /mnt/volume_nyc3_01/blissos-r36

cd /mnt/volume_nyc3_01/blissos-r36

wget https://github.com/sickcodes/dock-droid/build/Dockerfile

docker build -t blissos-builder .

docker run -it \
    -v /mnt/volume_nyc3_01/blissos-r36:/blissos-r36 \
    blissos-builder

```

