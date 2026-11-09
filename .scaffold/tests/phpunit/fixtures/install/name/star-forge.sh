#!/usr/bin/env bash
##
# Shell script template.
#
# @usage:
# Interactive prompt:
# ./star-forge.sh
#
# ./star-forge.sh 20
#
# shellcheck disable=SC2162

set -euo pipefail
[ "${SCRIPT_DEBUG-}" = "1" ] && set -x

sides="${1-}"

# Flag to bypass the prompt to proceed.
SHOULD_PROCEED="${SHOULD_PROCEED-}"

#-------------------------------------------------------------------------------

ask() {
  local prompt="$1"
  local default="${2-}"
  local result=""

  if [[ -n ${default} ]]; then
    prompt="${prompt} [${default}]: "
  else
    # LCOV_EXCL_START
    prompt="${prompt}: "
    # LCOV_EXCL_END
  fi

  while [[ -z ${result} ]]; do
    read -p "${prompt}" result
    # LCOV_EXCL_START
    if [[ -z ${result} && -n ${default} ]]; then
      result="${default}"
    fi
    # LCOV_EXCL_END
  done

  echo "${result}"
}

ask_yesno() {
  local prompt="${1}"
  local default="${2:-Y}"
  local result

  read -p "${prompt} [$([ "${default}" = "Y" ] && echo "Y/n" || echo "y/N")]: " result
  result="$(echo "${result:-${default}}" | tr '[:upper:]' '[:lower:]')"
  echo "${result}"
}

#-------------------------------------------------------------------------------

main() {
  echo "Follow the prompts"
  echo

  [ -z "${sides}" ] && sides="$(ask "Number of sides" "6")"

  # Limit to 3 digits so the value stays well below the $RANDOM ceiling of
  # 32767, and force base 10 so a leading zero is not read as octal.
  if [[ ! ${sides} =~ ^[0-9]{1,3}$ ]] || ((10#${sides} < 2 || 10#${sides} > 100)); then
    echo "ERROR: Number of sides must be a whole number from 2 to 100, got '${sides}'." >&2
    exit 1
  fi
  sides=$((10#${sides}))

  [ -z "${SHOULD_PROCEED}" ] && SHOULD_PROCEED="$(ask_yesno "Proceed?")"

  if [ "${SHOULD_PROCEED}" != "y" ]; then
    echo
    echo "Aborting."
    exit 0
  fi

  echo
  echo "Rolling a ${sides}-sided die..."
  echo

  echo "Rolled: $((RANDOM % sides + 1))"
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  main "$@"
fi
