#!/bin/bash

# Runs phoebus in the https://github.com/epics-containers/ec-phoebus container.

GREEN_START="\u001b[32m"
GREEN_STOP="\u001b[0m"
RED_START="\u001b[31m"
RED_STOP="\u001b[0m"

DEFAULT_PYTHON="3.11"

INDENT_LINE="━━━━━━━━━━━━━━━┫"

SCRIPT_DIR="$(dirname "$0")"

crazy_print_green() {
  echo -e "${GREEN_START}${INDENT_LINE} $1 ${GREEN_STOP}"
}

crazy_print_red() {
  echo -e "${RED_START}${INDENT_LINE} $1 ${RED_STOP}"
}

thisdir=$(realpath $(dirname ${BASH_SOURCE[0]}))
workspace=$(realpath ${thisdir}/..)

if [[ $(docker --version 2>/dev/null) == *Docker* ]]; then
  docker=docker
  echo ""
elif [[ $(podman --version 2>/dev/null) == *podman* ]]; then
  docker=podman
  args="--security-opt=label=type:container_runtime_t"
else
  crazy_print_red "Neither Docker nor Podman is installed. Please install one of them to proceed."
  exit 1
fi

show_help() {
  echo -e "${GREEN_START}"
  echo "Usage: $(basename $0) [options]"
  echo
  echo "Options:"
  echo "  --bobfiles <dirs>    Comma-separated list of directories to mount"
  echo "  --help               Show this help message and exit"
  echo -e "${GREEN_STOP}"
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
    crazy_print_red "Unknown option $1"
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
    crazy_print_red "Could not find directory $dir"
    exit 1
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
