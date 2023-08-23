#!/usr/bin/env bash
##
# Adjust project repository based on user input.
#
# @usage:
# Interactive prompt:
# ./init.sh
#
# Silent:
# ./init.sh yournamespace yourproject "Your Name"
#
# shellcheck disable=SC2162

set -u
set -e

namespace=${1:-}
project=${2:-}
author=${3:-}

echo "Please follow the prompts to adjust your project configuration"
echo

[ -z "${namespace}" ] && read -p 'Namespace: ' namespace
[ -z "${project}" ] && read -p 'Project: ' project
[ -z "${author}" ] && read -p 'Author: ' author
[ -z "${1:-}" ] && read -p 'Use Composer [Y/n]: ' use_composer
[ -z "${1:-}" ] && read -p 'Use NodeJS [Y/n]:' use_nodejs
[ -z "${1:-}" ] && read -p 'Remove this script [Y/n]: ' remove_self

: "${namespace:?Namespace is required}"
: "${project:?Project is required}"
: "${author:?Author is required}"

use_composer="${use_composer:-y}"
use_nodejs="${use_nodejs:-y}"
remove_self="${remove_self:-y}"

use_composer="$(echo "${use_composer}" | tr '[:upper:]' '[:lower:]')"
use_nodejs="$(echo "${use_nodejs}" | tr '[:upper:]' '[:lower:]')"
remove_self="$(echo "${remove_self}" | tr '[:upper:]' '[:lower:]')"

replace_string_content() {
  local needle="${1}"
  local replacement="${2}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  set +e
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${needle}" "$(pwd)" | xargs sed "${sed_opts[@]}" "s!$needle!$replacement!g" || true
  set -e
}

remove_string_content() {
  local token="${1}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${token}" "$(pwd)" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/^${token}/d" || true
}

remove_tokens_with_content() {
  local token="${1}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "#;> $token" "$(pwd)" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/#;< $token/,/#;> $token/d" || true
}

uncomment_line() {
  local file_name="${1}"
  local start_string="${2}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  LC_ALL=C.UTF-8 sed "${sed_opts[@]}" -e "s/^# ${start_string}/${start_string}/" "${file_name}"
}

remove_special_comments() {
  local token="#;"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${token}" "$(pwd)" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/${token}/d" || true
}

remove_composer() {
  rm -f omposer.json >/dev/null || true
  rm -f composer.lock >/dev/null || true
  rm -Rf vendor >/dev/null || true
  remove_tokens_with_content "COMPOSER"
}

remove_nodejs() {
  rm -f package.json >/dev/null || true
  rm -f package.lock >/dev/null || true
  rm -f yarn.lock >/dev/null || true
  rm -Rf node_modules >/dev/null || true
  remove_tokens_with_content "NODEJS"
}

[ "${use_composer}" != "y" ] && remove_composer
[ "${use_nodejs}" != "y" ] && remove_nodejs

replace_string_content "yournamespace" "${namespace}"
replace_string_content "yournamespace" "${namespace}"
replace_string_content "AlexSkrypnyk" "${namespace}"
replace_string_content "yourproject" "${project}"
replace_string_content "Your Name" "${author}"

remove_string_content "Generic project scaffold template"
replace_string_content "Scaffold" "${project}"
replace_string_content "scaffold" "${project}"

remove_string_content "# Uncomment the lines below"
uncomment_line ".gitattributes" ".editorconfig"
uncomment_line ".gitattributes" ".gitattributes"
uncomment_line ".gitattributes" ".github"
uncomment_line ".gitattributes" ".gitignore"
uncomment_line ".gitattributes" "tests"

remove_tokens_with_content "META"
remove_special_comments

[ "${remove_self}" != "n" ] && rm -- "$0" || true

echo
echo "Initialization complete."
