#!/bin/bash
set -e

HOST_IP=$(getent hosts host.docker.internal 2>/dev/null | awk '{print $1}')
if [ -n "$HOST_IP" ]; then
  export CHROME_CDP_URL="http://${HOST_IP}:${CHROME_REMOTE_PORT:-9222}"
fi

exec "$@"
