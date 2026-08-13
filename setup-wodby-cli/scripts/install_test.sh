#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

mock_dir="${tmp_dir}/mock"
install_dir="${tmp_dir}/bin"
payload_dir="${tmp_dir}/payload"
archive="${tmp_dir}/wodby.tar.gz"
url_file="${tmp_dir}/url"
mkdir -p "${mock_dir}" "${install_dir}" "${payload_dir}"

cat > "${payload_dir}/wodby" <<'EOF'
#!/usr/bin/env bash
echo "Wodby CLI version test"
EOF
chmod +x "${payload_dir}/wodby"
tar czf "${archive}" -C "${payload_dir}" wodby

cat > "${mock_dir}/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
url="${!#}"
printf '%s\n' "${url}" > "${WODBY_TEST_URL_FILE}"
cat "${WODBY_TEST_ARCHIVE}"
EOF
chmod +x "${mock_dir}/curl"

run_case() {
  local runner_os="$1"
  local runner_arch="$2"
  local version="$3"
  local expected_url="$4"

  rm -f "${install_dir}/wodby" "${url_file}"
  PATH="${mock_dir}:${install_dir}:${PATH}" \
    RUNNER_OS="${runner_os}" \
    RUNNER_ARCH="${runner_arch}" \
    INPUT_CLI_VERSION="${version}" \
    WODBY_CLI_INSTALL_DIR="${install_dir}" \
    WODBY_TEST_ARCHIVE="${archive}" \
    WODBY_TEST_URL_FILE="${url_file}" \
    "${script_dir}/install.sh" >/dev/null

  if [[ "$(<"${url_file}")" != "${expected_url}" ]]; then
    echo "Unexpected CLI URL for ${runner_os}/${runner_arch}: $(<"${url_file}")" >&2
    exit 1
  fi
}

run_case \
  Linux \
  X64 \
  "" \
  "https://github.com/wodby/wodby-cli/releases/latest/download/wodby-linux-amd64.tar.gz"

run_case \
  macOS \
  ARM64 \
  v2.8.0 \
  "https://github.com/wodby/wodby-cli/releases/download/2.8.0/wodby-darwin-arm64.tar.gz"

echo "Wodby CLI installer tests passed"
