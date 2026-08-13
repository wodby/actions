#!/usr/bin/env bash

set -euo pipefail

version="${INPUT_CLI_VERSION:-}"
runner_os="${RUNNER_OS:-}"
runner_arch="${RUNNER_ARCH:-}"
install_dir="${WODBY_CLI_INSTALL_DIR:-/usr/local/bin}"

case "${runner_os}" in
  Linux)
    os="linux"
    ;;
  macOS)
    os="darwin"
    ;;
  Windows)
    echo "The Wodby CLI setup action does not currently support Windows runners" >&2
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

release_path="latest/download"
if [[ -n "${version}" ]]; then
  release_path="download/${version#v}"
fi

cli_url="https://github.com/wodby/wodby-cli/releases/${release_path}/wodby-${os}-${arch}.tar.gz"
tar_command=(tar xz -C "${install_dir}")
if [[ ! -w "${install_dir}" ]]; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Wodby CLI install directory is not writable and sudo is unavailable: ${install_dir}" >&2
    exit 1
  fi
  tar_command=(sudo "${tar_command[@]}")
fi

echo "Installing Wodby CLI from ${cli_url}"
curl -fsSL "${cli_url}" | "${tar_command[@]}"

if ! command -v wodby >/dev/null 2>&1; then
  echo "Wodby CLI was not found on PATH after extracting the GitHub release" >&2
  exit 1
fi

wodby version
