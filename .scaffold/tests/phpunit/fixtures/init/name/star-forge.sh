#!/usr/bin/env bash
##
# Shell script template.
#
# @usage:
# Interactive prompt:
# ./star-forge.sh
#
# ./star-forge.sh "topic"
#
# shellcheck disable=SC2162

set -euo pipefail
[ "${SCRIPT_DEBUG-}" = "1" ] && set -x

# URL endpoint to fetch the data from.
URL_ENDPOINT="${JOKE_URL_ENDPOINT:-https://official-joke-api.appspot.com/jokes/__TOPIC__/random}"

# Topic.
topic="${1-}"

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

  [ -z "${topic}" ] && topic="$(ask "Joke topic" "general")"

  [ -z "${SHOULD_PROCEED}" ] && SHOULD_PROCEED="$(ask_yesno "Proceed?")"

  if [ "${SHOULD_PROCEED}" != "y" ]; then
    echo
    echo "Aborting."
    exit 0
  fi

  echo
  echo "Fetching joke for topic: ${topic}..."
  echo

  local url
  url="${URL_ENDPOINT//__TOPIC__/${topic}}"

  echo
  echo "URL: ${url}"
  echo

  response="$(curl -sL "${url}")"
  # Extract 'setup'
  setup=$(echo "${response}" | sed -E 's/.*"setup":"([^"]+)".*/\1/')
  # Extract 'punchline'
  punchline=$(echo "${response}" | sed -E 's/.*"punchline":"([^"]+)".*/\1/')

  echo "$setup"
  echo "$punchline"
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  main "$@"
fi
