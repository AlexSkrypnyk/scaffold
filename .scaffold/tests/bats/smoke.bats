#!/usr/bin/env bats
#
# Smoke tests.
#
# shellcheck disable=SC2030,SC2031,SC2129

load _helper

# ./.scaffold/tests/node_modules/.bin/bats --no-tempdir-cleanup --formatter tap --filter-tags smoke .scaffold/tests
# bats test_tags=smoke
@test "Smoke" {
  assert_contains "scaffold" "${BUILD_DIR}"
}
