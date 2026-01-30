#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-moltbot-sandbox-browser:bookworm-slim}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-Dockerfile.sandbox-browser}"
CONTEXT_DIR="${CONTEXT_DIR:-.}"

docker build -t "${IMAGE_NAME}" -f "${DOCKERFILE_PATH}" "${CONTEXT_DIR}"

IMAGE_NO_DIGEST="${IMAGE_NAME%%@*}"
IMAGE_PREFIX=""
IMAGE_LAST_PART="${IMAGE_NO_DIGEST}"
if [[ "${IMAGE_NO_DIGEST}" == */* ]]; then
  IMAGE_PREFIX="${IMAGE_NO_DIGEST%/*}"
  IMAGE_LAST_PART="${IMAGE_NO_DIGEST##*/}"
fi

if [[ "${IMAGE_LAST_PART}" == *:* ]]; then
  IMAGE_REPO_PART="${IMAGE_LAST_PART%%:*}"
  if [[ -n "${IMAGE_PREFIX}" ]]; then
    IMAGE_LATEST="${IMAGE_PREFIX}/${IMAGE_REPO_PART}:latest"
  else
    IMAGE_LATEST="${IMAGE_REPO_PART}:latest"
  fi
else
  IMAGE_LATEST="${IMAGE_NO_DIGEST}:latest"
fi

docker tag "${IMAGE_NAME}" "${IMAGE_LATEST}"
echo "Built ${IMAGE_NAME} (also tagged ${IMAGE_LATEST})"
