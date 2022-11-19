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

# Print information
# TODO: Pull more config data
echo "=====
  Username:           $USERNAME
  Port:               $PORT
  Custom Weapons:     $APPLYWEAPONS
====="

# Change user to gsa; launch the server
cd "/opt/GSA/GeneShiftAuto" && su-exec gsa ./GeneShiftAutoServer "${FLAGS[@]}" "$@" >>/dev/null &

wait $!
