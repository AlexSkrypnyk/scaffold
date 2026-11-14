#!/usr/bin/env bats
#
# Test entrypoint.sh functionality.

load _helper

bats_require_minimum_version 1.5.0

@test "Entrypoint reports that it is running when given no command" {
  run "${ROOT_DIR}/entrypoint.sh"
  assert_success
  assert_output "yourproject is running"
}

@test "Entrypoint runs the passed command with its arguments" {
  run "${ROOT_DIR}/entrypoint.sh" printf '%s\n' "first argument" second
  assert_success
  assert_equal "${#lines[@]}" 3
  assert_equal "${lines[0]}" "yourproject is running"
  assert_equal "${lines[1]}" "first argument"
  assert_equal "${lines[2]}" "second"
}

@test "Entrypoint exits with the exit code of the passed command" {
  run "${ROOT_DIR}/entrypoint.sh" bash -c 'exit 3'
  assert_equal "${status}" 3
  assert_output "yourproject is running"
}

@test "Entrypoint fails when the passed command does not exist" {
  run -127 "${ROOT_DIR}/entrypoint.sh" missing-entrypoint-command
  assert_output_contains "yourproject is running"
}
