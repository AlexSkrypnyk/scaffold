#!/usr/bin/env bash
##
# Verify the signed checksums of the Scaffold installer in a directory.
#
# Passes when 'SHA256SUMS.asc' is a valid signature of 'SHA256SUMS' made with
# the Scaffold signing key, and every file that 'SHA256SUMS' names matches its
# checksum. The key comes from '.scaffold/PUBLIC_KEY.asc'.
#
# @usage:
# .scaffold/installer/verify-release.sh <directory>

set -euo pipefail
[ "${SCRIPT_DEBUG-}" = "1" ] && set -x

# 'gpg --verify' accepts a signature from any key in the keyring, so the
# signing key is pinned by fingerprint.
SCAFFOLD_SIGNING_KEY_FINGERPRINT="755E824E80F849135F5F4043E71EDB25C4F6D89D"

SCAFFOLD_PUBLIC_KEY="${SCAFFOLD_PUBLIC_KEY:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/PUBLIC_KEY.asc}"

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

  gpg --batch --quiet --import "${SCAFFOLD_PUBLIC_KEY}"

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
