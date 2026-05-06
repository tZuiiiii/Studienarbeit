#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/noetic/setup.bash

workspace="/opt/smartmirror/PulsMeasurementStudien2"

if [ ! -f "$workspace/devel/setup.bash" ]; then
  echo "Error: devel/setup.bash not found in $workspace" >&2
  exit 1
fi

source "$workspace/devel/setup.bash"

export PYLON_ROOT="${PYLON_ROOT:-/opt/pylon}"
export LD_LIBRARY_PATH="${PYLON_ROOT}/lib:${LD_LIBRARY_PATH:-}"
export PORT="${PORT:-3001}"
export CAMERA_MODE="${CAMERA_MODE:-webcam}"
export ROS_MASTER_URI="${ROS_MASTER_URI:-http://127.0.0.1:11311}"
export ROS_IP="${ROS_IP:-127.0.0.1}"

camera_mode="${CAMERA_MODE,,}"
case "$camera_mode" in
  webcam)
    camera_label="webcam"
    camera_cmd=(roslaunch eulerian_motion_magnification webcam.launch)
    mood_cmd=(python3 src/mood_detection/src/mood_cv2.py)
    ;;
  pylon|basler|industry|industry_camera)
    camera_mode="pylon"
    camera_label="pylon"
    camera_cmd=(roslaunch eulerian_motion_magnification industry_camera.launch show_image_frame:=false show_processed_image:=false)
    mood_cmd=(python3 src/mood_detection/src/mood_industry_camera.py)
    ;;
  *)
    echo "Error: Unsupported CAMERA_MODE '$camera_mode'. Use 'webcam' or 'pylon'." >&2
    exit 1
    ;;
esac

if [ "$#" -eq 0 ]; then
  echo "Error: no WebUI command provided" >&2
  exit 1
fi

cd "$workspace"
pids=()

start_process() {
  echo "Starting $1"
  shift
  "$@" &
  pids+=("$!")
}

cleanup() {
  trap - EXIT INT TERM
  if [ "${#pids[@]}" -gt 0 ]; then
    kill "${pids[@]}" 2>/dev/null || true
    wait "${pids[@]}" 2>/dev/null || true
  fi
}

trap cleanup EXIT
trap 'exit 0' INT TERM

echo "Starting Smart Mirror with CAMERA_MODE=$camera_mode"

start_process "WebUI" "$@"
start_process "Rosbridge" roslaunch rosbridge_server rosbridge_websocket.launch
sleep 3
start_process "$camera_label camera pipeline" "${camera_cmd[@]}"
sleep 3
start_process "mood detection" "${mood_cmd[@]}"

echo "Smart Mirror running. PIDs: ${pids[*]}"

set +e
wait -n "${pids[@]}"
exit_code=$?
set -e

cleanup
exit "$exit_code"
