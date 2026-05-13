# Smart Mirror Docker

This builds one Ubuntu 20.04 / ROS Noetic image for PC (`amd64`) and Raspberry Pi 4 (`arm64`).
The container serves the static kiosk UI with Python and starts the required ROS processes.

## Build on the current machine

```sh
./docker/build-local.sh
```

## Build Raspberry Pi image on an x86 PC

Build an ARM64 image for the Raspberry Pi from an amd64/x86 PC:

If `docker buildx` is missing, install the plugin first:

```sh
sudo apt install docker-buildx-plugin
docker run --privileged --rm tonistiigi/binfmt --install arm64
```

Build and export it as a compressed archive:

```sh
./docker/build-arm64-on-x86.sh --save
scp smartmirror-kiosk-noetic-pi.tar.gz pi@<pi-ip>:~
```

On the Raspberry Pi:

```sh
gunzip -c smartmirror-kiosk-noetic-pi.tar.gz | docker load
```

## Camera mode

Configure the camera mode in `compose.yaml`:

```yaml
# Use "pylon" instead of "webcam" for the Basler/Pylon camera.
CAMERA_MODE: webcam
```

Then start or restart the container manually:

```sh
docker compose up -d
```

## Raspberry Pi autostart

On Raspberry Pi OS with Desktop, enable boot autostart for the Docker container and Chromium kiosk browser:

```sh
./autostart/enable-autostart.sh
sudo reboot
```

The autostart service uses the already loaded image and does not build on boot.

Disable it again:

```sh
./autostart/disable-autostart.sh
```

## Pylon package selection

Both pylon packages must exist in `install/`:

```text
install/pylon_7.5.0.15658-deb0_amd64.deb
install/pylon_7.5.0.15658-deb0_arm64.deb
```

[Download here](https://www.baslerweb.com/en/downloads/software/3359722533/)
