#!/usr/bin/env bash
##
# Shared helpers for the playground scripts.
#
# Sourced by the scripts in this directory; not run on its own.
#
# shellcheck disable=SC2034

set -euo pipefail

PLAYGROUND_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
PLAYGROUND_GITHUB_OWNER="${PLAYGROUND_GITHUB_OWNER:-AlexSkrypnyk}"

##
# Exit 1 unless 'gh' and SCAFFOLD_GITHUB_TOKEN are both available.
#
# A run that skips the GitHub step tests nothing, so a missing prerequisite
# fails here instead of being reported and skipped by 'install.sh'.
#
playground_check_prerequisites() {
  local missing=()

  command -v gh >/dev/null 2>&1 || missing+=("'gh' is not installed")
  [ -n "${SCAFFOLD_GITHUB_TOKEN:-}" ] || missing+=("SCAFFOLD_GITHUB_TOKEN is not set")

  [ "${#missing[@]}" -eq 0 ] && return 0

  local reason
  for reason in "${missing[@]}"; do
    echo "Error: ${reason}." >&2
  done

  exit 1
}

##
# Create a new work directory under '.artifacts/playground' and print its path.
#
# @param $1 string Script name used as the directory prefix
#
playground_workdir() {
  local dir
  dir="${PLAYGROUND_ROOT}/.artifacts/playground/${1}-$(date +%Y%m%d%H%M%S)"

  mkdir -p "${dir}"

  echo "${dir}"
}

##
# Print where to look after a run.
#
# @param $1 string Repository URL
# @param $2 string Work directory
#
playground_summary() {
  echo
  echo "Repository     : ${1}"
  echo "Work directory : ${2}"
}
