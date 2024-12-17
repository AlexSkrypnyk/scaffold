#!/usr/bin/env bats
#
# Functional test for Composer scripts.
#
# shellcheck disable=SC2030,SC2031,SC2034

load _helper

BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

@test "Composer scripts - lint" {
  assert_dir_not_exists "vendor"
  assert_file_not_exists "composer.lock"
  run composer install
  assert_success
  assert_dir_exists "vendor"
  assert_file_exists "composer.lock"

  run composer lint
  assert_success

  run composer reset
  assert_success
  assert_dir_not_exists "vendor"
  assert_file_not_exists "composer.lock"
}

@test "Composer scripts - test" {
  assert_xdebug_enabled

  composer install

  composer_reset_env

  run composer test
  assert_success
  assert_output_contains "OK (21 tests, 32 assertions)"
  assert_dir_not_exists ".coverage-html"

  composer_reset_env

  run bash -c "XDEBUG_MODE=coverage composer test"
  assert_success
  assert_output_contains "OK (21 tests, 32 assertions)"
  assert_dir_not_exists ".coverage-html"

  composer_reset_env

  run composer test -- --group=command
  assert_success
  assert_output_contains "OK (5 tests, 6 assertions)"
  assert_dir_not_exists ".coverage-html"

  composer_reset_env

  run bash -c "XDEBUG_MODE=coverage composer test -- --group=command"
  assert_success
  assert_output_contains "OK (5 tests, 6 assertions)"
  assert_dir_not_exists ".coverage-html"
}

@test "Composer scripts - test-coverage" {
  assert_xdebug_enabled

  composer install

  composer_reset_env

  run composer test-coverage
  assert_failure
  assert_output_contains "WARNINGS!"
  assert_dir_not_exists ".coverage-html"

  composer_reset_env

  run bash -c "XDEBUG_MODE=coverage composer test-coverage"
  assert_success
  assert_output_not_contains "WARNINGS!"
  assert_output_contains "OK (21 tests, 32 assertions)"
  assert_dir_exists ".coverage-html"

  composer_reset_env

  run composer test-coverage -- --group=command
  assert_failure
  assert_output_contains "WARNINGS!"
  assert_dir_not_exists ".coverage-html"

  composer_reset_env

  run bash -c "XDEBUG_MODE=coverage composer test-coverage -- --group=command"
  assert_success
  assert_output_not_contains "WARNINGS!"
  assert_output_contains "OK (5 tests, 6 assertions)"
  assert_dir_exists ".coverage-html"
}

composer_reset_env() {
  rm -rf .coverage-html >/dev/null
  export XDEBUG_MODE=off
}

assert_xdebug_enabled() {
  run bash -c "php -v | grep -q Xdebug"
  assert_success
}
