#!/usr/bin/env bats
#
# Test shell-command.sh functionality.
#
# bats --tap tests/bats/shell-command.bats
#
# shellcheck disable=SC2030,SC2031,SC2034

load _helper

# Script file for TUI testing.
export SCRIPT_FILE=./shell-command.sh

@test "Data can be fetched from the API with user input" {
  tui_run general y
  assert_success
}

@test "Data can be fetched from the API with CLI arguments" {
  export SHOULD_PROCEED=y

  run "${SCRIPT_FILE}" programming
  assert_success
}

@test "Data can be fetched from the API with CLI arguments, aborting" {
  export SHOULD_PROCEED=n

  run "${SCRIPT_FILE}" programming
  assert_success
  assert_output_contains "Aborting."
}

@test "Mocked endpoint" {
  declare -a STEPS=(
    '@curl -sL https://official-joke-api.appspot.com/jokes/mocked_topic/random # [{"type":"mocked_topic","setup":"mocked_setup","punchline":"mocked_punchline","id":251}]'
  )

  mocks="$(run_steps "setup")"

  export SHOULD_PROCEED=y
  run "${SCRIPT_FILE}" mocked_topic
  assert_success
  assert_output_contains "mocked_setup"
  assert_output_contains "mocked_punchline"

  run_steps "assert" "${mocks[@]}"
}
