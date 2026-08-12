#!/usr/bin/env bash

set -euo pipefail

cache="${INPUT_CACHE:-auto}"
working_directory="${INPUT_WORKING_DIRECTORY:-.}"
cache_lower="$(printf '%s' "${cache}" | tr '[:upper:]' '[:lower:]')"

if [[ "${working_directory}" = /* ]]; then
  root="${working_directory}"
else
  root="${GITHUB_WORKSPACE}/${working_directory}"
fi

if [[ ! -d "${root}" ]]; then
  echo "Cache working directory does not exist: ${root}" >&2
  exit 1
fi

npm=false
composer=false
uv=false

has_lockfile() {
  [[ -n "$(find "${root}" -type f -name "$1" -not -path '*/node_modules/*' -print -quit)" ]]
}

enable_profile() {
  case "$1" in
    npm)
      npm=true
      ;;
    composer)
      composer=true
      ;;
    uv)
      uv=true
      ;;
    *)
      echo "Unknown cache profile: $1 (supported: npm, composer, uv)" >&2
      exit 1
      ;;
  esac
}

case "${cache_lower}" in
  auto)
    if has_lockfile package-lock.json; then npm=true; fi
    if has_lockfile composer.lock; then composer=true; fi
    if has_lockfile uv.lock; then uv=true; fi
    ;;
  none|false|off)
    ;;
  *)
    while IFS= read -r profile; do
      profile="$(printf '%s' "${profile}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
      if [[ -n "${profile}" ]]; then
        enable_profile "${profile}"
      fi
    done < <(printf '%s\n' "${cache}" | tr ',' '\n')
    ;;
esac

{
  printf 'npm=%s\n' "${npm}"
  printf 'composer=%s\n' "${composer}"
  printf 'uv=%s\n' "${uv}"
} >> "${GITHUB_OUTPUT}"
