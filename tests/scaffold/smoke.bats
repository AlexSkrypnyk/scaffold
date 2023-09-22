#!/usr/bin/env bats
#
# Test initation into empty directory.
#
# shellcheck disable=SC2030,SC2031,SC2129

load _helper

export BATS_COVERAGE_ENABLED=1

# BATS_COVERAGE_DIR=$(pwd)/coverage ./tests/scaffold/node_modules/.bin/bats --no-tempdir-cleanup --formatter tap --filter-tags smoke tests/scaffold
# bats test_tags=smoke
@test "Smoke" {
  assert_contains "scaffold" "${BUILD_DIR}"
}
