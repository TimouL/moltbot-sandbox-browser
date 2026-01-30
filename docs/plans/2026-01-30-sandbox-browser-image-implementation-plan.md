# Sandbox Browser Image Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a standalone repo that builds a Chromium-based sandbox browser image and publishes it to GHCR via a manually-triggered GitHub Actions workflow.

**Architecture:** A single Dockerfile plus two small shell scripts (local build and container entrypoint). GitHub Actions uses buildx to build and push the image to `ghcr.io/${{ github.repository }}`.

**Tech Stack:** Docker, Debian (bookworm-slim), GitHub Actions.

---

### Task 1: Add Docker image build artifacts (Dockerfile + scripts)

**Files:**
- Create: `Dockerfile.sandbox-browser`
- Create: `scripts/sandbox-browser-entrypoint.sh`
- Create: `scripts/sandbox-browser-setup.sh`

**Step 1: Add the upstream Dockerfile and scripts**

- Copy content from moltbot:
  - `Dockerfile.sandbox-browser`
  - `scripts/sandbox-browser-entrypoint.sh`
  - `scripts/sandbox-browser-setup.sh`

**Step 2: Verify local build works**

Run: `docker build -f Dockerfile.sandbox-browser -t moltbot-sandbox-browser:bookworm-slim .`

Expected: build succeeds and outputs an image named `moltbot-sandbox-browser:bookworm-slim`.

**Step 3: Smoke test container**

Run:
- `docker run --rm -d -p 9222:9222 -e CLAWDBOT_BROWSER_HEADLESS=1 --name sandbox-browser-smoke moltbot-sandbox-browser:bookworm-slim`
- `curl -fsSL http://127.0.0.1:9222/json/version`
- `docker rm -f sandbox-browser-smoke`

Expected: the curl command returns JSON (Chromium CDP version payload).

---

### Task 2: Add docs and local usage instructions

**Files:**
- Create: `README.md`
- Create: `.gitignore`

**Step 1: Document local build/run**

Include commands to:
- build with `scripts/sandbox-browser-setup.sh`
- run container headless and connect to CDP
- run with noVNC enabled and open `http://localhost:6080/`

**Step 2: Verify README commands reference real files**

Run: `test -f scripts/sandbox-browser-setup.sh && test -f Dockerfile.sandbox-browser`

Expected: exit code 0.

---

### Task 3: Add GitHub Actions workflow to build & push to GHCR (manual trigger)

**Files:**
- Create: `.github/workflows/build-browser-image.yml`

**Step 1: Create `workflow_dispatch` workflow**

Inputs (suggested):
- `tag` (string, default `bookworm-slim`)
- `platforms` (string, default `linux/amd64`)
- `push` (boolean, default `true`)

Workflow requirements:
- `permissions: packages: write, contents: read`
- use `docker/login-action` with `GITHUB_TOKEN`
- use `docker/build-push-action` to build `Dockerfile.sandbox-browser`
- push to `ghcr.io/${{ github.repository }}` with `tag`

**Step 2: Validate workflow YAML parses**

Run: `python -c "import yaml,sys; yaml.safe_load(open('.github/workflows/build-browser-image.yml'))"`

Expected: no output, exit code 0.

---

### Task 4: Initialize git repo and set up GitHub remote

**Files:**
- N/A (git ops)

**Step 1: Initialize repository**

Run:
- `git init`
- `git add -A`
- `git commit -m "chore: initial sandbox browser image repo"`

**Step 2: Create GitHub repo and push**

Run (example):
- `gh repo create moltbot-sandbox-browser --public --source=. --remote=origin --push`

Expected: repo created under authenticated account; `origin` set; `main` pushed.

