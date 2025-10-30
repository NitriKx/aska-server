#!/usr/bin/env bash
set -euo pipefail

# Allow runtime override of steam user UID/GID via PUID/PGID env vars.
# If they differ from current numeric IDs, we modify /etc/passwd & /etc/group accordingly
# before executing steamcmd. This requires the container to start as root.

CURRENT_UID="$(id -u ubuntu)"
CURRENT_GID="$(id -g ubuntu)"
DESIRED_UID="${PUID:-$CURRENT_UID}"
DESIRED_GID="${PGID:-$CURRENT_GID}"

if [[ "${DESIRED_GID}" != "${CURRENT_GID}" ]]; then
  echo "Updating ubuntu group GID: ${CURRENT_GID} -> ${DESIRED_GID}" >&2
  groupmod -o -g "${DESIRED_GID}" ubuntu
  # Fix any files owned by old GID inside home (best effort)
  find /home/ubuntu -xdev -group "${CURRENT_GID}" -exec chgrp -h "${DESIRED_GID}" {} + || true
fi

if [[ "${DESIRED_UID}" != "${CURRENT_UID}" ]]; then
  echo "Updating ubuntu user UID: ${CURRENT_UID} -> ${DESIRED_UID}" >&2
  usermod -o -u "${DESIRED_UID}" ubuntu
  find /home/ubuntu -xdev -user "${CURRENT_UID}" -exec chown -h "${DESIRED_UID}" {} + || true
fi

# Ensure ownership of Steam data root (non-recursive check first, then minimal fix if needed)
if [[ ! -w /home/ubuntu ]]; then
  echo "Warning: /home/ubuntu not writable after UID/GID adjustment" >&2
fi

# Ensure X11 socket directory exists and has correct permissions for Xvfb
mkdir -p /tmp/.X11-unix
chown root:root /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Clean up Xvfb lock files from build process to prevent conflicts at runtime
rm -f /tmp/.X*-lock 2>/dev/null || true

# Drop to steam user and run the startup script
exec gosu ubuntu:ubuntu "$@"