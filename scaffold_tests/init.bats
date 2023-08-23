#!/usr/bin/env bats
#
# Test initation into empty directory.
#
# shellcheck disable=SC2030,SC2031,SC2129

load _helper.bash

# The name of the script to run.
export SCRIPT_FILE="init.sh"

@test "Variables" {
  assert_contains "scaffold" "${BUILD_DIR}"
}

@test "Init, defaults" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use Composer
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # remove init script
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_present_composer "${BUILD_DIR}"

  assert_files_present_nodejs "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, no composer" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "n"         # use Composer
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # remove init script
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_absent_composer "${BUILD_DIR}"

  assert_files_present_nodejs "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, no nodejs" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use Composer
    "n"         # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # remove init script
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"

  assert_files_present_composer "${BUILD_DIR}"

  assert_files_absent_nodejs "${BUILD_DIR}"

  assert_output_contains "Initialization complete."
}

@test "Init, no release drafter" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use Composer
    "nothing"   # use NodeJS
    "n"         # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # remove init script
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_composer "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"

  assert_file_not_exists ".github/release-drafter.yml"
  assert_file_not_exists ".github/workflows/draft-release.yml"

  assert_output_contains "Initialization complete."
}

@test "Init, no PR auto-assign" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use Composer
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "n"         # use GitHub pr auto-assign
    "nothing"   # use GitHub funding
    "nothing"   # remove init script
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_composer "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"

  assert_file_not_exists ".github/auto-assign-pr-author.yml"

  assert_output_contains "Initialization complete."
}

@test "Init, no funding" {
  answers=(
    "lucasfilm" # organisation
    "star-wars" # project
    "Jane Doe"  # author
    "nothing"   # use Composer
    "nothing"   # use NodeJS
    "nothing"   # use GitHub release drafter
    "nothing"   # use GitHub pr auto-assign
    "n"         # use GitHub funding
    "nothing"   # remove init script
  )
  output=$(run_script_interactive "${answers[@]}")

  assert_output_contains "Please follow the prompts to adjust your project configuration"

  assert_files_present_common "${BUILD_DIR}"
  assert_files_present_composer "${BUILD_DIR}"
  assert_files_present_nodejs "${BUILD_DIR}"

  assert_file_not_exists ".github/FUNDING.yml"

  assert_output_contains "Initialization complete."
}

################################################################################
#                               ASSERTIONS                                     #
################################################################################

# These files should exist in every project.
assert_files_present_common() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_exists ".github/workflows/test.yml"
  assert_file_exists ".editorconfig"
  assert_file_exists ".gitattributes"
  assert_file_exists ".gitignore"
  assert_file_exists "README.md"
  assert_file_not_exists "LICENSE"
  assert_file_not_exists ".github/workflows/scaffold_test.yml"
  assert_dir_exists "tests"

  # Assert that documentation was processed correctly.
  assert_file_not_contains README.md "Generic project scaffold template"
  assert_file_not_contains README.md "META"

  # Assert that .gitattributes were processed correctly.
  assert_file_contains ".gitattributes" ".editorconfig"
  assert_file_not_contains ".gitattributes" "# .editorconfig"
  assert_file_contains ".gitattributes" ".gitattributes"
  assert_file_not_contains ".gitattributes" "# .gitattributes"
  assert_file_contains ".gitattributes" ".github"
  assert_file_not_contains ".gitattributes" "# .github"
  assert_file_contains ".gitattributes" ".gitignore"
  assert_file_not_contains ".gitattributes" "# .gitignore"
  assert_file_contains ".gitattributes" "tests"
  assert_file_not_contains ".gitattributes" "# tests"
  assert_file_not_contains ".gitattributes" "# Uncomment the lines below in your project (or use init.sh script)."

  popd >/dev/null || exit 1
}

assert_files_present_composer() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_contains "composer.json" '"name": "lucasfilm/star-wars"'
  assert_file_contains "composer.json" '"description": "Provides star-wars functionality."'
  assert_file_contains "composer.json" '"name": "Jane Doe"'
  assert_file_contains "composer.json" '"homepage": "https://github.com/lucasfilm/star-wars"'
  assert_file_contains "composer.json" '"issues": "https://github.com/lucasfilm/star-wars/issues"'
  assert_file_contains "composer.json" '"source": "https://github.com/lucasfilm/star-wars"'
  assert_file_contains ".gitignore" "/vendor"
  assert_file_contains ".gitignore" "/composer.lock"
  assert_file_contains ".github/workflows/test.yml" "composer"
  assert_file_contains "README.md" "composer"

  popd >/dev/null || exit 1
}

assert_files_absent_composer() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists "composer.json"
  assert_file_not_contains ".gitignore" "/vendor"
  assert_file_not_contains ".gitignore" "/composer.lock"
  assert_file_not_contains ".github/workflows/test.yml" "composer"
  assert_file_not_contains "README.md" "composer"

  popd >/dev/null || exit 1
}

assert_files_present_nodejs() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_contains "package.json" '"name": "@lucasfilm/star-wars"'
  assert_file_contains "package.json" '"description": "Provides star-wars functionality."'
  assert_file_contains "package.json" '"name": "Jane Doe"'
  assert_file_contains "package.json" '"bugs": "https://github.com/lucasfilm/star-wars/issues"'
  assert_file_contains "package.json" '"repository": "github:lucasfilm/star-wars"'
  assert_file_contains ".gitignore" "/node_modules"
  assert_file_contains ".gitignore" "/package-lock.json"
  assert_file_contains ".gitignore" "/yarn.lock"
  assert_file_contains ".github/workflows/test.yml" "npm"
  assert_file_contains "README.md" "npm"

  popd >/dev/null || exit 1
}

assert_files_absent_nodejs() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists "package.json"
  assert_file_not_contains ".gitignore" "/node_modules"
  assert_file_not_contains ".gitignore" "/package-lock.json"
  assert_file_not_contains ".gitignore" "/yarn.lock"
  assert_file_not_contains ".github/workflows/test.yml" "npm"
  assert_file_not_contains "README.md" "npm"

  popd >/dev/null || exit 1
}
