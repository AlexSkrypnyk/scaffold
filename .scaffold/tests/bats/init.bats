#!/usr/bin/env bats
#
# Unit tests for init.sh.
#
# Variables under test are assigned by the sourced init.sh, which shellcheck
# does not follow, so disable "unassigned variable" (SC2154) here.
# shellcheck disable=SC2034,SC2154

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

  pushd "${tmpdir}" >/dev/null || exit 1
  remove_php
  popd >/dev/null || exit 1

  assert_file_contains "${tmpdir}/renovate.json" '"matchManagers": ["npm"]'
  assert_file_not_contains "${tmpdir}/renovate.json" '"composer"'
  assert_file_not_contains "${tmpdir}/renovate.json" '"matchDepNames": ["php"]'
  assert_file_contains "${tmpdir}/renovate.json" '"matchDepNames": ["node", "yarn"]'
}

@test "remove_nodejs removes npm from renovate matchManagers and node/yarn language rule" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_nodejs"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || exit 1
  remove_nodejs
  popd >/dev/null || exit 1

  assert_file_contains "${tmpdir}/renovate.json" '"matchManagers": ["composer"]'
  assert_file_not_contains "${tmpdir}/renovate.json" '"npm"'
  assert_file_not_contains "${tmpdir}/renovate.json" '"matchDepNames": ["node", "yarn"]'
  assert_file_contains "${tmpdir}/renovate.json" '"matchDepNames": ["php"]'
}

@test "remove_php then remove_nodejs empties matchManagers" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_both"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || exit 1
  remove_php
  remove_nodejs
  popd >/dev/null || exit 1

  assert_file_contains "${tmpdir}/renovate.json" '"matchManagers": []'
}

@test "cleanup_renovate_managers removes empty matchManagers block" {
  local tmpdir="${BATS_TEST_TMPDIR}/cleanup"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || exit 1
  remove_php
  remove_nodejs
  cleanup_renovate_managers
  popd >/dev/null || exit 1

  assert_file_not_contains "${tmpdir}/renovate.json" '"matchManagers"'
  assert_file_not_contains "${tmpdir}/renovate.json" '"matchUpdateTypes"'
  assert_file_contains "${tmpdir}/renovate.json" '"matchPackageNames"'
}

@test "cleanup_renovate_managers no-ops when matchManagers is not empty" {
  local tmpdir="${BATS_TEST_TMPDIR}/cleanup_noop"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || exit 1
  remove_php
  cleanup_renovate_managers
  popd >/dev/null || exit 1

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
