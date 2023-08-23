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
# shellcheck disable=SC2162,SC2015

set -u
set -e

namespace=${1-}
project=${2-}
author=${3-}

echo "Please follow the prompts to adjust your project configuration"
echo

[ -z "${namespace}" ] && read -p 'Namespace: ' namespace
[ -z "${project}" ] && read -p 'Project: ' project
[ -z "${author}" ] && read -p 'Author: ' author

[ -z "${1-}" ] && read -p 'Use PHP [Y/n]: ' use_php
use_php="$(echo "${use_php:-y}" | tr '[:upper:]' '[:lower:]')"

if [ "${use_php}" = "y" ]; then
  [ -z "${1-}" ] && read -p '  Use CLI command app [Y/n]: ' use_php_command
  use_php_command="$(echo "${use_php_command:-y}" | tr '[:upper:]' '[:lower:]')"
  if [ "${use_php_command}" = "y" ]; then
    [ -z "${1-}" ] && read -p '    Build PHAR [Y/n]: ' use_php_command_build
    use_php_command_build="$(echo "${use_php_command_build:-y}" | tr '[:upper:]' '[:lower:]')"
  else
    [ -z "${1-}" ] && read -p '  Use simple script [Y/n]: ' use_php_script
    use_php_script="$(echo "${use_php_script:-y}" | tr '[:upper:]' '[:lower:]')"
  fi
fi

[ -z "${1-}" ] && read -p 'Use NodeJS [Y/n]:' use_nodejs
use_nodejs="$(echo "${use_nodejs:-y}" | tr '[:upper:]' '[:lower:]')"

[ -z "${1-}" ] && read -p 'Use GitHub release drafter [Y/n]:' use_release_drafter
use_release_drafter="${use_release_drafter:-y}"

[ -z "${1-}" ] && read -p 'Use GitHub PR author auto-assign [Y/n]:' use_pr_autoassign
use_pr_autoassign="${use_pr_autoassign:-y}"

[ -z "${1-}" ] && read -p 'Use GitHub funding [Y/n]:' use_funding
use_funding="${use_funding:-y}"

[ -z "${1-}" ] && read -p 'Use GitHub PR template [Y/n]:' use_pr_template
use_pr_template="${use_pr_template:-y}"

[ -z "${1-}" ] && read -p 'Remove this script [Y/n]: ' remove_self
remove_self="$(echo "${remove_self:-y}" | tr '[:upper:]' '[:lower:]')"

: "${namespace:?Namespace is required}"
: "${project:?Project is required}"
: "${author:?Author is required}"

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

remove_php() {
  remove_php_command
  remove_php_command_build
  remove_php_script

  rm -f composer.json >/dev/null || true
  rm -f composer.lock >/dev/null || true
  rm -Rf vendor >/dev/null || true
  rm -f phpcs.xml || true
  rm -f phpmd.xml || true
  rm -f phpstan.neon || true

  remove_tokens_with_content "PHP"
}

remove_php_command() {
  rm -Rf bin || true
  rm -Rf src || true
  rm -Rf tests/phpunit/unit/Command || true
}

remove_php_command_build() {
  rm -Rf box.json || true
}

remove_php_script() {
  rm -f template-simple-script.php || true
  rm -f tests/phpunit/unit/ExampleScriptUnitTest.php || true
  rm -f tests/phpunit/unit/ScriptUnitTestBase.php || true
}

remove_nodejs() {
  rm -f package.json >/dev/null || true
  rm -f package.lock >/dev/null || true
  rm -f yarn.lock >/dev/null || true
  rm -Rf node_modules >/dev/null || true
  remove_tokens_with_content "NODEJS"
}

if [ "${use_php}" = "y" ]; then
  if [ "${use_php_command}" = "y" ]; then
    [ "${use_php_command_build:-n}" != "y" ] && remove_php_command_build
  else
    remove_php_command
    remove_php_command_build
  fi
  [ "${use_php_script:-n}" != "y" ] && remove_php_script
else
  remove_php
fi

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

rm -f LICENSE >/dev/null || true
rm -f ".github/workflows/scaffold_test.yml" >/dev/null || true

[ "${use_release_drafter}" != "y" ] && rm -f .github/release-drafter.yml && remove_tokens_with_content "RELEASEDRAFTER" || true
[ "${use_pr_autoassign}" != "y" ] && rm -f .github/workflows/auto-assign-pr-author.yml || true
[ "${use_funding}" != "y" ] && rm -f .github/FUNDING.yml || true
[ "${use_pr_template}" != "y" ] && rm -f .github/PULL_REQUEST_TEMPLATE.md || true

remove_tokens_with_content "META"
remove_special_comments

[ "${remove_self}" != "n" ] && rm -- "$0" || true

echo
echo "Initialization complete."
