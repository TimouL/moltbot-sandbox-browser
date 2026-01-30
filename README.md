# Sandbox Browser Image (Chromium + CDP + noVNC)

This repo builds a Debian (bookworm-slim) container image that runs Chromium with:

- a stable Chrome DevTools Protocol (CDP) endpoint (default `:9222`)
- optional VNC (`:5900`) + noVNC web UI (`:6080`) for interactive mode

The Dockerfile and entrypoint script are extracted from moltbot:

- `scripts/sandbox-browser-setup.sh`
- `Dockerfile.sandbox-browser`

## Local Build

```bash
./scripts/sandbox-browser-setup.sh
```

Override the image tag:

```bash
IMAGE_NAME=moltbot-sandbox-browser:dev ./scripts/sandbox-browser-setup.sh
```

## Run (Headless, CDP only)

```bash
docker run --rm -p 9222:9222 -e CLAWDBOT_BROWSER_HEADLESS=1 moltbot-sandbox-browser:bookworm-slim
```

Connect to CDP:

```bash
curl http://127.0.0.1:9222/json/version
```

## Run (Interactive, with noVNC)

```bash
docker run --rm -p 9222:9222 -p 6080:6080 moltbot-sandbox-browser:bookworm-slim
```

Open:

- noVNC UI: `http://localhost:6080/vnc.html` (some distros may show a file listing at `/`)
- CDP: `http://localhost:9222/`

## Configuration

All ports and modes are controlled via environment variables:

- `CLAWDBOT_BROWSER_CDP_PORT` (default: `9222`)
- `CLAWDBOT_BROWSER_VNC_PORT` (default: `5900`)
- `CLAWDBOT_BROWSER_NOVNC_PORT` (default: `6080`)
- `CLAWDBOT_BROWSER_ENABLE_NOVNC` (default: `1`)
- `CLAWDBOT_BROWSER_HEADLESS` (default: `0`)

## Persistence (Optional)

By default, the container stores the Chromium profile and caches under
`/tmp/moltbot-home` (see `scripts/sandbox-browser-entrypoint.sh`). Mount a
volume there if you want to persist state (cookies, cache, etc.) across restarts:

```bash
docker run --rm \
  -p 9222:9222 -p 6080:6080 \
  -v moltbot-browser-home:/tmp/moltbot-home \
  moltbot-sandbox-browser:bookworm-slim
```

The Chromium user profile directory is `/tmp/moltbot-home/.chrome` (cookies,
storage, and installed extensions live here). If you only want to persist the
browser profile, you can mount just that subdirectory instead.

For deterministic automation runs, consider not mounting a volume so every run
starts with a fresh profile.

## GitHub Actions (Publish to GHCR)

This repo includes a manually-triggered workflow that builds and pushes the image
to `ghcr.io/<owner>/<repo>`.

See: `.github/workflows/build-browser-image.yml`
