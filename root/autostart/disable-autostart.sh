#!/usr/bin/env bash
set -euo pipefail

service_name="smartmirror-kiosk.service"
service_file="/etc/systemd/system/$service_name"
autostart_file="${HOME}/.config/labwc/autostart"

if systemctl list-unit-files "$service_name" >/dev/null 2>&1; then
  sudo systemctl disable "$service_name" >/dev/null 2>&1 || true
fi

if [ -f "$service_file" ]; then
  sudo rm -f "$service_file"
  sudo systemctl daemon-reload
fi

if [ -f "$autostart_file" ]; then
  tmp_autostart="$(mktemp)"
  awk '
    $0 == "# BEGIN smartmirror kiosk" { skip = 1; next }
    $0 == "# END smartmirror kiosk" { skip = 0; next }
    skip != 1 { print }
  ' "$autostart_file" > "$tmp_autostart"
  mv "$tmp_autostart" "$autostart_file"
fi

echo "Disabled $service_name"
echo "Removed Smart Mirror Chromium autostart from $autostart_file if present"
