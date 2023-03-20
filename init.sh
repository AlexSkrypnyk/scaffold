#!/usr/bin/env bash
##
# Init repository by replacing string tokens.
#
# @usage:
# Interactive prompt:
# ./init
#
# Silent:
# ./init yournamespace yourproject "your name"
#
# shellcheck disable=SC2162

set -u
set -e

namespace=${1:-}
project=${2:-}
author=${3:-}

[ -z "${namespace}" ] && read -p 'Namespace: ' namespace
[ -z "${project}" ] && read -p 'Project: ' project
[ -z "${author}" ] && read -p 'Author: ' author
[ -z "${1:-}" ] && read -p 'Use Composer [Y/n]: ' usecomposer
[ -z "${1:-}" ] && read -p 'Use NodeJS [Y/n]:' usenodejs
[ -z "${1:-}" ] && read -p 'Remove this script [Y/n]: ' removeself

: "${namespace:?Namespace is required}"
: "${project:?Project is required}"
: "${author:?Author is required}"
usecomposer="${usecomposer:-y}"
usenodejs="${usenodejs:-y}"
removeself="${removeself:-y}"

replace_string_content() {
  local needle="${1}"
  local replacement="${2}"
  local dir="${3:-$(pwd)}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  set +e
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${needle}" "${dir}" | xargs sed "${sed_opts[@]}" "s!$needle!$replacement!g" || true
  set -e
}

remove_tokens_with_content() {
  local token="${1}"
  local dir="${2-$(pwd)}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "#;> $token" "${dir}" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/#;< $token/,/#;> $token/d" || true
}

remove_composer() {
  rm composer.json >/dev/null
  replace_string_content "composer require alexskrypnyk/scaffold" ""
  replace_string_content "vendor/bin/scaffold" ""
  replace_string_content "composer install" ""
  replace_string_content "composer lint" ""
  replace_string_content "composer test" ""
}

remove_node() {
  rm package.json >/dev/null
  replace_string_content "npm install @alexskrypnyk/scaffold" ""
  replace_string_content "node_modules/.bin/scaffold" ""
  replace_string_content "npm install" ""
  replace_string_content "npm run lint" ""
  replace_string_content "npm run test" ""
}

[ "$usecomposer" != "y" ] && remove_composer
[ "$usenodejs" != "y" ] && remove_node

replace_string_content "alexskrypnyk" "$namespace"
replace_string_content "AlexSkrypnyk" "$namespace"
replace_string_content "scaffold" "$project"
replace_string_content "Alex Skrypnyk" "$author"

remove_tokens_with_content "META"

[ "$removeself" != "n" ] && rm -- "$0"
