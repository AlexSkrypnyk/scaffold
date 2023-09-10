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

  assert_file_contains "composer.json" '"name": "yodasHut/force-crystal"'
  assert_file_contains "composer.json" '"description": "Provides force-crystal functionality."'
  assert_file_contains "composer.json" '"name": "Jane Doe"'
  assert_file_contains "composer.json" '"homepage": "https://github.com/yodasHut/force-crystal"'
  assert_file_contains "composer.json" '"issues": "https://github.com/yodasHut/force-crystal/issues"'
  assert_file_contains "composer.json" '"source": "https://github.com/yodasHut/force-crystal"'
  assert_file_contains ".gitignore" "/vendor"
  assert_file_contains ".gitignore" "/composer.lock"
  assert_file_contains ".github/workflows/test.yml" "composer"
  assert_file_contains ".github/workflows/release.yml" "composer"
  assert_file_contains "README.md" "composer"
  assert_file_exists "phpcs.xml"
  assert_file_exists "phpmd.xml"
  assert_file_exists "phpstan.neon"

  assert_dir_not_contains_string "${dir}" "YourNamespace"
  assert_dir_contains_string "${dir}" "YodasHut"

  popd >/dev/null || exit 1
}

assert_files_present_php_command() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_exists force-crystal
  assert_dir_exists src

  assert_dir_exists tests/phpunit/Unit/Command

  assert_file_contains "phpcs.xml" "<file>src</file>"
  assert_file_contains "phpstan.neon" "- src"
  assert_file_contains "phpunit.xml" "<directory>src</directory>"
  assert_dir_not_contains_string "${dir}" "template-command-script"

  assert_file_contains "composer.json" '"force-crystal"'

  popd >/dev/null || exit 1
}

assert_files_absent_php_command() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists template-command-script
  assert_dir_not_exists src
  assert_dir_not_exists tests/phpunit/Unit/Command

  assert_file_not_contains "phpcs.xml" "<file>src</file>"
  assert_file_not_contains "phpstan.neon" "- src"
  assert_file_not_contains "phpunit.xml" "<directory>src</directory>"

  assert_file_not_contains "composer.json" "template-command-script"
  assert_dir_not_contains_string "${dir}" "template-command-script"

  popd >/dev/null || exit 1
}

assert_files_present_php_command_build() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_exists "box.json"
  assert_file_contains "box.json" ".build/force-crystal.phar"
  assert_file_contains ".github/workflows/release.yml" "Build and test"
  assert_file_contains ".github/workflows/release.yml" "force-crystal.phar"

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

  assert_file_exists force-crystal
  assert_file_exists tests/phpunit/Unit/ExampleScriptUnitTest.php
  assert_file_exists tests/phpunit/Unit/ScriptUnitTestCase.php
  assert_file_exists tests/phpunit/Functional/ScriptFunctionalTestCase.php
  assert_file_exists tests/phpunit/Functional/ExampleScriptFunctionalTest.php

  assert_file_contains ".github/workflows/release.yml" "force-crystal"

  assert_file_contains "phpcs.xml" "force-crystal.php"
  assert_file_contains "phpstan.neon" "force-crystal.php"
  assert_file_contains "phpunit.xml" "force-crystal"

  assert_file_contains "composer.json" '"cp force-crystal force-crystal.php",'
  assert_file_contains "composer.json" '"rm force-crystal.php"'
  assert_file_contains "composer.json" '"phpstan",'
  assert_file_contains "composer.json" '"phpstan",'
  assert_file_contains "composer.json" '"force-crystal"'

  assert_dir_not_contains_string "${dir}" "template-simple-script"

  popd >/dev/null || exit 1
}

assert_files_absent_php_script() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists template-simple-script
  assert_file_not_exists tests/phpunit/Unit/ExampleScriptUnitTest.php
  assert_file_not_exists tests/phpunit/Unit/ScriptUnitTestCase.php
  assert_file_not_exists tests/phpunit/Functional/ScriptFunctionalTestCase.php
  assert_file_not_exists tests/phpunit/Functional/ExampleScriptFunctionalTest.php

  assert_file_not_contains ".github/workflows/release.yml" "template-simple-script"

  assert_file_not_contains "phpcs.xml" "force-crystal.php"
  assert_file_not_contains "phpstan.neon" "force-crystal.php"
  assert_file_not_contains "phpunit.xml" "force-crystal"

  assert_file_not_contains "composer.json" '"cp force-crystal force-crystal.php",'
  assert_file_not_contains "composer.json" '"rm force-crystal.php"'
  assert_file_not_contains "composer.json" '"phpstan",'
  assert_file_not_contains "composer.json" '"force-crystal",'

  assert_dir_not_contains_string "${dir}" "template-simple-script"

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

  assert_file_contains "package.json" '"name": "@yodasHut/force-crystal"'
  assert_file_contains "package.json" '"description": "Provides force-crystal functionality."'
  assert_file_contains "package.json" '"name": "Jane Doe"'
  assert_file_contains "package.json" '"bugs": "https://github.com/yodasHut/force-crystal/issues"'
  assert_file_contains "package.json" '"repository": "github:yodasHut/force-crystal"'
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

assert_workflow_php() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  composer install
  composer lint
  composer test

  popd >/dev/null || exit 1
}

assert_workflow_php_command_build() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  composer build

  popd >/dev/null || exit 1
}