#!/usr/bin/env bash

set -euo pipefail

version="${INPUT_CLI_VERSION:-}"
api_host="${INPUT_API_HOST:-https://apiv2.wodby.com}"
runner_os="${RUNNER_OS:-}"
runner_arch="${RUNNER_ARCH:-}"
runner_temp="${RUNNER_TEMP:-/tmp}"

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
    os="windows"
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

asset_name="wodby-${os}-${arch}.tar.gz"
install_dir="${runner_temp}/wodby-cli/${os}-${arch}"
archive_path="${runner_temp}/${asset_name}"

rm -rf "${install_dir}"
mkdir -p "${install_dir}"
rm -f "${archive_path}"

resolve_default_version() {
  local installer_script
  local default_url
  default_url="$(normalize_api_host "${api_host}")/v1/get/cli"
  installer_script="$(curl -fsSL "${default_url}")"

  if [[ "${installer_script}" =~ wodby-cli/([0-9]+\.[0-9]+\.[0-9]+)/ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi

  echo "Failed to resolve the default Wodby CLI version from ${default_url}" >&2
  exit 1
}

if [[ -z "${version}" ]]; then
  version="$(resolve_default_version)"
  echo "Resolved default Wodby CLI version ${version}"
fi

normalized_version="${version#v}"
download_url="https://github.com/wodby/wodby-cli/releases/download/${normalized_version}/${asset_name}"

echo "Downloading ${download_url}"
curl -fsSL "${download_url}" -o "${archive_path}"
tar -xzf "${archive_path}" -C "${install_dir}"

if [[ -x "${install_dir}/wodby" ]]; then
  binary_path="${install_dir}/wodby"
elif [[ -x "${install_dir}/wodby.exe" ]]; then
  binary_path="${install_dir}/wodby.exe"
else
  echo "Wodby binary was not found after extracting ${asset_name}" >&2
  exit 1
fi

printf '%s\n' "${install_dir}" >> "${GITHUB_PATH}"
"${binary_path}" version
