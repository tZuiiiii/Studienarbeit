#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

echo "Switching to workspace: $SCRIPT_DIR"

if [ -f "devel/setup.bash" ]; then
    source devel/setup.bash
else
    echo "ERROR: devel/setup.bash not found in $SCRIPT_DIR"
    exit 1
fi

if ! pgrep -f "rosbridge_websocket" > /dev/null; then
    echo "Starting Rosbridge..."
    roslaunch rosbridge_server rosbridge_websocket.launch &
    BRIDGE_PID=$!
    sleep 3
else
    echo "Rosbridge is already running."
    BRIDGE_PID=""
fi

sleep 3

echo "Starting webcam..."

source devel/setup.bash
roslaunch eulerian_motion_magnification webcam.launch &
WEBCAM_PID=$!

echo "System running. PIDs: $BRIDGE_PID, $WEBCAM_PID"

trap "kill $BRIDGE_PID $WEBCAM_PID; exit" INT TERM EXIT
wait