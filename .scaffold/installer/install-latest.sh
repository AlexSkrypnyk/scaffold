#!/usr/bin/env bash
##
# Download the installer of the latest Scaffold release and run it.
#
# getscaffold.dev serves this script as '/install.sh', so the one-line
# installer always runs the 'install.sh' attached to the latest GitHub
# release, the file that the release's attestation and signed 'SHA256SUMS'
# cover. Every argument passes through to that installer.
#
# @usage:
# curl -fsSL https://getscaffold.dev/install.sh | bash
# curl -fsSL https://getscaffold.dev/install.sh | bash -s -- --help
#
# Set SCAFFOLD_INSTALLER_URL to run the installer from another URL, such as
# the 'install.sh' asset of a specific release.

set -euo pipefail
[ "${SCRIPT_DEBUG-}" = "1" ] && set -x

SCAFFOLD_INSTALLER_URL="${SCAFFOLD_INSTALLER_URL:-https://github.com/AlexSkrypnyk/scaffold/releases/latest/download/install.sh}"

main() {
  local script

  # The download completes before anything runs, so a failed or truncated
  # transfer runs no part of the installer.
  if ! script="$(curl -fsSL "${SCAFFOLD_INSTALLER_URL}")" || [ -z "${script}" ]; then
    echo "Error: failed to download the Scaffold installer from ${SCAFFOLD_INSTALLER_URL}." >&2
    exit 1
  fi

  # Feeding the script on stdin matches 'curl ... | bash -s --', which the
  # installer expects. 'bash -c' would hit the 128 KB limit on 1 argument.
  bash -s -- "$@" <<<"${script}"
}

# Run main only when the script is executed, not when it is sourced. Piped
# through 'bash', the script has no source file, so "${BASH_SOURCE[0]}" is
# empty.
if [ -z "${BASH_SOURCE[0]:-}" ] || [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
