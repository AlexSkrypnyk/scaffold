#!/usr/bin/env bash
#
# Helpers related to common testing functionality.
#
# Run with "--verbose-run" to see debug output.
#

setup() {
  [ ! -d ".git" ] && echo "Tests must be run from the repository root directory." && exit 1

  export BATS_LIB_PATH="${BATS_TEST_DIRNAME}/node_modules"
  bats_load_library bats-helpers
  mock_setup

  # A token in the developer's shell must never reach the GitHub code paths;
  # the GitHub tests set their own dummy value.
  unset SCAFFOLD_GITHUB_TOKEN

  # LCOV_EXCL_START
  if [ "${BATS_VERBOSE_RUN-}" = "1" ]; then
    echo "BUILD_DIR: ${BUILD_DIR}" >&3
  fi
  # LCOV_EXCL_END
}
