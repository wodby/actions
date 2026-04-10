#!/usr/bin/env bash

set -euo pipefail

version="${INPUT_CLI_VERSION:-}"
api_host="${INPUT_API_HOST:-https://apiv2.wodby.com}"
runner_os="${RUNNER_OS:-}"
runner_arch="${RUNNER_ARCH:-}"

normalize_api_host() {
  local value="${1%/}"

  case "${value}" in
    http://*|https://*)
      printf '%s\n' "${value}"
      ;;
    *)
      printf 'https://%s\n' "${value}"
      ;;
  esac
}

case "${runner_os}" in
  Linux)
    os="linux"
    ;;
  macOS)
    os="darwin"
    ;;
  Windows)
    echo "The Wodby backend installer does not currently provide a Windows-specific install script" >&2
    exit 1
    ;;
  *)
    echo "Unsupported RUNNER_OS: ${runner_os}" >&2
    exit 1
    ;;
esac

case "${runner_arch}" in
  X64)
    arch="amd64"
    ;;
  ARM64)
    arch="arm64"
    ;;
  *)
    echo "Unsupported RUNNER_ARCH: ${runner_arch}" >&2
    exit 1
    ;;
esac

backend_url="$(normalize_api_host "${api_host}")/v1/get/cli?os=${os}&arch=${arch}"
if [[ -n "${version}" ]]; then
  backend_url="${backend_url}&version=${version#v}"
fi

echo "Installing Wodby CLI via ${backend_url}"
curl -fsSL "${backend_url}" | sh

if ! command -v wodby >/dev/null 2>&1; then
  echo "Wodby CLI was not found on PATH after running the backend installer" >&2
  exit 1
fi

wodby version
