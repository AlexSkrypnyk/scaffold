#!/usr/bin/env bats
#
# Unit tests for the GitHub repository configuration in install.sh.
#
# 'gh' and 'has_command' are replaced with functions. Calls that pass '--jq'
# are reads and land in GH_READS; every other call is a write and lands in
# GH_WRITES together with any request body, so the tests assert the exact
# writes of each section.
#
# Variables under test are assigned by the sourced install.sh, which shellcheck
# does not follow (SC2034, SC2153, SC2154). Each test runs in its own subshell,
# so setting a global in 1 test and reading it in another is intended (SC2030,
# SC2031). The mocks are invoked indirectly (SC2329).
# shellcheck disable=SC2030,SC2031,SC2034,SC2153,SC2154,SC2329

load _helper
load "../../../install.sh"

gh() {
  echo "${GH_TOKEN-}|${GITHUB_TOKEN-}" >>"${GH_ENV}"

  if [[ " $* " == *" --jq "* ]]; then
    echo "gh $*" >>"${GH_READS}"
  else
    echo "gh $*" >>"${GH_WRITES}"
    [[ " $* " != *" --input - "* ]] || cat >>"${GH_WRITES}"
  fi

  # shellcheck disable=SC2053
  if [ -n "${GH_FAIL_MATCH-}" ] && [[ $* == ${GH_FAIL_MATCH} ]]; then
    echo "${GH_FAIL_OUTPUT}" >&2
    return 1
  fi

  case "$*" in
    "api user --jq .login") echo "${GH_LOGIN}" ;;
    "api repos/acme/app --jq "*) echo "${GH_STATE}" ;;
    "api repos/acme/app/labels "*) printf '%s' "${GH_LABELS}" ;;
    "api repos/acme/app/rulesets --paginate "*) echo "${GH_RULESET_ID}" ;;
    "api repos/acme/app/rulesets/"*" --jq "*) echo "${GH_RULESET_CHECKS}" ;;
  esac
}

# Repository state with every general setting already applied.
state_applied() {
  cat <<'STATE'
default_branch=main
description=Acme app
allow_merge_commit=false
allow_squash_merge=true
allow_rebase_merge=true
squash_merge_commit_title=PR_TITLE
squash_merge_commit_message=BLANK
allow_auto_merge=true
allow_update_branch=true
delete_branch_on_merge=true
has_issues=true
has_wiki=false
has_projects=false
has_discussions=false
STATE
}

# Repository state of a new GitHub repository.
state_new() {
  cat <<'STATE'
default_branch=main
description=
allow_merge_commit=true
allow_squash_merge=true
allow_rebase_merge=true
squash_merge_commit_title=COMMIT_OR_PR_TITLE
squash_merge_commit_message=COMMIT_MESSAGES
allow_auto_merge=false
allow_update_branch=false
delete_branch_on_merge=false
has_issues=true
has_wiki=true
has_projects=true
has_discussions=false
STATE
}

# Labels as the API lists them once every baked-in label is applied.
labels_applied() {
  local entry
  local rest

  for entry in "${GITHUB_LABELS[@]}"; do
    rest="${entry#*|}"
    printf '%s\t%s\t%s\n' "${entry%%|*}" "$(to_lowercase "${rest%%|*}")" "${rest#*|}"
  done
}

github_setup() {
  GH_ENV="${BATS_TEST_TMPDIR}/gh.env"
  GH_READS="${BATS_TEST_TMPDIR}/gh.reads"
  GH_WRITES="${BATS_TEST_TMPDIR}/gh.writes"
  : >"${GH_ENV}"
  : >"${GH_READS}"
  : >"${GH_WRITES}"

  GH_LOGIN="jane"
  GH_STATE="$(state_applied)"
  GH_LABELS="$(labels_applied)"
  GH_RULESET_ID=""
  GH_RULESET_CHECKS=""
  GH_FAIL_MATCH=""
  GH_FAIL_OUTPUT=""

  has_command() { return 0; }
  SCAFFOLD_GITHUB_TOKEN="test-token"

  github_owner="acme"
  github_repo="app"
  github_apply_defaults
}

assert_no_writes() {
  run cat "${GH_WRITES}"
  assert_output ""
}

#-------------------------------------------------------------------------------
# Prerequisites and authentication
#-------------------------------------------------------------------------------

@test "gh_run authenticates with SCAFFOLD_GITHUB_TOKEN only" {
  github_setup
  GITHUB_TOKEN="shell-token"
  GH_TOKEN="shell-gh-token"

  gh_run api user --jq .login >/dev/null

  run cat "${GH_ENV}"
  assert_output "test-token|"
}

@test "github_prerequisites reports every missing prerequisite" {
  # gh installed, token set, expected status, expected output.
  local cases=(
    "y" "y" "0" ""
    "n" "y" "1" "Skipping GitHub repository settings: 'gh' is not installed.
Install GitHub CLI (https://cli.github.com), then run './install.sh github'."
    "y" "n" "1" "Skipping GitHub repository settings: SCAFFOLD_GITHUB_TOKEN is not set.
Set SCAFFOLD_GITHUB_TOKEN, then run './install.sh github'."
    "n" "n" "1" "Skipping GitHub repository settings: 'gh' is not installed; SCAFFOLD_GITHUB_TOKEN is not set.
Install GitHub CLI (https://cli.github.com) and set SCAFFOLD_GITHUB_TOKEN, then run './install.sh github'."
  )
  local i

  for ((i = 0; i < ${#cases[@]}; i += 4)); do
    GH_HAS="${cases[i]}"
    has_command() { [ "${1}" != "gh" ] || [ "${GH_HAS}" = "y" ]; }
    SCAFFOLD_GITHUB_TOKEN=""
    [ "${cases[i + 1]}" = "n" ] || SCAFFOLD_GITHUB_TOKEN="test-token"

    run github_prerequisites
    assert_status "${cases[i + 2]}"
    assert_output "${cases[i + 3]}"
  done
}

@test "github_main exits 1 without calling gh when a prerequisite is missing" {
  local combinations=("n:" "n:test-token" "y:")
  local combination

  for combination in "${combinations[@]}"; do
    github_setup
    GH_HAS="${combination%%:*}"
    has_command() { [ "${1}" != "gh" ] || [ "${GH_HAS}" = "y" ]; }
    SCAFFOLD_GITHUB_TOKEN="${combination#*:}"

    run github_main
    assert_failure
    assert_output_contains "Skipping GitHub repository settings:"
    assert_output_contains "then run './install.sh github'."

    run cat "${GH_READS}" "${GH_WRITES}"
    assert_output ""
  done
}

@test "collect_github_noninteractive continues without calling gh when a prerequisite is missing" {
  local combinations=("n:" "n:test-token" "y:")
  local combination

  for combination in "${combinations[@]}"; do
    github_setup
    GH_HAS="${combination%%:*}"
    has_command() { [ "${1}" != "gh" ] || [ "${GH_HAS}" = "y" ]; }
    SCAFFOLD_GITHUB_TOKEN="${combination#*:}"
    use_github="y"

    collect_github_noninteractive >"${BATS_TEST_TMPDIR}/out"

    assert_equal "${use_github}" "n"
    assert_file_contains "${BATS_TEST_TMPDIR}/out" "Skipping GitHub repository settings:"

    run cat "${GH_READS}" "${GH_WRITES}"
    assert_output ""
  done
}

@test "collect_github_interactive prints the message in place of the prompts when a prerequisite is missing" {
  github_setup
  SCAFFOLD_GITHUB_TOKEN=""

  # No input is given, so any prompt would read EOF and fall back silently.
  collect_github_interactive >"${BATS_TEST_TMPDIR}/out" </dev/null

  assert_equal "${use_github}" "n"
  assert_file_contains "${BATS_TEST_TMPDIR}/out" "SCAFFOLD_GITHUB_TOKEN is not set"

  run cat "${GH_READS}" "${GH_WRITES}"
  assert_output ""
}

@test "collect_github_noninteractive is a no-op without --github" {
  github_setup
  use_github="n"
  github_owner=""

  run collect_github_noninteractive
  assert_success
  assert_output ""

  run cat "${GH_READS}"
  assert_output ""
}

#-------------------------------------------------------------------------------
# Identity derivation
#-------------------------------------------------------------------------------

# Create a git repository with an optional 'origin' remote and enter it.
enter_repo() {
  local dir="${BATS_TEST_TMPDIR}/${1}"
  mkdir -p "${dir}"
  git -C "${dir}" init -q
  [ -z "${2:-}" ] || git -C "${dir}" remote add origin "${2}"
  cd "${dir}" || return 1
}

@test "github_origin parses the GitHub remote URL forms" {
  # Remote URL, expected "owner/repo".
  local cases=(
    "git@github.com:acme/app.git" "acme/app"
    "https://github.com/acme/app.git" "acme/app"
    "https://github.com/acme/app" "acme/app"
    "https://github.com/acme/app/" "acme/app"
    "ssh://git@github.com/acme/app.git" "acme/app"
    "https://x-access-token:secret@github.com/Acme-Org/Acme_App.git" "Acme-Org/Acme_App"
    "git@gitlab.com:acme/app.git" ""
    "git@github.com:AlexSkrypnyk/scaffold.git" ""
    "https://github.com/alexskrypnyk/Scaffold" ""
  )
  local i

  for ((i = 0; i < ${#cases[@]}; i += 2)); do
    enter_repo "origin_${i}" "${cases[i]}"
    run github_origin
    assert_success
    assert_output "${cases[i + 1]}"
  done
}

@test "github_origin prints nothing without a repository or an origin remote" {
  enter_repo "no_origin"
  run github_origin
  assert_success
  assert_output ""

  mkdir -p "${BATS_TEST_TMPDIR}/no_repo"
  cd "${BATS_TEST_TMPDIR}/no_repo" || return 1
  run github_origin
  assert_success
  assert_output ""
}

@test "github_origin ignores the remote when git is not installed" {
  enter_repo "no_git" "git@github.com:acme/app.git"
  has_command() { [ "${1}" != "git" ]; }

  run github_origin
  assert_success
  assert_output ""
}

@test "resolve_github_identity derives namespace and project defaults" {
  # Owner option, repository option, origin URL, expected owner, repository,
  # namespace default, project default, owner source, repository source.
  local cases=(
    "acme-org" "Acme_App" "" "acme-org" "Acme_App" "AcmeOrg" "acme-app" "--github-owner" "--github-repo"
    "" "" "git@github.com:acme-org/acme-app.git" "acme-org" "acme-app" "AcmeOrg" "acme-app" "the 'origin' remote" "the 'origin' remote"
    "Acme-Org" "" "git@github.com:acme-org/acme-app.git" "Acme-Org" "acme-app" "AcmeOrg" "acme-app" "--github-owner" "the 'origin' remote"
    "" "" "" "" "" "" "" "" ""
    "acme" "" "" "acme" "" "Acme" "" "--github-owner" ""
    "" "my.app" "" "" "my.app" "" "my.app" "" "--github-repo"
  )
  local i

  for ((i = 0; i < ${#cases[@]}; i += 9)); do
    enter_repo "derive_${i}" "${cases[i + 2]}"
    github_owner="${cases[i]}"
    github_repo="${cases[i + 1]}"
    github_owner_source=""
    github_repo_source=""
    namespace_default=""
    project_default=""

    resolve_github_identity

    assert_equal "${github_owner}" "${cases[i + 3]}"
    assert_equal "${github_repo}" "${cases[i + 4]}"
    assert_equal "${namespace_default}" "${cases[i + 5]}"
    assert_equal "${project_default}" "${cases[i + 6]}"
    assert_equal "${github_owner_source}" "${cases[i + 7]}"
    assert_equal "${github_repo_source}" "${cases[i + 8]}"
  done
}

@test "resolve_github_identity fails when the options do not match origin" {
  enter_repo "mismatch" "git@github.com:acme/app.git"
  github_owner="other"

  run resolve_github_identity
  assert_failure
  assert_output_contains "Error: GitHub repository other/app does not match the 'origin' remote acme/app. Change the options or the remote."

  run git remote get-url origin
  assert_output "git@github.com:acme/app.git"
}

@test "collect_noninteractive derives namespace and name from the GitHub options" {
  enter_repo "derived_noninteractive"
  parse_args --github-owner=acme-org --github-repo=Acme_App --author="Jane Doe"

  run collect_noninteractive
  assert_success
  assert_output_contains "Namespace                        : AcmeOrg"
  assert_output_contains "Project                          : acme-app"
}

@test "collect_noninteractive derives namespace and name from origin" {
  enter_repo "derived_origin" "https://github.com/acme-org/acme-app.git"
  parse_args --author="Jane Doe"

  run collect_noninteractive
  assert_success
  assert_output_contains "Namespace                        : AcmeOrg"
  assert_output_contains "Project                          : acme-app"
}

@test "collect_noninteractive prefers explicit identity options over derived values" {
  enter_repo "derived_override" "https://github.com/acme-org/acme-app.git"
  parse_args --namespace=Explicit --name=explicit-name --author="Jane Doe"

  run collect_noninteractive
  assert_success
  assert_output_contains "Namespace                        : Explicit"
  assert_output_contains "Project                          : explicit-name"
}

@test "collect_noninteractive still requires the author with derived values" {
  enter_repo "derived_no_author"
  parse_args --github-owner=acme --github-repo=app

  run collect_noninteractive
  assert_failure
  assert_output_contains "Missing required option(s) in non-interactive mode: --author"
}

@test "collect_noninteractive names the source of an invalid derived value" {
  # Options, expected error.
  local cases=(
    "--namespace=Acme --github-repo=acme.app" "Error: Name derived from --github-repo is invalid: 'acme.app'. Pass --name explicitly."
    "--name=acme --github-owner=1acme" "Error: Namespace derived from --github-owner is invalid: '1acme'. Pass --namespace explicitly."
  )
  local i

  for ((i = 0; i < ${#cases[@]}; i += 2)); do
    enter_repo "derived_invalid_${i}"
    namespace=""
    project=""
    github_owner=""
    github_repo=""
    # shellcheck disable=SC2086
    parse_args --author="Jane Doe" ${cases[i]}

    run collect_noninteractive
    assert_failure
    assert_output_contains "${cases[i + 1]}"
  done
}

@test "collect_noninteractive names origin as the source of an invalid derived value" {
  enter_repo "derived_invalid_origin" "git@github.com:acme/my.app.git"
  parse_args --author="Jane Doe"

  run collect_noninteractive
  assert_failure
  assert_output_contains "Error: Name derived from the 'origin' remote is invalid: 'my.app'. Pass --name explicitly."
}

@test "collect_interactive offers origin values as the Namespace and Project defaults" {
  enter_repo "derived_interactive" "git@github.com:acme-org/acme-app.git"

  # Accept both derived defaults, then the default for every other prompt.
  run collect_interactive <<<"$(printf '\n\nJane Doe\n')"
  assert_success
  assert_output_contains "Namespace                        : AcmeOrg"
  assert_output_contains "Project                          : acme-app"
  assert_output_contains './install.sh --author=Jane\ Doe'
  assert_output_not_contains "--namespace="
}

@test "github_default_identity falls back to the token login and the given name" {
  github_setup
  github_owner=""
  github_repo=""

  github_default_identity "fallback"

  assert_equal "${github_owner}" "jane"
  assert_equal "${github_repo}" "fallback"
  assert_equal "${github_owner_default}" "jane"
  assert_equal "${github_repo_default}" "fallback"
}

@test "github_default_identity keeps the resolved owner and repository" {
  github_setup

  github_default_identity "fallback"

  assert_equal "${github_owner}" "acme"
  assert_equal "${github_repo}" "app"

  run cat "${GH_READS}"
  assert_output ""
}

#-------------------------------------------------------------------------------
# Repository state
#-------------------------------------------------------------------------------

@test "github_load_repo reads the repository state" {
  github_setup

  github_load_repo

  assert_equal "$(github_state default_branch)" "main"
  assert_equal "$(github_state has_wiki)" "false"
  assert_equal "$(github_state description)" "Acme app"
  assert_equal "$(github_state missing_key)" ""
}

@test "github_load_repo reports a missing repository" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app --jq *"
  GH_FAIL_OUTPUT="gh: Not Found (HTTP 404)"

  run github_load_repo
  assert_failure
  assert_output "Error: GitHub repository acme/app does not exist, or the token cannot access it."
}

@test "github_load_repo reports any other read failure" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app --jq *"
  GH_FAIL_OUTPUT="gh: Bad credentials (HTTP 401)"

  run github_load_repo
  assert_failure
  assert_output "Error: Could not read GitHub repository acme/app: gh: Bad credentials (HTTP 401)"
}

@test "github_load_repo rejects an invalid owner or repository before any call" {
  github_setup

  github_owner=""
  run github_load_repo
  assert_failure
  assert_output "Error: Invalid GitHub owner: ''. Pass --github-owner."

  github_owner="acme"
  github_repo="../app"
  run github_load_repo
  assert_failure
  assert_output "Error: Invalid GitHub repository: '../app'. Pass --github-repo."

  run cat "${GH_READS}"
  assert_output ""
}

#-------------------------------------------------------------------------------
# General settings
#-------------------------------------------------------------------------------

@test "github_apply_settings leaves applied settings unchanged" {
  github_setup
  github_load_repo

  run github_apply_settings
  assert_success
  assert_output "  General settings: unchanged"
  assert_no_writes
}

@test "github_apply_settings patches only the settings that differ" {
  github_setup
  GH_STATE="$(state_new)"
  github_load_repo

  run github_apply_settings
  assert_success
  assert_output "  General settings: updated allow_merge_commit squash_merge_commit_title squash_merge_commit_message allow_auto_merge allow_update_branch delete_branch_on_merge has_wiki has_projects"

  run cat "${GH_WRITES}"
  assert_output "gh api --method PATCH repos/acme/app --silent -F allow_merge_commit=false -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=BLANK -F allow_auto_merge=true -F allow_update_branch=true -F delete_branch_on_merge=true -F has_wiki=false -F has_projects=false"
}

@test "github_apply_settings sends a description only when one is given" {
  github_setup
  github_load_repo
  github_description="New description"

  run github_apply_settings
  assert_success
  assert_output "  General settings: updated description"

  run cat "${GH_WRITES}"
  assert_output "gh api --method PATCH repos/acme/app --silent -f description=New description"
}

@test "github_apply_settings applies the --github-merge methods" {
  github_setup
  github_load_repo
  github_merge="merge"

  run github_apply_settings
  assert_success
  assert_output "  General settings: updated allow_merge_commit allow_squash_merge allow_rebase_merge"

  run cat "${GH_WRITES}"
  assert_output "gh api --method PATCH repos/acme/app --silent -F allow_merge_commit=true -F allow_squash_merge=false -F allow_rebase_merge=false"
}

@test "github_apply_settings skips on a 403 and names the permission" {
  github_setup
  GH_STATE="$(state_new)"
  github_load_repo
  GH_FAIL_MATCH="api --method PATCH *"
  GH_FAIL_OUTPUT="gh: Resource not accessible by personal access token (HTTP 403)"

  run github_apply_settings
  assert_status 2
  assert_output "  General settings: skipped (token lacks Administration: write)"
}

@test "github_apply_settings reports any other failure" {
  github_setup
  GH_STATE="$(state_new)"
  github_load_repo
  GH_FAIL_MATCH="api --method PATCH *"
  GH_FAIL_OUTPUT="gh: Validation Failed (HTTP 422)"

  run github_apply_settings
  assert_status 1
  assert_output "  General settings: failed (gh: Validation Failed (HTTP 422))"
}

@test "github_apply_settings prints the call under --dry-run" {
  github_setup
  github_load_repo
  github_description="Acme app, renamed"
  dry_run=1

  run github_apply_settings
  assert_success
  assert_output '  [dry-run] gh api --method PATCH repos/acme/app --silent -f description=Acme\ app\,\ renamed
  General settings: would update description'
  assert_no_writes
}

#-------------------------------------------------------------------------------
# Labels
#-------------------------------------------------------------------------------

@test "github_apply_labels leaves applied labels unchanged" {
  github_setup

  run github_apply_labels
  assert_success
  assert_output "  Labels: 0 created, 0 updated, 12 unchanged"
  assert_no_writes
}

@test "github_apply_labels creates every label in a repository without them" {
  github_setup
  GH_LABELS=""

  run github_apply_labels
  assert_success
  assert_output "  Labels: 12 created, 0 updated, 0 unchanged"

  run cat "${GH_WRITES}"
  assert_equal "${lines[0]}" "gh label create AUTOMERGE --repo acme/app --color 934BF4 --description Pull request has been approved and set to automerge --force"
  assert_equal "${lines[3]}" "gh label create Dependencies --repo acme/app --color 62E795 --description Pull request was raised automatically by a dependency bot --force"
  assert_equal "${lines[11]}" "gh label create URGENT --repo acme/app --color D93F0B --description Pull request needs to be urgently reviewed --force"
  assert_equal "${#lines[@]}" "12"
}

@test "github_apply_labels updates labels that differ and matches names case-insensitively" {
  github_setup
  GH_LABELS="$(labels_applied)"
  GH_LABELS="${GH_LABELS/AUTOMERGE$'\t'934bf4/automerge$'\t'ffffff}"
  GH_LABELS="${GH_LABELS/Pull request needs to be urgently reviewed/Old description}"

  run github_apply_labels
  assert_success
  assert_output "  Labels: 0 created, 2 updated, 10 unchanged"

  run cat "${GH_WRITES}"
  assert_output "gh label create AUTOMERGE --repo acme/app --color 934BF4 --description Pull request has been approved and set to automerge --force
gh label create URGENT --repo acme/app --color D93F0B --description Pull request needs to be urgently reviewed --force"
}

@test "github_apply_labels keeps other labels without pruning" {
  github_setup
  GH_LABELS="$(labels_applied)"$'\n'"bug"$'\t'"d73a4a"$'\t'"Something isn't working"

  run github_apply_labels
  assert_success
  assert_output "  Labels: 0 created, 0 updated, 12 unchanged"
  assert_no_writes
}

@test "github_apply_labels deletes other labels when pruning" {
  github_setup
  github_labels_prune="y"
  GH_LABELS="$(labels_applied)"$'\n'"bug"$'\t'"d73a4a"$'\t'"Something isn't working"$'\n'"good first issue"$'\t'"7057ff"$'\t'

  run github_apply_labels
  assert_success
  assert_output "  Labels: 0 created, 0 updated, 12 unchanged, 2 deleted"

  run cat "${GH_WRITES}"
  assert_output "gh label delete bug --repo acme/app --yes
gh label delete good first issue --repo acme/app --yes"
}

@test "github_apply_labels prints the calls under --dry-run" {
  github_setup
  github_labels_prune="y"
  dry_run=1
  GH_LABELS="$(labels_applied | sed '/^URGENT/d')"$'\n'"bug"$'\t'"d73a4a"$'\t'

  run github_apply_labels
  assert_success
  assert_output '  [dry-run] gh label create URGENT --repo acme/app --color D93F0B --description Pull\ request\ needs\ to\ be\ urgently\ reviewed --force
  [dry-run] gh label delete bug --repo acme/app --yes
  Labels: 1 to create, 0 to update, 11 unchanged, 1 to delete'
  assert_no_writes
}

@test "github_apply_labels skips on a 403" {
  github_setup
  GH_LABELS=""
  GH_FAIL_MATCH="label create *"
  GH_FAIL_OUTPUT="HTTP 403: Resource not accessible by personal access token"

  run github_apply_labels
  assert_status 2
  assert_output "  Labels: skipped (token lacks Issues: write)"
}

@test "github_apply_labels reports a failure to list the labels" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app/labels *"
  GH_FAIL_OUTPUT="gh: Server Error (HTTP 500)"

  run github_apply_labels
  assert_status 1
  assert_output "  Labels: failed (gh: Server Error (HTTP 500))"
  assert_no_writes
}

#-------------------------------------------------------------------------------
# Ruleset
#-------------------------------------------------------------------------------

ruleset_body() {
  cat <<JSON
{
  "name": "default-branch",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
  "rules": [{"type": "deletion"}, {"type": "non_fast_forward"}${1:+, ${1}}],
  "bypass_actors": [{"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always"}]
}
JSON
}

@test "github_apply_ruleset creates the ruleset when it is missing" {
  github_setup

  run github_apply_ruleset
  assert_success
  assert_output "  Ruleset: created default-branch"

  run cat "${GH_WRITES}"
  assert_output "gh api --method POST repos/acme/app/rulesets --silent --input -
$(ruleset_body)"

  run cat "${GH_READS}"
  assert_output 'gh api repos/acme/app/rulesets --paginate --jq .[] | select(.name == "default-branch" and .source_type == "Repository") | .id'
}

@test "github_apply_ruleset updates the ruleset and keeps its required checks" {
  github_setup
  GH_RULESET_ID="42"
  GH_RULESET_CHECKS='{"type":"required_status_checks","parameters":{"required_status_checks":[{"context":"test"}],"strict_required_status_checks_policy":false}}'

  run github_apply_ruleset
  assert_success
  assert_output "  Ruleset: updated default-branch"

  run cat "${GH_WRITES}"
  assert_output "gh api --method PUT repos/acme/app/rulesets/42 --silent --input -
$(ruleset_body "${GH_RULESET_CHECKS}")"
}

@test "github_apply_ruleset updates a ruleset without required checks" {
  github_setup
  GH_RULESET_ID="42"

  run github_apply_ruleset
  assert_success

  run cat "${GH_WRITES}"
  assert_output "gh api --method PUT repos/acme/app/rulesets/42 --silent --input -
$(ruleset_body)"
}

@test "github_apply_ruleset prints the call and the body under --dry-run" {
  github_setup
  dry_run=1

  run github_apply_ruleset
  assert_success
  assert_output_contains "  [dry-run] gh api --method POST repos/acme/app/rulesets --silent --input -"
  assert_output_contains '    "name": "default-branch",'
  assert_output_contains "  Ruleset: would create default-branch"
  assert_no_writes
}

@test "github_apply_ruleset skips a private repository without GitHub Pro" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app/rulesets *"
  GH_FAIL_OUTPUT="gh: Upgrade to GitHub Pro or make this repository public to enable this feature. (HTTP 403)"

  run github_apply_ruleset
  assert_status 2
  assert_output "  Ruleset: skipped (needs GitHub Pro or a public repository)"
  assert_no_writes
}

@test "github_apply_ruleset skips on a 403 when writing" {
  github_setup
  GH_FAIL_MATCH="api --method POST *"
  GH_FAIL_OUTPUT="gh: Resource not accessible by personal access token (HTTP 403)"

  run github_apply_ruleset
  assert_status 2
  assert_output "  Ruleset: skipped (token lacks Administration: write)"
}

@test "github_apply_ruleset reports a failure to read the existing ruleset" {
  github_setup
  GH_RULESET_ID="42"
  GH_FAIL_MATCH="api repos/acme/app/rulesets/42 *"
  GH_FAIL_OUTPUT="gh: Server Error (HTTP 500)"

  run github_apply_ruleset
  assert_status 1
  assert_output "  Ruleset: failed (gh: Server Error (HTTP 500))"
  assert_no_writes
}

#-------------------------------------------------------------------------------
# Sections together
#-------------------------------------------------------------------------------

@test "configure_github runs every selected section" {
  github_setup
  GH_STATE="$(state_new)"
  GH_LABELS=""

  run configure_github
  assert_success
  assert_output_contains "Configuring GitHub repository acme/app"
  assert_output_contains "  General settings: updated"
  assert_output_contains "  Labels: 12 created, 0 updated, 0 unchanged"
  assert_output_contains "  Ruleset: created default-branch"
  assert_output_contains "GitHub repository settings complete."
}

@test "configure_github runs only the selected sections" {
  github_setup
  GH_STATE="$(state_new)"
  github_settings="n"
  github_labels="n"

  run configure_github
  assert_success
  assert_output_not_contains "General settings"
  assert_output_not_contains "Labels"
  assert_output_contains "  Ruleset: created default-branch"
}

@test "configure_github keeps going after a skipped section and succeeds" {
  github_setup
  GH_STATE="$(state_new)"
  GH_FAIL_MATCH="api --method PATCH *"
  GH_FAIL_OUTPUT="gh: Resource not accessible by personal access token (HTTP 403)"

  run configure_github
  assert_success
  assert_output_contains "  General settings: skipped (token lacks Administration: write)"
  assert_output_contains "  Labels: 0 created, 0 updated, 12 unchanged"
  assert_output_contains "  Ruleset: created default-branch"
}

@test "configure_github keeps going after a failed section and fails" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app/labels *"
  GH_FAIL_OUTPUT="gh: Server Error (HTTP 500)"

  run configure_github
  assert_failure
  assert_output_contains "  Labels: failed (gh: Server Error (HTTP 500))"
  assert_output_contains "  Ruleset: created default-branch"
  assert_output_contains "GitHub repository settings finished with errors."
}

@test "configure_github fails when the repository does not exist" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app --jq *"
  GH_FAIL_OUTPUT="gh: Not Found (HTTP 404)"

  run configure_github
  assert_failure
  assert_output_contains "does not exist"
  assert_no_writes
}

@test "configure_github announces a dry run and writes nothing" {
  github_setup
  GH_STATE="$(state_new)"
  GH_LABELS=""
  dry_run=1

  run configure_github
  assert_success
  assert_output_contains "  Dry run: nothing is changed."
  assert_output_contains "  General settings: would update"
  assert_output_contains "  Labels: 12 to create, 0 to update, 0 unchanged"
  assert_output_contains "  Ruleset: would create default-branch"
  assert_no_writes
}

#-------------------------------------------------------------------------------
# Entry points
#-------------------------------------------------------------------------------

@test "main runs the github command without the template" {
  github_setup
  mkdir -p "${BATS_TEST_TMPDIR}/existing"
  cd "${BATS_TEST_TMPDIR}/existing" || return 1
  touch "${BATS_TEST_TMPDIR}/existing/kept.txt"

  run main github --github-owner=acme --github-repo=app
  assert_success
  assert_output_contains "Configuring GitHub repository acme/app"
  assert_output_contains "GitHub repository settings complete."
  assert_output_not_contains "Downloading Scaffold"

  run ls -A "${BATS_TEST_TMPDIR}/existing"
  assert_output "kept.txt"
}

@test "github_main falls back to the token login and the directory name" {
  github_setup
  mkdir -p "${BATS_TEST_TMPDIR}/app"
  cd "${BATS_TEST_TMPDIR}/app" || return 1
  github_owner=""
  github_repo=""
  GH_LOGIN="acme"
  interactive=0

  run github_main
  assert_success
  assert_output_contains "Configuring GitHub repository acme/app"
}

@test "github_main takes the repository from origin" {
  github_setup
  enter_repo "app_clone" "git@github.com:acme/app.git"
  github_owner=""
  github_repo=""
  GH_LOGIN="someone-else"
  interactive=0

  run github_main
  assert_success
  assert_output_contains "Configuring GitHub repository acme/app"
}

@test "github_main applies the section options" {
  github_setup
  GH_STATE="$(state_new)"
  interactive=0
  github_settings=""
  github_labels=""
  github_ruleset=""
  parse_args --no-github-settings --no-github-ruleset --github-labels-prune
  github_apply_defaults

  run github_main
  assert_success
  assert_output_not_contains "General settings"
  assert_output_contains "  Labels: 0 created, 0 updated, 12 unchanged, 0 deleted"
  assert_output_not_contains "Ruleset"
}

@test "github_main exits 1 when a section fails" {
  github_setup
  interactive=0
  GH_FAIL_MATCH="api --method POST *"
  GH_FAIL_OUTPUT="gh: Validation Failed (HTTP 422)"

  run github_main
  assert_failure
  assert_output_contains "  Ruleset: failed (gh: Validation Failed (HTTP 422))"
}

@test "github_main prompts for the repository and the sections" {
  github_setup
  GH_STATE="$(state_new)"
  GH_LABELS=""
  interactive=1

  # Owner, repository, general settings, description, labels, prune, ruleset.
  run github_main <<<"$(printf 'acme\napp\ny\nNew description\ny\nn\nn\n')"
  assert_success
  assert_output_contains "  General settings: updated"
  assert_output_contains "  Labels: 12 created, 0 updated, 0 unchanged"
  assert_output_not_contains "Ruleset"
  assert_file_contains "${GH_WRITES}" "-f description=New description"
}

@test "github_collect_interactive keeps the current description on empty input" {
  github_setup
  interactive=1

  # Owner, repository, general settings, description, labels, ruleset.
  github_collect_interactive <<<"$(printf '\n\ny\n\nn\nn\n')"

  assert_equal "${github_owner}" "acme"
  assert_equal "${github_repo}" "app"
  assert_equal "${github_settings}" "y"
  assert_equal "${github_description}" "Acme app"
  assert_equal "${github_labels}" "n"
  assert_equal "${github_labels_prune}" "n"
  assert_equal "${github_ruleset}" "n"
}

@test "github_collect_interactive skips the section prompts when the repository is missing" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app --jq *"
  GH_FAIL_OUTPUT="gh: Not Found (HTTP 404)"

  run github_collect_interactive <<<"$(printf 'acme\napp\n')"
  assert_failure
  assert_output_contains "does not exist"
}

@test "collect_github_interactive configures the repository on request" {
  github_setup
  project="app"
  github_owner=""
  github_repo=""
  GH_LOGIN="acme"

  # Configure, owner, repository, settings, description, labels, prune, ruleset.
  collect_github_interactive <<<"$(printf 'y\n\n\ny\n\ny\ny\ny\n')"

  assert_equal "${use_github}" "y"
  assert_equal "${github_owner}" "acme"
  assert_equal "${github_repo}" "app"
  assert_equal "${github_labels_prune}" "y"
  assert_equal "${github_merge}" "squash,rebase"
}

@test "collect_github_interactive is off by default" {
  github_setup

  collect_github_interactive <<<"$(printf '\n')"

  assert_equal "${use_github}" "n"
  run cat "${GH_READS}"
  assert_output ""
}

@test "collect_github_interactive turns off GitHub when the repository is missing" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app --jq *"
  GH_FAIL_OUTPUT="gh: Not Found (HTTP 404)"

  collect_github_interactive <<<"$(printf 'y\nacme\napp\n')" 2>/dev/null

  assert_equal "${use_github}" "n"
}

@test "collect_noninteractive with --github prints the GitHub summary" {
  github_setup
  enter_repo "summary"
  github_owner=""
  github_repo=""
  github_settings=""
  github_labels=""
  github_labels_prune=""
  github_ruleset=""
  GH_LOGIN="acme"
  parse_args --namespace=AcmeApp --name=app --author="Jane Doe" --github --no-github-labels

  run collect_noninteractive
  assert_success
  assert_output_contains "Configure GitHub repository      : y"
  assert_output_contains "  Repository                     : acme/app"
  assert_output_contains "  General settings               : y"
  assert_output_contains "  Labels                         : n"
  assert_output_contains "  Default branch ruleset         : y"
}

@test "collect_noninteractive keeps GitHub off by default" {
  enter_repo "summary_off"
  parse_args --namespace=AcmeApp --name=app --author="Jane Doe"

  run collect_noninteractive
  assert_success
  assert_output_contains "Configure GitHub repository      : n"
  assert_output_not_contains "Default branch ruleset"
}

#-------------------------------------------------------------------------------
# Options
#-------------------------------------------------------------------------------

@test "parse_args sets the GitHub options" {
  parse_args --github --github-owner=acme --github-repo=app --no-github-settings --github-description="Acme app" --github-merge=merge,squash --no-github-labels --github-labels-prune --no-github-ruleset --dry-run

  assert_equal "${use_github}" "y"
  assert_equal "${github_owner}" "acme"
  assert_equal "${github_repo}" "app"
  assert_equal "${github_settings}" "n"
  assert_equal "${github_description}" "Acme app"
  assert_equal "${github_merge}" "merge,squash"
  assert_equal "${github_labels}" "n"
  assert_equal "${github_labels_prune}" "y"
  assert_equal "${github_ruleset}" "n"
  assert_equal "${dry_run}" "1"
  assert_equal "${interactive}" "0"
}

@test "parse_args sets the negated and positive GitHub toggles" {
  parse_args --no-github --github-settings --github-labels --no-github-labels-prune --github-ruleset

  assert_equal "${use_github}" "n"
  assert_equal "${github_settings}" "y"
  assert_equal "${github_labels}" "y"
  assert_equal "${github_labels_prune}" "n"
  assert_equal "${github_ruleset}" "y"
}

@test "parse_args fails on an invalid --github-merge value" {
  run parse_args --github-merge=squash,fast-forward
  assert_failure
  assert_output_contains "Error: Invalid merge method for --github-merge: fast-forward. Allowed values: merge, squash, rebase."
  assert_output_contains "Run with --help for usage."

  run parse_args --github-merge=
  assert_failure
  assert_output_contains "Error: --github-merge needs at least 1 of: merge, squash, rebase."
}

@test "usage documents the github command, its options and the token" {
  run usage
  assert_output_contains "./install.sh github [OPTIONS]"
  assert_output_contains "SCAFFOLD_GITHUB_TOKEN"
  assert_output_contains "--dry-run"
}

@test "every prompt has an option in parse_args and a line in usage" {
  local parse_args_body
  local usage_text
  local prompts
  parse_args_body="$(declare -f parse_args)"
  usage_text="$(usage)"

  # Variables assigned from ask, ask_optional, ask_yesno or ask_choice. The
  # final confirmation is skipped by any option, so it has none of its own.
  prompts="$(grep -oE '[a-z_]+="?\$\(ask(_optional|_yesno|_choice)? ' install.sh | sed -E 's/="?\$\(.*//' | sort -u | grep -vx 'should_proceed')"

  [ -n "${prompts}" ]

  local variable
  local options
  local option

  while IFS= read -r variable; do
    # Case patterns whose branch assigns the variable.
    options="$(echo "${parse_args_body}" | awk -v var="${variable}" '
      /^ *[-a-z|= *]+\)$/ { pattern = $0; sub(/^ */, "", pattern); sub(/\)$/, "", pattern) }
      $0 ~ "(^|[^a-z_])" var "=" && pattern != "" { print pattern }
      /;;/ { pattern = "" }
    ')"

    if [ -z "${options}" ]; then
      echo "Prompt variable '${variable}' has no option in parse_args." >&3
      return 1
    fi

    while IFS= read -r option; do
      option="${option%%=*}"
      option="${option%% |*}"
      if [[ ${usage_text} != *"${option}"* ]]; then
        echo "Option '${option}' for '${variable}' is missing from usage." >&3
        return 1
      fi
    done <<<"${options}"
  done <<<"${prompts}"
}

#-------------------------------------------------------------------------------
# Reproduce command
#-------------------------------------------------------------------------------

# Answers equal to every interactive default.
default_answers() {
  namespace="AcmeApp"
  project="acme-app"
  author="Jane Doe"
  use_php="y"
  use_php_command="y"
  php_command_name="acme-app"
  use_php_command_build="y"
  use_php_script="n"
  use_nodejs="y"
  use_shell="y"
  shell_command_name="acme-app"
  use_docker="n"
  use_release_drafter="y"
  use_pr_autoassign="y"
  use_funding="y"
  use_pr_template="y"
  use_renovate="y"
  use_docs="y"
  use_test_actions="n"
  use_schedule="y"
  use_ai="y"
  use_ai_arch_docs="mermaid"
  remove_self="y"
  use_github="n"
}

@test "print_reproduce_command lists only the answers that differ from the defaults" {
  default_answers
  run print_reproduce_command
  assert_equal "${lines[1]}" '  ./install.sh --namespace=AcmeApp --name=acme-app --author=Jane\ Doe'

  default_answers
  use_php_command_build="n"
  php_command_name="acme"
  use_nodejs="n"
  shell_command_name="acme-sh"
  use_docker="y"
  docker_image_name="acmeapp/acme-app"
  use_release_drafter="n"
  use_pr_autoassign="n"
  use_funding="n"
  use_pr_template="n"
  use_renovate="n"
  use_docs="n"
  use_test_actions="y"
  use_schedule="n"
  use_ai_arch_docs="plantuml"
  remove_self="n"
  run print_reproduce_command
  assert_equal "${lines[1]}" '  ./install.sh --namespace=AcmeApp --name=acme-app --author=Jane\ Doe --php-command-name=acme --no-phar --no-nodejs --shell-command-name=acme-sh --docker --no-release-drafter --no-pr-autoassign --no-funding --no-pr-template --no-renovate --no-docs --test-actions --no-schedule --ai-arch-docs=plantuml --keep'
}

@test "print_reproduce_command covers the PHP modes, Docker image and AI options" {
  # Overrides, expected options after the identity.
  local cases=(
    "use_php=n" " --no-php"
    "use_php_command=n use_php_script=y php_script_name=acme-app" " --no-php-command"
    "use_php_command=n use_php_script=y php_script_name=tool" " --no-php-command --php-script-name=tool"
    "use_php_command=n use_php_script=n" " --no-php-command --no-php-script"
    "use_shell=n" " --no-shell"
    "use_docker=y docker_image_name=acme/app" " --docker-image-name=acme/app"
    "use_ai=n" " --no-ai"
    "use_ai_arch_docs=none" " --ai-arch-docs=none"
  )
  local i
  local assignment

  for ((i = 0; i < ${#cases[@]}; i += 2)); do
    default_answers
    for assignment in ${cases[i]}; do
      printf -v "${assignment%%=*}" '%s' "${assignment#*=}"
    done

    run print_reproduce_command
    assert_equal "${lines[1]}" "  ./install.sh --namespace=AcmeApp --name=acme-app --author=Jane\\ Doe${cases[i + 1]}"
  done
}

@test "print_reproduce_command leaves out derived values and the token" {
  github_setup
  default_answers
  namespace_source="the 'origin' remote"
  project_source="the 'origin' remote"
  use_github="y"
  github_owner_default="acme"
  github_repo_default="app"
  github_load_repo

  run print_reproduce_command
  assert_equal "${lines[1]}" '  ./install.sh --author=Jane\ Doe --github'
  assert_output_not_contains "test-token"
}

@test "print_reproduce_command lists the GitHub answers that differ" {
  github_setup
  default_answers
  use_github="y"
  github_owner="other"
  github_repo="repo"
  github_owner_default="acme"
  github_repo_default="app"
  github_settings="n"
  github_description="New description"
  github_labels="n"
  github_labels_prune="y"
  github_ruleset="n"

  run print_reproduce_command
  assert_equal "${lines[1]}" '  ./install.sh --namespace=AcmeApp --name=acme-app --author=Jane\ Doe --github --github-owner=other --github-repo=repo --no-github-settings --github-description=New\ description --no-github-labels --github-labels-prune --no-github-ruleset'
}
