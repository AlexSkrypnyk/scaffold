#!/usr/bin/env bats
#
# Unit tests for .scaffold/installer/install-latest.sh.
#
# shellcheck disable=SC2154

load _helper
load "../../installer/install-latest.sh"

# Write a stand-in installer and point the stub at it.
#
# @param $1 string Body of the stand-in installer.
fake_installer() {
  local path="${BATS_TEST_TMPDIR}/install.sh"
  printf '%s\n' "${1}" >"${path}"
  SCAFFOLD_INSTALLER_URL="file://${path}"
}

@test "SCAFFOLD_INSTALLER_URL defaults to the installer of the latest release" {
  run env -u SCAFFOLD_INSTALLER_URL bash -c 'source .scaffold/installer/install-latest.sh; echo "${SCAFFOLD_INSTALLER_URL}"'
  assert_success
  assert_output "https://github.com/AlexSkrypnyk/scaffold/releases/latest/download/install.sh"
}

@test "SCAFFOLD_INSTALLER_URL can be overridden" {
  run env SCAFFOLD_INSTALLER_URL=https://example.com/install.sh bash -c 'source .scaffold/installer/install-latest.sh; echo "${SCAFFOLD_INSTALLER_URL}"'
  assert_success
  assert_output "https://example.com/install.sh"
}

@test "main passes every argument to the downloaded installer" {
  fake_installer 'echo "count=$#"; for arg in "$@"; do echo "arg=${arg}"; done'
  run main --namespace=AcmeApp "--author=Jane Doe" github
  assert_success
  assert_output "count=3
arg=--namespace=AcmeApp
arg=--author=Jane Doe
arg=github"
}

@test "main runs the downloaded installer as a piped script" {
  fake_installer 'echo "source=${BASH_SOURCE[0]:-piped}"'
  run main
  assert_success
  assert_output "source=piped"
}

@test "main exits with the exit status of the downloaded installer" {
  fake_installer 'echo "failing"; exit 3'
  run main
  assert_equal "${status}" 3
  assert_output "failing"
}

@test "main fails when the installer cannot be downloaded" {
  SCAFFOLD_INSTALLER_URL="file://${BATS_TEST_TMPDIR}/missing.sh"
  run main
  assert_failure
  assert_output_contains "Error: failed to download the Scaffold installer from file://${BATS_TEST_TMPDIR}/missing.sh."
}

@test "main fails when the downloaded installer is empty" {
  : >"${BATS_TEST_TMPDIR}/empty.sh"
  SCAFFOLD_INSTALLER_URL="file://${BATS_TEST_TMPDIR}/empty.sh"
  run main
  assert_failure
  assert_output_contains "Error: failed to download the Scaffold installer"
}

@test "main runs the repository installer" {
  SCAFFOLD_INSTALLER_URL="file://${PWD}/install.sh"
  run main --version
  assert_success
  assert_output "dev"
}

@test "the stub runs the installer when piped into bash" {
  fake_installer 'echo "ran with $*"'
  run bash -c "SCAFFOLD_INSTALLER_URL='${SCAFFOLD_INSTALLER_URL}' bash -s -- --help <.scaffold/installer/install-latest.sh"
  assert_success
  assert_output "ran with --help"
}
