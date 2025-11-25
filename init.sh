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

set -euo pipefail
[ "${SCRIPT_DEBUG-}" = "1" ] && set -x

namespace=${1-}
project=${2-}
author=${3-}

#-------------------------------------------------------------------------------

convert_string() {
  input_string="$1"
  conversion_type="$2"

  case "${conversion_type}" in
    "file_name" | "route_path" | "deployment_id")
      echo "${input_string}" | tr ' ' '_' | tr '[:upper:]' '[:lower:]'
      ;;
    "domain_name" | "package_namespace")
      echo "${input_string}" | tr ' ' '_' | tr '[:upper:]' '[:lower:]' | tr -d '-'
      ;;
    "namespace" | "class_name")
      echo "${input_string}" | awk -F" " '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); } 1' | tr -d ' -'
      ;;
    "package_name")
      echo "${input_string}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]'
      ;;
    "function_name" | "ui_id" | "cli_command")
      echo "${input_string}" | tr ' ' '_' | tr '[:upper:]' '[:lower:]'
      ;;
    "log_entry" | "code_comment_title")
      echo "${input_string}"
      ;;
    *)
      echo "Invalid conversion type"
      ;;
  esac
}

replace_string_content() {
  local needle="${1}"
  local replacement="${2}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  set +e
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${needle}" "$(pwd)" | xargs sed "${sed_opts[@]}" "s!$needle!$replacement!g" || true
  set -e
}

to_lowercase() {
  echo "${1}" | tr '[:upper:]' '[:lower:]'
}

remove_string_content() {
  local token="${1}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${token}" "$(pwd)" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/^${token}/d" || true
}

remove_string_content_line() {
  local token="${1}"
  local target="${2:-.}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${token}" "$(pwd)/${target}" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/${token}/d" || true
}

remove_tokens_with_content() {
  local token="${1}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  grep -rI --include=".*" --include="*" --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "#;> $token" "$(pwd)" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/#;< $token/,/#;> $token/d" || true
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

ask() {
  local prompt="$1"
  local default="${2-}"
  local result=""

  if [[ -n $default ]]; then
    prompt="${prompt} [${default}]: "
  else
    prompt="${prompt}: "
  fi

  while [[ -z ${result} ]]; do
    read -p "${prompt}" result
    if [[ -n $default && -z ${result} ]]; then
      result="${default}"
    fi
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

remove_php() {
  remove_php_command
  remove_php_command_build
  remove_php_script

  rm -f composer.json >/dev/null || true
  rm -f composer.lock >/dev/null || true
  rm -Rf vendor >/dev/null || true
  rm -Rf tests/phpunit || true
  rm -f phpcs.xml || true
  rm -f phpstan.neon || true
  rm -f phpunit.xml || true
  rm -f rector.php || true

  rm -Rf docs/php || true

  remove_string_content_line "\/tests" ".gitattributes"
  remove_string_content_line "\/phpcs.xml" ".gitattributes"
  remove_string_content_line "\/phpstan.neon" ".gitattributes"
  remove_string_content_line "\/phpunit.xml" ".gitattributes"
  remove_string_content_line "\/rector.php" ".gitattributes"

  rm -f .github/workflows/test-php.yml || true
  rm -f .github/workflows/release-php.yml || true

  remove_tokens_with_content "PHP"
}

remove_php_command() {
  rm -Rf php-command || true
  rm -Rf src || true
  rm -Rf tests/phpunit/Functional/ApplicationFunctionalTestCase.php || true
  rm -Rf tests/phpunit/Functional/JokeCommandTest.php || true
  rm -Rf tests/phpunit/Functional/SayHelloCommandTest.php || true
  rm -f docs/content/php/php-command.mdx || true

  remove_tokens_with_content "PHP_COMMAND"

  remove_string_content_line '"php-command"'
  remove_string_content_line '"php-command",'
}

remove_php_command_build() {
  rm -Rf box.json || true
  rm -Rf docs/content/ci/php-packaging.mdx || true
  remove_tokens_with_content "PHP_PHAR"
}

remove_php_script() {
  local new_name="${1:-php-script}"
  rm -f php-script || true
  rm -f tests/phpunit/Unit/ExampleScriptUnitTest.php || true
  rm -f tests/phpunit/Unit/ScriptUnitTestCase.php || true
  rm -f tests/phpunit/Unit/ExampleScriptUnitTest.php || true
  rm -f tests/phpunit/Functional/ScriptFunctionalTestCase.php || true
  rm -f tests/phpunit/Functional/ExampleScriptFunctionalTest.php || true
  remove_tokens_with_content "!PHP_COMMAND"
  remove_tokens_with_content "!PHP_PHAR"
  remove_string_content_line '"php-script"'

  replace_string_content '"'"${new_name}"'",' '"'"${new_name}"'"'
}

remove_nodejs() {
  rm -f package.json >/dev/null || true
  rm -f package.lock >/dev/null || true
  rm -f yarn.lock >/dev/null || true
  rm -Rf node_modules >/dev/null || true

  remove_string_content_line "\/.npmignore" ".gitattributes"

  rm -f .github/workflows/test-nodejs.yml || true
  rm -f .github/workflows/release-nodejs.yml || true

  remove_tokens_with_content "NODEJS"
}

remove_shell() {
  rm -f shell-command.sh >/dev/null || true
  rm -Rf tests/bats || true

  rm -f .github/workflows/test-shell.yml || true

  remove_tokens_with_content "SHELL"
}

remove_release_drafter() {
  rm -f .github/workflows/draft-release-notes.yml || true
  rm -f .github/release-drafter.yml
  remove_tokens_with_content "RELEASEDRAFTER"
}

remove_pr_autoassign() {
  rm -f .github/workflows/assign-author.yml || true
}

remove_funding() {
  rm -f .github/FUNDING.yml || true
}

remove_pr_template() {
  rm -f .github/PULL_REQUEST_TEMPLATE.md || true
}

remove_renovate() {
  rm -f renovate.json || true
  remove_tokens_with_content "RENOVATE"
}

remove_docs() {
  rm -Rf docs || true
  rm -f .github/workflows/test-docs.yml || true
  rm -f .github/workflows/release-docs.yml || true
  remove_string_content_line "\/docs" ".gitattributes"
}

process_readme() {
  mv README.dist.md "README.md" >/dev/null 2>&1 || true

  # Update placeholder image URL and alt text in README.md
  replace_string_content 'text=Yourproject' "text=${1// /+}"
  replace_string_content 'alt="Yourproject logo"' "alt=\"${1} logo\""

  curl "https://placehold.jp/000000/ffffff/200x200.png?text=${1// /+}&css=%7B%22border-radius%22%3A%22%20100px%22%7D" >logo.tmp.png || true
  if [ -s "logo.tmp.png" ]; then
    mv logo.tmp.png "logo.png" >/dev/null 2>&1 || true
  fi
  rm logo.tmp.png >/dev/null 2>&1 || true
}

process_internal() {
  local namespace="${1}"
  local project="${2}"
  local author="${3}"
  local namespace_lowercase

  namespace_lowercase="$(to_lowercase "${namespace}")"

  rm -f LICENSE >/dev/null || true
  rm -f SECURITY.md >/dev/null || true
  rm -Rf ".scaffold" >/dev/null || true
  rm -f ".github/workflows/scaffold-test.yml" >/dev/null || true
  rm -f ".github/workflows/scaffold-release-docs.yml" >/dev/null || true
  rm -f ".github/workflows/test-actions.yml" >/dev/null || true
  rm -f ".github/.yamllint-for-gha.yml" >/dev/null || true

  rm -f "docs/static/img/init.gif" >/dev/null || true

  # Replace any existing necessary placeholders using a real value with
  # tokens used in further replacements.
  replace_string_content "AlexSkrypnyk/scaffold" "yournamespace/yourproject"

  replace_string_content "YourNamespace" "${namespace}"
  replace_string_content "yournamespace" "${namespace_lowercase}"
  replace_string_content "yourproject" "${project}"
  replace_string_content "Your Name" "${author}"
  replace_string_content "Alex Skrypnyk" "${author}"

  remove_string_content "Generic project scaffold template"
  replace_string_content "https://getscaffold.dev/ project scaffold template" "__ATTRIBUTION__"
  replace_string_content "Scaffold" "${project}"
  replace_string_content "scaffold" "${project}"
  replace_string_content "__ATTRIBUTION__" "https://getscaffold.dev/ project scaffold template"

  remove_string_content "# Uncomment the lines below"
  uncomment_line ".gitattributes" "\/.editorconfig"
  uncomment_line ".gitattributes" "\/.gitattributes"
  uncomment_line ".gitattributes" "\/.github"
  uncomment_line ".gitattributes" "\/.gitignore"
  uncomment_line ".gitattributes" "\/docs"
  uncomment_line ".gitattributes" "\/tests"
  uncomment_line ".gitattributes" "\/phpcs.xml"
  uncomment_line ".gitattributes" "\/phpstan.neon"
  uncomment_line ".gitattributes" "\/phpunit.xml"
  uncomment_line ".gitattributes" "\/rector.php"
  uncomment_line ".gitattributes" "\/.npmignore"
  uncomment_line ".gitattributes" "\/renovate.json"

  remove_tokens_with_content "META"
  remove_special_comments
}

#-------------------------------------------------------------------------------

main() {
  echo "Please follow the prompts to adjust your project configuration"
  echo

  [ -z "${namespace}" ] && namespace="$(ask "Namespace (PascalCase)")"
  [ -z "${project}" ] && project="$(ask "Project")"
  [ -z "${author}" ] && author="$(ask "Author")"

  # Make sure the input become valid value.
  project="$(convert_string "${project}" "package_name")"
  namespace="$(convert_string "${namespace}" "namespace")"

  use_php="$(ask_yesno "Use PHP")"

  use_php_command="y"
  use_php_command_build="y"
  use_php_script="n"
  php_command_name="<unset>"
  if [ "${use_php}" = "y" ]; then
    use_php_command="$(ask_yesno "  Use CLI command app")"
    if [ "${use_php_command}" = "y" ]; then
      php_command_name=$(ask "    CLI command name" "${project}")
      use_php_command_build="$(ask_yesno "    Build PHAR")"
      use_php_script="n"
      php_script_name="<unset>"
    else
      use_php_script="$(ask_yesno "  Use simple script")"
      php_script_name=$(ask "    CLI script name" "${project}")
      php_command_name="<unset>"
      use_php_command_build="n"
    fi
  fi

  use_nodejs="$(ask_yesno "Use NodeJS")"

  use_shell="$(ask_yesno "Use Shell")"
  if [ "${use_shell}" = "y" ]; then
    shell_command_name=$(ask "  Shell command name" "${project}")
  fi

  use_release_drafter="$(ask_yesno "Use GitHub release drafter")"
  use_pr_autoassign="$(ask_yesno "Use GitHub PR author auto-assign")"
  use_funding="$(ask_yesno "Use GitHub funding")"
  use_pr_template="$(ask_yesno "Use GitHub PR template")"
  use_renovate="$(ask_yesno "Use Renovate")"
  use_docs="$(ask_yesno "Use docs")"
  remove_self="$(ask_yesno "Remove this script")"

  echo
  echo "            Summary"
  echo "---------------------------------"
  echo "Namespace                        : ${namespace}"
  echo "Project                          : ${project}"
  echo "Author                           : ${author}"
  echo "Use PHP                          : ${use_php}"
  echo "  Use CLI command app            : ${use_php_command}"
  echo "    CLI command name             : ${php_command_name}"
  echo "    Build PHAR                   : ${use_php_command_build}"
  echo "  Use simple script              : ${use_php_script}"
  echo "Use NodeJS                       : ${use_nodejs}"
  echo "Use Shell                        : ${use_shell}"
  echo "Use GitHub release drafter       : ${use_release_drafter}"
  echo "Use GitHub PR author auto-assign : ${use_pr_autoassign}"
  echo "Use GitHub funding               : ${use_funding}"
  echo "Use GitHub PR template           : ${use_pr_template}"
  echo "Use Renovate                     : ${use_renovate}"
  echo "Use Docs                         : ${use_docs}"
  echo "Remove this script               : ${remove_self}"
  echo "---------------------------------"
  echo

  should_proceed="$(ask_yesno "Proceed with project init")"

  if [ "${should_proceed}" != "y" ]; then
    echo
    echo "Aborting."
    exit 1
  fi

  #
  # Processing.
  #

  : "${namespace:?Namespace is required}"
  : "${project:?Project is required}"
  : "${author:?Author is required}"

  if [ "${use_php}" = "y" ]; then

    if [ "${use_php_command}" = "y" ]; then
      [ "${use_php_command_build:-n}" != "y" ] && remove_php_command_build
      replace_string_content "php-command" "${php_command_name}"
      mv "php-command" "${php_command_name}" >/dev/null 2>&1 || true
      remove_php_script "${php_command_name}"
    else
      remove_php_command "${php_command_name}"
      remove_php_command_build

      if [ "${use_php_script:-n}" = "y" ]; then
        replace_string_content "php-script" "${php_script_name}"
        mv "php-script" "${php_script_name}" >/dev/null 2>&1 || true
      else
        remove_php_script "${php_script_name}"
      fi
    fi
  else
    remove_php
  fi

  [ "${use_nodejs}" != "y" ] && remove_nodejs

  if [ "${use_shell}" = "y" ]; then
    replace_string_content "shell-command.sh" "${shell_command_name}.sh"
    mv "shell-command.sh" "${shell_command_name}.sh" >/dev/null 2>&1 || true
  else
    remove_shell
  fi

  [ "${use_release_drafter}" != "y" ] && remove_release_drafter
  [ "${use_pr_autoassign}" != "y" ] && remove_pr_autoassign
  [ "${use_funding}" != "y" ] && remove_funding
  [ "${use_pr_template}" != "y" ] && remove_pr_template
  [ "${use_renovate}" != "y" ] && remove_renovate
  [ "${use_docs}" != "y" ] && remove_docs

  process_readme "${project}"

  process_internal "${namespace}" "${project}" "${author}"

  [ "${remove_self}" != "n" ] && rm -- "$0" || true

  echo
  echo "Initialization complete."
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  main "$@"
fi
