#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
service_name="smartmirror-kiosk.service"
service_file="/etc/systemd/system/$service_name"
autostart_file="${HOME}/.config/labwc/autostart"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not in PATH" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Error: docker compose plugin is not available" >&2
  exit 1
fi

docker_bin="$(command -v docker)"

tmp_service="$(mktemp)"
cat > "$tmp_service" <<SERVICE
[Unit]
Description=Smart Mirror Kiosk Docker Compose
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$repo_root
ExecStart=$docker_bin compose -f $repo_root/compose.yaml up -d --no-build
ExecStop=$docker_bin compose -f $repo_root/compose.yaml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SERVICE

sudo install -m 0644 "$tmp_service" "$service_file"
rm -f "$tmp_service"
sudo systemctl daemon-reload
sudo systemctl enable "$service_name"

mkdir -p "$(dirname "$autostart_file")"
touch "$autostart_file"

tmp_autostart="$(mktemp)"
awk '
  $0 == "# BEGIN smartmirror kiosk" { skip = 1; next }
  $0 == "# END smartmirror kiosk" { skip = 0; next }
  skip != 1 { print }
' "$autostart_file" > "$tmp_autostart"
cat >> "$tmp_autostart" <<AUTOSTART
# BEGIN smartmirror kiosk
sh -c 'until curl -fsS --max-time 2 http://127.0.0.1:3001 >/dev/null 2>&1; do sleep 2; done; browser="\$(command -v chromium-browser || command -v chromium)"; exec "\$browser" --start-fullscreen --noerrdialogs --disable-infobars --no-first-run --start-maximized --disable-session-crashed-bubble http://127.0.0.1:3001' &
# END smartmirror kiosk
AUTOSTART
mv "$tmp_autostart" "$autostart_file"

echo "Enabled $service_name"
echo "Enabled Chromium kiosk autostart in $autostart_file"
echo "Camera mode is configured in $repo_root/compose.yaml"
