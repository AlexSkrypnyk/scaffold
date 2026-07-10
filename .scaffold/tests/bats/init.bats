#!/usr/bin/env bats
#
# Unit tests for init.sh.
#
# Variables under test are assigned by the sourced init.sh, which shellcheck
# does not follow, so disable "unassigned variable" (SC2154) here. The 'curl'
# mocks are invoked indirectly by init.sh functions under 'run' and cannot be
# traced statically, so "function never invoked" (SC2329) is disabled too.
# shellcheck disable=SC2034,SC2154,SC2329

load _helper
load "../../../init.sh"

@test "Test all conversions" {
  input="I am a_string-With spaces 13"

  TEST_CASES=(
    "$input" "file_name" "i_am_a_string-with_spaces_13"
    "$input" "route_path" "i_am_a_string-with_spaces_13"
    "$input" "deployment_id" "i_am_a_string-with_spaces_13"
    "$input" "domain_name" "i_am_a_stringwith_spaces_13"
    "$input" "namespace" "IAmA_stringWithSpaces13"
    "$input" "package_name" "i-am-a_string-with-spaces-13"
    "$input" "function_name" "i_am_a_string-with_spaces_13"
    "$input" "ui_id" "i_am_a_string-with_spaces_13"
    "$input" "cli_command" "i_am_a_string-with_spaces_13"
    "$input" "log_entry" "I am a_string-With spaces 13"
    "$input" "code_comment_title" "I am a_string-With spaces 13"
    "$input" "dummy_type" "Invalid conversion type"
    "HelloWorld" "namespace" "HelloWorld"
    "Hello World" "namespace" "HelloWorld"
    "Hello world" "namespace" "HelloWorld"
    "Hello-world" "namespace" "Helloworld"
  )

  dataprovider_run "convert_string" 3
}

@test "Test to_pascalcase conversions" {
  TEST_CASES=(
    "my-awesome-project" "MyAwesomeProject"
    "my_awesome_project" "MyAwesomeProject"
    "my awesome project" "MyAwesomeProject"
    "force-crystal" "ForceCrystal"
    "test-app" "TestApp"
    "single" "Single"
    "mix-case_test project" "MixCaseTestProject"
    "MyAwesomeProject" "MyAwesomeProject"
  )

  dataprovider_run "to_pascalcase" 2
}

create_renovate_json() {
  cat >"${1}/renovate.json" <<'RENOVATE'
{
    "extends": ["config:recommended"],
    "automerge": true,
    "rangeStrategy": "bump",
    "dependencyDashboard": true,
    "pinDigests": true,
    "branchPrefix": "deps/",
    "packageRules": [
        {
            "matchDepNames": ["php"],
            "matchManagers": ["composer"],
            "enabled": false
        },
        {
            "matchDepNames": ["node", "yarn"],
            "matchManagers": ["npm"],
            "enabled": false
        },
        {
            "matchManagers": ["npm", "composer"],
            "matchUpdateTypes": ["major"],
            "enabled": false
        },
        {
            "matchPackageNames": ["*"],
            "groupName": "all dependencies",
            "groupSlug": "all"
        }
    ]
}
RENOVATE
}

@test "remove_php removes composer from renovate matchManagers and php language rule" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_php"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_php
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/renovate.json" '"matchManagers": ["npm"]'
  assert_file_not_contains "${tmpdir}/renovate.json" '"composer"'
  assert_file_not_contains "${tmpdir}/renovate.json" '"matchDepNames": ["php"]'
  assert_file_contains "${tmpdir}/renovate.json" '"matchDepNames": ["node", "yarn"]'
}

@test "remove_nodejs removes npm from renovate matchManagers and node/yarn language rule" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_nodejs"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_nodejs
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/renovate.json" '"matchManagers": ["composer"]'
  assert_file_not_contains "${tmpdir}/renovate.json" '"npm"'
  assert_file_not_contains "${tmpdir}/renovate.json" '"matchDepNames": ["node", "yarn"]'
  assert_file_contains "${tmpdir}/renovate.json" '"matchDepNames": ["php"]'
}

@test "remove_php then remove_nodejs empties matchManagers" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_both"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_php
  remove_nodejs
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/renovate.json" '"matchManagers": []'
}

@test "cleanup_renovate_managers removes empty matchManagers block" {
  local tmpdir="${BATS_TEST_TMPDIR}/cleanup"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_php
  remove_nodejs
  cleanup_renovate_managers
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/renovate.json" '"matchManagers"'
  assert_file_not_contains "${tmpdir}/renovate.json" '"matchUpdateTypes"'
  assert_file_contains "${tmpdir}/renovate.json" '"matchPackageNames"'
}

@test "cleanup_renovate_managers no-ops when matchManagers is not empty" {
  local tmpdir="${BATS_TEST_TMPDIR}/cleanup_noop"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_php
  cleanup_renovate_managers
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/renovate.json" '"matchManagers": ["npm"]'
}

@test "protect_skill_references and restore_skill_references round-trip" {
  local tmpdir="${BATS_TEST_TMPDIR}/skill_refs"
  mkdir -p "${tmpdir}"
  cat >"${tmpdir}/AGENTS.md" <<'AGENTS'
curl https://raw.githubusercontent.com/AlexSkrypnyk/scaffold/main/.scaffold/skills/update-consumer-scaffold/SKILL.md
Invoke the update-consumer-scaffold skill
ask Claude Code to "update scaffold"
AGENTS

  pushd "${tmpdir}" >/dev/null || exit 1
  protect_skill_references
  popd >/dev/null || exit 1

  assert_file_contains "${tmpdir}/AGENTS.md" '__SCAFFOLD_SKILL_URL__'
  assert_file_contains "${tmpdir}/AGENTS.md" '__SCAFFOLD_SKILL_NAME__'
  assert_file_contains "${tmpdir}/AGENTS.md" '__SCAFFOLD_SKILL_TRIGGER__'
  assert_file_not_contains "${tmpdir}/AGENTS.md" 'AlexSkrypnyk/scaffold'

  pushd "${tmpdir}" >/dev/null || exit 1
  restore_skill_references
  popd >/dev/null || exit 1

  assert_file_contains "${tmpdir}/AGENTS.md" 'https://raw.githubusercontent.com/AlexSkrypnyk/scaffold/main/.scaffold/skills/update-consumer-scaffold/SKILL.md'
  assert_file_contains "${tmpdir}/AGENTS.md" 'Invoke the update-consumer-scaffold skill'
  assert_file_contains "${tmpdir}/AGENTS.md" '"update scaffold"'
  assert_file_not_contains "${tmpdir}/AGENTS.md" '__SCAFFOLD_SKILL'
}

@test "remove_test_actions removes the workflow and its companion configs" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_test_actions"
  mkdir -p "${tmpdir}/.github/workflows"
  touch "${tmpdir}/.github/workflows/test-actions.yml"
  touch "${tmpdir}/.github/.yamllint-for-gha.yml"
  touch "${tmpdir}/zizmor.yml"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_test_actions
  popd >/dev/null || return 1

  assert_file_not_exists "${tmpdir}/.github/workflows/test-actions.yml"
  assert_file_not_exists "${tmpdir}/.github/.yamllint-for-gha.yml"
  assert_file_not_exists "${tmpdir}/zizmor.yml"
}

@test "remove_schedule removes the schedule trigger block" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_schedule"
  mkdir -p "${tmpdir}/.github/workflows"
  cat >"${tmpdir}/.github/workflows/test-php.yml" <<'WORKFLOW'
on:
  # yamllint disable-line #;< SCHEDULE
  schedule:
    - cron: '23 4 * * *'
  # yamllint disable-line #;> SCHEDULE
  push:
    branches:
      - main
WORKFLOW

  pushd "${tmpdir}" >/dev/null || return 1
  remove_schedule
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/.github/workflows/test-php.yml" "schedule:"
  assert_file_not_contains "${tmpdir}/.github/workflows/test-php.yml" "SCHEDULE"
  assert_file_contains "${tmpdir}/.github/workflows/test-php.yml" "push:"
}

@test "parse_args without arguments keeps interactive mode" {
  parse_args
  assert_equal "${interactive}" "1"
}

@test "parse_args sets identity values and disables interactive mode" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe"
  assert_equal "${namespace}" "AcmeApp"
  assert_equal "${project}" "acme-app"
  assert_equal "${author}" "Jane Doe"
  assert_equal "${interactive}" "0"
}

@test "parse_args --no-php disables PHP" {
  parse_args --no-php
  assert_equal "${use_php}" "n"
}

@test "parse_args --php-script selects the script sub-mode" {
  parse_args --php-script
  assert_equal "${use_php_script}" "y"
}

@test "parse_args --php-command-name implies the command sub-mode" {
  parse_args --php-command-name=mycli
  assert_equal "${php_command_name}" "mycli"
  assert_equal "${use_php_command}" "y"
}

@test "parse_args --docker-image-name implies Docker support" {
  parse_args --docker-image-name=acme/app
  assert_equal "${docker_image_name}" "acme/app"
  assert_equal "${use_docker}" "y"
}

@test "parse_args --test-actions enables GitHub Actions linting" {
  parse_args --test-actions
  assert_equal "${use_test_actions}" "y"
}

@test "parse_args --no-test-actions disables GitHub Actions linting" {
  parse_args --no-test-actions
  assert_equal "${use_test_actions}" "n"
}

@test "parse_args --schedule enables scheduled builds" {
  parse_args --schedule
  assert_equal "${use_schedule}" "y"
}

@test "parse_args --no-schedule disables scheduled builds" {
  parse_args --no-schedule
  assert_equal "${use_schedule}" "n"
}

@test "parse_args --keep preserves the script" {
  parse_args --keep
  assert_equal "${remove_self}" "n"
}

@test "parse_args --yes disables interactive mode" {
  parse_args --yes
  assert_equal "${interactive}" "0"
}

@test "parse_args fails on conflicting PHP sub-modes" {
  run parse_args --php-command --php-script
  assert_failure
  assert_output_contains "cannot be used together"
}

@test "parse_args fails on an unknown option" {
  run parse_args --unknown
  assert_failure
  assert_output_contains "Unknown option"
}

@test "parse_args prints usage for --help" {
  run parse_args --help
  assert_success
  assert_output_contains "Usage: ./init.sh"
}

@test "require_identity fails when identity is missing" {
  run require_identity
  assert_failure
  assert_output_contains "Missing required option"
}

@test "normalize_inputs canonicalises identity values" {
  namespace="Acme App"
  project="Acme App"
  author="Jane Doe"
  normalize_inputs
  assert_equal "${namespace}" "AcmeApp"
  assert_equal "${project}" "acme-app"
  assert_equal "${project_pascalcase}" "AcmeApp"
}

@test "collect_noninteractive applies defaults and prints a summary" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe"
  run collect_noninteractive
  assert_success
  assert_output_contains "Summary"
  assert_output_contains "AcmeApp"
  assert_output_contains "acme-app"
}

@test "collect_noninteractive honours the script sub-mode" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --php-script
  run collect_noninteractive
  assert_success
  assert_output_contains "Use simple script              : y"
}

@test "collect_noninteractive disables features on request" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --no-php --docker
  run collect_noninteractive
  assert_success
  assert_output_contains "Use PHP                          : n"
  assert_output_contains "Use Docker                       : y"
}

@test "collect_noninteractive keeps GitHub Actions linting off by default" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe"
  run collect_noninteractive
  assert_success
  assert_output_contains "Use GitHub Actions linting       : n"
}

@test "collect_noninteractive enables GitHub Actions linting on request" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --test-actions
  run collect_noninteractive
  assert_success
  assert_output_contains "Use GitHub Actions linting       : y"
}

@test "collect_noninteractive keeps scheduled builds on by default" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe"
  run collect_noninteractive
  assert_success
  assert_output_contains "Use scheduled builds             : y"
}

@test "collect_noninteractive disables scheduled builds on request" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --no-schedule
  run collect_noninteractive
  assert_success
  assert_output_contains "Use scheduled builds             : n"
}

create_claude_settings() {
  mkdir -p "${1}/.claude"
  cat >"${1}/.claude/settings.json" <<'SETTINGS'
{
  "permissions": {
    "allow": [
      "Bash(composer:*)",
      "Bash(./vendor/bin/phpcs:*)",
      "Bash(./vendor/bin/phpcbf:*)",
      "Bash(./vendor/bin/phpstan:*)",
      "Bash(./vendor/bin/rector:*)",
      "Bash(./vendor/bin/phpunit:*)",
      "Bash(./tests/bats/node_modules/bats/bin/bats:*)",
      "Bash(npm:*)",
      "Bash(docker build:*)",
      "Bash(docker run:*)"
    ]
  }
}
SETTINGS
}

@test "process_claude_settings keeps every rule when all features are selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_all"
  mkdir -p "${tmpdir}"
  create_claude_settings "${tmpdir}"

  use_php="y"
  use_shell="y"
  use_nodejs="y"
  use_docs="y"
  use_docker="y"

  pushd "${tmpdir}" >/dev/null || return 1
  process_claude_settings
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/.claude/settings.json" "composer:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "bats:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "npm:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "docker build:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "docker run:"
}

@test "process_claude_settings removes PHP rules when PHP is not selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_no_php"
  mkdir -p "${tmpdir}"
  create_claude_settings "${tmpdir}"

  use_php="n"
  use_shell="y"
  use_nodejs="y"
  use_docs="y"
  use_docker="y"

  pushd "${tmpdir}" >/dev/null || return 1
  process_claude_settings
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/.claude/settings.json" "composer:"
  assert_file_not_contains "${tmpdir}/.claude/settings.json" "phpstan:"
  assert_file_not_contains "${tmpdir}/.claude/settings.json" "phpunit:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "bats:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "npm:"
}

@test "process_claude_settings removes the bats rule when shell is not selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_no_shell"
  mkdir -p "${tmpdir}"
  create_claude_settings "${tmpdir}"

  use_php="y"
  use_shell="n"
  use_nodejs="y"
  use_docs="y"
  use_docker="y"

  pushd "${tmpdir}" >/dev/null || return 1
  process_claude_settings
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/.claude/settings.json" "bats:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "composer:"
}

@test "process_claude_settings removes Docker rules when Docker is not selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_no_docker"
  mkdir -p "${tmpdir}"
  create_claude_settings "${tmpdir}"

  use_php="y"
  use_shell="y"
  use_nodejs="y"
  use_docs="y"
  use_docker="n"

  pushd "${tmpdir}" >/dev/null || return 1
  process_claude_settings
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/.claude/settings.json" "docker build:"
  assert_file_not_contains "${tmpdir}/.claude/settings.json" "docker run:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "npm:"
}

@test "process_claude_settings keeps npm when docs is selected without NodeJS" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_docs_npm"
  mkdir -p "${tmpdir}"
  create_claude_settings "${tmpdir}"

  use_php="y"
  use_shell="y"
  use_nodejs="n"
  use_docs="y"
  use_docker="y"

  pushd "${tmpdir}" >/dev/null || return 1
  process_claude_settings
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/.claude/settings.json" "npm:"
}

@test "process_claude_settings removes npm when neither NodeJS nor docs is selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_no_npm"
  mkdir -p "${tmpdir}"
  create_claude_settings "${tmpdir}"

  use_php="y"
  use_shell="y"
  use_nodejs="n"
  use_docs="n"
  use_docker="y"

  pushd "${tmpdir}" >/dev/null || return 1
  process_claude_settings
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/.claude/settings.json" "npm:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "composer:"
}

@test "process_claude_settings is a no-op when the settings file is absent" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_absent"
  mkdir -p "${tmpdir}"

  use_php="n"

  pushd "${tmpdir}" >/dev/null || return 1
  run process_claude_settings
  popd >/dev/null || return 1

  assert_success
  assert_file_not_exists "${tmpdir}/.claude/settings.json"
}

@test "parse_args --ref sets the bootstrap ref" {
  parse_args --ref=1.2.3
  assert_equal "${archive_ref}" "1.2.3"
}

@test "template_present detects the .scaffold directory" {
  local tmpdir="${BATS_TEST_TMPDIR}/template_present"
  mkdir -p "${tmpdir}/.scaffold"

  pushd "${tmpdir}" >/dev/null || return 1
  run template_present
  popd >/dev/null || return 1

  assert_success
}

@test "template_present fails when .scaffold is absent" {
  local tmpdir="${BATS_TEST_TMPDIR}/template_absent"
  mkdir -p "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  run template_present
  popd >/dev/null || return 1

  assert_failure
}

@test "dir_is_empty is true for an empty directory" {
  local tmpdir="${BATS_TEST_TMPDIR}/empty"
  mkdir -p "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  run dir_is_empty
  popd >/dev/null || return 1

  assert_success
}

@test "dir_is_empty is false when a dotfile is present" {
  local tmpdir="${BATS_TEST_TMPDIR}/dotfile"
  mkdir -p "${tmpdir}"
  touch "${tmpdir}/.hidden"

  pushd "${tmpdir}" >/dev/null || return 1
  run dir_is_empty
  popd >/dev/null || return 1

  assert_failure
}

@test "resolve_archive_url prefers SCAFFOLD_ARCHIVE_URL" {
  SCAFFOLD_ARCHIVE_URL="file:///tmp/local.tar.gz"
  archive_ref="1.2.3"
  run resolve_archive_url
  assert_success
  assert_equal "${output}" "file:///tmp/local.tar.gz"
}

@test "resolve_archive_url builds an archive URL from --ref" {
  SCAFFOLD_ARCHIVE_URL=""
  archive_ref="feature-x"
  run resolve_archive_url
  assert_success
  assert_equal "${output}" "https://github.com/AlexSkrypnyk/scaffold/archive/feature-x.tar.gz"
}

@test "resolve_archive_url uses the latest release tag by default" {
  SCAFFOLD_ARCHIVE_URL=""
  archive_ref=""
  curl() { echo '{"tag_name": "9.9.9"}'; }
  run resolve_archive_url
  assert_success
  assert_equal "${output}" "https://github.com/AlexSkrypnyk/scaffold/archive/refs/tags/9.9.9.tar.gz"
}

@test "resolve_archive_url falls back to main when no release is found" {
  SCAFFOLD_ARCHIVE_URL=""
  archive_ref=""
  curl() { return 1; }
  run resolve_archive_url
  assert_success
  assert_equal "${output}" "https://github.com/AlexSkrypnyk/scaffold/archive/refs/heads/main.tar.gz"
}
