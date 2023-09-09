#!/usr/bin/env bats
#
# Test initation into empty directory.
#
# shellcheck disable=SC2030,SC2031,SC2129

load _helper.bash
load _assert.bash

# The name of the script to run.
export SCRIPT_FILE="init.sh"

@test "Smoke" {
  assert_contains "scaffold" "${BUILD_DIR}"
}

@test "Init, defaults" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use PHP
    "nothing"   # use PHP Command
    "nothing"   # CLI command name
    "nothing"   # use PHP Command Build
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # use GitHub PR template
    "nothing"   # use Renovate
    "nothing"   # remove init script
    "nothing"   # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_php_command "${BUILD_DIR}"
  assert_files_present_php_command_build "${BUILD_DIR}"
  assert_files_absent_php_script "${BUILD_DIR}"

  assert_files_present_nodejs "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, php command, no build" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use PHP
    "nothing"   # use PHP Command
    "nothing"   # CLI command name
    "n"         # use PHP Command Build
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # use GitHub PR template
    "nothing"   # use Renovate
    "nothing"   # remove init script
    "nothing"   # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_php_command "${BUILD_DIR}"
  assert_files_absent_php_command_build "${BUILD_DIR}"
  assert_files_absent_php_script "${BUILD_DIR}"

  assert_files_present_nodejs "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, php script" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use PHP
    "n"         # use PHP Command
    "nothing"   # use PHP Script
    "nothing"   # CLI command name
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # use GitHub PR template
    "nothing"   # use Renovate
    "nothing"   # remove init script
    "nothing"   # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_present_php "${BUILD_DIR}"
  assert_files_absent_php_command "${BUILD_DIR}"
  assert_files_absent_php_command_build "${BUILD_DIR}"
  assert_files_present_php_script "${BUILD_DIR}"

  assert_files_present_nodejs "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, neither php script nor php command" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use PHP
    "n"         # use PHP Command
    "n"         # use PHP Script
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # use GitHub PR template
    "nothing"   # use Renovate
    "nothing"   # remove init script
    "nothing"   # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_present_php "${BUILD_DIR}"
  assert_files_absent_php_command "${BUILD_DIR}"
  assert_files_absent_php_command_build "${BUILD_DIR}"
  assert_files_absent_php_script "${BUILD_DIR}"

  assert_files_present_nodejs "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, no php" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "n"         # use PHP
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # use GitHub PR template
    "nothing"   # use Renovate
    "nothing"   # remove init script
    "nothing"   # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_absent_php "${BUILD_DIR}"

  assert_files_present_nodejs "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, no nodejs" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use PHP
    "nothing"   # use PHP Command
    "nothing"   # CLI command name
    "nothing"   # use PHP Command Build
    "n"         # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # use GitHub PR template
    "nothing"   # use Renovate
    "nothing"   # remove init script
    "nothing"   # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_present_php "${BUILD_DIR}"

  assert_files_absent_nodejs "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, no release drafter" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use PHP
    "nothing"   # use PHP Command
    "nothing"   # CLI command name
    "nothing"   # use PHP Command Build
    "nothing"   # use NodeJS
    "n"         # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # use GitHub PR template
    "nothing"   # use Renovate
    "nothing"   # remove init script
    "nothing"   # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"

  assert_file_not_exists ".github/release-drafter.yml"
  assert_file_not_contains ".github/workflows/release.yml" "release-drafter"

  assert_output_contains "Initialization complete."
}

@test "Init, no PR auto-assign" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use PHP
    "nothing"   # use PHP Command
    "nothing"   # CLI command name
    "nothing"   # use PHP Command Build
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "n"         # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # use GitHub PR template
    "nothing"   # use Renovate
    "nothing"   # remove init script
    "nothing"   # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"

  assert_file_not_exists ".github/auto-assign-pr-author.yml"

  assert_output_contains "Initialization complete."
}

@test "Init, no funding" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use PHP
    "nothing"   # use PHP Command
    "nothing"   # CLI command name
    "nothing"   # use PHP Command Build
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "n"         # use GitHub funding
    "nothing"   # use GitHub PR template
    "nothing"   # use Renovate
    "nothing"   # remove init script
    "nothing"   # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"

  assert_file_not_exists ".github/FUNDING.yml"

  assert_output_contains "Initialization complete."
}

@test "Init, no PR template" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use PHP
    "nothing"   # use PHP Command
    "nothing"   # CLI command name
    "nothing"   # use PHP Command Build
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "n"         # use GitHub PR template
    "nothing"   # use Renovate
    "nothing"   # remove init script
    "nothing"   # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"

  assert_file_not_exists ".github/PULL_REQUEST_TEMPLATE.md"

  assert_output_contains "Initialization complete."
}

@test "Init, no Renovate" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use PHP
    "nothing"   # use PHP Command
    "nothing"   # CLI command name
    "nothing"   # use PHP Command Build
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # use GitHub PR template
    "n"         # use Renovate
    "nothing"   # remove init script
    "nothing"   # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"

  assert_file_not_exists "renovate.json"

  assert_output_contains "Initialization complete."
}

@test "Init, do not remove script" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use PHP
    "nothing"   # use PHP Command
    "nothing"   # CLI command name
    "nothing"   # use PHP Command Build
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # use GitHub PR template
    "nothing"   # use Renovate
    "n"         # remove init script
    "nothing"   # proceed with init
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"

  assert_file_exists "init.sh"

  assert_output_contains "Initialization complete."
}
