#!/usr/bin/env bash

set -euo pipefail

api_key="${INPUT_API_KEY:-}"
app_service_id="${INPUT_APP_SERVICE_ID:-}"
api_host="${INPUT_API_HOST:-https://apiv2.wodby.com}"
verbose="${INPUT_VERBOSE:-false}"

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

if [[ -z "${api_key}" ]]; then
  echo "The api-key input is required" >&2
  exit 1
fi

echo "::add-mask::${api_key}"

{
  printf 'WODBY_API_KEY<<__WODBY_API_KEY__\n%s\n__WODBY_API_KEY__\n' "${api_key}"
  printf 'WODBY_API_ENDPOINT=%s/query\n' "$(normalize_api_host "${api_host}")"

  if [[ -n "${app_service_id}" ]]; then
    printf 'WODBY_APP_SERVICE_ID=%s\n' "${app_service_id}"
  fi

  case "${verbose}" in
    true|TRUE|True|1)
      printf 'WODBY_VERBOSE=true\n'
      ;;
  esac
} >> "${GITHUB_ENV}"
