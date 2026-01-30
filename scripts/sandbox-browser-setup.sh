#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-moltbot-sandbox-browser:bookworm-slim}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-Dockerfile.sandbox-browser}"
CONTEXT_DIR="${CONTEXT_DIR:-.}"

docker build -t "${IMAGE_NAME}" -f "${DOCKERFILE_PATH}" "${CONTEXT_DIR}"
echo "Built ${IMAGE_NAME}"

