#!/bin/bash
exit_handler() {
  # TODO: Add a cleanup handler
  echo "Exit handler..."
  exit 0
}

# Trap specific signals and forward to the exit handler
trap exit_handler SIGINT SIGTERM

# Pull flags from env
FLAGS=(
  -p "$PORT"
  -h "$USERNAME"
)

# Set user and group ID to gsa user
groupmod -o -g "$PGID" gsa >/dev/null 2>&1
usermod -o -u "$PUID" gsa >/dev/null 2>&1

# Print information
# TODO: Pull more config data
echo "=====
  UID: $PUID / GID: $PGID
  Username:           $USERNAME
  Port:               $PORT
  Custom Weapons:     $APPLYWEAPONS
====="

# Change user to gsa; launch the server
cd "/opt/GSA/GeneShiftAuto" && su-exec gsa ./GeneShiftAutoServer "${FLAGS[@]}" "$@" >>/dev/null &

wait $!
