#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "${root}"' EXIT

project="${root}/project"
output="${root}/output"
mkdir -p "${project}/node_modules/nested"
touch \
  "${project}/package-lock.json" \
  "${project}/composer.lock" \
  "${project}/node_modules/nested/uv.lock"

run_cache() {
  : > "${output}"
  GITHUB_WORKSPACE="${root}" \
    GITHUB_OUTPUT="${output}" \
    INPUT_CACHE="$1" \
    INPUT_WORKING_DIRECTORY=project \
    bash "${script_dir}/cache.sh"
}

assert_output() {
  if ! grep -Fx "$1=$2" "${output}" >/dev/null; then
    echo "Expected $1=$2 in cache outputs:" >&2
    cat "${output}" >&2
    exit 1
  fi
}

run_cache auto
assert_output npm true
assert_output composer true
assert_output uv false

run_cache 'UV,npm'
assert_output npm true
assert_output composer false
assert_output uv true

run_cache none
assert_output npm false
assert_output composer false
assert_output uv false

if run_cache pnpm 2>/dev/null; then
  echo "Unknown cache profile unexpectedly succeeded" >&2
  exit 1
fi

echo "Cache profile detection tests passed."
