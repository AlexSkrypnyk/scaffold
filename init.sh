#!/usr/bin/env bash
##
# Adjust project repository based on user input.
#
# This script initializes a new project from the Scaffold template by:
# - Replacing placeholder values (namespace, project name, author)
# - Removing unwanted components (PHP, NodeJS, Shell, etc.)
# - Cleaning up template-specific files
# - Configuring selected features (release drafter, renovate, docs)
#
# The script can run interactively (with prompts) or non-interactively (with
# options). Passing any option switches to non-interactive mode: prompts are
# skipped, unspecified choices use their defaults, and --namespace, --name and
# --author are required.
#
# @usage:
# Interactive prompt:
# ./init.sh
#
# Non-interactive:
# ./init.sh --namespace=AcmeApp --name=acme-app --author="Jane Doe"
#
# Non-interactive one-liner (for AI agents and automation):
# curl -fsSL https://raw.githubusercontent.com/AlexSkrypnyk/scaffold/main/init.sh | \
#   bash -s -- --namespace=AcmeApp --name=acme-app --author="Jane Doe"
#
# Run "./init.sh --help" for the full list of options.
#
# shellcheck disable=SC2162,SC2015

set -euo pipefail
[ "${SCRIPT_DEBUG-}" = "1" ] && set -x

# Identity values. Populated from options or interactive prompts.
namespace=""
project=""
author=""
project_pascalcase=""

# Feature selections. An empty value means "not set on the command line"; it is
# resolved later from an interactive prompt or a non-interactive default.
use_php=""
use_php_command=""
php_command_name=""
use_php_command_build=""
use_php_script=""
php_script_name=""
use_nodejs=""
use_shell=""
shell_command_name=""
use_docker=""
docker_image_name=""
use_release_drafter=""
use_pr_autoassign=""
use_funding=""
use_pr_template=""
use_renovate=""
use_docs=""
use_test_actions=""
remove_self=""

# Whether to run interactively. Disabled as soon as any option is passed.
interactive=1

#-------------------------------------------------------------------------------
# STRING UTILITIES
#-------------------------------------------------------------------------------

##
# Convert a string to various naming conventions.
#
# @param $1 string Input string to convert
# @param $2 string Conversion type
#
# Conversion types:
#   file_name        : lowercase with underscores (my_file_name)
#   route_path       : lowercase with underscores (my_route_path)
#   deployment_id    : lowercase with underscores (my_deployment_id)
#   domain_name      : lowercase, underscores, no hyphens (mydomain_name)
#   package_namespace: lowercase, underscores, no hyphens (mypackage_namespace)
#   namespace        : PascalCase, no spaces/hyphens (MyNamespace)
#   class_name       : PascalCase, no spaces/hyphens (MyClassName)
#   package_name     : lowercase with hyphens (my-package-name)
#   function_name    : lowercase with underscores (my_function_name)
#   ui_id            : lowercase with underscores (my_ui_id)
#   cli_command      : lowercase with underscores (my_cli_command)
#   log_entry        : unchanged (My Log Entry)
#   code_comment_title: unchanged (My Comment Title)
#
# @return string Converted string
#
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
      echo "Error: Invalid conversion type '${conversion_type}'" >&2
      return 1
      ;;
  esac
}

#-------------------------------------------------------------------------------
# FILE OPERATION FUNCTIONS
#-------------------------------------------------------------------------------

##
# Replace all occurrences of a string in files.
# Searches recursively, excluding common directories.
#
# @param $1 string Needle (string to find)
# @param $2 string Replacement (string to replace with)
#
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

# Convert to PascalCase for project names (brief one-liner)
to_pascalcase() { echo "${1}" | awk -F'[-_ ]' '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); } 1' OFS=''; }

remove_string_content() {
  local token="${1}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${token}" "$(pwd)" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/^${token}/d" || true
}

remove_string_content_line() {
  local token="${1}"
  local target="${2:-.}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${token}" "$(pwd)/${target}" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/${token}/d" || true
}

##
# Remove tokens and their enclosed content from files.
# Tokens use format: #;< TOKEN ... #;> TOKEN
#
# @param $1 string Token name (without #;< or #;> prefixes)
#
# Example:
#   #;< PHP
#   Some PHP-specific content
#   #;> PHP
#   This entire block will be removed
#
remove_tokens_with_content() {
  local token="${1}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  grep -rI --include=".*" --include="*" --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "#;> $token" "$(pwd)" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/#;< $token/,/#;> $token/d" || true
}

uncomment_line() {
  local file_name="${1}"
  local start_string="${2}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  LC_ALL=C.UTF-8 sed "${sed_opts[@]}" -e "s/^# ${start_string}/${start_string}/" "${file_name}"
}

remove_special_comments() {
  local token="#;"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${token}" "$(pwd)" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/${token}/d" || true
}

#-------------------------------------------------------------------------------
# USER INTERACTION FUNCTIONS
#-------------------------------------------------------------------------------

##
# Prompt user for input with optional default value.
#
# @param $1 string Prompt text
# @param $2 string Default value (optional)
# @return string User input or default value
#
ask() {
  local label="$1"
  local prompt="$1"
  local default="${2-}"
  local result=""

  if [[ -n $default ]]; then
    prompt="${prompt} [${default}]: "
  else
    prompt="${prompt}: "
  fi

  while [[ -z ${result} ]]; do
    if ! read -p "${prompt}" result; then
      # Stdin reached EOF with no value. This happens when the script is piped
      # (e.g. 'curl ... | bash') without options, so there is nothing to read.
      if [[ -n $default ]]; then
        result="${default}"
        break
      fi
      echo "Error: No input available for '${label}'. Pass options (run with --help) or run interactively." >&2
      exit 1
    fi
    if [[ -n $default && -z ${result} ]]; then
      result="${default}"
    fi
  done
  echo "${result}"
}

##
# Prompt user for yes/no answer.
#
# @param $1 string Prompt text
# @param $2 string Default value (Y or N, default: Y)
# @return string 'y' or 'n'
#
ask_yesno() {
  local prompt="${1}"
  local default="${2:-Y}"
  local result

  read -p "${prompt} [$([ "${default}" = "Y" ] && echo "Y/n" || echo "y/N")]: " result
  result="$(echo "${result:-${default}}" | tr '[:upper:]' '[:lower:]')"
  echo "${result}"
}

#-------------------------------------------------------------------------------
# INPUT VALIDATION FUNCTIONS
#-------------------------------------------------------------------------------

##
# Check if required commands are available.
check_dependencies() {
  local missing=() required=("sed" "grep" "tr" "awk" "curl")
  for cmd in "${required[@]}"; do command -v "${cmd}" >/dev/null 2>&1 || missing+=("${cmd}"); done
  [ ${#missing[@]} -gt 0 ] && echo "Error: Missing required commands: ${missing[*]}" >&2 && return 1
  return 0
}

##
# Validate namespace format (PascalCase).
validate_namespace() {
  [[ ${1} =~ ^[A-Z][a-zA-Z0-9]*$ ]] || {
    echo "Error: Namespace must be PascalCase (e.g., MyNamespace)" >&2
    return 1
  }
}

##
# Validate project name format (lowercase with hyphens).
validate_project_name() {
  [[ ${1} =~ ^[a-z0-9-]+$ ]] && [[ ! ${1} =~ ^- ]] && [[ ! ${1} =~ -$ ]] || {
    echo "Error: Project name must be lowercase with hyphens (e.g., my-project)" >&2
    return 1
  }
}

##
# Validate author name (non-empty).
validate_author() {
  [ -n "${1}" ] || {
    echo "Error: Author name cannot be empty" >&2
    return 1
  }
}

#-------------------------------------------------------------------------------
# COMPONENT REMOVAL FUNCTIONS
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

  # Remove "composer" from renovate matchManagers and php language rule.
  if [ -f renovate.json ]; then
    local sed_opts
    sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
    sed "${sed_opts[@]}" 's/\["npm", "composer"\]/["npm"]/' renovate.json
    sed "${sed_opts[@]}" 's/\["composer"\]/[]/' renovate.json
    local line
    line=$(grep -n '"matchDepNames": \["php"\]' renovate.json | cut -d: -f1)
    if [ -n "${line}" ]; then
      local start=$((line - 1))
      local end=$((line + 3))
      sed "${sed_opts[@]}" "${start},${end}d" renovate.json
    fi
  fi
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

  # Remove "npm" from renovate matchManagers and node/yarn language rule.
  if [ -f renovate.json ]; then
    local sed_opts
    sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
    sed "${sed_opts[@]}" 's/\["npm", "composer"\]/["composer"]/' renovate.json
    sed "${sed_opts[@]}" 's/\["npm"\]/[]/' renovate.json
    local line
    line=$(grep -n '"matchDepNames": \["node", "yarn"\]' renovate.json | cut -d: -f1)
    if [ -n "${line}" ]; then
      local start=$((line - 1))
      local end=$((line + 3))
      sed "${sed_opts[@]}" "${start},${end}d" renovate.json
    fi
  fi
}

remove_shell() {
  rm -f shell-command.sh >/dev/null || true
  rm -Rf tests/bats || true

  rm -f .github/workflows/test-shell.yml || true

  remove_tokens_with_content "SHELL"
}

remove_docker() {
  rm -f Dockerfile >/dev/null || true
  rm -f entrypoint.sh >/dev/null || true

  rm -f .github/workflows/test-docker.yml || true
  rm -f .github/workflows/release-docker.yml || true

  remove_tokens_with_content "DOCKER"
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

cleanup_renovate_managers() {
  if [ -f renovate.json ] && grep -q '"matchManagers": \[\]' renovate.json; then
    local sed_opts
    sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
    local line
    line=$(grep -n '"matchManagers": \[\]' renovate.json | cut -d: -f1)
    if [ -n "${line}" ]; then
      local start=$((line - 1))
      local end=$((line + 3))
      sed "${sed_opts[@]}" "${start},${end}d" renovate.json
    fi
  fi
}

remove_docs() {
  rm -Rf docs || true
  rm -f .github/workflows/test-docs.yml || true
  rm -f .github/workflows/release-docs.yml || true
  remove_string_content_line "\/docs" ".gitattributes"
}

remove_test_actions() {
  rm -f .github/workflows/test-actions.yml || true
  rm -f .github/.yamllint-for-gha.yml || true
  rm -f zizmor.yml || true
}

#-------------------------------------------------------------------------------
# PROCESSING FUNCTIONS
#-------------------------------------------------------------------------------

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

##
# Replace the self-update skill references with placeholder tokens.
#
# The initialised project must keep instructions that point at the upstream
# template repository rather than at the project's own namespace, so these
# references are hidden behind tokens before the bulk replacements run and put
# back afterwards by restore_skill_references().
#
protect_skill_references() {
  replace_string_content "https://raw.githubusercontent.com/AlexSkrypnyk/scaffold/main/.scaffold/skills/update-consumer-scaffold/SKILL.md" "__SCAFFOLD_SKILL_URL__"
  replace_string_content "update-consumer-scaffold" "__SCAFFOLD_SKILL_NAME__"
  replace_string_content "update scaffold" "__SCAFFOLD_SKILL_TRIGGER__"
}

##
# Restore the self-update skill references hidden by protect_skill_references().
#
restore_skill_references() {
  replace_string_content "__SCAFFOLD_SKILL_URL__" "https://raw.githubusercontent.com/AlexSkrypnyk/scaffold/main/.scaffold/skills/update-consumer-scaffold/SKILL.md"
  replace_string_content "__SCAFFOLD_SKILL_NAME__" "update-consumer-scaffold"
  replace_string_content "__SCAFFOLD_SKILL_TRIGGER__" "update scaffold"
}

process_internal() {
  local namespace="${1}"
  local project="${2}"
  local author="${3}"
  local project_pascalcase="${4}"
  local namespace_lowercase

  namespace_lowercase="$(to_lowercase "${namespace}")"

  rm -f LICENSE >/dev/null || true
  rm -f SECURITY.md >/dev/null || true
  rm -Rf ".scaffold" >/dev/null || true
  rm -f ".github/workflows/scaffold-test.yml" >/dev/null || true
  rm -f ".github/workflows/scaffold-release-docs.yml" >/dev/null || true

  # The scaffold-only release workflow is always removed, so drop its companion
  # zizmor suppression entry too. A no-op when zizmor.yml is absent (Actions
  # linting not selected).
  remove_string_content_line "scaffold-release-docs.yml" "zizmor.yml"

  rm -f "docs/static/img/init.gif" >/dev/null || true

  protect_skill_references

  # Replace any existing necessary placeholders using a real value with
  # tokens used in further replacements.
  replace_string_content "AlexSkrypnyk/scaffold" "yournamespace/yourproject"

  replace_string_content "YourNamespace" "${namespace}"
  replace_string_content "yournamespace" "${namespace_lowercase}"
  replace_string_content "yourproject" "${project}"
  replace_string_content "Yourproject" "${project_pascalcase}"
  replace_string_content "Your Name" "${author}"
  replace_string_content "Alex Skrypnyk" "${author}"

  remove_string_content "Generic project scaffold template"
  replace_string_content "https://getscaffold.dev/ project scaffold template" "__ATTRIBUTION__"
  replace_string_content "Scaffold" "${project}"
  replace_string_content "scaffold" "${project}"
  replace_string_content "__ATTRIBUTION__" "https://getscaffold.dev/ project scaffold template"

  restore_skill_references

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
# ARGUMENT PARSING
#-------------------------------------------------------------------------------

##
# Print usage information.
#
usage() {
  cat <<'USAGE'
Usage: ./init.sh [OPTIONS]

Initialise a new project from the Scaffold template.

With no options the script runs interactively and prompts for every choice.
Passing any option switches to non-interactive mode: prompts are skipped,
unspecified choices use their defaults, and --namespace, --name and --author
are required.

One-liner (non-interactive):
  curl -fsSL https://raw.githubusercontent.com/AlexSkrypnyk/scaffold/main/init.sh | \
    bash -s -- --namespace=AcmeApp --name=acme-app --author="Jane Doe"

Identity (required in non-interactive mode):
  --namespace=VALUE              Project namespace in PascalCase (e.g. AcmeApp).
  --name=VALUE                   Project name in kebab-case (e.g. acme-app).
  --author=VALUE                 Author name (e.g. "Jane Doe").

Features (enabled by default unless noted; use --no-<name> to disable):
  --php, --no-php                PHP support.
  --php-command                  Use the Symfony CLI command app (default).
  --php-script                   Use a single-file script instead of the app.
  --php-command-name=VALUE       CLI command file name (default: project name).
  --php-script-name=VALUE        Script file name (default: project name).
  --phar, --no-phar              Build a PHAR (default: on).
  --nodejs, --no-nodejs          NodeJS support.
  --shell, --no-shell            Shell script support.
  --shell-command-name=VALUE     Shell script name (default: project name).
  --docker, --no-docker          Docker support (default: off).
  --docker-image-name=VALUE      Docker image name (default: namespace/project).
  --release-drafter, --no-release-drafter   GitHub Release Drafter.
  --pr-autoassign, --no-pr-autoassign       GitHub PR author auto-assign.
  --funding, --no-funding        GitHub funding configuration.
  --pr-template, --no-pr-template            GitHub pull request template.
  --renovate, --no-renovate      Renovate configuration.
  --docs, --no-docs              Documentation site.
  --test-actions, --no-test-actions  GitHub Actions linting (default: off).
  --keep                         Keep this init script (default: removed).

Other:
  --yes, -y                      Run non-interactively using defaults.
  --help, -h                     Show this help and exit.
USAGE
}

##
# Parse command-line options.
#
# Any recognised option disables interactive mode. Unknown options and the
# --help flag terminate the script.
#
parse_args() {
  if [ "$#" -gt 0 ]; then
    interactive=0
  fi

  while [ "$#" -gt 0 ]; do
    case "${1}" in
      --namespace=*) namespace="${1#*=}" ;;
      --name=*) project="${1#*=}" ;;
      --author=*) author="${1#*=}" ;;

      --php) use_php="y" ;;
      --no-php) use_php="n" ;;
      --php-command) use_php_command="y" ;;
      --php-script) use_php_script="y" ;;
      --php-command-name=*)
        php_command_name="${1#*=}"
        use_php_command="y"
        ;;
      --php-script-name=*)
        php_script_name="${1#*=}"
        use_php_script="y"
        ;;
      --phar) use_php_command_build="y" ;;
      --no-phar) use_php_command_build="n" ;;

      --nodejs) use_nodejs="y" ;;
      --no-nodejs) use_nodejs="n" ;;

      --shell) use_shell="y" ;;
      --no-shell) use_shell="n" ;;
      --shell-command-name=*)
        shell_command_name="${1#*=}"
        use_shell="y"
        ;;

      --docker) use_docker="y" ;;
      --no-docker) use_docker="n" ;;
      --docker-image-name=*)
        docker_image_name="${1#*=}"
        use_docker="y"
        ;;

      --release-drafter) use_release_drafter="y" ;;
      --no-release-drafter) use_release_drafter="n" ;;
      --pr-autoassign) use_pr_autoassign="y" ;;
      --no-pr-autoassign) use_pr_autoassign="n" ;;
      --funding) use_funding="y" ;;
      --no-funding) use_funding="n" ;;
      --pr-template) use_pr_template="y" ;;
      --no-pr-template) use_pr_template="n" ;;
      --renovate) use_renovate="y" ;;
      --no-renovate) use_renovate="n" ;;
      --docs) use_docs="y" ;;
      --no-docs) use_docs="n" ;;
      --test-actions) use_test_actions="y" ;;
      --no-test-actions) use_test_actions="n" ;;

      --keep) remove_self="n" ;;

      --yes | -y) interactive=0 ;;
      --help | -h)
        usage
        exit 0
        ;;
      *)
        echo "Error: Unknown option: ${1}" >&2
        echo "Run with --help for usage." >&2
        exit 1
        ;;
    esac
    shift
  done

  validate_php_mode
}

##
# Ensure the PHP sub-mode selection is not contradictory.
#
validate_php_mode() {
  if [ "${use_php_command}" = "y" ] && [ "${use_php_script}" = "y" ]; then
    echo "Error: --php-command and --php-script cannot be used together." >&2
    exit 1
  fi
}

#-------------------------------------------------------------------------------
# INPUT COLLECTION
#-------------------------------------------------------------------------------

##
# Ensure required identity values are present in non-interactive mode.
#
require_identity() {
  local missing=()
  [ -z "${namespace}" ] && missing+=("--namespace")
  [ -z "${project}" ] && missing+=("--name")
  [ -z "${author}" ] && missing+=("--author")

  if [ "${#missing[@]}" -gt 0 ]; then
    echo "Error: Missing required option(s) in non-interactive mode: ${missing[*]}" >&2
    echo "Run with --help for usage." >&2
    exit 1
  fi
}

##
# Coerce raw identity input into canonical values and validate them.
#
normalize_inputs() {
  project="$(convert_string "${project}" "package_name")"
  namespace="$(convert_string "${namespace}" "namespace")"
  project_pascalcase="$(to_pascalcase "${project}")"

  validate_namespace "${namespace}" || exit 1
  validate_project_name "${project}" || exit 1
  validate_author "${author}" || exit 1
}

##
# Fill any choice not set on the command line with its default value.
#
# Mirrors the defaults offered by the interactive prompts so that a
# non-interactive run with no feature options yields the same result.
#
apply_noninteractive_defaults() {
  : "${use_php:=y}"
  : "${use_nodejs:=y}"
  : "${use_shell:=y}"
  : "${use_docker:=n}"
  : "${use_release_drafter:=y}"
  : "${use_pr_autoassign:=y}"
  : "${use_funding:=y}"
  : "${use_pr_template:=y}"
  : "${use_renovate:=y}"
  : "${use_docs:=y}"
  : "${use_test_actions:=n}"
  : "${remove_self:=y}"

  if [ "${use_php}" = "y" ]; then
    if [ "${use_php_script}" = "y" ]; then
      use_php_command="n"
    else
      : "${use_php_command:=y}"
    fi

    if [ "${use_php_command}" = "y" ]; then
      : "${php_command_name:=${project}}"
      : "${use_php_command_build:=y}"
      use_php_script="n"
      php_script_name="<unset>"
    else
      : "${use_php_script:=y}"
      : "${php_script_name:=${project}}"
      use_php_command_build="n"
      php_command_name="<unset>"
    fi
  else
    use_php_command="n"
    use_php_command_build="n"
    use_php_script="n"
    php_command_name="<unset>"
    php_script_name="<unset>"
  fi

  [ "${use_shell}" = "y" ] && : "${shell_command_name:=${project}}"
  [ "${use_docker}" = "y" ] && : "${docker_image_name:=$(to_lowercase "${namespace}")/${project}}"

  return 0
}

##
# Print the selected configuration.
#
print_summary() {
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
  [ "${use_php_script}" = "y" ] && echo "    Simple script name           : ${php_script_name}"
  echo "Use NodeJS                       : ${use_nodejs}"
  echo "Use Shell                        : ${use_shell}"
  echo "Use Docker                       : ${use_docker}"
  [ "${use_docker}" = "y" ] && echo "  Docker image name              : ${docker_image_name}"
  echo "Use GitHub release drafter       : ${use_release_drafter}"
  echo "Use GitHub PR author auto-assign : ${use_pr_autoassign}"
  echo "Use GitHub funding               : ${use_funding}"
  echo "Use GitHub PR template           : ${use_pr_template}"
  echo "Use Renovate                     : ${use_renovate}"
  echo "Use Docs                         : ${use_docs}"
  echo "Use GitHub Actions linting       : ${use_test_actions}"
  echo "Remove this script               : ${remove_self}"
  echo "---------------------------------"
  echo
}

##
# Collect configuration through interactive prompts.
#
collect_interactive() {
  echo "Please follow the prompts to adjust your project configuration"
  echo

  [ -z "${namespace}" ] && namespace="$(ask "Namespace (PascalCase)")"
  [ -z "${project}" ] && project="$(ask "Project")"
  [ -z "${author}" ] && author="$(ask "Author")"

  normalize_inputs

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

  use_docker="$(ask_yesno "Use Docker" "N")"
  if [ "${use_docker}" = "y" ]; then
    docker_image_name=$(ask "  Docker image name" "$(to_lowercase "${namespace}")/${project}")
  fi

  use_release_drafter="$(ask_yesno "Use GitHub release drafter")"
  use_pr_autoassign="$(ask_yesno "Use GitHub PR author auto-assign")"
  use_funding="$(ask_yesno "Use GitHub funding")"
  use_pr_template="$(ask_yesno "Use GitHub PR template")"
  use_renovate="$(ask_yesno "Use Renovate")"
  use_docs="$(ask_yesno "Use docs")"
  use_test_actions="$(ask_yesno "Use GitHub Actions linting" "N")"
  remove_self="$(ask_yesno "Remove this script")"

  print_summary

  local should_proceed
  should_proceed="$(ask_yesno "Proceed with project init")"

  if [ "${should_proceed}" != "y" ]; then
    echo
    echo "Aborting."
    exit 1
  fi
}

##
# Collect configuration from options, falling back to defaults.
#
collect_noninteractive() {
  require_identity

  normalize_inputs

  apply_noninteractive_defaults

  print_summary
}

#-------------------------------------------------------------------------------
# MAIN FUNCTION
#-------------------------------------------------------------------------------

##
# Apply the selected configuration to the project files.
#
process_project() {
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

  if [ "${use_docker}" = "y" ]; then
    replace_string_content "yournamespace/yourproject" "${docker_image_name}"
  else
    remove_docker
  fi

  [ "${use_release_drafter}" != "y" ] && remove_release_drafter
  [ "${use_pr_autoassign}" != "y" ] && remove_pr_autoassign
  [ "${use_funding}" != "y" ] && remove_funding
  [ "${use_pr_template}" != "y" ] && remove_pr_template
  [ "${use_renovate}" != "y" ] && remove_renovate
  [ "${use_docs}" != "y" ] && remove_docs
  [ "${use_test_actions}" != "y" ] && remove_test_actions

  cleanup_renovate_managers

  process_readme "${project}"

  process_internal "${namespace}" "${project}" "${author}" "${project_pascalcase}"

  # Remove this init script. "${BASH_SOURCE[0]}" is the script's own path when
  # run as a file, and is empty (or a bare shell name) when piped through
  # 'curl ... | bash', so only a real on-disk script is removed - never the
  # interpreter (e.g. "/bin/bash" when invoked as 'curl ... | /bin/bash -s').
  local script_path="${BASH_SOURCE[0]:-}"
  if [ "${remove_self}" != "n" ] && [ -n "${script_path}" ] && [ -f "${script_path}" ]; then
    rm -- "${script_path}" || true
  fi

  echo
  echo "Initialization complete."
}

main() {
  parse_args "$@"

  check_dependencies || exit 1

  if [ "${interactive}" = "1" ]; then
    collect_interactive
  else
    collect_noninteractive
  fi

  process_project
}

# Run main only when the script is executed, not when it is sourced (e.g. by
# the BATS unit tests). When piped through 'bash -s' the script has no source
# file, so "${BASH_SOURCE[0]}" is empty - that case must still run.
if [ -z "${BASH_SOURCE[0]:-}" ] || [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
