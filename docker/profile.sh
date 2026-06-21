eval "$(git wt --init bash)"

HOST_IP=$(getent hosts host.docker.internal 2>/dev/null | awk '{print $1}')
if [ -n "$HOST_IP" ]; then
  export CHROME_CDP_URL="http://${HOST_IP}:${CHROME_REMOTE_PORT:-9222}"
  WS_URL=$(curl -sf -H "Host: localhost" "$CHROME_CDP_URL/json/version" 2>/dev/null \
    | jq -r .webSocketDebuggerUrl 2>/dev/null \
    | sed "s|ws://localhost|ws://${HOST_IP}:${CHROME_REMOTE_PORT:-9222}|")
  [ -n "$WS_URL" ] && [ "$WS_URL" != "null" ] && export CHROME_WS_URL="$WS_URL"
fi
