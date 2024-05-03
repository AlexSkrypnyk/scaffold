#!/usr/bin/env bats
#
# Test shell-command.sh functionality.
#
# Example usage:
# ./tests/scaffold/node_modules/.bin/bats --no-tempdir-cleanup --formatter tap --filter-tags smoke tests/bats
#
# shellcheck disable=SC2030,SC2031,SC2034

load _helper

export BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

# Script file for TUI testing.
export SCRIPT_FILE="shell-command.sh"

# bats test_tags=smoke
@test "Data can be fetched from the API with user input" {
  tui_run general y
  assert_success
  assert_output_contains "https://official-joke-api.appspot.com/jokes/general/random"
}

@test "Data can be fetched from the API with CLI arguments" {
  export SHOULD_PROCEED=y

  tui_run programming
  assert_success
  assert_output_contains "https://official-joke-api.appspot.com/jokes/programming/random"
}

@test "Data can be fetched from the API with CLI arguments, aborting" {
  export SHOULD_PROCEED=n

  tui_run programming
  assert_success
  assert_output_contains "Aborting."
}

@test "Mocked endpoint" {
  declare -a STEPS=(
    '@curl -sL https://official-joke-api.appspot.com/jokes/mocked_topic/random # [{"type":"mocked_topic","setup":"mocked_setup","punchline":"mocked_punchline","id":251}]'
  )

  mocks="$(run_steps "setup")"

  export SHOULD_PROCEED=y
  tui_run mocked_topic
  assert_success
  assert_output_contains "mocked_setup"
  assert_output_contains "mocked_punchline"

  run_steps "assert" "${mocks[@]}"
}
