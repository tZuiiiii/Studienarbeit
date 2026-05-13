FROM ros:noetic-ros-base-focal

ARG DEBIAN_FRONTEND=noninteractive
ARG ROSLIB_VERSION=1.4.1
ARG UBUNTU_MIRROR=http://de.archive.ubuntu.com/ubuntu
ENV ROS_DISTRO=noetic \
    PYLON_ROOT=/opt/pylon \
    LD_LIBRARY_PATH=/opt/pylon/lib \
    PORT=3001

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    sed -i "s|http://archive.ubuntu.com/ubuntu|${UBUNTU_MIRROR}|g" /etc/apt/sources.list; \
    sed -i "s|http://security.ubuntu.com/ubuntu|${UBUNTU_MIRROR}|g" /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    ros-noetic-rosbridge-server \
    ros-noetic-cv-bridge \
    ros-noetic-image-geometry \
    ros-noetic-image-transport \
    ros-noetic-camera-info-manager \
    ros-noetic-roslint \
    ros-noetic-diagnostic-updater \
    ros-noetic-tf \
    ros-noetic-camera-calibration-parsers \
    ros-noetic-vision-opencv \
    ros-noetic-dynamic-reconfigure \
    ros-noetic-nodelet \
    ros-noetic-actionlib \
    ros-noetic-actionlib-msgs \
    python3-rosdep \
    python3-numpy \
    python3-scipy \
    python3-matplotlib \
    python3-sklearn \
    python3-pandas \
    python3-opencv \
    opencv-data \
    && rm -rf /var/lib/apt/lists/*

COPY docker/pylon.deb /tmp/pylon.deb
RUN set -eux; \
    apt-get update; \
    dpkg -i /tmp/pylon.deb || apt-get install -f -y --no-install-recommends; \
    rm -f /tmp/pylon.deb; \
    rm -rf /var/lib/apt/lists/*

RUN rosdep init || true

WORKDIR /opt/smartmirror

COPY webui ./webui
RUN set -eux; \
    mkdir -p webui/vendor/roslib; \
    curl -fsSL "https://registry.npmjs.org/roslib/-/roslib-${ROSLIB_VERSION}.tgz" -o /tmp/roslib.tgz; \
    tar -xzf /tmp/roslib.tgz -C /tmp package/build/roslib.min.js; \
    cp /tmp/package/build/roslib.min.js webui/vendor/roslib/roslib.min.js; \
    rm -rf /tmp/roslib.tgz /tmp/package

COPY PulsMeasurementStudien2 ./PulsMeasurementStudien2
COPY docker/entrypoint.sh /usr/local/bin/smartmirror-entrypoint

RUN chmod +x /usr/local/bin/smartmirror-entrypoint \
    && source /opt/ros/noetic/setup.bash \
    && cd PulsMeasurementStudien2 \
    && catkin_make

EXPOSE 3001 9090

ENTRYPOINT ["smartmirror-entrypoint"]
CMD ["bash", "-lc", "python3 -m http.server \"${PORT:-3001}\" --directory /opt/smartmirror/webui"]
