#!/usr/bin/env bats
#
# Unit tests for .scaffold/installer/verify-release.sh.
#
# The 'gpg' and 'sha256sum' mocks are invoked indirectly by main() under 'run'
# and cannot be traced statically.
# shellcheck disable=SC2154,SC2329

load _helper
load "../../installer/verify-release.sh"

# Create a release directory with both checksum files.
release_dir() {
  local dir="${BATS_TEST_TMPDIR}/release"
  mkdir -p "${dir}"
  touch "${dir}/SHA256SUMS" "${dir}/SHA256SUMS.asc"
  echo "${dir}"
}

# Make 'gpg --verify' report a valid signature by a key.
#
# @param $1 string Fingerprint of the signing key.
gpg_signed_by() {
  GPG_FINGERPRINT="${1}"
  gpg() {
    case " $* " in
      *" --import "*) echo "gpg import $*" >>"${BATS_TEST_TMPDIR}/gpg.log" ;;
      *" --verify "*) echo "[GNUPG:] VALIDSIG ${GPG_FINGERPRINT} 2026-11-10 1762732800 0 4 0 1 10 00 ${GPG_FINGERPRINT}" ;;
    esac
  }
}

@test "SCAFFOLD_PUBLIC_KEY points at the published key" {
  assert_equal "${SCAFFOLD_PUBLIC_KEY}" "$(pwd)/install-key.asc"
  assert_file_exists "${SCAFFOLD_PUBLIC_KEY}"
}

@test "the published key has the pinned fingerprint" {
  run gpg --show-keys --with-colons "${SCAFFOLD_PUBLIC_KEY}"
  assert_success
  assert_output_contains "fpr:::::::::${SCAFFOLD_SIGNING_KEY_FINGERPRINT}:"
}

@test "the script runs main when executed" {
  run .scaffold/installer/verify-release.sh
  assert_failure
  assert_output_contains "Error: pass the directory that holds SHA256SUMS and SHA256SUMS.asc."
}

@test "main fails without a directory" {
  run main
  assert_failure
  assert_output_contains "Error: pass the directory that holds SHA256SUMS and SHA256SUMS.asc."
}

@test "main fails on a missing directory" {
  run main "${BATS_TEST_TMPDIR}/missing"
  assert_failure
  assert_output_contains "Error: pass the directory"
}

@test "main fails without SHA256SUMS.asc" {
  local dir
  dir="$(release_dir)"
  rm "${dir}/SHA256SUMS.asc"
  run main "${dir}"
  assert_failure
  assert_output_contains "Error: ${dir}/SHA256SUMS.asc does not exist."
}

@test "main fails without SHA256SUMS" {
  local dir
  dir="$(release_dir)"
  rm "${dir}/SHA256SUMS"
  run main "${dir}"
  assert_failure
  assert_output_contains "Error: ${dir}/SHA256SUMS does not exist."
}

@test "main fails on a signature by another key" {
  local dir
  dir="$(release_dir)"
  gpg_signed_by "0000000000000000000000000000000000000000"
  sha256sum() { echo "sha256sum must not be called"; }
  run main "${dir}"
  assert_failure
  assert_output_contains "Error: ${dir}/SHA256SUMS is not signed by the Scaffold signing key ${SCAFFOLD_SIGNING_KEY_FINGERPRINT}."
  assert_output_not_contains "sha256sum must not be called"
}

@test "main fails on an invalid signature" {
  local dir
  dir="$(release_dir)"
  gpg() {
    case " $* " in
      *" --verify "*)
        echo "[GNUPG:] BADSIG ${SCAFFOLD_SIGNING_KEY_FINGERPRINT}"
        return 1
        ;;
    esac
  }
  run main "${dir}"
  assert_failure
  assert_output_contains "is not signed by the Scaffold signing key"
}

@test "main fails on a checksum mismatch" {
  local dir
  dir="$(release_dir)"
  gpg_signed_by "${SCAFFOLD_SIGNING_KEY_FINGERPRINT}"
  sha256sum() {
    echo "install.sh: FAILED"
    return 1
  }
  run main "${dir}"
  assert_failure
  assert_output_contains "install.sh: FAILED"
  assert_output_contains "Error: a file in ${dir} does not match its checksum in SHA256SUMS."
}

@test "main passes on a valid signature and matching checksums" {
  local dir
  dir="$(release_dir)"
  gpg_signed_by "${SCAFFOLD_SIGNING_KEY_FINGERPRINT}"
  sha256sum() { echo "install.sh: OK (in $(pwd))"; }
  run main "${dir}"
  assert_success
  assert_output_contains "SHA256SUMS is signed by the Scaffold signing key ${SCAFFOLD_SIGNING_KEY_FINGERPRINT}."
  assert_output_contains "install.sh: OK (in ${dir})"
  assert_file_contains "${BATS_TEST_TMPDIR}/gpg.log" "--import ${SCAFFOLD_PUBLIC_KEY}"
}
