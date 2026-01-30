#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=:1
export HOME=/tmp/moltbot-home
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"

CDP_PORT="${CLAWDBOT_BROWSER_CDP_PORT:-9222}"
VNC_PORT="${CLAWDBOT_BROWSER_VNC_PORT:-5900}"
NOVNC_PORT="${CLAWDBOT_BROWSER_NOVNC_PORT:-6080}"
ENABLE_NOVNC="${CLAWDBOT_BROWSER_ENABLE_NOVNC:-1}"
HEADLESS="${CLAWDBOT_BROWSER_HEADLESS:-0}"

mkdir -p "${HOME}" "${HOME}/.chrome" "${XDG_CONFIG_HOME}" "${XDG_CACHE_HOME}"

# When using a persistent volume for the profile directory, Chromium can leave
# singleton lock files behind if it was terminated uncleanly (e.g. container
# restart or host reboot). These stale locks prevent Chromium from starting.
rm -f \
  "${HOME}/.chrome/SingletonCookie" \
  "${HOME}/.chrome/SingletonLock" \
  "${HOME}/.chrome/SingletonSocket" \
  >/dev/null 2>&1 || true

mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix || true

# If the container was stopped uncleanly, Xvfb can leave stale lock/socket files
# behind which prevents it from starting on the next boot.
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 || true

Xvfb :1 -screen 0 1280x800x24 -ac -nolisten tcp &
XVFB_PID=$!

# Wait for Xvfb to be ready before launching Chromium.
for _ in $(seq 1 50); do
  if [[ -S /tmp/.X11-unix/X1 ]]; then
    break
  fi
  if ! kill -0 "${XVFB_PID}" 2>/dev/null; then
    echo "Xvfb exited unexpectedly" >&2
    exit 1
  fi
  sleep 0.1
done

if [[ "${HEADLESS}" == "1" ]]; then
  CHROME_ARGS=(
    "--headless=new"
    "--disable-gpu"
  )
else
  CHROME_ARGS=()
fi

if [[ "${CDP_PORT}" -ge 65535 ]]; then
  CHROME_CDP_PORT="$((CDP_PORT - 1))"
else
  CHROME_CDP_PORT="$((CDP_PORT + 1))"
fi

CHROME_ARGS+=(
  "--remote-debugging-address=127.0.0.1"
  "--remote-debugging-port=${CHROME_CDP_PORT}"
  "--user-data-dir=${HOME}/.chrome"
  "--no-first-run"
  "--no-default-browser-check"
  "--disable-dev-shm-usage"
  "--disable-background-networking"
  "--disable-features=TranslateUI"
  "--disable-breakpad"
  "--disable-crash-reporter"
  "--metrics-recording-only"
  "--no-sandbox"
)

chromium "${CHROME_ARGS[@]}" about:blank &

for _ in $(seq 1 50); do
  if curl -sS --max-time 1 "http://127.0.0.1:${CHROME_CDP_PORT}/json/version" >/dev/null; then
    break
  fi
  sleep 0.1
done

socat \
  TCP-LISTEN:"${CDP_PORT}",fork,reuseaddr,bind=0.0.0.0 \
  TCP:127.0.0.1:"${CHROME_CDP_PORT}" &

if [[ "${ENABLE_NOVNC}" == "1" && "${HEADLESS}" != "1" ]]; then
  x11vnc -display :1 -rfbport "${VNC_PORT}" -shared -forever -nopw -localhost &
  websockify --web /usr/share/novnc/ "${NOVNC_PORT}" "localhost:${VNC_PORT}" &
fi

wait -n
