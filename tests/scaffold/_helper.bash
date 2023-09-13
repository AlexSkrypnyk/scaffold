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

  # Setup command mocking.
  setup_mock

  # Current directory where the test is run from.
  # shellcheck disable=SC2155
  export CURDIR="$(pwd)"

  # Directory where the init script will be running on.
  # As a part of test setup, the local copy of Scaffold at the last commit is
  # copied to this location. This means that during development of tests local
  # changes need to be committed.
  export BUILD_DIR="${BUILD_DIR:-"${BATS_TEST_TMPDIR//\/\//\/}/scaffold-$(date +%s)"}"
  prepare_fixture_dir "${BUILD_DIR}"

  # Copy code at the last commit.
  copy_code "${BUILD_DIR}" >/dev/null

  # Print debug information if "--verbose-run" is passed.
  [ "$BATS_VERBOSE_RUN" = "1" ] && echo "BUILD_DIR: ${BUILD_DIR}" >&3

  # Change directory to the current project directory for each test. Tests
  # requiring to operate outside of BUILD_DIR (like deployment tests)
  # should change directory explicitly within their tests.
  pushd "${BUILD_DIR}" >/dev/null || exit 1
}

teardown() {
  # Restore the original directory.
  popd >/dev/null || cd "${CURDIR}" || exit 1
}

################################################################################
#                               UTILITIES                                      #
################################################################################

#
# Copy source code at the latest commit to the destination directory.
#
copy_code() {
  local dst="${1:-${BUILD_DIR}}"

  assert_dir_exists "${dst}"
  assert_git_repo "${CURDIR}"

  pushd "${CURDIR}" >/dev/null || exit 1

  # Copy the latest commit to the build directory.
  git archive --format=tar HEAD | (cd "${dst}" && tar -xf -)

  popd >/dev/null || exit 1
}

#
# Run the script.
# shellcheck disable=SC2120
run_script() {
  pushd "${BUILD_DIR}" >/dev/null || exit 1

  [ -z "${SCRIPT_FILE}" ] && echo "ERROR: SCRIPT_FILE is not defined" >&3 && exit 1

  run "./${SCRIPT_FILE}" "$@"

  popd >/dev/null || exit 1

  # Print the output of the init script. This, however, makes error logs
  # harder to read.
  # shellcheck disable=SC2154
  echo "${output}"
}

#
# Run the script in the interactive mode.
#
# Use 'y' for 'yes' and 'n' for 'no'.
#
# 'nothing' stands for user not providing an input and accepting suggested
# default values.
#
# @code
# answers=(
#   "nothing" # default answer
#   "custom" # custom answer
# )
# output=$(run_script_interactive "${answers[@]}")
# @endcode
run_script_interactive() {
  local answers=("${@}")
  local input

  for i in "${answers[@]}"; do
    val="${i}"
    [ "${i}" = "nothing" ] && val='\n' || val="${val}"'\n'
    input="${input}""${val}"
  done

  # shellcheck disable=SC2059,SC2119
  # ATTENTION! Questions change based on some answers, so using the same set of
  # answers for all tests will not work. Make sure that correct answers
  # provided for specific tests.
  printf "$input" | run_script
}
