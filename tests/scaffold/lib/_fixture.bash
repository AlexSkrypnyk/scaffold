#!/usr/bin/env bash
#
# A Bats helper library for working with fixtures.
#

#
# Export codebase source code at the latest commit to the destination directory.
#
fixture_export_codebase() {
  if [ "${BATS_FIXTURE_EXPORT_CODEBASE_ENABLED-}" != "1" ]; then
    return
  fi

  local dst="${1?Destination directory is required}"
  local src="${2:-"$(pwd)"}"

  assert_dir_exists "${dst}"
  assert_git_repo "${src}"

  pushd "${src}" >/dev/null || exit 1

  git archive --format=tar HEAD | (cd "${dst}" && tar -xf -)

  popd >/dev/null || exit 1
}

#
# Prepare a directory for a fixture.
#
fixture_prepare_dir() {
  local dir="${1:-"$(pwd)"}"
  rm -Rf "${dir}" >/dev/null
  mkdir -p "${dir}"
  assert_dir_exists "${dir}"
}
