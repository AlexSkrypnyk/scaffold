#!/usr/bin/env bats
#
# Unit tests for init.sh.
#
# Variables under test are assigned by the sourced init.sh, which shellcheck
# does not follow, so disable "unassigned variable" (SC2154) here. The 'curl'
# mocks are invoked indirectly by init.sh functions under 'run' and cannot be
# traced statically, so "function never invoked" (SC2329) is disabled too.
# shellcheck disable=SC2034,SC2154,SC2329

load _helper
load "../../../init.sh"

@test "convert_string converts to each conversion type" {
  local input="I am a_string-With spaces 13"

  TEST_CASES=(
    "$input" "file_name" "i_am_a_string-with_spaces_13"
    "$input" "route_path" "i_am_a_string-with_spaces_13"
    "$input" "deployment_id" "i_am_a_string-with_spaces_13"
    "$input" "domain_name" "i_am_a_stringwith_spaces_13"
    "$input" "namespace" "IAmA_stringWithSpaces13"
    "$input" "package_name" "i-am-a_string-with-spaces-13"
    "$input" "function_name" "i_am_a_string-with_spaces_13"
    "$input" "ui_id" "i_am_a_string-with_spaces_13"
    "$input" "cli_command" "i_am_a_string-with_spaces_13"
    "$input" "log_entry" "I am a_string-With spaces 13"
    "$input" "code_comment_title" "I am a_string-With spaces 13"
    "$input" "dummy_type" "Invalid conversion type"
    "HelloWorld" "namespace" "HelloWorld"
    "Hello World" "namespace" "HelloWorld"
    "Hello world" "namespace" "HelloWorld"
    "Hello-world" "namespace" "Helloworld"
  )

  dataprovider_run "convert_string" 3
}

@test "to_pascalcase converts strings to PascalCase" {
  TEST_CASES=(
    "my-awesome-project" "MyAwesomeProject"
    "my_awesome_project" "MyAwesomeProject"
    "my awesome project" "MyAwesomeProject"
    "force-crystal" "ForceCrystal"
    "test-app" "TestApp"
    "single" "Single"
    "mix-case_test project" "MixCaseTestProject"
    "MyAwesomeProject" "MyAwesomeProject"
  )

  dataprovider_run "to_pascalcase" 2
}

create_renovate_json() {
  cat >"${1}/renovate.json" <<'RENOVATE'
{
    "extends": ["config:recommended"],
    "automerge": true,
    "rangeStrategy": "bump",
    "dependencyDashboard": true,
    "pinDigests": true,
    "branchPrefix": "deps/",
    "packageRules": [
        {
            "matchDepNames": ["php"],
            "matchManagers": ["composer"],
            "enabled": false
        },
        {
            "matchDepNames": ["node", "yarn"],
            "matchManagers": ["npm"],
            "enabled": false
        },
        {
            "matchManagers": ["npm", "composer"],
            "matchUpdateTypes": ["major"],
            "enabled": false
        },
        {
            "matchPackageNames": ["*"],
            "groupName": "all dependencies",
            "groupSlug": "all"
        }
    ]
}
RENOVATE
}

@test "remove_php removes composer from renovate matchManagers and php language rule" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_php"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_php
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/renovate.json" '"matchManagers": ["npm"]'
  assert_file_not_contains "${tmpdir}/renovate.json" '"composer"'
  assert_file_not_contains "${tmpdir}/renovate.json" '"matchDepNames": ["php"]'
  assert_file_contains "${tmpdir}/renovate.json" '"matchDepNames": ["node", "yarn"]'
}

@test "remove_nodejs removes npm from renovate matchManagers and node/yarn language rule" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_nodejs"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_nodejs
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/renovate.json" '"matchManagers": ["composer"]'
  assert_file_not_contains "${tmpdir}/renovate.json" '"npm"'
  assert_file_not_contains "${tmpdir}/renovate.json" '"matchDepNames": ["node", "yarn"]'
  assert_file_contains "${tmpdir}/renovate.json" '"matchDepNames": ["php"]'
}

@test "remove_php then remove_nodejs empties matchManagers" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_both"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_php
  remove_nodejs
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/renovate.json" '"matchManagers": []'
}

@test "remove_renovate_managers removes empty matchManagers block" {
  local tmpdir="${BATS_TEST_TMPDIR}/cleanup"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_php
  remove_nodejs
  remove_renovate_managers
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/renovate.json" '"matchManagers"'
  assert_file_not_contains "${tmpdir}/renovate.json" '"matchUpdateTypes"'
  assert_file_contains "${tmpdir}/renovate.json" '"matchPackageNames"'
}

@test "remove_renovate_managers no-ops when matchManagers is not empty" {
  local tmpdir="${BATS_TEST_TMPDIR}/cleanup_noop"
  mkdir -p "${tmpdir}"
  create_renovate_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_php
  remove_renovate_managers
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/renovate.json" '"matchManagers": ["npm"]'
}

create_composer_json() {
  cat >"${1}/composer.json" <<'COMPOSER'
{
    "name": "yournamespace/yourproject",
    "type": "library",
    "bin": [
        "php-command",
        "php-script"
    ],
    "config": {
        "sort-packages": true
    }
}
COMPOSER
}

@test "remove_php_entrypoint drops the composer bin section" {
  local tmpdir="${BATS_TEST_TMPDIR}/entrypoint"
  mkdir -p "${tmpdir}"
  create_composer_json "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_php_entrypoint
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/composer.json" '"bin"'
  assert_file_not_contains "${tmpdir}/composer.json" 'php-command'
  assert_file_not_contains "${tmpdir}/composer.json" 'php-script'
  assert_file_contains "${tmpdir}/composer.json" '"type": "library"'
  assert_file_contains "${tmpdir}/composer.json" '"sort-packages": true'
}

@test "remove_php_entrypoint is a no-op without a composer.json" {
  local tmpdir="${BATS_TEST_TMPDIR}/entrypoint_no_composer"
  mkdir -p "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_php_entrypoint
  popd >/dev/null || return 1

  assert_file_not_exists "${tmpdir}/composer.json"
}

@test "protect_skill_references and restore_skill_references round-trip" {
  local tmpdir="${BATS_TEST_TMPDIR}/skill_refs"
  mkdir -p "${tmpdir}"
  cat >"${tmpdir}/AGENTS.md" <<'AGENTS'
curl https://raw.githubusercontent.com/AlexSkrypnyk/scaffold/main/.scaffold/skills/update-consumer-scaffold/SKILL.md
Invoke the update-consumer-scaffold skill
ask Claude Code to "update scaffold"
AGENTS

  pushd "${tmpdir}" >/dev/null || return 1
  protect_skill_references
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/AGENTS.md" '__SCAFFOLD_SKILL_URL__'
  assert_file_contains "${tmpdir}/AGENTS.md" '__SCAFFOLD_SKILL_NAME__'
  assert_file_contains "${tmpdir}/AGENTS.md" '__SCAFFOLD_SKILL_TRIGGER__'
  assert_file_not_contains "${tmpdir}/AGENTS.md" 'AlexSkrypnyk/scaffold'

  pushd "${tmpdir}" >/dev/null || return 1
  restore_skill_references
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/AGENTS.md" 'https://raw.githubusercontent.com/AlexSkrypnyk/scaffold/main/.scaffold/skills/update-consumer-scaffold/SKILL.md'
  assert_file_contains "${tmpdir}/AGENTS.md" 'Invoke the update-consumer-scaffold skill'
  assert_file_contains "${tmpdir}/AGENTS.md" '"update scaffold"'
  assert_file_not_contains "${tmpdir}/AGENTS.md" '__SCAFFOLD_SKILL'
}

@test "remove_test_actions removes the workflow and its companion configs" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_test_actions"
  mkdir -p "${tmpdir}/.github/workflows"
  touch "${tmpdir}/.github/workflows/test-actions.yml"
  touch "${tmpdir}/.github/.yamllint-for-gha.yml"
  touch "${tmpdir}/zizmor.yml"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_test_actions
  popd >/dev/null || return 1

  assert_file_not_exists "${tmpdir}/.github/workflows/test-actions.yml"
  assert_file_not_exists "${tmpdir}/.github/.yamllint-for-gha.yml"
  assert_file_not_exists "${tmpdir}/zizmor.yml"
}

@test "remove_schedule removes the schedule trigger block" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_schedule"
  mkdir -p "${tmpdir}/.github/workflows"
  cat >"${tmpdir}/.github/workflows/test-php.yml" <<'WORKFLOW'
on:
  # yamllint disable-line #;< SCHEDULE
  schedule:
    - cron: '23 4 * * *'
  # yamllint disable-line #;> SCHEDULE
  push:
    branches:
      - main
WORKFLOW

  pushd "${tmpdir}" >/dev/null || return 1
  remove_schedule
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/.github/workflows/test-php.yml" "schedule:"
  assert_file_not_contains "${tmpdir}/.github/workflows/test-php.yml" "SCHEDULE"
  assert_file_contains "${tmpdir}/.github/workflows/test-php.yml" "push:"
}

@test "remove_ai removes the AI agent files and strips the AI token block" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_ai"
  mkdir -p "${tmpdir}/.claude"
  touch "${tmpdir}/CLAUDE.md"
  touch "${tmpdir}/AGENTS.md"
  echo '{}' >"${tmpdir}/.claude/settings.json"
  cat >"${tmpdir}/.gitignore" <<'GITIGNORE'
/vendor
#;< AI
!/.claude/
#;> AI
/node_modules
GITIGNORE

  pushd "${tmpdir}" >/dev/null || return 1
  remove_ai
  popd >/dev/null || return 1

  assert_file_not_exists "${tmpdir}/CLAUDE.md"
  assert_file_not_exists "${tmpdir}/AGENTS.md"
  assert_dir_not_exists "${tmpdir}/.claude"
  assert_file_not_contains "${tmpdir}/.gitignore" ".claude"
  assert_file_not_contains "${tmpdir}/.gitignore" "AI"
  assert_file_contains "${tmpdir}/.gitignore" "/vendor"
  assert_file_contains "${tmpdir}/.gitignore" "/node_modules"
}

create_ai_arch_docs_tokens() {
  cat >"${1}/AGENTS.md" <<'TOKENS'
before content
#;< AI_ARCH_DOCS
feature content
#;> AI_ARCH_DOCS
#;< AI_ARCH_DOCS_MERMAID
mermaid content
#;> AI_ARCH_DOCS_MERMAID
#;< AI_ARCH_DOCS_PLANTUML
plantuml content
#;> AI_ARCH_DOCS_PLANTUML
after content
TOKENS
}

@test "remove_ai_arch_docs removes the skill and docs dirs and strips all token blocks" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_ai_arch_docs"
  mkdir -p "${tmpdir}/.claude/skills/update-architecture-docs"
  touch "${tmpdir}/.claude/skills/update-architecture-docs/SKILL.md"
  mkdir -p "${tmpdir}/docs/content/architecture"
  touch "${tmpdir}/docs/content/architecture/README.md"
  create_ai_arch_docs_tokens "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_ai_arch_docs
  popd >/dev/null || return 1

  assert_dir_not_exists "${tmpdir}/.claude/skills/update-architecture-docs"
  assert_dir_not_exists "${tmpdir}/docs/content/architecture"
  assert_file_not_contains "${tmpdir}/AGENTS.md" "feature content"
  assert_file_not_contains "${tmpdir}/AGENTS.md" "mermaid content"
  assert_file_not_contains "${tmpdir}/AGENTS.md" "plantuml content"
  assert_file_not_contains "${tmpdir}/AGENTS.md" "AI_ARCH_DOCS"
  assert_file_contains "${tmpdir}/AGENTS.md" "before content"
  assert_file_contains "${tmpdir}/AGENTS.md" "after content"
}

@test "process_ai_arch_docs keeps Mermaid and strips PlantUML when mermaid is selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/process_arch_mermaid"
  mkdir -p "${tmpdir}"
  create_ai_arch_docs_tokens "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  use_ai_arch_docs="mermaid" process_ai_arch_docs
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/AGENTS.md" "feature content"
  assert_file_contains "${tmpdir}/AGENTS.md" "mermaid content"
  assert_file_not_contains "${tmpdir}/AGENTS.md" "plantuml content"
  assert_file_not_contains "${tmpdir}/AGENTS.md" "AI_ARCH_DOCS_PLANTUML"
}

@test "process_ai_arch_docs keeps PlantUML and strips Mermaid when plantuml is selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/process_arch_plantuml"
  mkdir -p "${tmpdir}"
  create_ai_arch_docs_tokens "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  use_ai_arch_docs="plantuml" process_ai_arch_docs
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/AGENTS.md" "feature content"
  assert_file_contains "${tmpdir}/AGENTS.md" "plantuml content"
  assert_file_not_contains "${tmpdir}/AGENTS.md" "mermaid content"
  assert_file_not_contains "${tmpdir}/AGENTS.md" "AI_ARCH_DOCS_MERMAID"
}

@test "process_ai_arch_docs keeps both formats when none is selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/process_arch_none"
  mkdir -p "${tmpdir}"
  create_ai_arch_docs_tokens "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  use_ai_arch_docs="" process_ai_arch_docs
  use_ai_arch_docs="none" process_ai_arch_docs
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/AGENTS.md" "mermaid content"
  assert_file_contains "${tmpdir}/AGENTS.md" "plantuml content"
}

@test "remove_docs relocates the architecture docs when present" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_docs_preserve"
  mkdir -p "${tmpdir}/docs/content/architecture"
  echo "arch content" >"${tmpdir}/docs/content/architecture/README.md"
  touch "${tmpdir}/docs/docusaurus.config.js"
  echo "Architecture documentation lives in docs/content/architecture/." >"${tmpdir}/AGENTS.md"
  mkdir -p "${tmpdir}/.github/workflows"
  touch "${tmpdir}/.github/workflows/test-docs.yml"
  touch "${tmpdir}/.github/workflows/release-docs.yml"
  printf '# /docs            export-ignore\n# /tests           export-ignore\n' >"${tmpdir}/.gitattributes"
  mkdir -p "${tmpdir}/.architecture-preserve-tmp"
  touch "${tmpdir}/.architecture-preserve-tmp/stale.txt"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_docs
  popd >/dev/null || return 1

  assert_file_exists "${tmpdir}/docs/architecture/README.md"
  assert_file_contains "${tmpdir}/docs/architecture/README.md" "arch content"
  assert_file_not_exists "${tmpdir}/docs/docusaurus.config.js"
  assert_dir_not_exists "${tmpdir}/.architecture-preserve-tmp"
  assert_file_not_exists "${tmpdir}/docs/architecture/stale.txt"
  assert_dir_not_exists "${tmpdir}/docs/architecture/architecture"
  run ls -A "${tmpdir}/docs"
  assert_output "architecture"
  assert_file_contains "${tmpdir}/AGENTS.md" "docs/architecture"
  assert_file_not_contains "${tmpdir}/AGENTS.md" "docs/content/architecture"
  assert_file_not_exists "${tmpdir}/.github/workflows/test-docs.yml"
  assert_file_not_exists "${tmpdir}/.github/workflows/release-docs.yml"
  assert_file_contains "${tmpdir}/.gitattributes" "/docs"
}

@test "remove_docs removes docs fully when the architecture docs are absent" {
  local tmpdir="${BATS_TEST_TMPDIR}/remove_docs_full"
  mkdir -p "${tmpdir}/docs"
  touch "${tmpdir}/docs/docusaurus.config.js"
  mkdir -p "${tmpdir}/.github/workflows"
  touch "${tmpdir}/.github/workflows/test-docs.yml"
  touch "${tmpdir}/.github/workflows/release-docs.yml"
  printf '# /docs            export-ignore\n# /tests           export-ignore\n' >"${tmpdir}/.gitattributes"

  pushd "${tmpdir}" >/dev/null || return 1
  remove_docs
  popd >/dev/null || return 1

  assert_dir_not_exists "${tmpdir}/docs"
  assert_file_not_exists "${tmpdir}/.github/workflows/test-docs.yml"
  assert_file_not_exists "${tmpdir}/.github/workflows/release-docs.yml"
  assert_file_not_contains "${tmpdir}/.gitattributes" "/docs"
  assert_file_contains "${tmpdir}/.gitattributes" "/tests"
}

@test "ask_choice returns the default on empty input" {
  run ask_choice "AI architecture docs" "mermaid" "mermaid plantuml none" <<<''
  assert_success
  assert_output "mermaid"
}

@test "ask_choice accepts a valid value" {
  run ask_choice "AI architecture docs" "mermaid" "mermaid plantuml none" <<<'plantuml'
  assert_success
  assert_output "plantuml"
}

@test "ask_choice lowercases the input" {
  run ask_choice "AI architecture docs" "mermaid" "mermaid plantuml none" <<<'PLANTUML'
  assert_success
  assert_output "plantuml"
}

@test "ask_choice re-prompts on invalid input until a valid value is given" {
  run ask_choice "AI architecture docs" "mermaid" "mermaid plantuml none" <<<$'bogus\nplantuml'
  assert_success
  assert_output "plantuml"
}

@test "ask_choice re-prompts on multi-word input" {
  run ask_choice "AI architecture docs" "mermaid" "mermaid plantuml none" <<<$'mermaid plantuml\nnone'
  assert_success
  assert_output "none"
}

@test "ask_choice returns the default on EOF" {
  run ask_choice "AI architecture docs" "mermaid" "mermaid plantuml none" </dev/null
  assert_success
  assert_output "mermaid"
}

@test "parse_args without arguments keeps interactive mode" {
  parse_args
  assert_equal "${interactive}" "1"
}

@test "parse_args sets identity values and disables interactive mode" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe"
  assert_equal "${namespace}" "AcmeApp"
  assert_equal "${project}" "acme-app"
  assert_equal "${author}" "Jane Doe"
  assert_equal "${interactive}" "0"
}

@test "parse_args --no-php disables PHP" {
  parse_args --no-php
  assert_equal "${use_php}" "n"
}

@test "parse_args --php-script selects the script sub-mode" {
  parse_args --php-script
  assert_equal "${use_php_script}" "y"
}

@test "parse_args --no-php-command declines the command sub-mode" {
  parse_args --no-php-command
  assert_equal "${use_php_command}" "n"
}

@test "parse_args --no-php-script declines the script sub-mode" {
  parse_args --no-php-script
  assert_equal "${use_php_script}" "n"
}

@test "parse_args --php-command-name implies the command sub-mode" {
  parse_args --php-command-name=mycli
  assert_equal "${php_command_name}" "mycli"
  assert_equal "${use_php_command}" "y"
}

@test "parse_args --docker-image-name implies Docker support" {
  parse_args --docker-image-name=acme/app
  assert_equal "${docker_image_name}" "acme/app"
  assert_equal "${use_docker}" "y"
}

@test "parse_args --test-actions enables GitHub Actions linting" {
  parse_args --test-actions
  assert_equal "${use_test_actions}" "y"
}

@test "parse_args --no-test-actions disables GitHub Actions linting" {
  parse_args --no-test-actions
  assert_equal "${use_test_actions}" "n"
}

@test "parse_args --schedule enables scheduled builds" {
  parse_args --schedule
  assert_equal "${use_schedule}" "y"
}

@test "parse_args --no-schedule disables scheduled builds" {
  parse_args --no-schedule
  assert_equal "${use_schedule}" "n"
}

@test "parse_args --ai enables AI agents" {
  parse_args --ai
  assert_equal "${use_ai}" "y"
}

@test "parse_args --no-ai disables AI agents" {
  parse_args --no-ai
  assert_equal "${use_ai}" "n"
}

@test "parse_args --ai-arch-docs selects the default Mermaid format" {
  parse_args --ai-arch-docs
  assert_equal "${use_ai_arch_docs}" "mermaid"
}

@test "parse_args --ai-arch-docs=plantuml selects the PlantUML format" {
  parse_args --ai-arch-docs=plantuml
  assert_equal "${use_ai_arch_docs}" "plantuml"
}

@test "parse_args --ai-arch-docs=none disables AI architecture docs" {
  parse_args --ai-arch-docs=none
  assert_equal "${use_ai_arch_docs}" "none"
}

@test "parse_args --no-ai-arch-docs disables AI architecture docs" {
  parse_args --no-ai-arch-docs
  assert_equal "${use_ai_arch_docs}" "none"
}

@test "parse_args --keep preserves the script" {
  parse_args --keep
  assert_equal "${remove_self}" "n"
}

@test "parse_args --yes disables interactive mode" {
  parse_args --yes
  assert_equal "${interactive}" "0"
}

@test "parse_args --ref sets the bootstrap ref" {
  parse_args --ref=1.2.3
  assert_equal "${archive_ref}" "1.2.3"
}

@test "parse_args fails on conflicting PHP sub-modes" {
  run parse_args --php-command --php-script
  assert_failure
  assert_output_contains "cannot be used together"
}

@test "parse_args fails on an unknown option" {
  run parse_args --unknown
  assert_failure
  assert_output_contains "Unknown option"
}

@test "parse_args fails on an invalid --ai-arch-docs value" {
  run parse_args --ai-arch-docs=bogus
  assert_failure
  assert_output_contains "Error: Invalid value for --ai-arch-docs: bogus. Allowed values: mermaid, plantuml, none."
  assert_output_contains "Run with --help for usage."
}

@test "parse_args prints usage for --help" {
  run parse_args --help
  assert_success
  assert_output_contains "Usage: ./init.sh"
}

@test "parse_args prints the version for --version" {
  run parse_args --version
  assert_success
  assert_output "dev"
}

@test "require_identity fails when identity is missing" {
  run require_identity
  assert_failure
  assert_output_contains "Missing required option"
}

@test "normalize_inputs canonicalizes identity values" {
  namespace="Acme App"
  project="Acme App"
  author="Jane Doe"
  normalize_inputs
  assert_equal "${namespace}" "AcmeApp"
  assert_equal "${project}" "acme-app"
  assert_equal "${project_pascalcase}" "AcmeApp"
}

@test "collect_noninteractive applies defaults and prints a summary" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe"
  run collect_noninteractive
  assert_success
  assert_output_contains "Summary"
  assert_output_contains "AcmeApp"
  assert_output_contains "acme-app"
}

@test "collect_noninteractive honors the script sub-mode" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --php-script
  run collect_noninteractive
  assert_success
  assert_output_contains "Use simple script              : y"
}

@test "collect_noninteractive falls back to the script when only the command app is declined" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --no-php-command
  run collect_noninteractive
  assert_success
  assert_output_contains "Use CLI command app            : n"
  assert_output_contains "Use simple script              : y"
  assert_output_contains "Simple script name           : acme-app"
}

@test "collect_noninteractive keeps the command app when only the script is declined" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --no-php-script
  run collect_noninteractive
  assert_success
  assert_output_contains "Use CLI command app            : y"
  assert_output_contains "Use simple script              : n"
}

@test "collect_noninteractive selects the library when both entry points are declined" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --no-php-command --no-php-script
  run collect_noninteractive
  assert_success
  assert_output_contains "Use PHP                          : y"
  assert_output_contains "Use CLI command app            : n"
  assert_output_contains "CLI command name             : <unset>"
  assert_output_contains "Build PHAR                   : n"
  assert_output_contains "Use simple script              : n"
}

@test "collect_noninteractive disables features on request" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --no-php --docker
  run collect_noninteractive
  assert_success
  assert_output_contains "Use PHP                          : n"
  assert_output_contains "Use Docker                       : y"
}

@test "collect_noninteractive keeps GitHub Actions linting off by default" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe"
  run collect_noninteractive
  assert_success
  assert_output_contains "Use GitHub Actions linting       : n"
}

@test "collect_noninteractive enables GitHub Actions linting on request" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --test-actions
  run collect_noninteractive
  assert_success
  assert_output_contains "Use GitHub Actions linting       : y"
}

@test "collect_noninteractive keeps scheduled builds on by default" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe"
  run collect_noninteractive
  assert_success
  assert_output_contains "Use scheduled builds             : y"
}

@test "collect_noninteractive disables scheduled builds on request" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --no-schedule
  run collect_noninteractive
  assert_success
  assert_output_contains "Use scheduled builds             : n"
}

@test "collect_noninteractive keeps AI agents on by default" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe"
  run collect_noninteractive
  assert_success
  assert_output_contains "Use AI agents                    : y"
  assert_output_contains "AI architecture docs             : mermaid"
}

@test "collect_noninteractive disables AI agents and architecture docs on request" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --no-ai
  run collect_noninteractive
  assert_success
  assert_output_contains "Use AI agents                    : n"
  assert_output_contains "AI architecture docs             : none"
}

@test "collect_noninteractive selects the PlantUML architecture docs on request" {
  parse_args --namespace=AcmeApp --name=acme-app --author="Jane Doe" --ai-arch-docs=plantuml
  run collect_noninteractive
  assert_success
  assert_output_contains "AI architecture docs             : plantuml"
}

create_claude_settings() {
  mkdir -p "${1}/.claude"
  cat >"${1}/.claude/settings.json" <<'SETTINGS'
{
  "permissions": {
    "allow": [
      "Bash(composer:*)",
      "Bash(./vendor/bin/phpcs:*)",
      "Bash(./vendor/bin/phpcbf:*)",
      "Bash(./vendor/bin/phpstan:*)",
      "Bash(./vendor/bin/rector:*)",
      "Bash(./vendor/bin/phpunit:*)",
      "Bash(./tests/bats/node_modules/bats/bin/bats:*)",
      "Bash(npm:*)",
      "Bash(docker build:*)",
      "Bash(docker run:*)"
    ]
  }
}
SETTINGS
}

@test "process_claude_settings keeps every rule when all features are selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_all"
  mkdir -p "${tmpdir}"
  create_claude_settings "${tmpdir}"

  use_php="y"
  use_shell="y"
  use_nodejs="y"
  use_docs="y"
  use_docker="y"

  pushd "${tmpdir}" >/dev/null || return 1
  process_claude_settings
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/.claude/settings.json" "composer:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "bats:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "npm:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "docker build:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "docker run:"
}

@test "process_claude_settings removes PHP rules when PHP is not selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_no_php"
  mkdir -p "${tmpdir}"
  create_claude_settings "${tmpdir}"

  use_php="n"
  use_shell="y"
  use_nodejs="y"
  use_docs="y"
  use_docker="y"

  pushd "${tmpdir}" >/dev/null || return 1
  process_claude_settings
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/.claude/settings.json" "composer:"
  assert_file_not_contains "${tmpdir}/.claude/settings.json" "phpstan:"
  assert_file_not_contains "${tmpdir}/.claude/settings.json" "phpunit:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "bats:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "npm:"
}

@test "process_claude_settings removes the bats rule when shell is not selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_no_shell"
  mkdir -p "${tmpdir}"
  create_claude_settings "${tmpdir}"

  use_php="y"
  use_shell="n"
  use_nodejs="y"
  use_docs="y"
  use_docker="y"

  pushd "${tmpdir}" >/dev/null || return 1
  process_claude_settings
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/.claude/settings.json" "bats:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "composer:"
}

@test "process_claude_settings removes Docker rules when Docker is not selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_no_docker"
  mkdir -p "${tmpdir}"
  create_claude_settings "${tmpdir}"

  use_php="y"
  use_shell="y"
  use_nodejs="y"
  use_docs="y"
  use_docker="n"

  pushd "${tmpdir}" >/dev/null || return 1
  process_claude_settings
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/.claude/settings.json" "docker build:"
  assert_file_not_contains "${tmpdir}/.claude/settings.json" "docker run:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "npm:"
}

@test "process_claude_settings keeps npm when docs is selected without NodeJS" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_docs_npm"
  mkdir -p "${tmpdir}"
  create_claude_settings "${tmpdir}"

  use_php="y"
  use_shell="y"
  use_nodejs="n"
  use_docs="y"
  use_docker="y"

  pushd "${tmpdir}" >/dev/null || return 1
  process_claude_settings
  popd >/dev/null || return 1

  assert_file_contains "${tmpdir}/.claude/settings.json" "npm:"
}

@test "process_claude_settings removes npm when neither NodeJS nor docs is selected" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_no_npm"
  mkdir -p "${tmpdir}"
  create_claude_settings "${tmpdir}"

  use_php="y"
  use_shell="y"
  use_nodejs="n"
  use_docs="n"
  use_docker="y"

  pushd "${tmpdir}" >/dev/null || return 1
  process_claude_settings
  popd >/dev/null || return 1

  assert_file_not_contains "${tmpdir}/.claude/settings.json" "npm:"
  assert_file_contains "${tmpdir}/.claude/settings.json" "composer:"
}

@test "process_claude_settings no-ops when the settings file is absent" {
  local tmpdir="${BATS_TEST_TMPDIR}/claude_absent"
  mkdir -p "${tmpdir}"

  use_php="n"

  pushd "${tmpdir}" >/dev/null || return 1
  run process_claude_settings
  popd >/dev/null || return 1

  assert_success
  assert_file_not_exists "${tmpdir}/.claude/settings.json"
}

@test "process_contributing promotes the distributable CONTRIBUTING file" {
  local tmpdir="${BATS_TEST_TMPDIR}/process_contributing"
  mkdir -p "${tmpdir}"
  echo "Contributing guide" >"${tmpdir}/CONTRIBUTING.dist.md"

  pushd "${tmpdir}" >/dev/null || return 1
  process_contributing
  popd >/dev/null || return 1

  assert_file_exists "${tmpdir}/CONTRIBUTING.md"
  assert_file_not_exists "${tmpdir}/CONTRIBUTING.dist.md"
  assert_file_contains "${tmpdir}/CONTRIBUTING.md" "Contributing guide"
}

@test "process_project runs the full flow and promotes the dist docs" {
  local tmpdir="${BATS_TEST_TMPDIR}/process_project"
  mkdir -p "${tmpdir}"
  printf '# /.editorconfig   export-ignore\n# /docs            export-ignore\n' >"${tmpdir}/.gitattributes"
  echo "README dist content" >"${tmpdir}/README.dist.md"
  echo "Contributing dist content" >"${tmpdir}/CONTRIBUTING.dist.md"

  namespace="AcmeApp"
  project="acme-app"
  author="Jane Doe"
  project_pascalcase="AcmeApp"
  remove_self="n"

  # Stub the placeholder-logo download so the flow never hits the network.
  curl() { return 0; }

  pushd "${tmpdir}" >/dev/null || return 1
  process_project
  popd >/dev/null || return 1

  assert_file_exists "${tmpdir}/README.md"
  assert_file_not_exists "${tmpdir}/README.dist.md"
  assert_file_exists "${tmpdir}/CONTRIBUTING.md"
  assert_file_not_exists "${tmpdir}/CONTRIBUTING.dist.md"
}

@test "process_project scaffolds a class library when both entry points are declined" {
  local tmpdir="${BATS_TEST_TMPDIR}/process_project_library"
  mkdir -p "${tmpdir}/src/Command"
  mkdir -p "${tmpdir}/tests/phpunit/Unit"
  printf '# /.editorconfig   export-ignore\n# /docs            export-ignore\n' >"${tmpdir}/.gitattributes"
  echo "README dist content" >"${tmpdir}/README.dist.md"
  echo "Contributing dist content" >"${tmpdir}/CONTRIBUTING.dist.md"
  create_composer_json "${tmpdir}"
  echo "<?php // command" >"${tmpdir}/php-command"
  echo "<?php // script" >"${tmpdir}/php-script"
  echo "<?php // library" >"${tmpdir}/src/Example.php"
  echo "<?php // joke" >"${tmpdir}/src/Command/JokeCommand.php"
  echo "<?php // library test" >"${tmpdir}/tests/phpunit/Unit/ExampleUnitTest.php"

  namespace="AcmeApp"
  project="acme-app"
  author="Jane Doe"
  project_pascalcase="AcmeApp"
  remove_self="n"
  use_php="y"
  use_php_command="n"
  use_php_script="n"

  # Stub the placeholder-logo download so the flow never hits the network.
  curl() { return 0; }

  pushd "${tmpdir}" >/dev/null || return 1
  process_project
  popd >/dev/null || return 1

  assert_file_not_exists "${tmpdir}/php-command"
  assert_file_not_exists "${tmpdir}/php-script"
  assert_dir_not_exists "${tmpdir}/src/Command"
  assert_file_exists "${tmpdir}/src/Example.php"
  assert_file_exists "${tmpdir}/tests/phpunit/Unit/ExampleUnitTest.php"
  assert_file_not_contains "${tmpdir}/composer.json" '"bin"'
}

create_release_workflow() {
  mkdir -p "${1}/.github/workflows"
  cat >"${1}/.github/workflows/release-php.yml" <<'RELEASE'
      - name: Set release version
        run: echo "Release version"
      # yamllint disable-line #;< PHP_PHAR
      - name: Build PHAR
        run: composer build
      # yamllint disable-line #;> PHP_PHAR
      - name: Create Release
        with:
          tag_name: ${{ env.RELEASE_VERSION }}
          # yamllint disable-line #;< PHP_RELEASE_FILES
          files: |
            #;< PHP_PHAR
            ./.build/php-command.phar
            #;> PHP_PHAR
            #;< PHP_SCRIPT
            php-script
            #;> PHP_SCRIPT
          # yamllint disable-line #;> PHP_RELEASE_FILES
RELEASE
}

@test "process_project drops the release artifact list when the command app skips the PHAR" {
  local tmpdir="${BATS_TEST_TMPDIR}/process_project_no_phar"
  mkdir -p "${tmpdir}"
  printf '# /.editorconfig   export-ignore\n# /docs            export-ignore\n' >"${tmpdir}/.gitattributes"
  echo "README dist content" >"${tmpdir}/README.dist.md"
  echo "Contributing dist content" >"${tmpdir}/CONTRIBUTING.dist.md"
  create_composer_json "${tmpdir}"
  create_release_workflow "${tmpdir}"
  echo '{"main": "php-command"}' >"${tmpdir}/box.json"
  echo "<?php // command" >"${tmpdir}/php-command"
  echo "<?php // script" >"${tmpdir}/php-script"

  namespace="AcmeApp"
  project="acme-app"
  author="Jane Doe"
  project_pascalcase="AcmeApp"
  remove_self="n"
  use_php="y"
  use_php_command="y"
  use_php_command_build="n"
  php_command_name="acme-app"

  # Stub the placeholder-logo download so the flow never hits the network.
  curl() { return 0; }

  pushd "${tmpdir}" >/dev/null || return 1
  process_project
  popd >/dev/null || return 1

  assert_file_not_exists "${tmpdir}/box.json"
  assert_file_exists "${tmpdir}/acme-app"
  assert_file_contains "${tmpdir}/.github/workflows/release-php.yml" "tag_name"
  assert_file_not_contains "${tmpdir}/.github/workflows/release-php.yml" "files:"
  assert_file_not_contains "${tmpdir}/.github/workflows/release-php.yml" "Build PHAR"
}

@test "collect_interactive declines both entry points without asking for a script name" {
  run collect_interactive <<<"$(printf 'AcmeApp\nacme-app\nJane Doe\ny\nn\nn\n')"

  assert_success
  assert_output_contains "Use CLI command app            : n"
  assert_output_contains "Use simple script              : n"
  assert_output_not_contains "CLI script name"
}

@test "template_present detects the .scaffold directory" {
  local tmpdir="${BATS_TEST_TMPDIR}/template_present"
  mkdir -p "${tmpdir}/.scaffold"

  pushd "${tmpdir}" >/dev/null || return 1
  run template_present
  popd >/dev/null || return 1

  assert_success
}

@test "template_present fails when .scaffold is absent" {
  local tmpdir="${BATS_TEST_TMPDIR}/template_absent"
  mkdir -p "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  run template_present
  popd >/dev/null || return 1

  assert_failure
}

@test "dir_is_empty is true for an empty directory" {
  local tmpdir="${BATS_TEST_TMPDIR}/empty"
  mkdir -p "${tmpdir}"

  pushd "${tmpdir}" >/dev/null || return 1
  run dir_is_empty
  popd >/dev/null || return 1

  assert_success
}

@test "dir_is_empty is false when a dotfile is present" {
  local tmpdir="${BATS_TEST_TMPDIR}/dotfile"
  mkdir -p "${tmpdir}"
  touch "${tmpdir}/.hidden"

  pushd "${tmpdir}" >/dev/null || return 1
  run dir_is_empty
  popd >/dev/null || return 1

  assert_failure
}

@test "resolve_archive_url prefers SCAFFOLD_ARCHIVE_URL" {
  SCAFFOLD_ARCHIVE_URL="file:///tmp/local.tar.gz"
  archive_ref="1.2.3"
  run resolve_archive_url
  assert_success
  assert_output "file:///tmp/local.tar.gz"
}

@test "resolve_archive_url builds an archive URL from --ref" {
  SCAFFOLD_ARCHIVE_URL=""
  archive_ref="feature-x"
  run resolve_archive_url
  assert_success
  assert_output "https://github.com/AlexSkrypnyk/scaffold/archive/feature-x.tar.gz"
}

@test "resolve_archive_url uses the latest release tag by default" {
  SCAFFOLD_ARCHIVE_URL=""
  archive_ref=""
  curl() { echo '{"tag_name": "9.9.9"}'; }
  run resolve_archive_url
  assert_success
  assert_output "https://github.com/AlexSkrypnyk/scaffold/archive/refs/tags/9.9.9.tar.gz"
}

@test "resolve_archive_url falls back to main when no release is found" {
  SCAFFOLD_ARCHIVE_URL=""
  archive_ref=""
  curl() { return 1; }
  run resolve_archive_url
  assert_success
  assert_output "https://github.com/AlexSkrypnyk/scaffold/archive/refs/heads/main.tar.gz"
}

create_template_tarball() {
  local out="${1}"
  local with_scaffold="${2:-1}"
  local src="${BATS_TEST_TMPDIR}/template_src"
  rm -rf "${src}"
  mkdir -p "${src}/pkg"
  touch "${src}/pkg/composer.json"
  if [ "${with_scaffold}" = "1" ]; then
    mkdir -p "${src}/pkg/.scaffold"
    touch "${src}/pkg/.scaffold/README.md"
  fi
  tar -czf "${out}" -C "${src}" pkg
}

@test "fetch_and_stage_template promotes a valid archive" {
  local archive="${BATS_TEST_TMPDIR}/valid.tar.gz"
  create_template_tarball "${archive}" 1

  local target="${BATS_TEST_TMPDIR}/valid_target"
  mkdir -p "${target}"

  pushd "${target}" >/dev/null || return 1
  run fetch_and_stage_template "file://${archive}"
  popd >/dev/null || return 1

  assert_success
  assert_dir_exists "${target}/.scaffold"
  assert_file_exists "${target}/composer.json"
  assert_dir_not_exists "${target}/.scaffold-bootstrap"
}

@test "fetch_and_stage_template fails on an archive without .scaffold" {
  local archive="${BATS_TEST_TMPDIR}/invalid.tar.gz"
  create_template_tarball "${archive}" 0

  local target="${BATS_TEST_TMPDIR}/invalid_target"
  mkdir -p "${target}"

  pushd "${target}" >/dev/null || return 1
  run fetch_and_stage_template "file://${archive}"
  popd >/dev/null || return 1

  assert_failure
  assert_output_contains "not a Scaffold template"
  assert_dir_not_exists "${target}/.scaffold-bootstrap"
  assert_file_not_exists "${target}/composer.json"
}

@test "fetch_and_stage_template fails when the download fails" {
  local target="${BATS_TEST_TMPDIR}/download_fail_target"
  mkdir -p "${target}"

  pushd "${target}" >/dev/null || return 1
  run fetch_and_stage_template "file://${BATS_TEST_TMPDIR}/missing.tar.gz"
  popd >/dev/null || return 1

  assert_failure
  assert_output_contains "failed to download"
  assert_dir_not_exists "${target}/.scaffold-bootstrap"
}
