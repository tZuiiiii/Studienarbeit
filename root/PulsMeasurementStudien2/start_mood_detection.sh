#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

echo "Change to Workspace: $SCRIPT_DIR"

if [ -f "devel/setup.bash" ]; then
    source devel/setup.bash
else
    echo "Error: devel/setup.bash not found in $SCRIPT_DIR"
    exit 1
fi

if ! pgrep -f "rosbridge_websocket" > /dev/null; then
    echo "Start Rosbridge..."
    roslaunch rosbridge_server rosbridge_websocket.launch &
    BRIDGE_PID=$!
    sleep 3
else
    echo "Rosbridge already running. Skip start..."
    BRIDGE_PID=""
fi

if ! pgrep -f "webcam.launch" > /dev/null; then
    echo "Start Camera..."
    roslaunch eulerian_motion_magnification webcam.launch &
    CAMERA_PID=$!
    sleep 3
else
    echo "Camera already running. Skip start..."
    CAMERA_PID=""
fi

echo "Start Mood Detection..."

python3 src/mood_detection/src/mood_cv2.py &
MOOD_PID=$!

echo "System running. PIDs: $BRIDGE_PID (Rosbridge), $CAMERA_PID (Camera), $MOOD_PID (Mood)"

trap 'kill $MOOD_PID; [ -n "$CAMERA_PID" ] && kill $CAMERA_PID; [ -n "$BRIDGE_PID" ] && kill $BRIDGE_PID; exit' INT TERM EXIT
wait