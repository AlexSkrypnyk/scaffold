#!/usr/bin/env bash
#
# Helpers related to common testing functionality.
#
# Run with "--verbose-run" to see debug output.
#

################################################################################
#                       BATS HOOK IMPLEMENTATIONS                              #
################################################################################

setup() {
  [ ! -d ".git" ] && echo "Tests must be run from the repository root directory." && exit 1

  # Available BATS variables:
  # @see https://bats-core.readthedocs.io/en/stable/writing-tests.html#special-variables

  export BATS_LIB_PATH="${BATS_TEST_DIRNAME}/node_modules"

  bats_load_library bats-helpers

  mock_setup

  # shellcheck disable=SC2155
  export CUR_DIR="$(pwd)"

  # Project directory root (where .git is located).
  export ROOT_DIR="${CUR_DIR}"

  # Directory where the shell command script runs.
  export BUILD_DIR="${BUILD_DIR:-"${BATS_TEST_TMPDIR//\/\//\/}/shell-$(date +%s)"}"
  fixture_prepare_dir "${BUILD_DIR}"

  # Copy the codebase at the last commit into BUILD_DIR. Tests that work with
  # the copy opt in with BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1.
  # During test development, local changes must be committed.
  fixture_export_codebase "${BUILD_DIR}" "${ROOT_DIR}"

  # Print debug information if "--verbose-run" is passed.
  # LCOV_EXCL_START
  if [ "${BATS_VERBOSE_RUN-}" = "1" ]; then
    echo "BUILD_DIR: ${BUILD_DIR}" >&3
  fi
  # LCOV_EXCL_END

  # Change directory to the current project directory for each test. Tests
  # requiring to operate outside of BUILD_DIR should change directory explicitly
  # within their tests.
  pushd "${BUILD_DIR}" >/dev/null || exit 1
}

teardown() {
  popd >/dev/null || cd "${CUR_DIR}" || exit 1
}
