#!/usr/bin/env bash

set -euo pipefail

release_tag="${1:-${GITHUB_REF_NAME:-}}"
remote="${2:-origin}"

if [[ ! "${release_tag}" =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "Release tag must be a stable semantic version such as v1.2.3: ${release_tag}" >&2
  exit 1
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"

git fetch --force "${remote}" "+refs/tags/*:refs/tags/*"
git fetch --force "${remote}" "+refs/heads/main:refs/remotes/${remote}/main"

release_commit="$(git rev-list -n 1 "${release_tag}")"
if ! git merge-base --is-ancestor "${release_commit}" "refs/remotes/${remote}/main"; then
  echo "Release tag ${release_tag} does not point to a commit on ${remote}/main" >&2
  exit 1
fi

latest_stable_tag() {
  local pattern="$1"
  local regex="$2"
  local tag
  local tag_commit
  local latest=""

  while IFS= read -r tag; do
    if [[ "${tag}" =~ ${regex} ]]; then
      tag_commit="$(git rev-list -n 1 "${tag}")"
      if git merge-base --is-ancestor "${tag_commit}" "refs/remotes/${remote}/main"; then
        latest="${tag}"
      fi
    fi
  done < <(git tag --list "${pattern}" --sort=version:refname)

  if [[ -z "${latest}" ]]; then
    echo "No stable release tag on ${remote}/main matches ${pattern}" >&2
    exit 1
  fi

  printf '%s\n' "${latest}"
}

major_release="$(latest_stable_tag "v${major}.*.*" "^v${major}\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")"
minor_release="$(latest_stable_tag "v${major}.${minor}.*" "^v${major}\.${minor}\.(0|[1-9][0-9]*)$")"

major_alias="v${major}"
minor_alias="v${major}.${minor}"

git tag -f "${major_alias}" "$(git rev-list -n 1 "${major_release}")"
git tag -f "${minor_alias}" "$(git rev-list -n 1 "${minor_release}")"
git push --force "${remote}" "refs/tags/${major_alias}" "refs/tags/${minor_alias}"

echo "${major_alias} -> ${major_release}"
echo "${minor_alias} -> ${minor_release}"
