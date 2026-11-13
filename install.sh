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
# ./install.sh
#
# Interactive one-liner (downloads Scaffold, then prompts):
# curl -fsSL https://getscaffold.dev/install.sh | bash
#
# Non-interactive:
# ./install.sh --namespace=AcmeApp --name=acme-app --author="Jane Doe"
#
# Non-interactive one-liner (for AI agents and automation):
# curl -fsSL https://getscaffold.dev/install.sh | \
#   bash -s -- --namespace=AcmeApp --name=acme-app --author="Jane Doe"
#
# When run without the template present (for example piped from curl in an
# empty directory), the script downloads the Scaffold into the current
# directory and then initializes it. The directory must be empty. Piping with
# no options prompts interactively; pass options to run unattended.
#
# Configure the GitHub repository of an existing project (needs GitHub CLI and
# SCAFFOLD_GITHUB_TOKEN):
# curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github
#
# Run "./install.sh --help" for the full list of options.
#
# shellcheck disable=SC2162,SC2015

set -euo pipefail
[ "${SCRIPT_DEBUG-}" = "1" ] && set -x

# Scaffold version. The release workflow rewrites it to the release tag in the
# 'install.sh' it attaches to the release; stays "dev" in a plain checkout.
SCAFFOLD_VERSION="dev"

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
use_schedule=""
use_ai=""
use_ai_arch_docs=""
remove_self=""

# GitHub repository configuration. Empty values follow the same rule as the
# feature selections above.
use_github=""
github_owner=""
github_repo=""
github_settings=""
github_description=""
github_merge=""
github_labels=""
github_labels_prune=""
github_ruleset=""
github_required_checks=""
github_create=""
github_visibility=""
github_push=""
github_wait_checks=""
github_wait_timeout=""
dry_run=0

# Seconds between CI polls, and seconds the first CI run may take to appear.
github_poll_interval=10
github_runs_timeout=60

# Where a derived identity value came from, named in validation errors.
# Empty when the value was typed or passed as its own option.
namespace_source=""
project_source=""
github_owner_source=""
github_repo_source=""

# Values the identity prompts and the reproduce command treat as defaults.
namespace_default=""
project_default=""
github_owner_default=""
github_repo_default=""

# Repository state read from the GitHub API as "key=value" lines.
github_repo_state=""

# Whether the repository exists on GitHub: "y", "n", or empty before the read.
github_repo_exists=""

# Set once this run creates the repository, and to the pushed commit.
github_created=0
github_pushed_sha=""

# The required status checks rule computed from CI, as a JSON object.
github_checks_rule=""

# CI runs of the pushed commit as "status<TAB>conclusion<TAB>name" lines.
github_runs=""

# App that owns the check runs of GitHub Actions workflows.
GITHUB_ACTIONS_APP_ID=15368

# Labels applied to the GitHub repository as "name|colour|description".
GITHUB_LABELS=(
  "AUTOMERGE|934BF4|Pull request has been approved and set to automerge"
  "BLOCKED|D93F0B|Issue or pull request is blocked"
  "CONFLICT|BC143E|Pull request has a conflict that needs to be resolved before it can be merged"
  "Dependencies|62E795|Pull request was raised automatically by a dependency bot"
  "DO NOT MERGE|D93F0B|Do not merge this pull request"
  "Do not review|D93F0B|Do not review this pull request"
  "Needs review|5319E7|Pull request needs a review from assigned developers"
  "Ready for test|0E8A16|Pull request is ready for manual testing"
  "Ready to be merged|C2E0C6|Pull request is ready to be merged (assigned after testing is complete)"
  "Requires more work|B60205|Pull request was reviewed and reviewer(s) asked to work further on the pull request"
  "UPSTREAM|FBCA04|Issue or pull request is related to an upstream project"
  "URGENT|D93F0B|Pull request needs to be urgently reviewed"
)

# Ruleset that protects the default branch.
GITHUB_RULESET_NAME="default-branch"

# Ref (tag, branch, or commit) to bootstrap the template from when the script is
# run without the template present. Empty means "use the release of
# SCAFFOLD_VERSION", or the default branch for "dev".
archive_ref=""

# Sub-command: "install" initialises the template, "github" only configures
# the GitHub repository.
subcommand="install"

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
  local input_string="${1}"
  local conversion_type="${2}"

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

to_lowercase() {
  echo "${1}" | tr '[:upper:]' '[:lower:]'
}

to_pascalcase() { echo "${1}" | awk -F'[-_ ]' '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); } 1' OFS=''; }

#-------------------------------------------------------------------------------
# FILE OPERATION FUNCTIONS
#-------------------------------------------------------------------------------

##
# List the files containing a needle, restricted to template-owned paths.
#
# '.claude' holds both template-owned and consumer-owned files, so it is
# excluded from the recursive search and its shipped paths are searched
# explicitly. Paths are NUL-terminated, so callers read them with 'xargs -0'
# and a space in the project path stays inside 1 argument.
#
# @param $1 string Needle (string to find)
# @param $2 string Path relative to the project root to search instead of the
#                  whole tree (optional)
#
sweep_files() {
  local needle="${1}"
  local target="${2:-}"

  if [ -n "${target}" ]; then
    grep -rIl --null "${needle}" "$(pwd)/${target}" 2>/dev/null || true
    return 0
  fi

  grep -rIl --null --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir=".claude" --exclude-dir="vendor" --exclude-dir="node_modules" "${needle}" "$(pwd)" || true
  grep -rIl --null "${needle}" "$(pwd)/.claude/settings.json" "$(pwd)/.claude/skills/update-architecture-docs" 2>/dev/null || true
}

##
# Replace all occurrences of a string in files.
#
# @param $1 string Needle (string to find)
# @param $2 string Replacement (string to replace with)
#
replace_string_content() {
  local needle="${1}"
  local replacement="${2}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  sweep_files "${needle}" | xargs -0 sed "${sed_opts[@]}" "s!${needle}!${replacement}!g" || true
}

remove_string_content() {
  local token="${1}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  sweep_files "${token}" | LC_ALL=C.UTF-8 xargs -0 sed "${sed_opts[@]}" -e "/^${token}/d" || true
}

remove_string_content_line() {
  local token="${1}"
  local target="${2:-}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  sweep_files "${token}" "${target}" | LC_ALL=C.UTF-8 xargs -0 sed "${sed_opts[@]}" -e "/${token}/d" || true
}

##
# Drop a workflow's suppression entries from the zizmor configuration.
#
# 'zizmor.yml' is absent when Actions linting is not selected, and grepping a
# missing file errors.
#
# @param $1 string Workflow file name
#
remove_zizmor_entry() {
  [ -f zizmor.yml ] || return 0

  remove_string_content_line "${1}" "zizmor.yml"
}

##
# Remove the template's own 'scaffold-*' workflows and their zizmor entries.
#
remove_scaffold_workflows() {
  local workflow

  for workflow in .github/workflows/scaffold-*.yml; do
    [ -e "${workflow}" ] || continue
    rm -f "${workflow}"
    remove_zizmor_entry "${workflow##*/}"
  done
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
  sweep_files "#;> $token" | LC_ALL=C.UTF-8 xargs -0 sed "${sed_opts[@]}" -e "/#;< $token/,/#;> $token/d" || true
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
  sweep_files "${token}" | LC_ALL=C.UTF-8 xargs -0 sed "${sed_opts[@]}" -e "/${token}/d" || true
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
  local label="${1}"
  local prompt="${1}"
  local default="${2-}"
  local result=""

  if [ -n "${default}" ]; then
    prompt="${prompt} [${default}]: "
  else
    prompt="${prompt}: "
  fi

  while [ -z "${result}" ]; do
    if ! read -p "${prompt}" result; then
      # Stdin reached EOF with no value. This happens when the script is piped
      # (e.g. 'curl ... | bash') without options, so there is nothing to read.
      if [ -n "${default}" ]; then
        result="${default}"
        break
      fi
      echo "Error: No input available for '${label}'. Pass options (run with --help) or run interactively." >&2
      exit 1
    fi
    if [ -n "${default}" ] && [ -z "${result}" ]; then
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
  result="$(to_lowercase "${result:-${default}}")"
  echo "${result}"
}

##
# Prompt user to choose one of the allowed values.
#
# @param $1 string Prompt text
# @param $2 string Default value
# @param $3 string Space-separated allowed values
# @return string Chosen value
#
ask_choice() {
  local label="${1}"
  local default="${2}"
  local options="${3}"
  local choices
  local result

  choices="$(echo "${options}" | tr ' ' '/')"

  while :; do
    if ! read -p "${label} (${choices}) [${default}]: " result; then
      # Stdin reached EOF with no value. This happens when the script is piped
      # (e.g. 'curl ... | bash') without options, so there is nothing to read.
      if [ -n "${default}" ]; then
        result="${default}"
        break
      fi
      echo "Error: No input available for '${label}'. Pass options (run with --help) or run interactively." >&2
      exit 1
    fi
    result="$(to_lowercase "${result:-${default}}")"
    [[ ${result} != *" "* ]] && [[ " ${options} " == *" ${result} "* ]] && break
  done

  echo "${result}"
}

##
# Prompt user for a value that may be left empty.
#
# @param $1 string Prompt text
# @param $2 string Default value, returned on empty input (optional)
# @return string User input or default value
#
ask_optional() {
  local prompt="${1}"
  local default="${2-}"
  local result=""

  if [ -n "${default}" ]; then
    prompt="${prompt} [${default}]: "
  else
    prompt="${prompt}: "
  fi

  read -p "${prompt}" result || true
  echo "${result:-${default}}"
}

#-------------------------------------------------------------------------------
# INPUT VALIDATION FUNCTIONS
#-------------------------------------------------------------------------------

##
# Check whether a command is available.
#
# @param $1 string Command name
#
has_command() {
  command -v "${1}" >/dev/null 2>&1
}

check_dependencies() {
  local missing=() required=("sed" "grep" "tr" "awk" "curl")
  for cmd in "${required[@]}"; do has_command "${cmd}" || missing+=("${cmd}"); done
  [ ${#missing[@]} -gt 0 ] && echo "Error: Missing required commands: ${missing[*]}" >&2 && return 1
  return 0
}

validate_namespace() {
  [[ ${1} =~ ^[A-Z][a-zA-Z0-9]*$ ]] || {
    echo "Error: Namespace must be PascalCase (e.g., MyNamespace)" >&2
    return 1
  }
}

validate_project_name() {
  [[ ${1} =~ ^[a-z0-9-]+$ ]] && [[ ! ${1} =~ ^- ]] && [[ ! ${1} =~ -$ ]] || {
    echo "Error: Project name must be lowercase with hyphens (e.g., my-project)" >&2
    return 1
  }
}

validate_author() {
  [ -n "${1}" ] || {
    echo "Error: Author name cannot be empty" >&2
    return 1
  }
}

validate_php_mode() {
  if [ "${use_php_command}" = "y" ] && [ "${use_php_script}" = "y" ]; then
    echo "Error: --php-command and --php-script cannot be used together." >&2
    return 1
  fi
}

##
# Validate a comma-separated list of merge methods.
#
# @param $1 string Merge methods, e.g. "squash,rebase"
#
validate_github_merge() {
  local methods="${1}"
  local method
  local count=0

  for method in ${methods//,/ }; do
    case "${method}" in
      merge | squash | rebase) count=$((count + 1)) ;;
      *)
        echo "Error: Invalid merge method for --github-merge: ${method}. Allowed values: merge, squash, rebase." >&2
        return 1
        ;;
    esac
  done

  [ "${count}" -gt 0 ] || {
    echo "Error: --github-merge needs at least 1 of: merge, squash, rebase." >&2
    return 1
  }
}

##
# Validate an identity value and exit when it is invalid.
#
# A derived value was never typed, so its error names the source and the
# option that overrides it.
#
# @param $1 string Validator function
# @param $2 string Value to validate
# @param $3 string Label, e.g. "Namespace"
# @param $4 string Source of a derived value, e.g. "--github-owner" (optional)
# @param $5 string Option that sets the value explicitly
#
validate_identity_value() {
  local validator="${1}"
  local value="${2}"
  local label="${3}"
  local source="${4}"
  local option="${5}"

  if [ -z "${source}" ]; then
    "${validator}" "${value}" || exit 1
    return 0
  fi

  "${validator}" "${value}" 2>/dev/null && return 0

  echo "Error: ${label} derived from ${source} is invalid: '${value}'. Pass ${option} explicitly." >&2
  exit 1
}

#-------------------------------------------------------------------------------
# COMPONENT REMOVAL FUNCTIONS
#-------------------------------------------------------------------------------

remove_php() {
  remove_php_command
  remove_php_command_build
  remove_php_script
  remove_php_classes
  remove_php_library
  remove_php_entrypoint
  remove_php_release

  rm -f composer.json || true
  rm -f composer.lock || true
  rm -Rf vendor || true
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
  rm -f bin/php-command || true
  rmdir bin >/dev/null 2>&1 || true
  rm -Rf src/Command || true
  rm -f tests/phpunit/Functional/ApplicationFunctionalTestCase.php || true
  rm -f tests/phpunit/Functional/RollDiceCommandTest.php || true
  rm -f tests/phpunit/Functional/SayHelloCommandTest.php || true
  rm -f docs/content/php/php-command.mdx || true

  remove_tokens_with_content "PHP_COMMAND"

  remove_string_content_line '"bin\/php-command"'
}

remove_php_command_build() {
  rm -f box.json || true
  rm -f docs/content/ci/php-packaging.mdx || true
  remove_tokens_with_content "PHP_PHAR"

  [ -f composer.json ] || return 0

  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  # JSON carries no token markers, so the Box build and the bin plugin that
  # installs Box are removed by key. The "build" range ends on the array's
  # closing bracket with or without a comma, so it never runs to the end of
  # the file.
  sed "${sed_opts[@]}" \
    -e '/^ *"bamarni\/composer-bin-plugin": /d' \
    -e '/^ *"build": \[$/,/^ *\],\{0,1\}$/d' \
    -e 's/^\( *"reset": "rm -Rf vendor\) vendor-bin /\1 /' \
    composer.json
}

##
# Remove the release workflow, which exists only to attach an asset to a tag.
#
remove_php_release() {
  rm -f .github/workflows/release-php.yml || true

  remove_zizmor_entry "release-php.yml"

  remove_tokens_with_content "PHP_RELEASE"
}

remove_php_script() {
  local new_name="${1:-php-script}"
  rm -f php-script || true
  rm -f tests/phpunit/Unit/ExampleScriptUnitTest.php || true
  rm -f tests/phpunit/Unit/ScriptUnitTestCase.php || true
  rm -f tests/phpunit/Functional/ScriptFunctionalTestCase.php || true
  rm -f tests/phpunit/Functional/ExampleScriptFunctionalTest.php || true
  remove_tokens_with_content "PHP_SCRIPT"
  remove_string_content_line '"php-script"'

  replace_string_content '"'"${new_name}"'",' '"'"${new_name}"'"'
}

##
# Remove the class source directory and the tooling references to it.
#
remove_php_classes() {
  rm -Rf src || true

  remove_tokens_with_content "!PHP_SCRIPT"
}

##
# Remove the class-library example and notes from a project with an entry point.
#
remove_php_library() {
  rm -f src/Example.php || true
  rm -f tests/phpunit/Unit/ExampleUnitTest.php || true

  remove_tokens_with_content "PHP_LIBRARY"
}

##
# Remove the declaration and the documentation of an executable entry point.
#
remove_php_entrypoint() {
  remove_tokens_with_content "!PHP_LIBRARY"

  [ -f composer.json ] || return 0

  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  # An empty "bin" array passes 'composer validate' but fails the
  # 'composer normalize' check the shipped workflow runs. Both ends of the
  # range are anchored so an unexpected layout removes nothing instead of
  # swallowing the keys that follow.
  sed "${sed_opts[@]}" -e '/^ *"bin": \[$/,/^ *\],$/d' composer.json
}

remove_nodejs() {
  rm -f package.json || true
  rm -f package-lock.json || true
  rm -f yarn.lock || true
  rm -f .npmrc || true
  rm -Rf node_modules || true

  rm -f nodejs-script || true
  rm -f eslint.config.js || true
  rm -f .c8rc.json || true
  rm -Rf tests/nodejs || true

  remove_string_content_line "\/.npmignore" ".gitattributes"

  rm -f .github/workflows/test-nodejs.yml || true
  rm -f .github/workflows/release-nodejs.yml || true

  remove_zizmor_entry "release-nodejs.yml"

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
  rm -f shell-command.sh || true
  rm -Rf tests/bats || true

  rm -f .github/workflows/test-shell.yml || true

  remove_tokens_with_content "SHELL"
}

remove_docker() {
  rm -f Dockerfile || true
  rm -f entrypoint.sh || true

  rm -f .github/workflows/test-docker.yml || true
  rm -f .github/workflows/release-docker.yml || true

  remove_tokens_with_content "DOCKER"
}

remove_release_drafter() {
  rm -f .github/workflows/draft-release-notes.yml || true
  rm -f .github/release-drafter.yml || true
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
  rm -f .github/workflows/update-dependencies.yml || true
  remove_tokens_with_content "RENOVATE"
}

remove_renovate_managers() {
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

##
# Stop Renovate from raising the floor of the 'require' constraints.
#
# A library's 'require' block is the support window its consumers inherit,
# and with no committed lock file a bump changes nothing the project resolves.
#
disable_renovate_require_updates() {
  [ -f renovate.json ] || return 0

  local rule
  # 'read -d' exits non-zero at the end of the heredoc.
  IFS= read -r -d '' rule <<'RULE' || true
        {
            "matchManagers": ["composer"],
            "matchFileNames": ["composer.json"],
            "matchDepTypes": ["require"],
            "enabled": false
        },
RULE

  # BSD 'sed a\' strips leading whitespace from the appended text, and awk
  # rejects a newline in a '-v' value, so the rule travels through ENVIRON.
  RULE="${rule}" awk '{ print } /"packageRules": \[/ { printf "%s", ENVIRON["RULE"] }' renovate.json >renovate.json.tmp
  mv renovate.json.tmp renovate.json
}

remove_ai() {
  rm -f CLAUDE.md || true
  rm -f AGENTS.md || true
  rm -Rf .claude || true

  remove_tokens_with_content "AI"
}

remove_ai_arch_docs() {
  rm -Rf .claude/skills/update-architecture-docs || true
  rm -Rf docs/content/architecture || true

  # Prefix match also removes AI_ARCH_DOCS_MERMAID and AI_ARCH_DOCS_PLANTUML.
  remove_tokens_with_content "AI_ARCH_DOCS"
}

remove_docs() {
  if [ -d docs/content/architecture ]; then
    # Keep the AI architecture docs: relocate them from the site content
    # tree to docs/architecture and rewrite path references to match.
    # 'mv' would nest into a pre-existing destination directory.
    rm -Rf .architecture-preserve-tmp || true
    mv docs/content/architecture .architecture-preserve-tmp
    rm -Rf docs || true
    mkdir -p docs
    mv .architecture-preserve-tmp docs/architecture
    replace_string_content "docs/content/architecture" "docs/architecture"
  else
    rm -Rf docs || true
    remove_string_content_line "\/docs" ".gitattributes"
  fi

  rm -f .github/workflows/test-docs.yml || true
  rm -f .github/workflows/release-docs.yml || true

  remove_tokens_with_content "DOCS"
}

remove_test_actions() {
  rm -f .github/workflows/test-actions.yml || true
  rm -f .github/.yamllint-for-gha.yml || true
  rm -f zizmor.yml || true
}

remove_schedule() {
  remove_tokens_with_content "SCHEDULE"
}

#-------------------------------------------------------------------------------
# PROCESSING FUNCTIONS
#-------------------------------------------------------------------------------

##
# Reduce the PHP stack to a class library with no entry point.
#
process_php_library() {
  remove_php_command
  remove_php_command_build
  remove_php_script
  remove_php_entrypoint
  remove_php_release
  disable_renovate_require_updates
}

##
# Keep only the selected diagram format in the AI architecture docs.
#
process_ai_arch_docs() {
  case "${use_ai_arch_docs:-none}" in
    mermaid) remove_tokens_with_content "AI_ARCH_DOCS_PLANTUML" ;;
    plantuml) remove_tokens_with_content "AI_ARCH_DOCS_MERMAID" ;;
    none) ;;
  esac
}

##
# Trim Claude Code permission rules to match the selected features.
#
# The template ships '.claude/settings.json' with the full command allow-list.
# Rules for features that were not selected are removed so that a generated
# project only pre-approves commands it can actually run.
#
process_claude_settings() {
  local file=".claude/settings.json"
  [ -f "${file}" ] || return 0

  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')

  [ "${use_php:-n}" != "y" ] && sed "${sed_opts[@]}" -e '/"Bash(composer /d' -e '/phpcs:/d' -e '/phpcbf:/d' -e '/phpstan:/d' -e '/rector:/d' -e '/phpunit:/d' "${file}"
  [ "${use_shell:-n}" != "y" ] && sed "${sed_opts[@]}" -e '/bats:/d' "${file}"
  [ "${use_nodejs:-n}" != "y" ] && sed "${sed_opts[@]}" -e '/"Bash(npm run lint/d' -e '/"Bash(npm run test/d' "${file}"
  [ "${use_docs:-n}" != "y" ] && sed "${sed_opts[@]}" -e '/"Bash(npm start)"/d' -e '/"Bash(npm run build)"/d' -e '/"Bash(npm run spellcheck)"/d' "${file}"
  [ "${use_docker:-n}" != "y" ] && sed "${sed_opts[@]}" -e '/"Bash(docker /d' "${file}"
  [ "${use_ai_arch_docs:-none}" != "plantuml" ] && sed "${sed_opts[@]}" -e '/plantuml:/d' "${file}"

  # 'npm install' is shared by the NodeJS feature and the documentation site, so
  # keep it while either is present.
  if [ "${use_nodejs:-n}" != "y" ] && [ "${use_docs:-n}" != "y" ]; then
    sed "${sed_opts[@]}" -e '/"Bash(npm install)"/d' "${file}"
  fi

  # Drop a trailing comma left on the final array element after any removals.
  awk 'NR>1{if($0~/^ *]/)sub(/,$/,"",prev);print prev}{prev=$0}END{if(NR>0)print prev}' "${file}" >"${file}.tmp" && mv "${file}.tmp" "${file}"
}

process_readme() {
  local project="${1}"

  mv README.dist.md "README.md" >/dev/null 2>&1 || true

  # Update placeholder image URL and alt text in README.md
  replace_string_content 'text=Yourproject' "text=${project// /+}"
  replace_string_content 'alt="Yourproject logo"' "alt=\"${project} logo\""

  curl -sS "https://placehold.jp/000000/ffffff/200x200.png?text=${project// /+}&css=%7B%22border-radius%22%3A%22%20100px%22%7D" >logo.tmp.png || true
  if [ -s "logo.tmp.png" ]; then
    mv logo.tmp.png "logo.png" >/dev/null 2>&1 || true
  fi
  rm -f logo.tmp.png || true
}

##
# Promote the distributable CONTRIBUTING guide to its final name.
#
# Scaffold keeps its own CONTRIBUTING.md; CONTRIBUTING.dist.md is the guide that
# ships to generated projects, mirroring the README.dist.md handling.
#
process_contributing() {
  mv CONTRIBUTING.dist.md "CONTRIBUTING.md" >/dev/null 2>&1 || true
}

##
# Replace the self-update skill references with placeholder tokens.
#
# The initialised project must keep instructions that point at the upstream
# template repository rather than at the project's own namespace. These
# references are hidden behind tokens before the bulk replacements run and
# put back afterwards by restore_skill_references().
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

  rm -f SECURITY.md || true
  rm -f install-key.asc || true
  rm -Rf ".scaffold" || true

  remove_scaffold_workflows

  protect_skill_references

  # Replace the real repository name with the placeholder token used in the
  # replacements below.
  replace_string_content "AlexSkrypnyk/scaffold" "yournamespace/yourproject"

  replace_string_content "YourNamespace" "${namespace}"
  replace_string_content "yournamespace" "${namespace_lowercase}"
  replace_string_content "yourproject" "${project}"
  replace_string_content "Yourproject" "${project_pascalcase}"
  replace_string_content "Your Name" "${author}"
  replace_string_content "Alex Skrypnyk" "${author}"

  remove_string_content "Generic project scaffold template"

  restore_skill_references

  remove_string_content "# Uncomment the lines below"
  uncomment_line ".gitattributes" "\/.editorconfig"
  uncomment_line ".gitattributes" "\/.gitattributes"
  uncomment_line ".gitattributes" "\/.github"
  uncomment_line ".gitattributes" "\/.gitignore"
  uncomment_line ".gitattributes" "\/docs"
  uncomment_line ".gitattributes" "\/logo.png"
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
# GITHUB REPOSITORY CONFIGURATION
#-------------------------------------------------------------------------------

##
# Turn off command tracing until xtrace_restore().
#
# SCRIPT_DEBUG traces every expanded command, which would print the token.
# kcov reads coverage from the same trace, so the lines that run with tracing
# off are marked as excluded.
#
xtrace_suspend() {
  xtrace_was_on=0

  case $- in
    *x*)
      xtrace_was_on=1
      set +x
      ;;
  esac
}

##
# Turn command tracing back on when xtrace_suspend() turned it off.
#
xtrace_restore() {
  # LCOV_EXCL_START
  [ "${xtrace_was_on:-0}" != "1" ] || set -x
  # LCOV_EXCL_STOP
}

##
# Check whether SCAFFOLD_GITHUB_TOKEN is set, without tracing its value.
#
github_token_set() {
  local status=0

  xtrace_suspend
  # LCOV_EXCL_START
  [ -n "${SCAFFOLD_GITHUB_TOKEN:-}" ] || status=1
  xtrace_restore
  # LCOV_EXCL_STOP

  return "${status}"
}

##
# Run 'gh' authenticated with SCAFFOLD_GITHUB_TOKEN only.
#
# GH_TOKEN overrides the account 'gh' is logged in with, and GITHUB_TOKEN is
# blanked so a token already exported in the shell is never used.
#
gh_run() {
  local status=0

  xtrace_suspend
  # LCOV_EXCL_START
  GH_TOKEN="${SCAFFOLD_GITHUB_TOKEN:-}" GITHUB_TOKEN="" gh "$@" || status=$?
  xtrace_restore
  # LCOV_EXCL_STOP

  return "${status}"
}

##
# Run a 'gh' call that changes the repository, or print it under --dry-run.
#
# A request body passed on stdin with '--input -' is printed with the call.
#
gh_write() {
  if [ "${dry_run}" != "1" ]; then
    gh_run "$@"
    return
  fi

  local call
  printf -v call ' %q' "$@"
  echo "  [dry-run] gh${call}"

  case " $* " in
    *" --input - "*) sed 's/^/    /' ;;
  esac
}

##
# Check the prerequisites of the GitHub calls and report everything missing.
#
# @return int 0 when 'gh' is installed and SCAFFOLD_GITHUB_TOKEN is set.
#
github_prerequisites() {
  local reasons=""
  local actions=""

  if ! has_command gh; then
    reasons="'gh' is not installed"
    actions="Install GitHub CLI (https://cli.github.com)"
  fi

  if ! github_token_set; then
    reasons="${reasons:+${reasons}; }SCAFFOLD_GITHUB_TOKEN is not set"

    if [ -n "${actions}" ]; then
      actions="${actions} and set SCAFFOLD_GITHUB_TOKEN"
    else
      actions="Set SCAFFOLD_GITHUB_TOKEN"
    fi
  fi

  [ -n "${reasons}" ] || return 0

  # The install removes this script at the end, so the hint downloads it.
  echo "Skipping GitHub repository settings: ${reasons}."
  echo "${actions}, then run 'curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github'."

  return 1
}

##
# Print the GitHub "owner/repo" of the 'origin' remote.
#
# Prints nothing outside a repository root, without an 'origin' remote, for a
# remote not on GitHub, and for a plain clone of the template itself.
#
github_origin() {
  [ -e .git ] || return 0
  has_command git || return 0

  local url
  url="$(git remote get-url origin 2>/dev/null || true)"
  url="${url%/}"
  url="${url%.git}"

  [[ ${url} =~ github\.com[:/]([^/]+)/([^/]+)$ ]] || return 0

  local slug="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"

  [ "$(to_lowercase "${slug}")" != "alexskrypnyk/scaffold" ] || return 0

  echo "${slug}"
}

##
# Check that the GitHub owner and repository match the 'origin' remote.
#
# An empty owner or repository takes the remote's value. The remote is never
# rewritten, so another repository would receive this checkout's history.
#
# @return int 1 when they name another repository than 'origin'.
#
github_check_origin() {
  local origin
  origin="$(github_origin)"

  [ -n "${origin}" ] || return 0

  local wanted="${github_owner:-${origin%%/*}}/${github_repo:-${origin#*/}}"

  [ "$(to_lowercase "${wanted}")" != "$(to_lowercase "${origin}")" ] || return 0

  echo "Error: GitHub repository ${wanted} does not match the 'origin' remote ${origin}. Change the options or the remote." >&2
  return 1
}

##
# Resolve the GitHub owner and repository from options and 'origin', then
# derive the namespace and project defaults from them.
#
# Exits when the options name another repository than 'origin', because the
# remote is never rewritten.
#
resolve_github_identity() {
  [ -z "${github_owner}" ] || github_owner_source="--github-owner"
  [ -z "${github_repo}" ] || github_repo_source="--github-repo"

  github_check_origin || exit 1

  local origin
  origin="$(github_origin)"

  if [ -n "${origin}" ]; then
    if [ -z "${github_owner}" ]; then
      github_owner="${origin%%/*}"
      github_owner_source="the 'origin' remote"
    fi

    if [ -z "${github_repo}" ]; then
      github_repo="${origin#*/}"
      github_repo_source="the 'origin' remote"
    fi
  fi

  [ -z "${github_owner}" ] || namespace_default="$(to_pascalcase "${github_owner}")"
  [ -z "${github_repo}" ] || project_default="$(convert_string "${github_repo//_/-}" "package_name")"
}

##
# Fill the namespace and project not passed as options with derived defaults.
#
apply_identity_defaults() {
  if [ -z "${namespace}" ] && [ -n "${namespace_default}" ]; then
    namespace="${namespace_default}"
    namespace_source="${github_owner_source}"
  fi

  if [ -z "${project}" ] && [ -n "${project_default}" ]; then
    project="${project_default}"
    project_source="${github_repo_source}"
  fi
}

##
# Fill the GitHub owner and repository left empty by options and 'origin'.
#
# The owner falls back to the token's login, never to the namespace.
#
# @param $1 string Repository name to fall back to
#
github_default_identity() {
  if [ -z "${github_owner}" ]; then
    github_owner="$(gh_run api user --jq .login 2>/dev/null || true)"
  fi

  if [ -z "${github_repo}" ]; then
    github_repo="${1}"
  fi

  github_owner_default="${github_owner}"
  github_repo_default="${github_repo}"
}

##
# Fill the GitHub section choices not set on the command line.
#
github_apply_defaults() {
  : "${github_settings:=y}"
  : "${github_labels:=y}"
  : "${github_labels_prune:=n}"
  : "${github_ruleset:=y}"
  : "${github_merge:=squash,rebase}"
  : "${github_required_checks:=y}"
  : "${github_create:=n}"
  : "${github_visibility:=public}"
  : "${github_push:=y}"
  : "${github_wait_checks:=y}"
  : "${github_wait_timeout:=1800}"
}

##
# Read the repository state that the sections compare against.
#
# Sets github_repo_exists to "y", or to "n" on a 404.
#
# @return int 0 when read, 3 when the repository does not exist, 1 otherwise.
#
github_load_repo() {
  if [[ ! ${github_owner} =~ ^[A-Za-z0-9-]+$ ]]; then
    echo "Error: Invalid GitHub owner: '${github_owner}'. Pass --github-owner." >&2
    return 1
  fi

  if [[ ! ${github_repo} =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Error: Invalid GitHub repository: '${github_repo}'. Pass --github-repo." >&2
    return 1
  fi

  local keys='"default_branch", "description", "allow_merge_commit", "allow_squash_merge", "allow_rebase_merge", "squash_merge_commit_title", "squash_merge_commit_message", "allow_auto_merge", "allow_update_branch", "delete_branch_on_merge", "has_issues", "has_wiki", "has_projects", "has_discussions"'
  local output

  if output="$(gh_run api "repos/${github_owner}/${github_repo}" --jq ". as \$repo | [${keys}][] | \"\\(.)=\\(\$repo[.] | if . == null then \"\" else . end)\"" 2>&1)"; then
    github_repo_state="${output}"
    github_repo_exists="y"
    return 0
  fi

  if [[ ${output} == *"HTTP 404"* ]]; then
    github_repo_exists="n"
    return 3
  fi

  echo "Error: Could not read GitHub repository ${github_owner}/${github_repo}: ${output//$'\n'/ }" >&2
  return 1
}

##
# Report a repository that does not exist and is not being created.
#
github_missing_error() {
  echo "Error: GitHub repository ${github_owner}/${github_repo} does not exist, or the token cannot access it. Pass --github-create to create it." >&2
}

##
# Print 1 value of the repository state read by github_load_repo().
#
# @param $1 string Key, e.g. "has_wiki"
#
github_state() {
  local line

  while IFS= read -r line; do
    if [ "${line%%=*}" = "${1}" ]; then
      echo "${line#*=}"
      return 0
    fi
  done <<<"${github_repo_state}"
}

##
# Report a failed GitHub call of 1 section.
#
# @param $1 string Section label, e.g. "Ruleset"
# @param $2 string Token permission the call needs
# @param $3 string Output of the failed call
# @return int 2 when the section is skipped on a 403, 1 otherwise.
#
github_section_error() {
  local label="${1}"
  local permission="${2}"
  local output="${3//$'\n'/ }"

  if [[ ${output} == *"Upgrade to GitHub Pro"* ]]; then
    echo "  ${label}: skipped (needs GitHub Pro or a public repository)"
    return 2
  fi

  if [[ ${output} == *"HTTP 403"* ]]; then
    echo "  ${label}: skipped (token lacks ${permission})"
    return 2
  fi

  echo "  ${label}: failed (${output})" >&2
  return 1
}

##
# Run a write call of 1 section and report a failure.
#
# @param $1 string Section label
# @param $2 string Token permission the call needs
# @param $@ Arguments for 'gh'
# @return int 0 on success, 2 when skipped on a 403, 1 otherwise.
#
github_call() {
  local label="${1}"
  local permission="${2}"
  shift 2

  local output

  # Only the dry-run listing is shown; each section reports its own outcome.
  if output="$(gh_write "$@" 2>&1)"; then
    [ "${dry_run}" != "1" ] || [ -z "${output}" ] || echo "${output}"
    return 0
  fi

  github_section_error "${label}" "${permission}" "${output}"
}

##
# Print the outcome of 1 section, worded for a dry run when needed.
#
# @param $1 string Section label
# @param $2 string Outcome of a dry run, e.g. "would update"
# @param $3 string Outcome of a real run, e.g. "updated"
# @param $4 string Details
#
github_report() {
  local outcome="${3}"

  [ "${dry_run}" != "1" ] || outcome="${2}"

  echo "  ${1}: ${outcome} ${4}"
}

##
# Run 1 section, treating a skip on a 403 as success.
#
# @param $@ Section function and its arguments
#
github_run_section() {
  "$@" && return 0

  [ "$?" -eq 2 ]
}

##
# Print the general settings to apply as "key=value" lines.
#
github_desired_settings() {
  local merge=",${github_merge},"
  local pair
  local value

  for pair in merge:allow_merge_commit squash:allow_squash_merge rebase:allow_rebase_merge; do
    value="false"
    [[ ${merge} != *",${pair%%:*},"* ]] || value="true"
    echo "${pair#*:}=${value}"
  done

  if [[ ${merge} == *",squash,"* ]]; then
    echo "squash_merge_commit_title=PR_TITLE"
    echo "squash_merge_commit_message=BLANK"
  fi

  echo "allow_auto_merge=true"
  echo "allow_update_branch=true"
  echo "delete_branch_on_merge=true"
  echo "has_issues=true"
  echo "has_wiki=false"
  echo "has_projects=false"
  echo "has_discussions=false"

  # An empty description is never sent, so an existing one is never blanked.
  # Each line is 1 setting, so a newline in the description would add others.
  [ -z "${github_description}" ] || echo "description=${github_description//[$'\r\n']/ }"
}

##
# Apply the general settings that differ from the repository state.
#
github_apply_settings() {
  local args=()
  local changed=()
  local line
  local key
  local value

  while IFS= read -r line; do
    key="${line%%=*}"
    value="${line#*=}"

    [ "$(github_state "${key}")" != "${value}" ] || continue

    changed+=("${key}")

    case "${value}" in
      true | false) args+=(-F "${key}=${value}") ;;
      *) args+=(-f "${key}=${value}") ;;
    esac
  done < <(github_desired_settings)

  if [ "${#changed[@]}" -eq 0 ]; then
    echo "  General settings: unchanged"
    return 0
  fi

  github_call "General settings" "Administration: write" api --method PATCH "repos/${github_owner}/${github_repo}" --silent "${args[@]}" || return $?

  github_report "General settings" "would update" "updated" "${changed[*]}"
}

##
# Create or update the baked-in labels, and delete the others when pruning.
#
# Label names match case-insensitively, as they do on GitHub.
#
github_apply_labels() {
  local slug="${github_owner}/${github_repo}"
  local output=""

  # A dry run that would create the repository has no labels to read.
  if [ "${github_repo_exists}" != "n" ] && ! output="$(gh_run api "repos/${slug}/labels" --paginate --jq '.[] | [.name, .color, (.description // "")] | join("\t")' 2>&1)"; then
    github_section_error "Labels" "Issues: read" "${output}"
    return $?
  fi

  local lines=()
  local names=()
  local line

  while IFS= read -r line; do
    [ -n "${line}" ] || continue
    lines+=("${line}")
    names+=("$(to_lowercase "${line%%$'\t'*}")")
  done <<<"${output}"

  local created=0
  local updated=0
  local unchanged=0
  local deleted=0
  local wanted="|"
  local entry name colour description lower existing rest i

  for entry in "${GITHUB_LABELS[@]}"; do
    name="${entry%%|*}"
    rest="${entry#*|}"
    colour="${rest%%|*}"
    description="${rest#*|}"
    lower="$(to_lowercase "${name}")"
    wanted="${wanted}${lower}|"

    existing=""
    for ((i = 0; i < ${#names[@]}; i++)); do
      if [ "${names[i]}" = "${lower}" ]; then
        existing="${lines[i]#*$'\t'}"
        break
      fi
    done

    if [ -n "${existing}" ] && [ "$(to_lowercase "${existing%%$'\t'*}")" = "$(to_lowercase "${colour}")" ] && [ "${existing#*$'\t'}" = "${description}" ]; then
      unchanged=$((unchanged + 1))
      continue
    fi

    github_call "Labels" "Issues: write" label create "${name}" --repo "${slug}" --color "${colour}" --description "${description}" --force || return $?

    if [ -n "${existing}" ]; then
      updated=$((updated + 1))
    else
      created=$((created + 1))
    fi
  done

  if [ "${github_labels_prune}" = "y" ]; then
    for ((i = 0; i < ${#names[@]}; i++)); do
      [[ ${wanted} != *"|${names[i]}|"* ]] || continue

      github_call "Labels" "Issues: write" label delete "${lines[i]%%$'\t'*}" --repo "${slug}" --yes || return $?
      deleted=$((deleted + 1))
    done
  fi

  local summary

  if [ "${dry_run}" = "1" ]; then
    summary="${created} to create, ${updated} to update, ${unchanged} unchanged"
    [ "${github_labels_prune}" != "y" ] || summary="${summary}, ${deleted} to delete"
  else
    summary="${created} created, ${updated} updated, ${unchanged} unchanged"
    [ "${github_labels_prune}" != "y" ] || summary="${summary}, ${deleted} deleted"
  fi

  echo "  Labels: ${summary}"
}

##
# Print the body of the default branch ruleset.
#
# The admin repository role (actor 5) bypasses the ruleset, so the owner can
# still push directly.
#
# @param $1 string Extra rules as comma-separated JSON objects (optional)
# @param $2 string Extra bypass actors as comma-separated JSON objects
#                  (optional)
#
github_ruleset_body() {
  local rules='{"type": "deletion"}, {"type": "non_fast_forward"}'
  local actors='{"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always"}'

  [ -z "${1:-}" ] || rules="${rules}, ${1}"
  [ -z "${2:-}" ] || actors="${actors}, ${2}"

  cat <<JSON
{
  "name": "${GITHUB_RULESET_NAME}",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
  "rules": [${rules}],
  "bypass_actors": [${actors}]
}
JSON
}

##
# Create the default branch ruleset, or update it when it exists.
#
# The update body replaces the rules and bypass actors, so the ones this script
# does not manage are read and sent back. A given required status checks rule
# replaces the existing one; without it, the existing one is kept.
#
# @param $1 string Required status checks rule as a JSON object (optional)
#
github_apply_ruleset() {
  local checks_rule="${1:-}"
  local slug="${github_owner}/${github_repo}"
  local output=""
  local details="${GITHUB_RULESET_NAME}"

  [ -z "${checks_rule}" ] || details="${details} with required checks"

  # A dry run that would create the repository has no rulesets to read.
  if [ "${github_repo_exists}" != "n" ] && ! output="$(gh_run api "repos/${slug}/rulesets" --paginate --jq ".[] | select(.name == \"${GITHUB_RULESET_NAME}\" and .source_type == \"Repository\") | .id" 2>&1)"; then
    github_section_error "Ruleset" "Administration: read" "${output}"
    return $?
  fi

  local id="${output%%$'\n'*}"

  if [ -z "${id}" ]; then
    github_call "Ruleset" "Administration: write" api --method POST "repos/${slug}/rulesets" --silent --input - <<<"$(github_ruleset_body "${checks_rule}")" || return $?
    github_report "Ruleset" "would create" "created" "${details}"
    return 0
  fi

  local managed='.type != "deletion" and .type != "non_fast_forward"'
  [ -z "${checks_rule}" ] || managed="${managed} and .type != \"required_status_checks\""

  # Prints the unmanaged rules on line 1 and the unmanaged actors on line 2.
  local jq_kept="([.rules[]? | select(${managed}) | tojson] | join(\", \")), ([.bypass_actors[]? | select((.actor_type == \"RepositoryRole\" and .actor_id == 5) | not) | tojson] | join(\", \"))"

  if ! output="$(gh_run api "repos/${slug}/rulesets/${id}" --jq "${jq_kept}" 2>&1)"; then
    github_section_error "Ruleset" "Administration: read" "${output}"
    return $?
  fi

  local kept_rules="${output%%$'\n'*}"
  local kept_actors=""
  [[ ${output} != *$'\n'* ]] || kept_actors="${output#*$'\n'}"

  if [ -n "${checks_rule}" ]; then
    kept_rules="${kept_rules:+${kept_rules}, }${checks_rule}"
  fi

  github_call "Ruleset" "Administration: write" api --method PUT "repos/${slug}/rulesets/${id}" --silent --input - <<<"$(github_ruleset_body "${kept_rules}" "${kept_actors}")" || return $?
  github_report "Ruleset" "would update" "updated" "${details}"
}

##
# Check whether a workflow file read from stdin runs on pull requests to a
# branch.
#
# Reads the top-level 'on' key, quoted or not, in its string, list and map
# forms, and only the events directly under it. A 'pull_request' trigger
# counts only when no 'paths', 'paths-ignore' or 'branches-ignore' filter can
# skip it, and when its 'branches' list, if any, matches the branch. Comments
# are ignored, and 'pull_request_target' does not count.
#
# @param $1 string Branch the pull requests target (default: main)
#
github_workflow_has_pull_request() {
  # The awk program is not bash, so kcov cannot trace its lines.
  # LCOV_EXCL_START
  awk -v branch="${1:-main}" -v sq="'" '
    function unquote(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub("^[\"" sq "]|[\"" sq "]$", "", value)
      return value
    }
    function glob_match(pattern, text, re) {
      re = pattern
      gsub(/\./, "\\.", re)
      gsub(/\*+/, ".*", re)
      gsub(/\?/, ".", re)
      return text ~ ("^" re "$")
    }
    function add_branches(list, count, parts, i, pattern) {
      gsub(/[][]/, "", list)
      count = split(list, parts, ",")
      for (i = 1; i <= count; i++) {
        pattern = unquote(parts[i])
        if (pattern == "") continue
        has_branches = 1
        if (glob_match(pattern, branch)) branch_matches = 1
      }
    }
    {
      line = $0
      sub(/[[:space:]]+#.*$/, "", line)
      if (line ~ /^[[:space:]]*(#.*)?$/) next
      match(line, /^[[:space:]]*/)
      indent = RLENGTH
      key = substr(line, indent + 1)
    }
    indent == 0 {
      in_on = (key ~ ("^[\"" sq "]?on[\"" sq "]?:"))
      in_pr = 0
      base = 0
      if (in_on) {
        rest = key
        sub(/^[^:]*:/, "", rest)
        if (rest ~ /(^|[^a-z_])pull_request([^a-z_]|$)/) found = 1
      }
      next
    }
    !in_on { next }
    base == 0 { base = indent }
    indent <= base {
      in_pr = 0
      in_branches = 0
      if (indent == base && key ~ ("^(-[[:space:]]+)?[\"" sq "]?pull_request[\"" sq "]?[[:space:]]*(:.*)?$")) {
        found = 1
        in_pr = 1
        pr_indent = 0
      }
      next
    }
    in_pr {
      if (pr_indent == 0) pr_indent = indent
      if (indent == pr_indent) {
        in_branches = 0
        if (key ~ /^(paths|paths-ignore|branches-ignore):/) filtered = 1
        if (key ~ /^branches:/) {
          in_branches = 1
          rest = key
          sub(/^branches:/, "", rest)
          if (rest ~ /[^[:space:]]/) add_branches(rest)
        }
      } else if (in_branches && key ~ /^-/) {
        sub(/^-[[:space:]]*/, "", key)
        add_branches(key)
      }
    }
    END { exit (found && !filtered && (!has_branches || branch_matches)) ? 0 : 1 }
  '
  # LCOV_EXCL_STOP
}

##
# Build the required status checks rule from a list of check names.
#
# @param $1 string Check names, 1 per line
#
github_checks_rule_json() {
  local checks=""
  local name

  while IFS= read -r name; do
    [ -n "${name}" ] || continue
    name="${name//\\/\\\\}"
    name="${name//\"/\\\"}"
    checks="${checks:+${checks}, }{\"context\": \"${name}\", \"integration_id\": ${GITHUB_ACTIONS_APP_ID}}"
  done <<<"${1}"

  [ -n "${checks}" ] || return 0

  echo "{\"type\": \"required_status_checks\", \"parameters\": {\"strict_required_status_checks_policy\": false, \"do_not_enforce_on_create\": false, \"required_status_checks\": [${checks}]}}"
}

##
# Work out the required checks from the latest commit on the default branch.
#
# Only GitHub Actions checks from workflows with a 'pull_request' trigger
# count, because a push-only check never reports on a pull request and would
# block every one. Each check is traced through its check suite to the
# workflow file at that commit, read through the API so no checkout is needed.
#
# Sets github_checks_rule, left empty when no check qualifies.
#
# @return int 0 on success, 2 when skipped on a 403, 1 otherwise.
#
github_compute_checks() {
  local slug="${github_owner}/${github_repo}"
  local branch
  branch="$(github_state default_branch)"
  branch="${branch:-main}"
  github_checks_rule=""

  # Branch names may hold URL metacharacters, which must not end the path.
  local ref="${branch//%/%25}"
  ref="${ref//#/%23}"
  ref="${ref//\?/%3F}"

  local output

  if ! output="$(gh_run api "repos/${slug}/commits/${ref}/check-runs" --paginate --jq ".check_runs[] | select(.app.id == ${GITHUB_ACTIONS_APP_ID} and .conclusion != \"skipped\" and .conclusion != \"cancelled\" and .conclusion != \"neutral\") | [(.check_suite.id | tostring), .head_sha, .name] | join(\"\\t\")" 2>&1)"; then
    # An empty repository has no commit on its default branch to read.
    if [[ ${output} == *"No commit found for SHA"* ]]; then
      echo "  Required checks: none found, because ${branch} has no commits"
      return 0
    fi

    github_section_error "Required checks" "Checks: read" "${output}"
    return $?
  fi

  local suites="|"
  local check_names=""
  local line suite sha name path decision

  while IFS= read -r line; do
    [ -n "${line}" ] || continue
    suite="${line%%$'\t'*}"
    line="${line#*$'\t'}"
    sha="${line%%$'\t'*}"
    name="${line#*$'\t'}"

    # Each check suite is 1 workflow run, so its file is read once.
    if [[ ${suites} == *"|${suite}:"* ]]; then
      decision="${suites#*|"${suite}":}"
      decision="${decision%%|*}"
    else
      decision="n"

      if ! path="$(gh_run api "repos/${slug}/actions/runs?check_suite_id=${suite}" --jq '.workflow_runs[0].path // ""' 2>&1)"; then
        github_section_error "Required checks" "Actions: read" "${path}"
        return $?
      fi

      if [ -n "${path}" ] && gh_run api -H "Accept: application/vnd.github.raw" "repos/${slug}/contents/${path}?ref=${sha}" 2>/dev/null | github_workflow_has_pull_request "${branch}"; then
        decision="y"
      fi

      suites="${suites}${suite}:${decision}|"
    fi

    [ "${decision}" = "n" ] || check_names="${check_names}${name}"$'\n'
  done <<<"${output}"

  check_names="$(printf '%s' "${check_names}" | sort -u)"

  if [ -z "${check_names}" ]; then
    echo "  Required checks: none found on ${branch}"
    return 0
  fi

  github_checks_rule="$(github_checks_rule_json "${check_names}")"
  echo "  Required checks: ${check_names//$'\n'/; }"
}

##
# Print the command that adds the required checks once CI has run.
#
github_rerun_hint() {
  echo "  After CI finishes, run the following command to require its checks:"
  echo "    curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github --github-owner=${github_owner} --github-repo=${github_repo} --no-github-settings --no-github-labels"
}

##
# List the CI runs of the pushed commit as "status<TAB>conclusion<TAB>name".
#
# Sets github_runs. A commit can start more runs than the default page of 20,
# so the limit is raised.
#
# @return int 1 when the runs cannot be listed.
#
github_list_runs() {
  local output

  if ! output="$(gh_run run list --repo "${github_owner}/${github_repo}" --commit "${github_pushed_sha}" --limit 100 --json status,conclusion,name --jq '.[] | [.status, (.conclusion // ""), .name] | join("\t")' 2>&1)"; then
    echo "  CI: could not list the runs (${output//$'\n'/ })" >&2
    return 1
  fi

  github_runs="${output}"
}

##
# Wait for the CI runs of the pushed commit to finish.
#
# Polls instead of using 'timeout', which macOS does not ship. An interrupt
# stops the wait and prints the command to finish the job later.
#
# @return int 0 when every run finished, 1 when none appeared, the runs could
#   not be listed or the deadline passed.
#
github_wait_for_runs() {
  local deadline=$((SECONDS + github_runs_timeout))
  github_runs=""

  trap 'github_wait_interrupted' INT

  echo "  Waiting for the CI runs of the pushed commit"

  while :; do
    if ! github_list_runs; then
      trap - INT
      return 1
    fi

    [ -z "${github_runs}" ] || break

    if [ "${SECONDS}" -ge "${deadline}" ]; then
      trap - INT
      echo "  CI: no runs started within ${github_runs_timeout}s"
      return 1
    fi

    sleep "${github_poll_interval}"
  done

  deadline=$((SECONDS + github_wait_timeout))

  while grep -qv $'^completed\t' <<<"${github_runs}"; do
    if [ "${SECONDS}" -ge "${deadline}" ]; then
      trap - INT
      echo "  CI: runs still in progress after ${github_wait_timeout}s"
      return 1
    fi

    sleep "${github_poll_interval}"

    if ! github_list_runs; then
      trap - INT
      return 1
    fi
  done

  trap - INT

  local total
  local failed
  total="$(grep -c . <<<"${github_runs}")"
  failed="$(awk -F '\t' '$2 != "success" && $2 != "skipped" && $2 != "neutral" { print $3 }' <<<"${github_runs}")"

  echo "  CI: ${total} runs finished"

  if [ -n "${failed}" ]; then
    echo "  Warning: these runs failed, so pull requests stay blocked until CI passes: ${failed//$'\n'/; }"
  fi

  return 0
}

##
# Stop waiting for CI on an interrupt.
#
github_wait_interrupted() {
  echo
  echo "  CI: waiting was interrupted, so the ruleset has no required checks."
  github_rerun_hint
  exit 130
}

##
# Check the prerequisites of creating and pushing a repository.
#
# @return int 0 when 'git' is installed and git user.email is set.
#
github_creation_prerequisites() {
  if ! has_command git; then
    echo "Skipping repository creation: 'git' is not installed."
    return 1
  fi

  if [ -z "$(git config user.email 2>/dev/null || true)" ]; then
    echo "Skipping repository creation: git user.email is not set. Run 'git config --global user.email \"you@example.com\"' first."
    return 1
  fi
}

##
# Run a 'git' call that changes the repository, or print it under --dry-run.
#
git_write() {
  if [ "${dry_run}" != "1" ]; then
    git "$@"
    return
  fi

  local call
  printf -v call ' %q' "$@"
  echo "  [dry-run] git${call}"
}

##
# Print the path of this script when it is removed at the end of the run.
#
# "${BASH_SOURCE[0]}" is empty when the script is piped through 'curl ... |
# bash', so only a real file on disk is printed.
#
self_removal_path() {
  local script_path="${BASH_SOURCE[0]:-}"

  [ "${remove_self}" != "n" ] || return 0
  [ -n "${script_path}" ] && [ -f "${script_path}" ] || return 0

  echo "${script_path}"
}

##
# Remove this script, unless --keep was passed or it was piped.
#
remove_self_script() {
  local script_path
  script_path="$(self_removal_path)"

  [ -z "${script_path}" ] || rm -- "${script_path}" || true
}

##
# Print a pathspec that leaves this script out of a commit.
#
# The script is removed only at the very end of the run, after the commit, so
# it never reaches the project's history. Prints nothing when the script stays
# or lives outside the current directory.
#
github_self_exclude() {
  local script_path
  script_path="$(self_removal_path)"

  [ -n "${script_path}" ] || return 0

  script_path="${script_path#"${PWD}"/}"
  script_path="${script_path#./}"

  [[ ${script_path} != /* ]] || return 0

  echo ":(exclude)${script_path}"
}

##
# Push with SCAFFOLD_GITHUB_TOKEN, independent of local git credentials.
#
# The empty helper clears any configured one, and the inline helper reads the
# token from the environment, so it never appears on the command line.
#
# @param $1 string Repository URL
# @param $2 string Branch to push
#
github_git_push() {
  local status=0

  xtrace_suspend
  # LCOV_EXCL_START
  # shellcheck disable=SC2016
  SCAFFOLD_GITHUB_TOKEN="${SCAFFOLD_GITHUB_TOKEN:-}" GIT_TERMINAL_PROMPT=0 git_write -c credential.helper= -c 'credential.helper=!f() { echo username=x-access-token; echo "password=${SCAFFOLD_GITHUB_TOKEN}"; }; f' push -q "${1}" "HEAD:refs/heads/${2}" || status=$?
  xtrace_restore
  # LCOV_EXCL_STOP

  return "${status}"
}

##
# Create the GitHub repository and push the local commits to it.
#
# Initialises git and commits every file when needed. An existing 'origin'
# is never rewritten.
#
# @return int 1 when any step failed.
#
github_create_repo() {
  local slug="${github_owner}/${github_repo}"
  local url="https://github.com/${slug}.git"
  local exclude
  local fresh=0

  github_creation_prerequisites || return 1

  exclude="$(github_self_exclude)"

  echo "  Creating ${github_visibility} repository ${slug}"

  if [ ! -e .git ]; then
    fresh=1
    git_write init -q || return 1
    git_write symbolic-ref HEAD refs/heads/main || return 1
  fi

  if [ "${fresh}" = "1" ] || ! git rev-parse --verify -q HEAD >/dev/null 2>&1; then
    git_write add -A -- . ${exclude:+"${exclude}"} || return 1
    git_write commit -q -m "Initial commit." || return 1
  elif [ -n "$(git status --porcelain -- . ${exclude:+"${exclude}"} 2>/dev/null)" ]; then
    echo "  Warning: uncommitted changes are not pushed."
  fi

  local rc=0
  github_call "Repository" "Administration: write" repo create "${slug}" "--${github_visibility}" || rc=$?
  [ "${rc}" -eq 0 ] || return 1

  if [ "${fresh}" = "1" ] || ! git remote get-url origin >/dev/null 2>&1; then
    git_write remote add origin "${url}" || return 1
  fi

  github_created=1

  if [ "${github_push}" = "n" ]; then
    echo "  Push: skipped"
  else
    local branch="main"
    [ "${fresh}" = "1" ] || branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo main)"

    # A re-run finds the repository and skips creation, so the push has to be
    # finished by hand.
    if ! github_git_push "${url}" "${branch}"; then
      echo "  Push: failed. The repository exists but is empty. Push with 'git push -u origin ${branch}', then run 'curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github' to apply the settings." >&2
      return 1
    fi

    git_write config "branch.${branch}.remote" origin
    git_write config "branch.${branch}.merge" "refs/heads/${branch}"

    if [ "${dry_run}" != "1" ]; then
      github_pushed_sha="$(git rev-parse HEAD)"
      echo "  Pushed ${branch} to ${url}"
    fi
  fi

  # A dry run creates nothing, so there is no new state to read.
  [ "${dry_run}" = "1" ] || github_load_repo
}

##
# Apply the ruleset to a repository this run created.
#
# The ruleset goes on first without checks. After the first CI run finishes,
# its pull-request checks are added.
#
github_apply_new_ruleset() {
  github_apply_ruleset || return $?

  if [ "${dry_run}" = "1" ]; then
    if [ "${github_wait_checks}" != "n" ] && [ "${github_push}" != "n" ]; then
      echo "  CI: would wait for the first CI run and require its checks"
    fi

    return 0
  fi

  if [ "${github_wait_checks}" = "n" ] || [ -z "${github_pushed_sha}" ]; then
    github_rerun_hint
    return 0
  fi

  if ! github_wait_for_runs; then
    github_rerun_hint
    return 0
  fi

  github_compute_checks || return $?

  if [ -z "${github_checks_rule}" ]; then
    github_rerun_hint
    return 0
  fi

  github_apply_ruleset "${github_checks_rule}"
}

##
# Apply the ruleset to an existing repository, with the checks of its latest
# CI run when requested.
#
github_apply_existing_ruleset() {
  if [ "${github_required_checks}" != "y" ]; then
    github_apply_ruleset
    return
  fi

  github_compute_checks || return $?

  github_apply_ruleset "${github_checks_rule}" || return $?

  [ -n "${github_checks_rule}" ] || github_rerun_hint
}

##
# Apply the selected sections to the GitHub repository.
#
# A section skipped on a 403 neither stops the others nor fails the run.
#
# @return int 1 when the repository cannot be read or any section failed.
#
configure_github() {
  echo
  echo "Configuring GitHub repository ${github_owner}/${github_repo}"
  [ "${dry_run}" != "1" ] || echo "  Dry run: nothing is changed."

  if [ -z "${github_repo_exists}" ]; then
    local rc=0
    github_load_repo || rc=$?
    [ "${rc}" -eq 0 ] || [ "${rc}" -eq 3 ] || return 1
  fi

  if [ "${github_repo_exists}" = "n" ]; then
    if [ "${github_create}" != "y" ]; then
      github_missing_error
      return 1
    fi

    github_create_repo || return 1
  fi

  local failed=0

  if [ "${github_settings}" = "y" ]; then
    github_run_section github_apply_settings || failed=1
  fi

  if [ "${github_labels}" = "y" ]; then
    github_run_section github_apply_labels || failed=1
  fi

  if [ "${github_ruleset}" = "y" ] && [ "${github_created}" = "1" ]; then
    github_run_section github_apply_new_ruleset || failed=1
  elif [ "${github_ruleset}" = "y" ]; then
    github_run_section github_apply_existing_ruleset || failed=1
  fi

  if [ "${failed}" = "1" ]; then
    echo "GitHub repository settings finished with errors." >&2
    return 1
  fi

  echo "GitHub repository settings complete."
}

##
# Prompt for the GitHub repository and the sections to apply.
#
# A repository that does not exist is offered for creation, and the creation
# prompts appear only then.
#
# @return int 1 when the repository cannot be read or is not created.
#
github_collect_interactive() {
  github_owner="$(ask "  GitHub owner" "${github_owner}")"
  github_repo="$(ask "  GitHub repository" "${github_repo}")"

  github_check_origin || return 1

  local rc=0
  github_load_repo || rc=$?

  if [ "${rc}" -eq 3 ]; then
    if [ "${github_create}" != "y" ]; then
      github_create="$(ask_yesno "  ${github_owner}/${github_repo} does not exist. Create it")"
      [ "${github_create}" = "y" ] || return 1
    fi

    github_creation_prerequisites || return 1

    github_visibility="$(ask_choice "  Visibility" "public" "public private")"
  elif [ "${rc}" -ne 0 ]; then
    return 1
  elif [ "${github_create}" = "y" ]; then
    echo "  ${github_owner}/${github_repo} already exists, so only its settings are applied."
    github_create="n"
  fi

  github_settings="$(ask_yesno "  Apply general settings")"
  if [ "${github_settings}" = "y" ]; then
    github_description="$(ask_optional "    Description" "$(github_state description)")"
  fi

  github_labels="$(ask_yesno "  Apply labels")"
  github_labels_prune="n"
  if [ "${github_labels}" = "y" ]; then
    github_labels_prune="$(ask_yesno "    Delete labels not in the list" "N")"
  fi

  github_ruleset="$(ask_yesno "  Protect the default branch with a ruleset")"

  if [ "${github_ruleset}" = "y" ] && [ "${github_create}" = "y" ]; then
    github_wait_checks="$(ask_yesno "    Wait for the first CI run and require its checks")"
  elif [ "${github_ruleset}" = "y" ]; then
    github_required_checks="$(ask_yesno "    Require checks from the latest CI run")"
  fi

  github_apply_defaults
}

##
# Offer to configure the GitHub repository during an interactive install.
#
# The prompts appear only when the prerequisites pass. Without a '.git'
# directory the offer is to create the repository.
#
collect_github_interactive() {
  use_github="n"

  github_prerequisites || return 0

  if [ ! -e .git ] && github_creation_prerequisites; then
    use_github="$(ask_yesno "Create a GitHub repository" "N")"
    [ "${use_github}" = "y" ] || return 0
    github_create="y"
  else
    use_github="$(ask_yesno "Configure GitHub repository settings" "N")"
    [ "${use_github}" = "y" ] || return 0
  fi

  github_default_identity "${project}"
  github_collect_interactive || use_github="n"
}

##
# Resolve the GitHub repository for a non-interactive install with --github.
#
collect_github_noninteractive() {
  [ "${use_github}" = "y" ] || return 0

  if ! github_prerequisites; then
    use_github="n"
    return 0
  fi

  github_default_identity "${project}"
  github_apply_defaults
}

##
# Configure the GitHub repository of an existing project.
#
# Needs neither the template nor the identity options, and leaves the project
# files untouched.
#
github_main() {
  github_prerequisites || exit 1

  resolve_github_identity
  github_default_identity "$(basename "${PWD}")"

  if [ "${interactive}" = "1" ]; then
    github_collect_interactive || exit 1
  else
    github_apply_defaults
  fi

  configure_github || exit 1
}

#-------------------------------------------------------------------------------
# ARGUMENT PARSING
#-------------------------------------------------------------------------------

usage() {
  cat <<'USAGE'
Usage: ./install.sh [OPTIONS]
       ./install.sh github [OPTIONS]

Initialise a new project from the Scaffold template, or with the 'github'
command configure the GitHub repository of an existing project.

With no options the script runs interactively and prompts for every choice.
Passing any option switches to non-interactive mode: prompts are skipped,
unspecified choices use their defaults, and --namespace, --name and --author
are required unless --github-owner, --github-repo or the 'origin' remote
supply the first 2.

One-liner (interactive - downloads Scaffold, then prompts):
  curl -fsSL https://getscaffold.dev/install.sh | bash

One-liner (non-interactive):
  curl -fsSL https://getscaffold.dev/install.sh | \
    bash -s -- --namespace=AcmeApp --name=acme-app --author="Jane Doe"

When run without the template present (e.g. piped from curl in an empty
directory), the script downloads the Scaffold into the current directory first,
then initialises it. The directory must be empty. Piping with no options prompts
interactively. Set SCAFFOLD_ARCHIVE_URL to bootstrap from a specific archive URL.

Identity (required in non-interactive mode):
  --namespace=VALUE              Project namespace in PascalCase (e.g. AcmeApp).
                                 Defaults to the GitHub owner when one is given.
  --name=VALUE                   Project name in kebab-case (e.g. acme-app).
                                 Defaults to the GitHub repository when one is
                                 given.
  --author=VALUE                 Author name (e.g. "Jane Doe").

Features (enabled by default unless noted; use --no-<name> to disable):
  --php, --no-php                PHP support.
  --php-command                  Use the Symfony CLI command app (default).
  --no-php-command               Do not use the Symfony CLI command app.
  --php-script                   Use a single-file script instead of the app.
  --no-php-script                Do not use a single-file script. Combined with
                                 --no-php-command, scaffolds a class library
                                 with the PHP tooling and no entry point.
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
  --schedule, --no-schedule      Daily scheduled build (default: on).
  --ai, --no-ai                  AI agents configuration (default: on).
  --ai-arch-docs[=VALUE]         AI architecture docs: mermaid, plantuml or
                                 none (default: mermaid).
  --no-ai-arch-docs              Disable AI architecture docs.
  --keep                         Keep this install script (default: removed).

GitHub repository (needs GitHub CLI and SCAFFOLD_GITHUB_TOKEN):
  github                         Command: configure the GitHub repository of an
                                 existing project without touching its files.
                                 Every section is on unless turned off.
  --github, --no-github          Configure the GitHub repository after init
                                 (default: off).
  --github-owner=VALUE           GitHub user or organisation (default: the
                                 'origin' remote, then the token's login).
  --github-repo=VALUE            GitHub repository (default: the 'origin'
                                 remote, then the project name, or the current
                                 directory name for the 'github' command).
  --github-settings, --no-github-settings
                                 General settings (default: on).
  --github-description=VALUE     Repository description (default: unchanged).
  --github-merge=VALUE           Allowed merge methods, comma-separated: merge,
                                 squash, rebase (default: squash,rebase).
  --github-labels, --no-github-labels
                                 Labels (default: on).
  --github-labels-prune, --no-github-labels-prune
                                 Delete labels not in the list (default: off).
  --github-ruleset, --no-github-ruleset
                                 Default branch ruleset (default: on).
  --github-required-checks, --no-github-required-checks
                                 Require the pull-request checks of the latest
                                 CI run on the default branch (default: on).
  --github-create, --no-github-create
                                 Create the repository when it does not exist:
                                 initialise git, commit, create and push
                                 (default: off). Implies --github.
  --github-visibility=VALUE      Visibility of a created repository: public or
                                 private (default: public).
  --github-push, --no-github-push
                                 Push a created repository (default: on).
  --github-wait-checks, --no-github-wait-checks
                                 After creating, wait for the first CI run and
                                 require its checks (default: on).
  --github-wait-timeout=SECONDS  How long to wait for CI (default: 1800).
  --dry-run                      Print the GitHub changes without making them.

Environment:
  SCAFFOLD_GITHUB_TOKEN          GitHub token for every GitHub call. The
                                 account 'gh' is logged in with and any
                                 GITHUB_TOKEN are never used.

Other:
  --ref=VALUE                    Bootstrap from a tag, branch or commit when the
                                 template is absent (default: the release of
                                 this install script, or 'main' for 'dev').
  --yes, -y                      Run non-interactively using defaults.
  --help, -h                     Show this help and exit.
  --version                      Print the version ("dev" unless released).
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
      --no-php-command) use_php_command="n" ;;
      --php-script) use_php_script="y" ;;
      --no-php-script) use_php_script="n" ;;
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
      --schedule) use_schedule="y" ;;
      --no-schedule) use_schedule="n" ;;

      --ai) use_ai="y" ;;
      --no-ai) use_ai="n" ;;
      --ai-arch-docs) use_ai_arch_docs="mermaid" ;;
      --ai-arch-docs=*)
        use_ai_arch_docs="${1#*=}"
        case "${use_ai_arch_docs}" in
          mermaid | plantuml | none) ;;
          *)
            echo "Error: Invalid value for --ai-arch-docs: ${use_ai_arch_docs}. Allowed values: mermaid, plantuml, none." >&2
            echo "Run with --help for usage." >&2
            exit 1
            ;;
        esac
        ;;
      --no-ai-arch-docs) use_ai_arch_docs="none" ;;

      --keep) remove_self="n" ;;

      --github) use_github="y" ;;
      --no-github) use_github="n" ;;
      --github-owner=*) github_owner="${1#*=}" ;;
      --github-repo=*) github_repo="${1#*=}" ;;
      --github-settings) github_settings="y" ;;
      --no-github-settings) github_settings="n" ;;
      --github-description=*) github_description="${1#*=}" ;;
      --github-merge=*)
        github_merge="${1#*=}"
        github_merge="${github_merge//[[:space:]]/}"
        if ! validate_github_merge "${github_merge}"; then
          echo "Run with --help for usage." >&2
          exit 1
        fi
        ;;
      --github-labels) github_labels="y" ;;
      --no-github-labels) github_labels="n" ;;
      --github-labels-prune) github_labels_prune="y" ;;
      --no-github-labels-prune) github_labels_prune="n" ;;
      --github-ruleset) github_ruleset="y" ;;
      --no-github-ruleset) github_ruleset="n" ;;
      --github-required-checks) github_required_checks="y" ;;
      --no-github-required-checks) github_required_checks="n" ;;
      --github-create)
        github_create="y"
        use_github="y"
        ;;
      --no-github-create) github_create="n" ;;
      --github-visibility=*)
        github_visibility="${1#*=}"
        case "${github_visibility}" in
          public | private) ;;
          *)
            echo "Error: Invalid value for --github-visibility: ${github_visibility}. Allowed values: public, private." >&2
            echo "Run with --help for usage." >&2
            exit 1
            ;;
        esac
        ;;
      --github-push) github_push="y" ;;
      --no-github-push) github_push="n" ;;
      --github-wait-checks) github_wait_checks="y" ;;
      --no-github-wait-checks) github_wait_checks="n" ;;
      --github-wait-timeout=*)
        github_wait_timeout="${1#*=}"
        if [[ ! ${github_wait_timeout} =~ ^[0-9]+$ ]]; then
          echo "Error: Invalid value for --github-wait-timeout: ${github_wait_timeout}. Pass a number of seconds." >&2
          echo "Run with --help for usage." >&2
          exit 1
        fi
        # A leading zero would otherwise make the arithmetic read it as octal.
        github_wait_timeout=$((10#${github_wait_timeout}))
        ;;
      --dry-run) dry_run=1 ;;

      --ref=*) archive_ref="${1#*=}" ;;

      --yes | -y) interactive=0 ;;
      --help | -h)
        usage
        exit 0
        ;;
      --version)
        echo "${SCAFFOLD_VERSION}"
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

  validate_php_mode || exit 1
}

#-------------------------------------------------------------------------------
# INPUT COLLECTION
#-------------------------------------------------------------------------------

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

  validate_identity_value validate_namespace "${namespace}" "Namespace" "${namespace_source}" "--namespace"
  validate_identity_value validate_project_name "${project}" "Name" "${project_source}" "--name"
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
  : "${use_schedule:=y}"
  : "${use_ai:=y}"
  : "${remove_self:=y}"
  : "${use_github:=n}"

  if [ "${use_php}" = "y" ]; then
    if [ "${use_php_script}" = "y" ]; then
      : "${use_php_command:=n}"
    else
      : "${use_php_command:=y}"
    fi

    if [ "${use_php_command}" = "y" ]; then
      : "${php_command_name:=${project}}"
      : "${use_php_command_build:=y}"
      use_php_script="n"
      php_script_name="<unset>"
    else
      # Declining the command app offers the script next, as the prompts do;
      # declining both leaves a class library with no entry point.
      : "${use_php_script:=y}"
      use_php_command_build="n"
      php_command_name="<unset>"

      if [ "${use_php_script}" = "y" ]; then
        : "${php_script_name:=${project}}"
      else
        php_script_name="<unset>"
      fi
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

  if [ "${use_ai}" = "y" ]; then
    : "${use_ai_arch_docs:=mermaid}"
  else
    use_ai_arch_docs="none"
  fi

  return 0
}

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
  echo "Use scheduled builds             : ${use_schedule}"
  echo "Use AI agents                    : ${use_ai}"
  echo "AI architecture docs             : ${use_ai_arch_docs:-none}"
  echo "Remove this script               : ${remove_self}"
  echo "Configure GitHub repository      : ${use_github}"
  if [ "${use_github}" = "y" ]; then
    echo "  Repository                     : ${github_owner}/${github_repo}"
    if [ "${github_create}" = "y" ]; then
      echo "  Create repository              : y"
      echo "    Visibility                   : ${github_visibility}"
      echo "    Push                         : ${github_push}"
    fi
    echo "  General settings               : ${github_settings}"
    echo "  Labels                         : ${github_labels}"
    echo "    Delete labels not in list    : ${github_labels_prune}"
    echo "  Default branch ruleset         : ${github_ruleset}"
    if [ "${github_ruleset}" = "y" ] && [ "${github_create}" = "y" ]; then
      echo "    Wait for CI, require checks  : ${github_wait_checks}"
    elif [ "${github_ruleset}" = "y" ]; then
      echo "    Require latest CI checks     : ${github_required_checks}"
    fi
  fi
  echo "---------------------------------"
  echo
}

##
# Print the non-interactive command that reproduces the interactive answers.
#
# Choices equal to their non-interactive default and values that would be
# derived again are left out. SCAFFOLD_GITHUB_TOKEN is never included.
#
print_reproduce_command() {
  local args=()

  [ -n "${namespace_source}" ] || args+=("--namespace=${namespace}")
  [ -n "${project_source}" ] || args+=("--name=${project}")
  args+=("--author=${author}")

  if [ "${use_php}" != "y" ]; then
    args+=("--no-php")
  elif [ "${use_php_command}" = "y" ]; then
    [ "${php_command_name}" = "${project}" ] || args+=("--php-command-name=${php_command_name}")
    [ "${use_php_command_build}" = "y" ] || args+=("--no-phar")
  else
    args+=("--no-php-command")

    if [ "${use_php_script}" != "y" ]; then
      args+=("--no-php-script")
    elif [ "${php_script_name}" != "${project}" ]; then
      args+=("--php-script-name=${php_script_name}")
    fi
  fi

  [ "${use_nodejs}" = "y" ] || args+=("--no-nodejs")

  if [ "${use_shell}" != "y" ]; then
    args+=("--no-shell")
  elif [ "${shell_command_name}" != "${project}" ]; then
    args+=("--shell-command-name=${shell_command_name}")
  fi

  if [ "${use_docker}" = "y" ]; then
    if [ "${docker_image_name}" = "$(to_lowercase "${namespace}")/${project}" ]; then
      args+=("--docker")
    else
      args+=("--docker-image-name=${docker_image_name}")
    fi
  fi

  [ "${use_release_drafter}" = "y" ] || args+=("--no-release-drafter")
  [ "${use_pr_autoassign}" = "y" ] || args+=("--no-pr-autoassign")
  [ "${use_funding}" = "y" ] || args+=("--no-funding")
  [ "${use_pr_template}" = "y" ] || args+=("--no-pr-template")
  [ "${use_renovate}" = "y" ] || args+=("--no-renovate")
  [ "${use_docs}" = "y" ] || args+=("--no-docs")
  [ "${use_test_actions}" != "y" ] || args+=("--test-actions")
  [ "${use_schedule}" = "y" ] || args+=("--no-schedule")

  if [ "${use_ai}" != "y" ]; then
    args+=("--no-ai")
  elif [ "${use_ai_arch_docs}" != "mermaid" ]; then
    args+=("--ai-arch-docs=${use_ai_arch_docs}")
  fi

  [ "${remove_self}" != "n" ] || args+=("--keep")

  if [ "${use_github}" = "y" ]; then
    args+=("--github")
    [ "${github_create}" != "y" ] || args+=("--github-create")
    [ "${github_create}" != "y" ] || [ "${github_visibility}" = "public" ] || args+=("--github-visibility=${github_visibility}")
    [ "${github_owner}" = "${github_owner_default}" ] || args+=("--github-owner=${github_owner}")
    [ "${github_repo}" = "${github_repo_default}" ] || args+=("--github-repo=${github_repo}")
    [ "${github_settings}" = "y" ] || args+=("--no-github-settings")
    [ -z "${github_description}" ] || [ "${github_description}" = "$(github_state description)" ] || args+=("--github-description=${github_description}")
    [ "${github_labels}" = "y" ] || args+=("--no-github-labels")
    [ "${github_labels_prune}" != "y" ] || args+=("--github-labels-prune")
    [ "${github_ruleset}" = "y" ] || args+=("--no-github-ruleset")
    [ "${github_ruleset}" != "y" ] || [ "${github_create}" != "y" ] || [ "${github_wait_checks}" = "y" ] || args+=("--no-github-wait-checks")
    [ "${github_ruleset}" != "y" ] || [ "${github_create}" = "y" ] || [ "${github_required_checks}" = "y" ] || args+=("--no-github-required-checks")
  fi

  local command="./install.sh"
  local arg

  for arg in "${args[@]}"; do
    if [[ ${arg} == *=* ]]; then
      command="${command} ${arg%%=*}=$(printf '%q' "${arg#*=}")"
    else
      command="${command} ${arg}"
    fi
  done

  echo "To repeat this setup without prompts, run:"
  echo "  ${command}"
  echo
}

collect_interactive() {
  echo "Please follow the prompts to adjust your project configuration"
  echo

  resolve_github_identity

  if [ -z "${namespace}" ]; then
    namespace="$(ask "Namespace (PascalCase)" "${namespace_default}")"
    [ -z "${namespace_default}" ] || [ "${namespace}" != "${namespace_default}" ] || namespace_source="${github_owner_source}"
  fi

  if [ -z "${project}" ]; then
    project="$(ask "Project" "${project_default}")"
    [ -z "${project_default}" ] || [ "${project}" != "${project_default}" ] || project_source="${github_repo_source}"
  fi

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
      php_command_name="<unset>"
      php_script_name="<unset>"
      use_php_command_build="n"

      if [ "${use_php_script}" = "y" ]; then
        php_script_name=$(ask "    CLI script name" "${project}")
      fi
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
  use_schedule="$(ask_yesno "Use scheduled builds")"

  use_ai="$(ask_yesno "Use AI agents")"
  if [ "${use_ai}" = "y" ]; then
    use_ai_arch_docs="$(ask_choice "AI architecture docs" "mermaid" "mermaid plantuml none")"
  fi

  remove_self="$(ask_yesno "Remove this script")"

  collect_github_interactive

  print_summary

  print_reproduce_command

  local should_proceed
  should_proceed="$(ask_yesno "Proceed with project init")"

  if [ "${should_proceed}" != "y" ]; then
    echo
    echo "Aborting."
    exit 1
  fi
}

collect_noninteractive() {
  resolve_github_identity

  apply_identity_defaults

  require_identity

  normalize_inputs

  apply_noninteractive_defaults

  collect_github_noninteractive

  print_summary
}

#-------------------------------------------------------------------------------
# TEMPLATE BOOTSTRAP
#-------------------------------------------------------------------------------

##
# Check whether the Scaffold template is present in the current directory.
#
# The '.scaffold' directory ships with the template and is removed once init
# completes, so its presence means "the template is here, initialise in place".
#
template_present() {
  [ -d ".scaffold" ]
}

##
# Check whether the current directory is empty, including dotfiles.
#
dir_is_empty() {
  [ -z "$(ls -A)" ]
}

##
# Resolve the installer script that the extracted template ships.
#
# Archives of older refs ship the script as 'init.sh'.
#
# @return string Path of the script to re-run, relative to the current dir.
#
bootstrapped_script() {
  if [ ! -f "./install.sh" ] && [ -f "./init.sh" ]; then
    echo "./init.sh"
    return 0
  fi

  echo "./install.sh"
}

##
# Resolve the URL of the template archive to download.
#
# Precedence: an explicit SCAFFOLD_ARCHIVE_URL wins (an exact archive URL);
# then --ref pins to a tag, branch, or commit; then a release installer uses
# the archive of its own version, so it installs the release it came from.
# The development installer uses the default branch.
#
# @return string Archive URL.
#
resolve_archive_url() {
  if [ -n "${SCAFFOLD_ARCHIVE_URL:-}" ]; then
    echo "${SCAFFOLD_ARCHIVE_URL}"
    return 0
  fi

  if [ -n "${archive_ref}" ]; then
    echo "https://github.com/AlexSkrypnyk/scaffold/archive/${archive_ref}.tar.gz"
    return 0
  fi

  if [ "${SCAFFOLD_VERSION}" != "dev" ]; then
    echo "https://github.com/AlexSkrypnyk/scaffold/archive/refs/tags/${SCAFFOLD_VERSION}.tar.gz"
    return 0
  fi

  echo "https://github.com/AlexSkrypnyk/scaffold/archive/refs/heads/main.tar.gz"
}

##
# Download, extract, validate, and promote the template into the current dir.
#
# The archive is staged in a sub-directory and only promoted once it is
# confirmed to contain '.scaffold'. A failed download, a partial extraction,
# or an archive that is not a Scaffold leaves the current directory clean
# instead of tripping the empty-directory guard on the next attempt.
#
# @param $1 string Archive URL to download.
# @return int 0 when the template was promoted, non-zero on any failure.
#
fetch_and_stage_template() {
  local url="${1}"
  local staging=".scaffold-bootstrap"

  rm -Rf "${staging}"
  mkdir -p "${staging}"

  if ! curl -fsSL "${url}" -o "${staging}/scaffold.tar.gz"; then
    echo "Error: failed to download the template archive from ${url}." >&2
    rm -Rf "${staging}"
    return 1
  fi

  if ! tar -xzf "${staging}/scaffold.tar.gz" -C "${staging}" --strip-components=1; then
    echo "Error: failed to extract the template archive." >&2
    rm -Rf "${staging}"
    return 1
  fi

  rm -f "${staging}/scaffold.tar.gz"

  if [ ! -d "${staging}/.scaffold" ]; then
    echo "Error: the downloaded archive is not a Scaffold template." >&2
    rm -Rf "${staging}"
    return 1
  fi

  # Promote the validated staged contents (including dotfiles) into the current
  # directory, then remove the now-empty staging directory.
  local entry
  for entry in "${staging}"/* "${staging}"/.[!.]*; do
    [ -e "${entry}" ] || continue
    mv "${entry}" .
  done
  rm -Rf "${staging}"
}

##
# Download the template into the current directory, then re-run in place.
#
# Runs only when the template is absent (for example when this script was
# fetched and piped straight from 'curl'). Requires an empty directory so
# nothing is clobbered. After the download the freshly written on-disk script is
# re-executed with stdin reconnected to the terminal, so interactive prompts
# work even though this instance was fed through a pipe. Does not return.
#
bootstrap_template() {
  if ! command -v tar >/dev/null 2>&1; then
    echo "Error: 'tar' is required to bootstrap the template." >&2
    exit 1
  fi

  if ! dir_is_empty; then
    echo "Error: current directory is not empty. Bootstrapping requires an empty directory." >&2
    exit 1
  fi

  local url
  url="$(resolve_archive_url)"

  echo "Downloading Scaffold from ${url}"

  if ! fetch_and_stage_template "${url}"; then
    exit 1
  fi

  # Re-run the freshly extracted script as a normal on-disk invocation so init
  # proceeds against the downloaded files. In interactive mode reconnect stdin to
  # the terminal (a piped stdin is already at EOF) when one is actually
  # reachable; other modes keep the inherited stdin so non-interactive and CI
  # runs, where /dev/tty exists but cannot be opened, are unaffected.
  local script
  script="$(bootstrapped_script)"

  if [ "${interactive}" = "1" ] && : 2>/dev/null </dev/tty; then
    exec bash "${script}" "$@" </dev/tty
  fi

  exec bash "${script}" "$@"
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
      if [ "${use_php_command_build:-n}" != "y" ]; then
        remove_php_command_build
        remove_php_release
      fi

      replace_string_content "php-command" "${php_command_name}"
      mv "bin/php-command" "bin/${php_command_name}" >/dev/null 2>&1 || true
      remove_php_script "bin/${php_command_name}"
      remove_php_library
    elif [ "${use_php_script:-n}" = "y" ]; then
      remove_php_command
      remove_php_command_build
      remove_php_classes
      remove_php_library
      replace_string_content "php-script" "${php_script_name}"
      mv "php-script" "${php_script_name}" >/dev/null 2>&1 || true
    else
      process_php_library
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
    replace_string_content "yournamespace/yourdockerimage" "${docker_image_name}"
  else
    remove_docker
  fi

  [ "${use_release_drafter}" != "y" ] && remove_release_drafter
  [ "${use_pr_autoassign}" != "y" ] && remove_pr_autoassign
  [ "${use_funding}" != "y" ] && remove_funding
  [ "${use_pr_template}" != "y" ] && remove_pr_template
  [ "${use_renovate}" != "y" ] && remove_renovate
  [ "${use_ai}" != "y" ] && remove_ai
  [ "${use_ai_arch_docs:-none}" = "none" ] && remove_ai_arch_docs
  process_ai_arch_docs
  [ "${use_docs}" != "y" ] && remove_docs
  [ "${use_test_actions}" != "y" ] && remove_test_actions
  [ "${use_schedule}" != "y" ] && remove_schedule

  process_claude_settings

  remove_renovate_managers

  process_readme "${project}"

  process_contributing

  process_internal "${namespace}" "${project}" "${author}" "${project_pascalcase}"

  echo
  echo "Initialization complete."
}

main() {
  if [ "${1:-}" = "github" ]; then
    subcommand="github"
    shift
  fi

  parse_args "$@"

  check_dependencies || exit 1

  if [ "${subcommand}" = "github" ]; then
    # Piped through 'curl ... | bash', stdin holds the rest of the script, so
    # the prompts read from the terminal. Redirecting only this call keeps
    # bash reading the script from the pipe.
    if [ "${interactive}" = "1" ] && [ ! -t 0 ] && : 2>/dev/null </dev/tty; then
      github_main </dev/tty
    else
      github_main
    fi

    return 0
  fi

  # When the template is absent (for example this script was fetched and piped
  # straight from 'curl'), download it into the current directory and re-run.
  if ! template_present; then
    bootstrap_template "$@"
  fi

  if [ "${interactive}" = "1" ]; then
    collect_interactive
  else
    collect_noninteractive
  fi

  process_project

  if [ "${use_github}" = "y" ]; then
    configure_github || exit 1
  fi

  # Last, so a failed or interrupted run keeps the script for a re-run.
  remove_self_script
}

# Run main only when the script is executed, not when it is sourced. When
# piped through 'bash -s' the script has no source file, so
# "${BASH_SOURCE[0]}" is empty - that case must still run.
#
# main is the final statement, which also bounds the effect of a truncated
# 'curl ... | bash' download. Every file and network operation lives inside a
# function that only main invokes, so a cut-off download performs no real
# work - at most the harmless top-level variable and option setup before it
# hits EOF.
if [ -z "${BASH_SOURCE[0]:-}" ] || [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
