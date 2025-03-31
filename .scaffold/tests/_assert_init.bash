#!/usr/bin/env bash
#
# Scaffold template assertions.
#

# This file structure should exist in every project type.
assert_files_present_common() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_exists ".editorconfig"
  assert_file_exists ".gitattributes"
  assert_file_exists ".gitignore"
  assert_file_contains ".gitignore" "/.build"
  assert_file_not_contains ".gitignore" "/coverage"
  assert_file_exists "README.md"
  assert_file_not_exists "README.dist.md"
  assert_file_exists "logo.png"
  assert_file_not_exists "logo.tmp.png"

  assert_file_not_exists "LICENSE"
  assert_file_not_exists ".github/workflows/scaffold-test.yml"
  assert_file_not_exists ".github/workflows/scaffold-release-docs.yml"
  assert_dir_not_exists ".scaffold"
  assert_dir_exists "tests"

  # Assert that documentation was processed correctly.
  assert_file_not_contains README.md "Generic project scaffold template"
  assert_file_not_contains README.md "META"
  assert_file_contains README.md "_This repository was created using the [force-crystal](https://getforce-crystal.dev/) project template_"

  # Assert that .gitattributes were processed correctly.
  assert_file_contains ".gitattributes" "/.editorconfig"
  assert_file_not_contains ".gitattributes" "# /.editorconfig"
  assert_file_contains ".gitattributes" "/.gitattributes"
  assert_file_not_contains ".gitattributes" "# /.gitattributes"
  assert_file_contains ".gitattributes" "/.github"
  assert_file_not_contains ".gitattributes" "# /.github"
  assert_file_contains ".gitattributes" "/.gitignore"
  assert_file_not_contains ".gitattributes" "# /.gitignore"
  assert_file_not_contains ".gitattributes" "# Uncomment the lines below in your project (or use init.sh script)."

  assert_file_not_contains "docs/index.md" "Welcome to the documentation for"
  assert_file_not_contains "docs/documentation.md" "You may re-use the configuration"
  assert_file_not_exists "docs/static/img/init.gif"

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

  assert_file_contains ".gitattributes" "/tests"
  assert_file_contains ".gitattributes" "/phpcs.xml"
  assert_file_contains ".gitattributes" "/phpmd.xml"
  assert_file_contains ".gitattributes" "/phpstan.neon"
  assert_file_contains ".gitattributes" "/phpunit.xml"

  assert_file_not_contains ".gitattributes" "# /tests"
  assert_file_not_contains ".gitattributes" "# /phpcs.xml"
  assert_file_not_contains ".gitattributes" "# /phpmd.xml"
  assert_file_not_contains ".gitattributes" "# /phpstan.neon"
  assert_file_not_contains ".gitattributes" "# /phpunit.xml"
  assert_file_not_contains ".gitattributes" "# /rector.php"

  assert_file_exists ".github/workflows/test-php.yml"
  assert_file_exists ".github/workflows/release-php.yml"

  assert_file_contains "README.md" "composer"

  assert_file_exists "phpcs.xml"
  assert_file_exists "phpmd.xml"
  assert_file_exists "phpstan.neon"
  assert_file_exists "phpunit.xml"
  assert_file_exists "rector.php"
  assert_dir_exists "tests/phpunit"

  assert_dir_not_contains_string "${dir}" "YourNamespace"
  assert_dir_contains_string "${dir}" "YodasHut"

  popd >/dev/null || exit 1
}

assert_files_absent_php() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists "composer.json"
  assert_file_not_exists "composer.json"

  assert_file_not_contains ".gitignore" "/vendor"
  assert_file_not_contains ".gitignore" "/composer.lock"

  assert_file_not_contains ".gitattributes" "/phpcs.xml"
  assert_file_not_contains ".gitattributes" "/phpmd.xml"
  assert_file_not_contains ".gitattributes" "/phpstan.neon"
  assert_file_not_contains ".gitattributes" "/phpunit.xml"
  assert_file_not_contains ".gitattributes" "/rector.php"

  assert_file_not_exists ".github/workflows/test-php.yml"
  assert_file_not_exists ".github/workflows/release-php.yml"

  assert_file_not_contains "README.md" "composer"

  assert_file_not_exists "phpcs.xml"
  assert_file_not_exists "phpmd.xml"
  assert_file_not_exists "phpstan.neon"
  assert_file_not_exists "phpunit.xml"
  assert_file_not_exists "rector.php"
  assert_dir_not_exists "tests/phpunit"

  assert_files_absent_php_command "${dir}"
  assert_files_absent_php_command_build "${dir}"
  assert_files_absent_php_script "${dir}"

  popd >/dev/null || exit 1
}

assert_files_present_php_command() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_exists force-crystal
  assert_dir_exists src

  assert_file_exists tests/phpunit/Functional/ApplicationFunctionalTestCase.php
  assert_file_exists tests/phpunit/Functional/JokeCommandTest.php
  assert_file_exists tests/phpunit/Functional/SayHelloCommandTest.php

  assert_file_contains "phpcs.xml" "<file>src</file>"
  assert_file_contains "phpstan.neon" "- src"
  assert_file_contains "phpunit.xml" "<directory>src</directory>"
  assert_dir_not_contains_string "${dir}" "php-command"

  assert_file_contains "composer.json" '"force-crystal"'

  popd >/dev/null || exit 1
}

assert_files_absent_php_command() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists php-command
  assert_dir_not_exists src
  assert_file_not_exists tests/phpunit/Functional/ApplicationFunctionalTestCase.php
  assert_file_not_exists tests/phpunit/Functional/JokeCommandTest.php
  assert_file_not_exists tests/phpunit/Functional/SayHelloCommandTest.php

  assert_file_not_contains "phpcs.xml" "<file>src</file>"
  assert_file_not_contains "phpstan.neon" "- src"
  assert_file_not_contains "phpunit.xml" "<directory>src</directory>"

  assert_file_not_contains "composer.json" "php-command"
  assert_dir_not_contains_string "${dir}" "php-command"

  popd >/dev/null || exit 1
}

assert_files_present_php_command_build() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_exists "box.json"
  assert_file_contains "box.json" ".build/force-crystal.phar"

  assert_file_contains ".github/workflows/release-php.yml" "Build PHAR"
  assert_file_contains ".github/workflows/release-php.yml" "Test PHAR"
  assert_file_contains ".github/workflows/release-php.yml" "force-crystal.phar"

  popd >/dev/null || exit 1
}

assert_files_absent_php_command_build() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists "box.json"

  assert_file_not_contains ".github/workflows/release-php.yml" "Build PHAR"
  assert_file_not_contains ".github/workflows/release-php.yml" "Test PHAR"
  assert_file_not_contains ".github/workflows/release-php.yml" "php-command.phar"

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

  assert_file_contains ".github/workflows/release-php.yml" "force-crystal"

  assert_file_contains "phpcs.xml" "force-crystal.php"
  assert_file_contains "phpstan.neon" "force-crystal"
  assert_file_contains "phpunit.xml" "force-crystal"

  assert_file_contains "composer.json" '"cp force-crystal force-crystal.php && phpcs; rm force-crystal.php",'
  assert_file_contains "composer.json" '"force-crystal"'

  assert_dir_not_contains_string "${dir}" "php-script"

  popd >/dev/null || exit 1
}

assert_files_absent_php_script() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists php-script
  assert_file_not_exists tests/phpunit/Unit/ExampleScriptUnitTest.php
  assert_file_not_exists tests/phpunit/Unit/ScriptUnitTestCase.php
  assert_file_not_exists tests/phpunit/Functional/ScriptFunctionalTestCase.php
  assert_file_not_exists tests/phpunit/Functional/ExampleScriptFunctionalTest.php

  assert_file_not_contains ".github/workflows/release-php.yml" "php-script"

  assert_file_not_contains "phpcs.xml" "force-crystal.php"
  assert_file_not_contains "phpstan.neon" "force-crystal"
  assert_file_not_contains "phpunit.xml" "force-crystal"

  assert_file_not_contains "composer.json" '"cp force-crystal force-crystal.php && phpcs; rm force-crystal.php",'
  assert_file_not_contains "composer.json" '"cp force-crystal force-crystal.php && phpcbf; rm force-crystal.php",'
  assert_file_not_contains "composer.json" '"force-crystal",'

  assert_dir_not_contains_string "${dir}" "php-script"

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

  assert_file_not_contains ".gitattributes" "# /.npmignore"
  assert_file_contains ".gitattributes" "/.npmignore"

  assert_file_contains ".github/workflows/test-nodejs.yml" "npm"
  assert_file_contains ".github/workflows/release-nodejs.yml" "npm"

  assert_file_contains "README.md" "npm install"

  popd >/dev/null || exit 1
}

assert_files_absent_nodejs() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists "package.json"

  assert_file_not_contains ".gitignore" "/node_modules"
  assert_file_not_contains ".gitignore" "/package-lock.json"
  assert_file_not_contains ".gitignore" "/yarn.lock"

  assert_file_not_contains ".gitattributes" "/.npmignore"

  assert_file_not_contains ".github/workflows/test-nodejs.yml" "npm"
  assert_file_not_contains ".github/workflows/release-nodejs.yml" "npm"

  assert_file_not_contains "README.md" "npm install"

  popd >/dev/null || exit 1
}

assert_files_present_shell() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_exists "force-crystal.sh"
  assert_file_exists ".github/workflows/test-shell.yml"
  assert_dir_exists "tests/bats"

  assert_file_contains "README.md" "force-crystal"

  popd >/dev/null || exit 1
}

assert_files_absent_shell() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_not_exists "force-crystal.sh"
  assert_file_not_exists ".github/workflows/test-shell.yml"
  assert_dir_not_exists "tests/bats"

  popd >/dev/null || exit 1
}

assert_files_present_docs() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_file_exists "docs/.gitignore"
  assert_file_exists "docs/docusaurus.config.js"
  assert_file_exists "docs/package.json"
  assert_file_exists "docs/package-lock.json"
  assert_file_exists "docs/README.md"
  assert_file_exists "docs/content/README.mdx"

  assert_file_exists "docs/static/README.md"

  assert_file_exists ".github/workflows/test-docs.yml"
  assert_file_exists ".github/workflows/release-docs.yml"

  assert_file_contains ".gitattributes" "/docs"
  assert_file_not_contains ".gitattributes" "# /docs"

  popd >/dev/null || exit 1
}

assert_files_absent_docs() {
  local dir="${1:-$(pwd)}"

  pushd "${dir}" >/dev/null || exit 1

  assert_dir_not_exists "docs"

  assert_file_not_exists ".github/workflows/test-docs.yml"
  assert_file_not_exists ".github/workflows/release-docs.yml"

  assert_file_not_contains ".gitattributes" "/docs"
  assert_file_not_contains ".gitattributes" "# /docs"

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
