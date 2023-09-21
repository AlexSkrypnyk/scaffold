#!/usr/bin/env bash
#
# A Bats helper library providing code coverage support.
#

crun() {
  local kcov_exists
  local is_bin

  kcov_exists=$(command -v kcov >/dev/null 2>&1 && echo 1 || echo 0)
  is_bin=$(type -t "$1" | grep -q 'file' && echo 1 || echo 0)

  if [ "${kcov_exists}" -eq 1 ] && [ "${is_bin}" -eq 1 ] && [ -n "${BATS_COVERAGE_DIR-}" ]; then
    # shellcheck disable=SC2086
    run kcov --bash-dont-parse-binary-dir ${BATS_COVERAGE_OPTIONS-} "${BATS_COVERAGE_DIR}" "$@"
  else
    run "$@"
  fi
}
