#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

remote_dir="${tmp_dir}/remote.git"
repo_dir="${tmp_dir}/repo"

git init --bare --quiet "${remote_dir}"
git init --quiet --initial-branch=main "${repo_dir}"
git -C "${repo_dir}" config user.email actions-test@wodby.com
git -C "${repo_dir}" config user.name "Wodby Actions Test"
git -C "${repo_dir}" config commit.gpgsign false
git -C "${repo_dir}" config tag.gpgsign false
git -C "${repo_dir}" remote add origin "${remote_dir}"

git -C "${repo_dir}" commit --quiet --allow-empty -m v1.0.0
v100_commit="$(git -C "${repo_dir}" rev-parse HEAD)"
git -C "${repo_dir}" tag v1.0.0

git -C "${repo_dir}" commit --quiet --allow-empty -m v1.0.2
v102_commit="$(git -C "${repo_dir}" rev-parse HEAD)"
git -C "${repo_dir}" tag v1.0.2

git -C "${repo_dir}" commit --quiet --allow-empty -m v1.1.0
v110_commit="$(git -C "${repo_dir}" rev-parse HEAD)"
git -C "${repo_dir}" tag v1.1.0
git -C "${repo_dir}" push --quiet origin main --tags

(
  cd "${repo_dir}"
  "${script_dir}/update-version-aliases.sh" v1.0.2 >/dev/null
)

if [[ "$(git --git-dir="${remote_dir}" rev-parse refs/tags/v1)" != "${v110_commit}" ]]; then
  echo "Major alias did not remain on the newest v1 release" >&2
  exit 1
fi

if [[ "$(git --git-dir="${remote_dir}" rev-parse refs/tags/v1.0)" != "${v102_commit}" ]]; then
  echo "Minor alias did not point to the newest v1.0 patch" >&2
  exit 1
fi

git -C "${repo_dir}" switch --quiet --detach "${v100_commit}"
git -C "${repo_dir}" commit --quiet --allow-empty -m invalid-release
git -C "${repo_dir}" tag v1.2.0
git -C "${repo_dir}" push --quiet origin refs/tags/v1.2.0

if (
  cd "${repo_dir}"
  "${script_dir}/update-version-aliases.sh" v1.2.0 >/dev/null 2>&1
); then
  echo "Release alias update accepted a tag outside main" >&2
  exit 1
fi

(
  cd "${repo_dir}"
  "${script_dir}/update-version-aliases.sh" v1.1.0 >/dev/null
)

if [[ "$(git --git-dir="${remote_dir}" rev-parse refs/tags/v1)" != "${v110_commit}" ]]; then
  echo "Major alias selected a newer tag outside main" >&2
  exit 1
fi

echo "Action version alias tests passed"
