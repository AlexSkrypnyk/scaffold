#!/usr/bin/env bats
#
# Test initation into empty directory.
#
# shellcheck disable=SC2030,SC2031,SC2129

load _helper.bash
load _assert.bash

# The name of the script to run.
export SCRIPT_FILE="init.sh"

@test "Init, do not remove script" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "nothing"       # use NodeJS
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "n"             # remove init script
    "nothing"       # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")
  assert_equal "1" "1"
}
