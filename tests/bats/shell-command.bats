#!/usr/bin/env bats
#
# Test shell-command.sh functionality.
#
# Example usage:
# ./tests/bats/node_modules/.bin/bats --no-tempdir-cleanup --formatter tap --filter-tags smoke tests/bats
#
# shellcheck disable=SC2030,SC2031,SC2034

load _helper

export BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

# Script file for TUI testing.
export SCRIPT_FILE="shell-command.sh"

# bats test_tags=smoke
@test "Die can be rolled with user input" {
  tui_run 6 y
  assert_success
  assert_output_contains "Rolling a 6-sided die..."
  assert_output_contains "Rolled: "
}

@test "Die can be rolled with the confirmation bypassed" {
  export SHOULD_PROCEED=y

  tui_run 20
  assert_success
  assert_output_contains "Rolling a 20-sided die..."
}

@test "Die roll can be aborted" {
  export SHOULD_PROCEED=n

  tui_run 20
  assert_success
  assert_output_contains "Aborting."
  assert_output_not_contains "Rolled: "
}

@test "Rolled value stays within the number of sides" {
  export SHOULD_PROCEED=y

  for _ in $(seq 1 20); do
    tui_run 2
    assert_success
    assert_any_line_matches_case "^Rolled: [12]$"
  done
}

@test "Leading zeros in the number of sides are read as base 10" {
  export SHOULD_PROCEED=y

  tui_run 010
  assert_success
  assert_output_contains "Rolling a 10-sided die..."
}

@test "Invalid number of sides is rejected" {
  export SHOULD_PROCEED=y

  for sides in 1 101 1000 abc -6 6.5; do
    tui_run "${sides}"
    assert_failure
    assert_output_contains "ERROR: Number of sides must be a whole number from 2 to 100, got '${sides}'."
    assert_output_not_contains "Rolled: "
  done
}
