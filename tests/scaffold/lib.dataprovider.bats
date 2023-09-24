#!/usr/bin/env bats
#
# BATS tests for dataprovider runner.
#
# shellcheck disable=SC2034

load _helper

fixture_add() {
  local num1=$1
  local num2=$2
  echo $((num1 + num2))
}

fixture_concat() {
  local num1=$1
  local num2=$2
  echo "$num1$num2"
}

@test "Test dataprovider runner, direct - success" {
  # Numbers.
  TEST_CASES=(
    1 2 3
    4 5 9
  )
  dataprovider_run "fixture_add" 3

  # String.
  TEST_CASES=(
    "start" "finish" "startfinish"
  )
  dataprovider_run "fixture_concat" 3

  # More arguments than needed is allowed.
  TEST_CASES=(
    "start" "middle" "finish" "startmiddle"
  )
  dataprovider_run "fixture_concat" 4
}

@test "Test dataprovider runner - success" {
  run fixture_add 1 2
  TEST_CASES=(
    1 2 3
    1 2 3
  )

  run dataprovider_run "fixture_add" 3
  assert_success

  assert_output_not_contains "Failed Sets (0-based)"
  assert_output_not_contains "Total failed test sets"
}

@test "Test dataprovider runner - failure" {
  TEST_CASES=(
    1 2 3
    1 2 4
    1 2 3
    1 2 4
  )

  run dataprovider_run "fixture_add" 3
  assert_failure
  assert_output_contains "Failed Sets (0-based): 1, 3"
  assert_output_contains "Total failed test sets: 2"
}

@test "Test dataprovider runner, validation - failure" {
  run dataprovider_run "" 3
  assert_failure
  assert_output_contains "Function name must not be empty."

  run dataprovider_run "non_existing_func" 3
  assert_failure
  assert_output_contains "Function non_existing_func is not a valid function."

  run dataprovider_run "non_existing_func" 3
  assert_failure
  assert_output_contains "Function non_existing_func is not a valid function."

  run dataprovider_run "fixture_add" 0
  assert_failure
  assert_output_contains "Number of arguments per test case must be greater than zero."

  run dataprovider_run "fixture_add" 2
  assert_failure
  assert_output_contains "TEST_CASES array is empty."

  TEST_CASES=()
  run dataprovider_run "fixture_add" 2
  assert_failure
  assert_output_contains "TEST_CASES array is empty."

  TEST_CASES=(
    1 2
  )
  run dataprovider_run "fixture_add" 3
  assert_failure
  assert_output_contains "Number of arguments per test case is greater than the total elements in TEST_CASES."

  TEST_CASES=(
    1 2 3
    1 2
  )
  run dataprovider_run "fixture_add" 3
  assert_failure
  assert_output_contains "Total elements in TEST_CASES must be a multiple of 3."

  TEST_CASES=(
    1 2 3
    1 2 ""
    1 2 4
  )
  run dataprovider_run "fixture_add" 3
  assert_failure
  assert_output_contains "Expected value (last element) in the data set 1 is empty."
}
