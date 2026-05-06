#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if command -v dpkg >/dev/null 2>&1; then
  ARCH="$(dpkg --print-architecture)"
else
  case "$(uname -m)" in
    x86_64) ARCH="amd64" ;;
    aarch64 | arm64) ARCH="arm64" ;;
    *) echo "Unsupported machine architecture: $(uname -m)" >&2; exit 1 ;;
  esac
fi

case "$ARCH" in
  amd64) PYLON_SOURCE="$(find "$ROOT_DIR/install" -maxdepth 1 -name '*_amd64.deb' -print -quit)" ;;
  arm64) PYLON_SOURCE="$(find "$ROOT_DIR/install" -maxdepth 1 -name '*_arm64.deb' -print -quit)" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

if [ -z "$PYLON_SOURCE" ]; then
  echo "No pylon .deb found for architecture $ARCH in $ROOT_DIR/install" >&2
  exit 1
fi

cp "$PYLON_SOURCE" "$ROOT_DIR/docker/pylon.deb"
trap 'rm -f "$ROOT_DIR/docker/pylon.deb"' EXIT

docker compose build --build-arg UBUNTU_MIRROR="${UBUNTU_MIRROR:-http://de.archive.ubuntu.com/ubuntu}" "$@"
