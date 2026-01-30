# Sandbox Browser Image Design

Goal: provide a Debian-based container image that runs Chromium with a stable
Chrome DevTools Protocol (CDP) endpoint and optional VNC/noVNC access, built and
published to GHCR via a manually-triggered GitHub Actions workflow.

## What Gets Built

- Base image: `debian:bookworm-slim`
- Packages: `chromium`, `xvfb`, `x11vnc`, `novnc`, `websockify`, `socat`, plus
  a few utility dependencies (`curl`, `jq`, fonts, etc.).
- Entrypoint: `scripts/sandbox-browser-entrypoint.sh` copied to
  `/usr/local/bin/moltbot-sandbox-browser` and used as the container `CMD`.
- Exposed ports:
  - `9222` for CDP (proxied via `socat` to avoid Chromium binding to 0.0.0.0)
  - `5900` for VNC (optional)
  - `6080` for noVNC web UI (optional)

This is extracted from moltbot's `Dockerfile.sandbox-browser` and related
scripts so this repo can build/publish the image independently.

## Runtime Behavior (Entrypoint)

- Starts an X11 virtual framebuffer on `DISPLAY=:1` (Xvfb).
- Launches Chromium with:
  - a user-data-dir under `/tmp`
  - remote debugging bound to 127.0.0.1 with an internal port
  - security/UX flags appropriate for container usage
- Waits until the internal CDP endpoint is reachable, then exposes the external
  CDP port by proxying `0.0.0.0:${CDP_PORT}` -> `127.0.0.1:${CHROME_CDP_PORT}`.
- If `ENABLE_NOVNC=1` and not headless:
  - starts `x11vnc` bound to localhost
  - starts `websockify` to expose noVNC web UI on `${NOVNC_PORT}`

Environment variables (kept compatible with upstream):

- `CLAWDBOT_BROWSER_CDP_PORT` (default 9222)
- `CLAWDBOT_BROWSER_VNC_PORT` (default 5900)
- `CLAWDBOT_BROWSER_NOVNC_PORT` (default 6080)
- `CLAWDBOT_BROWSER_ENABLE_NOVNC` (default 1)
- `CLAWDBOT_BROWSER_HEADLESS` (default 0)

## Publishing

GitHub Actions workflow runs on `workflow_dispatch` and:

- builds the Dockerfile (`Dockerfile.sandbox-browser`)
- pushes the image to `ghcr.io/<owner>/<repo>` with configurable tag(s)
- optionally builds multi-arch images via buildx (platforms configurable)

