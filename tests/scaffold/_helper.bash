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
  # Register a path to libraries.
  export BATS_LIB_PATH="${BATS_TEST_DIRNAME}/node_modules"

  # Load 'bats-helpers' library.
  bats_load_library bats-helpers

  # Load local libraries.
  # @see https://github.com/drevops/bats-helpers/issues/21
  load lib/_dataprovider
  # @see https://github.com/drevops/bats-helpers/issues/20
  load lib/_coverage
  # @see https://github.com/drevops/bats-helpers/issues/18
  load lib/_fixture
  # @see https://github.com/drevops/bats-helpers/issues/19
  load lib/_tui

  # Setup command mocking.
  # Remove when upstream implements support.
  # @see https://github.com/drevops/bats-helpers/issues/17
  if [ "${BATS_MOCK_ENABLED-}" = "1" ]; then
    setup_mock
  fi

  # Current directory where the test is run from.
  # shellcheck disable=SC2155
  export CUR_DIR="$(pwd)"

  # Directory where the init script will be running on.
  # As a part of test setup, the local copy of Scaffold at the last commit is
  # copied to this location. This means that during development of tests local
  # changes need to be committed.
  export BUILD_DIR="${BUILD_DIR:-"${BATS_TEST_TMPDIR//\/\//\/}/scaffold-$(date +%s)"}"
  fixture_prepare_dir "${BUILD_DIR}"

  # Copy code at the last commit.
  fixture_export_codebase "${BUILD_DIR}" "${CUR_DIR}"

  # Print debug information if "--verbose-run" is passed.
  if [ "${BATS_VERBOSE_RUN-}" = "1" ]; then
    echo "BUILD_DIR: ${BUILD_DIR}" >&3
  fi

  # Change directory to the current project directory for each test. Tests
  # requiring to operate outside of BUILD_DIR (like deployment tests)
  # should change directory explicitly within their tests.
  pushd "${BUILD_DIR}" >/dev/null || exit 1
}

teardown() {
  # Restore the original directory.
  popd >/dev/null || cd "${CUR_DIR}" || exit 1
}
