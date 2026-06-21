eval "$(git wt --init bash)"

HOST_IP=$(getent hosts host.docker.internal 2>/dev/null | awk '{print $1}')
if [ -n "$HOST_IP" ]; then
  export CHROME_CDP_URL="http://${HOST_IP}:${CHROME_REMOTE_PORT:-9222}"
fi

chrome-connect() {
  if [ -z "$CHROME_CDP_URL" ]; then
    echo "CHROME_CDP_URL is not set" >&2
    return 1
  fi
  local ip="${CHROME_CDP_URL#http://}"
  local ws_url
  ws_url=$(curl -sf -H "Host: localhost" "$CHROME_CDP_URL/json/version" \
    | jq -r .webSocketDebuggerUrl \
    | sed "s|ws://localhost|ws://${ip}|")
  if [ -n "$ws_url" ] && [ "$ws_url" != "null" ]; then
    export CHROME_WS_URL="$ws_url"
    agent-browser connect "$CHROME_WS_URL"
  else
    echo "Failed to connect to Chrome at $CHROME_CDP_URL" >&2
    return 1
  fi
}
