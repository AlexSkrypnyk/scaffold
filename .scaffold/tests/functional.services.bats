#!/usr/bin/env bats
#
# Functional test for additional services.
#
# shellcheck disable=SC2030,SC2031,SC2034

load _helper

BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1

@test "Renovate - Check config" {
  run npx --yes --package renovate -- renovate-config-validator --strict
  assert_success
}
