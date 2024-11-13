#!/bin/bash

# Runs phoebus in the https://github.com/epics-containers/ec-phoebus container.

thisdir=$(realpath $(dirname ${BASH_SOURCE[0]}))
workspace=$(realpath ${thisdir}/..)

if [[ $(docker --version 2>/dev/null) == *Docker* ]]; then
  docker=docker
  echo ""
elif [[ $(podman --version 2>/dev/null) == *podman* ]]; then
  docker=podman
  args="--security-opt=label=type:container_runtime_t"
else
  echo "Neither Docker nor Podman is installed. Please install one of them to proceed."
  exit 1
fi

show_help() {
  echo "Usage: $(basename $0) [options]"
  echo
  echo "Options:"
  echo "  --bobfiles <dirs>    Comma-separated list of directories to mount"
  echo "  --help               Show this help message and exit"
}

# Parse arguments
bobfiles=()
other_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
  --bobfiles)
    shift
    IFS=',' read -r -a bobfiles <<<"$1"
    shift
    ;;
  --help)
    show_help
    exit 0
    ;;
  *)
    echo "Unknown option $1"
    exit 1
    ;;
  esac
done

# Add bobfiles to mounts
for dir in "${bobfiles[@]}"; do
  if [[ -d "$dir" ]]; then
    dir_name=$(basename "$dir")
    mounts+=" -v=${dir}:/phoebus/${dir_name}"
  else
    echo "Warning: ${dir} is not a directory and will be skipped."
  fi
done

XSOCK=/tmp/.X11-unix # X11 socket (but we mount the whole of tmp)
XAUTH=/tmp/.container.xauth.$USER
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
chmod 777 $XAUTH

x11="
-e DISPLAY
-v $XAUTH:$XAUTH
-e XAUTHORITY=$XAUTH
--net host
"

args=${args}"
-it
"

export MYHOME=/home/${USER}
# mount in your own home dir in same folder for access to external files
mounts+="
 -v=/tmp:/tmp
 -v=${MYHOME}/.ssh:/root/.ssh
 -v=${MYHOME}:/phoebus/${USER}
 -v=${thisdir}/config:/phoebus/config
"

# phoebus settings, turning off warnings and passing settings
settings="
-D 
-settings /phoebus/config/settings.ini
"

set -x
$docker run ${mounts} ${args} ${x11} ghcr.io/epics-containers/ec-phoebus:latest ${settings} ${PHOEBUS_ARGS}
