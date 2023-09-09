#!/usr/bin/env bash

# These files should exist in every project.
assert_files_present_common() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_exists ".github/workflows/test.yml"
  assert_file_exists ".editorconfig"
  assert_file_exists ".gitattributes"
  assert_file_exists ".gitignore"
  assert_file_contains ".gitignore" ".build"
  assert_file_exists "README.md"
  assert_file_not_exists "LICENSE"
  assert_file_not_exists ".github/workflows/scaffold-test.yml"
  assert_dir_not_exists "scaffold_tests"
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

assert_files_present_php() {
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
  assert_file_contains ".github/workflows/release.yml" "composer"
  assert_file_contains "README.md" "composer"
  assert_file_exists "phpcs.xml"
  assert_file_exists "phpmd.xml"
  assert_file_exists "phpstan.neon"

  popd >/dev/null || exit 1
}

assert_files_present_php_command() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_exists star-wars
  assert_dir_exists src

  assert_dir_exists tests/phpunit/Unit/Command

  popd >/dev/null || exit 1
}

assert_files_absent_php_command() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists template-command-script
  assert_dir_not_exists src
  assert_dir_not_exists tests/phpunit/Unit/Command

  popd >/dev/null || exit 1
}

assert_files_present_php_command_build() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_exists "box.json"
  assert_file_contains ".github/workflows/release.yml" "Build and test"
  assert_file_contains ".github/workflows/release.yml" "template-command-script.phar"

  popd >/dev/null || exit 1
}

assert_files_absent_php_command_build() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists "box.json"
  assert_file_not_contains ".github/workflows/release.yml" "Build and test"
  assert_file_not_contains ".github/workflows/release.yml" "template-command-script.phar"

  popd >/dev/null || exit 1
}

assert_files_present_php_script() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_exists star-wars
  assert_file_exists tests/phpunit/Unit/ExampleScriptUnitTest.php
  assert_file_exists tests/phpunit/Unit/ScriptUnitTestCase.php

  assert_file_contains ".github/workflows/release.yml" "template-simple-script"

  popd >/dev/null || exit 1
}

assert_files_absent_php_script() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists template-simple-script
  assert_file_not_exists tests/phpunit/Unit/ExampleScriptUnitTest.php
  assert_file_not_exists tests/phpunit/Unit/ScriptUnitTestCase.php

  assert_not_contains ".github/workflows/release.yml" "template-simple-script"

  popd >/dev/null || exit 1
}

assert_files_absent_php() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists "composer.json"
  assert_file_not_exists "composer.json"
  assert_file_not_contains ".gitignore" "/vendor"
  assert_file_not_contains ".gitignore" "/composer.lock"
  assert_file_not_contains ".github/workflows/test.yml" "composer"
  assert_file_not_contains ".github/workflows/release.yml" "composer"
  assert_file_not_contains "README.md" "composer"
  assert_file_not_exists "phpcs.xml"
  assert_file_not_exists "phpmd.xml"
  assert_file_not_exists "phpstan.neon"
  assert_dir_not_exists "tests/phpunit"

  assert_files_absent_php_command "${dir}"
  assert_files_absent_php_command_build "${dir}"
  assert_files_absent_php_script "${dir}"

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
  assert_file_contains ".github/workflows/release.yml" "npm"
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
  assert_file_not_contains ".github/workflows/release.yml" "npm"
  assert_file_not_contains "README.md" "npm"

  popd >/dev/null || exit 1
}
