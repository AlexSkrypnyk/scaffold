#!/usr/bin/env bats
#
# Functional tests for init.sh.
#
# Example usage:
# ./tests/scaffold/node_modules/.bin/bats --no-tempdir-cleanup --formatter tap --filter-tags smoke tests/scaffold
#
# shellcheck disable=SC2030,SC2031,SC2129

load _helper
load _assert_init

export BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1
export SCRIPT_FILE="init.sh"

# bats test_tags=smoke
@test "Init, defaults" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_php_command "${BUILD_DIR}"
  assert_files_present_php_command_build "${BUILD_DIR}"
  assert_files_absent_php_script "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_output_contains "Initialization complete."

  assert_files_present_docs "${BUILD_DIR}"
}

@test "Init, defaults, workflows" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_php_command "${BUILD_DIR}"
  assert_files_present_php_command_build "${BUILD_DIR}"
  assert_files_absent_php_script "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_output_contains "Initialization complete."

  assert_workflow_php "${BUILD_DIR}"
  assert_workflow_php_command_build "${BUILD_DIR}"

  assert_files_present_docs "${BUILD_DIR}"
}

@test "Init, php command, no build" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "n"             # use PHP Command Build
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_php_command "${BUILD_DIR}"
  assert_files_absent_php_command_build "${BUILD_DIR}"
  assert_files_absent_php_script "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, php script" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "n"             # use PHP Command
    "nothing"       # use PHP Script
    "nothing"       # CLI command name
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_present_php "${BUILD_DIR}"
  assert_files_absent_php_command "${BUILD_DIR}"
  assert_files_absent_php_command_build "${BUILD_DIR}"
  assert_files_present_php_script "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_output_contains "Initialization complete."

  assert_workflow_php "${BUILD_DIR}"
}

@test "Init, neither php script nor php command" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "n"             # use PHP Command
    "n"             # use PHP Script
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_present_php "${BUILD_DIR}"
  assert_files_absent_php_command "${BUILD_DIR}"
  assert_files_absent_php_command_build "${BUILD_DIR}"
  assert_files_absent_php_script "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, no php" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "n"             # use PHP
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_absent_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, no nodejs" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "n"             # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_absent_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, no shell" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "nothing"       # use NodeJS
    "n"             # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_absent_shell "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, no release drafter" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "n"             # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_file_not_exists ".github/workflows/draft-release-notes.yml"
  assert_file_not_exists ".github/release-drafter.yml"

  assert_output_contains "Initialization complete."
}

@test "Init, no PR auto-assign" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "n"             # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_file_not_exists ".github/assign-author.yml"

  assert_output_contains "Initialization complete."
}

@test "Init, no funding" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "n"             # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_file_not_exists ".github/FUNDING.yml"

  assert_output_contains "Initialization complete."
}

@test "Init, no PR template" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "n"             # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_file_not_exists ".github/PULL_REQUEST_TEMPLATE.md"

  assert_output_contains "Initialization complete."
}

@test "Init, no Renovate" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "n"             # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_file_not_exists "renovate.json"

  assert_output_contains "Initialization complete."
}

@test "Init, no docs" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "n"             # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_files_absent_docs "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

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
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "n"             # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"

  assert_file_exists "init.sh"

  assert_output_contains "Initialization complete."
}

@test "Init, no proceed" {
  answers=(
    "YodasHut"      # organisation
    "force-crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "n"             # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Aborting."
  assert_failure
}

@test "Init, project is invalid has space, uppercase, workflow" {
  answers=(
    "YodasHut"      # organisation
    "Force crystal" # project
    "Jane Doe"      # author
    "nothing"       # use PHP
    "nothing"       # use PHP Command
    "nothing"       # CLI command name
    "nothing"       # use PHP Command Build
    "nothing"       # use NodeJS
    "nothing"       # use Shell
    "nothing"       # Shell command name
    "nothing"       # use GitHub release drafter
    "nothing"       # use GitHub pr auto-assign
    "nothing"       # use GitHub funding
    "nothing"       # use GitHub PR template
    "nothing"       # use Renovate
    "nothing"       # remove docs
    "nothing"       # remove init script
    "nothing"       # proceed with init
  )
  tui_run "${answers[@]}"

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_php "${BUILD_DIR}"
  assert_files_present_php_command "${BUILD_DIR}"
  assert_files_present_php_command_build "${BUILD_DIR}"
  assert_files_absent_php_script "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"
  assert_files_present_shell "${BUILD_DIR}"
  assert_workflow_php "${BUILD_DIR}"
  assert_workflow_php_command_build "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}
