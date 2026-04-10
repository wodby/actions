#!/usr/bin/env bash

set -euo pipefail

app_service_id="${INPUT_APP_SERVICE_ID:-}"
api_host="${INPUT_API_HOST:-https://apiv2.wodby.com}"

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

if [[ -z "${app_service_id}" ]]; then
  echo "The app-service-id input is required when running init" >&2
  exit 1
fi

export WODBY_API_ENDPOINT="${WODBY_API_ENDPOINT:-$(normalize_api_host "${api_host}")/query}"

wodby ci init "${app_service_id}"
