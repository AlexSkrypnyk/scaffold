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
  # For a list of available variables see:
  # @see https://bats-core.readthedocs.io/en/stable/writing-tests.html#special-variables

  # Register a path to libraries.
  export BATS_LIB_PATH="${BATS_TEST_DIRNAME}/node_modules"

  # Load 'bats-helpers' library.
  bats_load_library bats-helpers

  # Setup command mocking.
  setup_mock

  # Current directory where the test is run from.
  # shellcheck disable=SC2155
  export CUR_DIR="$(pwd)"

  # Allow to run tests in a copy of the repository at the last commit.
  if [ "${BATS_FIXTURE_EXPORT_CODEBASE_ENABLED-}" = "1" ]; then
    # Directory where the shell command script will be running in.
    # As a part of test setup, the local copy of the repository at the last commit
    # is copied to this location. This means that during development of tests
    # local changes need to be committed.
    export BUILD_DIR="${BUILD_DIR:-"${BATS_TEST_TMPDIR//\/\//\/}/shell-command-$(date +%s)"}"
    fixture_prepare_dir "${BUILD_DIR}"

    # Copy code at the last commit.
    fixture_export_codebase "${BUILD_DIR}" "${CUR_DIR}"

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
  fi
}

teardown() {
  if [ "${BATS_FIXTURE_EXPORT_CODEBASE_ENABLED-}" = "1" ]; then
    # Restore the original directory.
    popd >/dev/null || cd "${CUR_DIR}" || exit 1
  fi
}
