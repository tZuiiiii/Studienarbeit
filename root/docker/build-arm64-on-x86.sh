#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_TAG="${IMAGE_TAG:-smartmirror-kiosk-noetic:pi}"
UBUNTU_MIRROR="${UBUNTU_MIRROR:-http://de.archive.ubuntu.com/ubuntu}"
SAVE_IMAGE=0
TAG_LOCAL=1

usage() {
  cat <<'EOF'
Usage: docker/build-arm64-on-x86.sh [--save] [--no-local-tag]

Builds a linux/arm64 image on an amd64 PC using Docker Buildx.

Options:
  --save          Save the built image to smartmirror-kiosk-noetic-pi.tar.gz
  --no-local-tag  Do not additionally tag the image as smartmirror-kiosk-noetic:local

Environment:
  IMAGE_TAG       Image tag to build (default: smartmirror-kiosk-noetic:pi)
  UBUNTU_MIRROR   Ubuntu mirror build arg (default: http://de.archive.ubuntu.com/ubuntu)
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --save)
      SAVE_IMAGE=1
      ;;
    --no-local-tag)
      TAG_LOCAL=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if ! docker buildx version >/dev/null 2>&1; then
  cat >&2 <<'EOF'
docker buildx is required for cross-architecture builds, but it is not available.

Install the Docker Buildx plugin first. On Debian/Ubuntu this is usually:
  sudo apt install docker-buildx-plugin

For ARM64 emulation you may also need:
  docker run --privileged --rm tonistiigi/binfmt --install arm64
EOF
  exit 1
fi

PYLON_SOURCE="$(find "$ROOT_DIR/install" -maxdepth 1 -name '*_arm64.deb' -print -quit)"
if [ -z "$PYLON_SOURCE" ]; then
  echo "No ARM64 pylon .deb found in $ROOT_DIR/install" >&2
  exit 1
fi

if ! docker run --rm --entrypoint bash \
  -v "$PYLON_SOURCE:/tmp/pylon.deb:ro" \
  ros:noetic-ros-base-focal \
  -lc 'dpkg-deb --fsys-tarfile /tmp/pylon.deb >/dev/null'; then
  cat >&2 <<EOF
The ARM64 pylon package is not readable:
  $PYLON_SOURCE

Download or copy the ARM64 pylon .deb again, then retry this script.
EOF
  exit 1
fi

cp "$PYLON_SOURCE" "$ROOT_DIR/docker/pylon.deb"
trap 'rm -f "$ROOT_DIR/docker/pylon.deb"' EXIT

build_tags=(-t "$IMAGE_TAG")
if [ "$TAG_LOCAL" -eq 1 ] && [ "$IMAGE_TAG" != "smartmirror-kiosk-noetic:local" ]; then
  build_tags+=(-t "smartmirror-kiosk-noetic:local")
fi

docker buildx build \
  --platform linux/arm64 \
  --build-arg UBUNTU_MIRROR="$UBUNTU_MIRROR" \
  "${build_tags[@]}" \
  --load \
  "$ROOT_DIR"

if [ "$SAVE_IMAGE" -eq 1 ]; then
  output="$ROOT_DIR/smartmirror-kiosk-noetic-pi.tar.gz"
  save_tags=("$IMAGE_TAG")
  if [ "$TAG_LOCAL" -eq 1 ] && [ "$IMAGE_TAG" != "smartmirror-kiosk-noetic:local" ]; then
    save_tags+=("smartmirror-kiosk-noetic:local")
  fi
  docker save "${save_tags[@]}" | gzip > "$output"
  echo "Saved image to $output"
fi
