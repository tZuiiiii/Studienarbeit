#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

echo "Wechsle in Workspace: $SCRIPT_DIR"

if [ -f "devel/setup.bash" ]; then
    source devel/setup.bash
else
    echo "FEHLER: devel/setup.bash nicht gefunden in $SCRIPT_DIR"
    exit 1
fi

echo "Starte Rosbridge..."
roslaunch rosbridge_server rosbridge_websocket.launch &
BRIDGE_PID=$!

sleep 3

echo "Starte Webcam..."

source devel/setup.bash
roslaunch eulerian_motion_magnification webcam.launch &
WEBCAM_PID=$!

echo "System läuft. PIDs: $BRIDGE_PID, $WEBCAM_PID"

trap "kill $BRIDGE_PID $WEBCAM_PID; exit" INT TERM EXIT
wait
