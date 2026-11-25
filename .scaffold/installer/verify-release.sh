#!/usr/bin/env bash
##
# Verify the signed checksums of the Scaffold installer in a directory.
#
# Passes when 'SHA256SUMS.asc' is a valid signature of 'SHA256SUMS' made with
# the Scaffold signing key, and every file that 'SHA256SUMS' names matches its
# checksum. The key comes from keys.openpgp.org.
#
# @usage:
# .scaffold/installer/verify-release.sh <directory>

set -euo pipefail
[ "${SCRIPT_DEBUG-}" = "1" ] && set -x

# 'gpg --verify' accepts a signature from any key in the keyring, so the
# signing key is pinned by fingerprint.
SCAFFOLD_SIGNING_KEY_FINGERPRINT="86F077A2E80667D7CF4A3320EDEAF2FCD434756C"

SCAFFOLD_KEYSERVER="${SCAFFOLD_KEYSERVER:-hkps://keys.openpgp.org}"

main() {
  local dir="${1:-}"

  if [ -z "${dir}" ] || [ ! -d "${dir}" ]; then
    echo "Error: pass the directory that holds SHA256SUMS and SHA256SUMS.asc." >&2
    return 1
  fi

  local file
  for file in SHA256SUMS SHA256SUMS.asc; do
    if [ ! -f "${dir}/${file}" ]; then
      echo "Error: ${dir}/${file} does not exist." >&2
      return 1
    fi
  done

  if ! gpg --batch --quiet --keyserver "${SCAFFOLD_KEYSERVER}" --recv-keys "${SCAFFOLD_SIGNING_KEY_FINGERPRINT}"; then
    echo "Error: could not fetch the Scaffold signing key ${SCAFFOLD_SIGNING_KEY_FINGERPRINT} from ${SCAFFOLD_KEYSERVER}." >&2
    return 1
  fi

  local status
  status="$(gpg --batch --status-fd 1 --verify "${dir}/SHA256SUMS.asc" "${dir}/SHA256SUMS" 2>/dev/null || true)"

  if ! grep -q "^\[GNUPG:\] VALIDSIG ${SCAFFOLD_SIGNING_KEY_FINGERPRINT} " <<<"${status}"; then
    echo "Error: ${dir}/SHA256SUMS is not signed by the Scaffold signing key ${SCAFFOLD_SIGNING_KEY_FINGERPRINT}." >&2
    return 1
  fi

  echo "SHA256SUMS is signed by the Scaffold signing key ${SCAFFOLD_SIGNING_KEY_FINGERPRINT}."

  if ! (cd "${dir}" && sha256sum -c SHA256SUMS); then
    echo "Error: a file in ${dir} does not match its checksum in SHA256SUMS." >&2
    return 1
  fi
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
