#!/usr/bin/env bash
#
# A Bats helper library for working with TUI.
#

#
# Run the script.
# shellcheck disable=SC2120
tui_run() {
  [ -z "${SCRIPT_FILE}" ] && flunk "SCRIPT_FILE is not set." && exit 1

  pushd "${BUILD_DIR}" >/dev/null || exit 1

  run "./${SCRIPT_FILE}" "$@"

  popd >/dev/null || exit 1

  # Print the output of the init script. This, however, makes error logs
  # harder to read.
  # shellcheck disable=SC2154
  echo "${output-}"
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
# output=$(tui_run_interactive "${answers[@]}")
# @endcode
tui_run_interactive() {
  local answers=("${@}")
  local input

  for i in "${answers[@]}"; do
    val="${i}"
    [ "${i}" = "nothing" ] && val='\n' || val="${val}"'\n'
    input="${input-}""${val}"
  done

  # shellcheck disable=SC2059,SC2119
  # ATTENTION! Questions change based on some answers, so using the same set of
  # answers for all tests will not work. Make sure that correct answers
  # provided for specific tests.
  printf "$input" | tui_run
}
