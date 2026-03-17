#!/usr/bin/env bats
#
# Unit tests for init.sh.
#
# shellcheck disable=SC2034

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
