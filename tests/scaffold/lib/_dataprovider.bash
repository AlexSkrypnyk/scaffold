#!/usr/bin/env bash
#
# A Bats helper library providing data providers support.
#

##
# Run multiple test cases for a given function (aka Data Provider).
#
# Arguments:
#   1. func_name: The name of the function to be tested.
#   2. args_per_row: (Optional) The number of arguments in each row of the TEST_CASES array, defaults to 1.
#
# Global Variables:
#   TEST_CASES: An array containing test cases with their expected values.
#
# Examples:
#   To run a function `test_func` with TEST_CASES containing two arguments per row,
#   you can call run_test_cases like so:
#     run_test_cases "test_func" 2
##

dataprovider_run() {
  local func_name="${1}"
  local args_per_row=${2:-1}

  ##
  ## Input validation.
  ##

  if [[ -z $func_name ]]; then
    flunk "Function name must not be empty."
    return
  fi

  # Verify that func_name is a valid function that can be called.
  if ! type -t "${func_name}" | grep -q 'function'; then
    flunk "Function ${func_name} is not a valid function."
    return
  fi

  # Using the normal run() function is sufficient for testing functions with no
  # arguments.
  if [[ $args_per_row -le 0 ]]; then
    flunk "Number of arguments per test case must be greater than zero."
    return
  fi

  # Check that TEST_CASES is not empty.
  if [ -z "${TEST_CASES+x}" ]; then
    flunk "TEST_CASES array is empty."
    return
  fi

  if [ "${#TEST_CASES[@]}" -eq 0 ]; then
    flunk "TEST_CASES array is empty."
    return
  fi

  # Ensure args_per_row is less than or equal to the total number of elements in TEST_CASES.
  if [ "${args_per_row}" -gt ${#TEST_CASES[@]} ]; then
    flunk "Number of arguments per test case is greater than the total elements in TEST_CASES."
    return
  fi

  # Ensure that TEST_CASES has a multiple of args_per_row elements.
  if [[ $((${#TEST_CASES[@]} % args_per_row)) -ne 0 ]]; then
    flunk "Total elements in TEST_CASES must be a multiple of $args_per_row."
    return
  fi

  # Ensure that the last argument in each row (i.e., "expected" value) is not empty.
  for ((i = args_per_row - 1, data_set_idx = 0; i < ${#TEST_CASES[@]}; i += args_per_row, data_set_idx++)); do
    if [ -z "${TEST_CASES[i]}" ]; then
      flunk "Expected value (last element) in the data set ${data_set_idx} is empty."
      return
    fi
  done

  ##
  ## Runner.
  ##

  local set_idx=0
  local error_count=0
  local failed_sets=""

  for ((i = 0; i < ${#TEST_CASES[@]}; i += args_per_row)); do
    expected="${TEST_CASES[i + args_per_row - 1]}"
    test_args=("${TEST_CASES[@]:i:args_per_row-1}")

    run "$func_name" "${test_args[@]}"

    if ! assert_output_contains "$expected"; then
      echo "Error: Failed for set $set_idx"
      error_count=$((error_count + 1))
      failed_sets="${failed_sets}${set_idx}, "
    fi

    set_idx=$((set_idx + 1))
  done

  ##
  ## Error reporting.
  ##

  if [[ $error_count -ne 0 ]]; then
    failed_sets=${failed_sets%, } # Remove trailing comma
    echo
    echo "Failed Sets (0-based): $failed_sets"
    flunk "Total failed test sets: $error_count"
  fi
}
