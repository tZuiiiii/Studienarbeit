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

CAMERA_MODE="${CAMERA_MODE:-webcam}"
CAMERA_MODE="${CAMERA_MODE,,}"

case "$CAMERA_MODE" in
    webcam)
        CAMERA_LABEL="Webcam"
        CAMERA_PROCESS_PATTERN="eulerian_motion_magnification webcam.launch"
        CAMERA_CMD=(roslaunch eulerian_motion_magnification webcam.launch)
        MOOD_CMD=(python3 src/mood_detection/src/mood_cv2.py)
        ;;
    pylon|basler|industry|industry_camera)
        CAMERA_MODE="pylon"
        CAMERA_LABEL="Pylon camera"
        CAMERA_PROCESS_PATTERN="eulerian_motion_magnification industry_camera.launch"
        CAMERA_CMD=(roslaunch eulerian_motion_magnification industry_camera.launch show_image_frame:=false show_processed_image:=false)
        MOOD_CMD=(python3 src/mood_detection/src/mood_industry_camera.py)
        ;;
    *)
        echo "Error: Unsupported CAMERA_MODE '$CAMERA_MODE'. Use 'webcam' or 'pylon'."
        exit 1
        ;;
esac

echo "Camera mode: $CAMERA_MODE"

if ! pgrep -f "rosbridge_websocket" > /dev/null; then
    echo "Start Rosbridge..."
    roslaunch rosbridge_server rosbridge_websocket.launch &
    BRIDGE_PID=$!
    sleep 3
else
    echo "Rosbridge already running. Skip start..."
    BRIDGE_PID=""
fi

if ! pgrep -f "$CAMERA_PROCESS_PATTERN" > /dev/null; then
    echo "Start $CAMERA_LABEL..."
    "${CAMERA_CMD[@]}" &
    CAMERA_PID=$!
    sleep 3
else
    echo "$CAMERA_LABEL already running. Skip start..."
    CAMERA_PID=""
fi

echo "Start Mood Detection..."

"${MOOD_CMD[@]}" &
MOOD_PID=$!

echo "System running. PIDs: $BRIDGE_PID (Rosbridge), $CAMERA_PID (Camera), $MOOD_PID (Mood)"

trap 'kill $MOOD_PID; [ -n "$CAMERA_PID" ] && kill $CAMERA_PID; [ -n "$BRIDGE_PID" ] && kill $BRIDGE_PID; exit' INT TERM EXIT
wait
