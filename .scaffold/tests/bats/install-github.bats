#!/usr/bin/env bats
#
# Unit tests for the GitHub repository configuration in install.sh.
#
# 'gh' and 'has_command' are replaced with functions. Calls that pass '--jq',
# and 'api' calls without '--method', are reads and land in GH_READS; every
# other call is a write and lands in GH_WRITES together with any request body,
# so the tests assert the exact writes of each section. 'git push' is replaced
# too and logs to GH_WRITES; every other git command runs for real.
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

  local body=""

  if [[ " $* " == *" --jq "* ]] || { [ "${1:-}" = "api" ] && [[ " $* " != *" --method "* ]]; }; then
    echo "gh $*" >>"${GH_READS}"
  else
    echo "gh $*" >>"${GH_WRITES}"

    if [[ " $* " == *" --input - "* ]]; then
      body="$(cat)"
      echo "${body}" >>"${GH_WRITES}"
    fi
  fi

  # shellcheck disable=SC2053
  if [ -n "${GH_FAIL_MATCH-}" ] && [[ $* == ${GH_FAIL_MATCH} ]]; then
    echo "${GH_FAIL_OUTPUT}" >&2
    return 1
  fi

  local count

  case "$*" in
    "api user --jq .login") echo "${GH_LOGIN}" ;;
    "api repos/acme/app --jq "*security_and_analysis*) echo "${GH_SECRET_SCANNING}" ;;
    "api repos/acme/app --jq "*)
      if [ "${GH_MISSING}" = "1" ] && [ ! -f "${GH_CREATED}" ]; then
        echo "gh: Not Found (HTTP 404)" >&2
        return 1
      fi
      echo "${GH_STATE}"
      ;;
    "repo create "*)
      touch "${GH_CREATED}"
      echo "https://github.com/acme/app"
      ;;
    "api repos/acme/app/labels "*) printf '%s' "${GH_LABELS}" ;;
    "api repos/acme/app/immutable-releases --jq "*)
      count="$(grep -c "^gh api --method PUT repos/acme/app/immutable-releases " "${GH_WRITES}")"
      if [ "${count}" -gt 0 ] && [ "${GH_IMMUTABLE_REREAD_FAIL}" = "1" ]; then
        echo "gh: Server Error (HTTP 500)" >&2
        return 1
      fi
      if [ "${count}" -gt "${GH_IMMUTABLE_IGNORED_PUTS}" ]; then echo "true false"; else echo "${GH_IMMUTABLE}"; fi
      ;;
    "api repos/acme/app/vulnerability-alerts")
      if [ "${GH_DEPENDABOT}" != "1" ]; then
        echo "gh: Not Found (HTTP 404)" >&2
        return 1
      fi
      ;;
    "api repos/acme/app/private-vulnerability-reporting --jq "*) echo "${GH_VULN_REPORTING}" ;;
    "api repos/acme/app/actions/permissions/workflow --jq "*) echo "${GH_WORKFLOW_PERMISSIONS}" ;;
    "api repos/acme/app/rulesets --paginate "*'"tags"'*)
      if [ -f "${GH_TAG_RULESET_CREATED}" ]; then echo "9"; else echo "${GH_TAG_RULESET_ID}"; fi
      ;;
    "api repos/acme/app/rulesets --paginate "*)
      if [ -f "${GH_RULESET_CREATED}" ]; then echo "7"; else echo "${GH_RULESET_ID}"; fi
      ;;
    "api --method POST repos/acme/app/rulesets "*)
      if [[ ${body} == *'"target": "tag"'* ]]; then touch "${GH_TAG_RULESET_CREATED}"; else touch "${GH_RULESET_CREATED}"; fi
      ;;
    "api repos/acme/app/rulesets/"*" --jq "*) echo "${GH_RULESET_KEPT}" ;;
    "api repos/acme/app/commits/"*"/check-runs "*) printf '%s' "${GH_CHECK_RUNS}" ;;
    "api repos/acme/app/actions/runs?check_suite_id="*)
      grep "^${2#*check_suite_id=} " <<<"${GH_SUITE_PATHS}" | cut -d ' ' -f 2
      ;;
    "api -H Accept: application/vnd.github.raw repos/acme/app/contents/"*)
      local path="${4#repos/acme/app/contents/}"
      cat "${GH_WORKFLOWS}/$(basename "${path%%\?*}")" 2>/dev/null || return 1
      ;;
    "run list "*)
      count="$(cat "${GH_RUN_LIST_COUNT}" 2>/dev/null || echo 0)"
      echo "$((count + 1))" >"${GH_RUN_LIST_COUNT}"
      if [ "$((count + 1))" = "${GH_RUN_LIST_FAIL_AT:-0}" ]; then
        echo "gh: Server Error (HTTP 500)" >&2
        return 1
      fi
      [ "${count}" -lt "${#GH_RUN_LISTS[@]}" ] || count=$((${#GH_RUN_LISTS[@]} - 1))
      [ "${count}" -lt 0 ] || printf '%s' "${GH_RUN_LISTS[count]}"
      ;;
  esac
}

git() {
  if [[ " $* " != *" push "* ]]; then
    command git "$@"
    return
  fi

  echo "git push ${*: -2} [token=${SCAFFOLD_GITHUB_TOKEN-} prompt=${GIT_TERMINAL_PROMPT-}]" >>"${GH_WRITES}"
  return "${GIT_PUSH_STATUS:-0}"
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
  GH_IMMUTABLE="true false"
  GH_IMMUTABLE_IGNORED_PUTS=0
  GH_IMMUTABLE_REREAD_FAIL=0
  GH_SECRET_SCANNING="enabled enabled"
  GH_DEPENDABOT=1
  GH_VULN_REPORTING="true"
  GH_WORKFLOW_PERMISSIONS="read"
  GH_TAG_RULESET_ID=""
  GH_TAG_RULESET_CREATED="${BATS_TEST_TMPDIR}/gh.tag-ruleset-created"
  GH_RULESET_ID=""
  GH_RULESET_KEPT=""
  GH_FAIL_MATCH=""
  GH_FAIL_OUTPUT=""
  GH_MISSING=0
  GH_CREATED="${BATS_TEST_TMPDIR}/gh.created"
  GH_RULESET_CREATED="${BATS_TEST_TMPDIR}/gh.ruleset-created"
  GH_CHECK_RUNS=""
  GH_SUITE_PATHS=""
  GH_WORKFLOWS="${BATS_TEST_TMPDIR}/workflows"
  GH_RUN_LISTS=()
  GH_RUN_LIST_COUNT="${BATS_TEST_TMPDIR}/gh.run-list-count"
  GIT_PUSH_STATUS=0
  rm -f "${GH_CREATED}" "${GH_RULESET_CREATED}" "${GH_TAG_RULESET_CREATED}" "${GH_RUN_LIST_COUNT}"
  mkdir -p "${GH_WORKFLOWS}"

  # The tests run in the template, which ships both release workflows.
  GITHUB_POST_PUBLISH_WORKFLOW="${BATS_TEST_TMPDIR}/release-php.yml"
  GITHUB_PUBLISH_WORKFLOW="${BATS_TEST_TMPDIR}/release-nodejs.yml"

  # Commits need an identity, and the developer's own git config stays out.
  export GIT_CONFIG_GLOBAL="${BATS_TEST_TMPDIR}/gitconfig"
  export GIT_CONFIG_NOSYSTEM=1
  command git config --global user.email "jane@example.com"
  command git config --global user.name "Jane Doe"

  github_poll_interval=0
  github_runs_timeout=0

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
Install GitHub CLI (https://cli.github.com), then run 'curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github'."
    "y" "n" "1" "Skipping GitHub repository settings: SCAFFOLD_GITHUB_TOKEN is not set.
Set SCAFFOLD_GITHUB_TOKEN, then run 'curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github'."
    "n" "n" "1" "Skipping GitHub repository settings: 'gh' is not installed; SCAFFOLD_GITHUB_TOKEN is not set.
Install GitHub CLI (https://cli.github.com) and set SCAFFOLD_GITHUB_TOKEN, then run 'curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github'."
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
    assert_output_contains "then run 'curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github'."

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

@test "github_load_repo returns 3 and records a missing repository" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app --jq *"
  GH_FAIL_OUTPUT="gh: Not Found (HTTP 404)"

  local rc=0
  github_load_repo >"${BATS_TEST_TMPDIR}/out" 2>&1 || rc=$?

  assert_equal "${rc}" "3"
  assert_equal "${github_repo_exists}" "n"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/out" "Error"

  run github_missing_error
  assert_output "Error: GitHub repository acme/app does not exist, or the token cannot access it. Pass --github-create to create it."
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
  assert_output "  Labels: 0 created, 0 updated, 12 unchanged, 0 deleted"
  assert_no_writes
}

@test "github_apply_labels creates every label in a repository without them" {
  github_setup
  GH_LABELS=""

  run github_apply_labels
  assert_success
  assert_output "  Labels: 12 created, 0 updated, 0 unchanged, 0 deleted"

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
  assert_output "  Labels: 0 created, 2 updated, 10 unchanged, 0 deleted"

  run cat "${GH_WRITES}"
  assert_output "gh label create AUTOMERGE --repo acme/app --color 934BF4 --description Pull request has been approved and set to automerge --force
gh label create URGENT --repo acme/app --color D93F0B --description Pull request needs to be urgently reviewed --force"
}

@test "github_apply_labels keeps other labels without pruning" {
  github_setup
  github_labels_prune="n"
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
# Immutable releases
#-------------------------------------------------------------------------------

@test "github_apply_immutable_releases leaves enabled releases unchanged" {
  github_setup

  run github_apply_immutable_releases
  assert_success
  assert_output "  Immutable releases: unchanged"
  assert_no_writes

  run cat "${GH_READS}"
  assert_output 'gh api repos/acme/app/immutable-releases --jq "\(.enabled) \(.enforced_by_owner)"'
}

@test "github_apply_immutable_releases leaves releases the owner enforces unchanged" {
  github_setup
  GH_IMMUTABLE="false true"

  run github_apply_immutable_releases
  assert_success
  assert_output "  Immutable releases: unchanged (enforced by the owner)"
  assert_no_writes
}

@test "github_apply_immutable_releases enables releases and reads them back" {
  github_setup
  GH_IMMUTABLE="false false"

  run github_apply_immutable_releases
  assert_success
  assert_output "  Immutable releases: enabled"

  run cat "${GH_WRITES}"
  assert_output "gh api --method PUT repos/acme/app/immutable-releases --silent"

  run grep -c "immutable-releases" "${GH_READS}"
  assert_output "2"
}

@test "github_apply_immutable_releases writes once more when the first write did not take" {
  github_setup
  GH_IMMUTABLE="false false"
  GH_IMMUTABLE_IGNORED_PUTS=1

  run github_apply_immutable_releases
  assert_success
  assert_output "  Immutable releases: enabled"

  run cat "${GH_WRITES}"
  assert_output "gh api --method PUT repos/acme/app/immutable-releases --silent
gh api --method PUT repos/acme/app/immutable-releases --silent"
}

@test "github_apply_immutable_releases fails when 2 writes do not take" {
  github_setup
  GH_IMMUTABLE="false false"
  GH_IMMUTABLE_IGNORED_PUTS=2

  run github_apply_immutable_releases
  assert_status 1
  assert_output "  Immutable releases: failed (still disabled after 2 attempts)"

  run grep -c "immutable-releases" "${GH_WRITES}"
  assert_output "2"
}

@test "github_apply_immutable_releases skips on a 403 and names the permission" {
  github_setup

  GH_FAIL_MATCH="api repos/acme/app/immutable-releases *"
  GH_FAIL_OUTPUT="gh: Resource not accessible by personal access token (HTTP 403)"
  run github_apply_immutable_releases
  assert_status 2
  assert_output "  Immutable releases: skipped (token lacks Administration: read)"
  assert_no_writes

  GH_IMMUTABLE="false false"
  GH_FAIL_MATCH="api --method PUT *"
  run github_apply_immutable_releases
  assert_status 2
  assert_output "  Immutable releases: skipped (token lacks Administration: write)"
}

@test "github_apply_immutable_releases reports a failure to read the setting" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app/immutable-releases *"
  GH_FAIL_OUTPUT="gh: Server Error (HTTP 500)"

  run github_apply_immutable_releases
  assert_status 1
  assert_output "  Immutable releases: failed (gh: Server Error (HTTP 500))"
  assert_no_writes
}

@test "github_apply_immutable_releases reports a failure to read the setting back" {
  github_setup
  GH_IMMUTABLE="false false"
  GH_IMMUTABLE_REREAD_FAIL=1

  run github_apply_immutable_releases
  assert_status 1
  assert_output "  Immutable releases: failed (gh: Server Error (HTTP 500))"

  run cat "${GH_WRITES}"
  assert_output "gh api --method PUT repos/acme/app/immutable-releases --silent"
}

@test "github_apply_immutable_releases prints the call under --dry-run" {
  github_setup
  GH_IMMUTABLE="false false"
  dry_run=1

  run github_apply_immutable_releases
  assert_success
  assert_output "  [dry-run] gh api --method PUT repos/acme/app/immutable-releases --silent
  Immutable releases: would enable"
  assert_no_writes

  run grep -c "immutable-releases" "${GH_READS}"
  assert_output "1"
}

@test "github_apply_immutable_releases reads nothing for a repository a dry run would create" {
  github_setup
  github_repo_exists="n"
  dry_run=1

  run github_apply_immutable_releases
  assert_success
  assert_output "  [dry-run] gh api --method PUT repos/acme/app/immutable-releases --silent
  Immutable releases: would enable"

  run cat "${GH_READS}"
  assert_output ""
}

@test "github_apply_immutable_releases skips a project whose release workflow attaches assets after publishing" {
  github_setup
  GH_IMMUTABLE="false false"
  touch "${GITHUB_POST_PUBLISH_WORKFLOW}"

  run github_apply_immutable_releases
  assert_success
  assert_output "  Immutable releases: skipped (release-php.yml attaches assets after the release is published)"
  assert_no_writes

  run cat "${GH_READS}"
  assert_output ""
}

@test "github_apply_immutable_releases enables releases when the Node.js release workflow publishes them" {
  github_setup
  GH_IMMUTABLE="false false"
  touch "${GITHUB_POST_PUBLISH_WORKFLOW}" "${GITHUB_PUBLISH_WORKFLOW}"

  run github_apply_immutable_releases
  assert_success
  assert_output "  Immutable releases: enabled"
}

#-------------------------------------------------------------------------------
# Security settings
#-------------------------------------------------------------------------------

@test "github_apply_secret_scanning leaves enabled scanning unchanged" {
  github_setup

  run github_apply_secret_scanning
  assert_success
  assert_output "  Secret scanning: unchanged"
  assert_no_writes

  run cat "${GH_READS}"
  assert_output 'gh api repos/acme/app --jq "\(.security_and_analysis.secret_scanning.status // "") \(.security_and_analysis.secret_scanning_push_protection.status // "")"'
}

@test "github_apply_secret_scanning enables only the features that are off" {
  # Statuses read, expected report, expected request body.
  local cases=(
    "enabled disabled" "secret_scanning_push_protection" '{"security_and_analysis": {"secret_scanning_push_protection": {"status": "enabled"}}}'
    "disabled enabled" "secret_scanning" '{"security_and_analysis": {"secret_scanning": {"status": "enabled"}}}'
    " " "secret_scanning secret_scanning_push_protection" '{"security_and_analysis": {"secret_scanning": {"status": "enabled"}, "secret_scanning_push_protection": {"status": "enabled"}}}'
  )
  local i

  for ((i = 0; i < ${#cases[@]}; i += 3)); do
    github_setup
    GH_SECRET_SCANNING="${cases[i]}"

    run github_apply_secret_scanning
    assert_success
    assert_output "  Secret scanning: enabled ${cases[i + 1]}"

    run cat "${GH_WRITES}"
    assert_output "gh api --method PATCH repos/acme/app --silent --input -
${cases[i + 2]}"
  done
}

@test "github_apply_secret_scanning and github_apply_vulnerability_reporting skip a private repository" {
  github_setup
  GH_SECRET_SCANNING=" "
  GH_VULN_REPORTING="false"
  github_repo_state="private=true"

  run github_apply_secret_scanning
  assert_success
  assert_output "  Secret scanning: skipped (needs a public repository)"

  run github_apply_vulnerability_reporting
  assert_success
  assert_output "  Private vulnerability reporting: skipped (needs a public repository)"

  assert_no_writes
  run cat "${GH_READS}"
  assert_output ""
}

@test "github_apply_secret_scanning skips on a 403 and reports any other failure" {
  github_setup
  GH_SECRET_SCANNING="disabled disabled"
  GH_FAIL_MATCH="api --method PATCH *"
  GH_FAIL_OUTPUT="gh: Resource not accessible by personal access token (HTTP 403)"

  run github_apply_secret_scanning
  assert_status 2
  assert_output "  Secret scanning: skipped (token lacks Administration: write)"

  GH_FAIL_MATCH="api repos/acme/app --jq *"
  GH_FAIL_OUTPUT="gh: Server Error (HTTP 500)"

  run github_apply_secret_scanning
  assert_status 1
  assert_output "  Secret scanning: failed (gh: Server Error (HTTP 500))"
}

@test "github_apply_secret_scanning prints the call under --dry-run" {
  github_setup
  GH_SECRET_SCANNING="disabled enabled"
  dry_run=1

  run github_apply_secret_scanning
  assert_success
  assert_output '  [dry-run] gh api --method PATCH repos/acme/app --silent --input -
    {"security_and_analysis": {"secret_scanning": {"status": "enabled"}}}
  Secret scanning: would enable secret_scanning'
  assert_no_writes
}

@test "github_apply_dependabot_alerts leaves enabled alerts unchanged" {
  github_setup

  run github_apply_dependabot_alerts
  assert_success
  assert_output "  Dependabot alerts: unchanged"
  assert_no_writes

  run cat "${GH_READS}"
  assert_output "gh api repos/acme/app/vulnerability-alerts"
}

@test "github_apply_dependabot_alerts enables alerts that read as not found" {
  github_setup
  GH_DEPENDABOT=0

  run github_apply_dependabot_alerts
  assert_success
  assert_output "  Dependabot alerts: enabled"

  run cat "${GH_WRITES}"
  assert_output "gh api --method PUT repos/acme/app/vulnerability-alerts --silent"
}

@test "github_apply_dependabot_alerts skips on a 403 and reports any other failure" {
  github_setup
  GH_DEPENDABOT=0
  GH_FAIL_MATCH="api --method PUT *"
  GH_FAIL_OUTPUT="gh: Resource not accessible by personal access token (HTTP 403)"

  run github_apply_dependabot_alerts
  assert_status 2
  assert_output "  Dependabot alerts: skipped (token lacks Administration: write)"

  GH_FAIL_MATCH="api repos/acme/app/vulnerability-alerts"
  GH_FAIL_OUTPUT="gh: Server Error (HTTP 500)"

  run github_apply_dependabot_alerts
  assert_status 1
  assert_output "  Dependabot alerts: failed (gh: Server Error (HTTP 500))"
}

@test "github_apply_vulnerability_reporting leaves enabled reporting unchanged" {
  github_setup

  run github_apply_vulnerability_reporting
  assert_success
  assert_output "  Private vulnerability reporting: unchanged"
  assert_no_writes

  run cat "${GH_READS}"
  assert_output "gh api repos/acme/app/private-vulnerability-reporting --jq .enabled"
}

@test "github_apply_vulnerability_reporting enables reporting" {
  github_setup
  GH_VULN_REPORTING="false"

  run github_apply_vulnerability_reporting
  assert_success
  assert_output "  Private vulnerability reporting: enabled"

  run cat "${GH_WRITES}"
  assert_output "gh api --method PUT repos/acme/app/private-vulnerability-reporting --silent"
}

@test "github_apply_vulnerability_reporting skips on a 403 when reading" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app/private-vulnerability-reporting *"
  GH_FAIL_OUTPUT="gh: Resource not accessible by personal access token (HTTP 403)"

  run github_apply_vulnerability_reporting
  assert_status 2
  assert_output "  Private vulnerability reporting: skipped (token lacks Administration: read)"
  assert_no_writes
}

@test "github_apply_workflow_token leaves a read-only token unchanged" {
  github_setup

  run github_apply_workflow_token
  assert_success
  assert_output "  Workflow token: unchanged"
  assert_no_writes

  run cat "${GH_READS}"
  assert_output "gh api repos/acme/app/actions/permissions/workflow --jq .default_workflow_permissions"
}

@test "github_apply_workflow_token makes a write token read-only" {
  github_setup
  GH_WORKFLOW_PERMISSIONS="write"

  run github_apply_workflow_token
  assert_success
  assert_output "  Workflow token: set to read-only"

  run cat "${GH_WRITES}"
  assert_output "gh api --method PUT repos/acme/app/actions/permissions/workflow --silent -f default_workflow_permissions=read"
}

@test "github_apply_workflow_token skips on a 403 and reports any other failure" {
  github_setup
  GH_WORKFLOW_PERMISSIONS="write"
  GH_FAIL_MATCH="api --method PUT *"
  GH_FAIL_OUTPUT="gh: Resource not accessible by personal access token (HTTP 403)"

  run github_apply_workflow_token
  assert_status 2
  assert_output "  Workflow token: skipped (token lacks Administration: write)"

  GH_FAIL_MATCH="api repos/acme/app/actions/permissions/workflow *"
  GH_FAIL_OUTPUT="gh: Server Error (HTTP 500)"

  run github_apply_workflow_token
  assert_status 1
  assert_output "  Workflow token: failed (gh: Server Error (HTTP 500))"
}

# Expected tag ruleset body, with extra rules ($1) and extra bypass actors ($2).
tag_ruleset_body() {
  cat <<JSON
{
  "name": "tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["~ALL"], "exclude": []}},
  "rules": [{"type": "creation"}, {"type": "update"}, {"type": "deletion"}${1:+, ${1}}],
  "bypass_actors": [{"actor_id": 2, "actor_type": "RepositoryRole", "bypass_mode": "always"}, {"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always"}${2:+, ${2}}]
}
JSON
}

@test "github_apply_tag_ruleset creates the tag ruleset when it is missing" {
  github_setup

  run github_apply_tag_ruleset
  assert_success
  assert_output "  Tag ruleset: created tags"

  run cat "${GH_WRITES}"
  assert_output "gh api --method POST repos/acme/app/rulesets --silent --input -
$(tag_ruleset_body)"

  run cat "${GH_READS}"
  assert_output 'gh api repos/acme/app/rulesets --paginate --jq .[] | select(.name == "tags" and .target == "tag" and .source_type == "Repository") | .id'
}

@test "github_apply_tag_ruleset updates the tag ruleset and keeps the rules and actors it does not manage" {
  github_setup
  GH_TAG_RULESET_ID="43"
  local rules='{"type":"required_signatures"}'
  local actors='{"actor_id":1,"actor_type":"Integration","bypass_mode":"always"}'
  GH_RULESET_KEPT="${rules}"$'\n'"${actors}"

  run github_apply_tag_ruleset
  assert_success
  assert_output "  Tag ruleset: updated tags"

  run cat "${GH_WRITES}"
  assert_output "gh api --method PUT repos/acme/app/rulesets/43 --silent --input -
$(tag_ruleset_body "${rules}" "${actors}")"

  run grep -F 'select((.actor_type == "RepositoryRole" and (.actor_id == 2 or .actor_id == 5)) | not)' "${GH_READS}"
  assert_success
}

@test "github_apply_security applies every setting" {
  github_setup
  GH_SECRET_SCANNING="disabled disabled"
  GH_DEPENDABOT=0
  GH_VULN_REPORTING="false"
  GH_WORKFLOW_PERMISSIONS="write"

  run github_apply_security
  assert_success
  assert_output "  Secret scanning: enabled secret_scanning secret_scanning_push_protection
  Dependabot alerts: enabled
  Private vulnerability reporting: enabled
  Workflow token: set to read-only
  Tag ruleset: created tags"
}

@test "github_apply_security keeps going after a skipped or failed setting" {
  github_setup
  GH_DEPENDABOT=0
  GH_FAIL_MATCH="api --method PUT repos/acme/app/vulnerability-alerts *"
  GH_FAIL_OUTPUT="gh: Resource not accessible by personal access token (HTTP 403)"

  run github_apply_security
  assert_success
  assert_output_contains "  Dependabot alerts: skipped (token lacks Administration: write)"
  assert_output_contains "  Tag ruleset: created tags"

  GH_FAIL_MATCH="api repos/acme/app/private-vulnerability-reporting *"
  GH_FAIL_OUTPUT="gh: Server Error (HTTP 500)"

  run github_apply_security
  assert_failure
  assert_output_contains "  Private vulnerability reporting: failed (gh: Server Error (HTTP 500))"
  assert_output_contains "  Workflow token: unchanged"
}

@test "github_apply_security reads nothing for a repository a dry run would create" {
  github_setup
  github_repo_exists="n"
  dry_run=1

  run github_apply_security
  assert_success
  assert_output_contains "  Secret scanning: would enable secret_scanning secret_scanning_push_protection"
  assert_output_contains "  Dependabot alerts: would enable"
  assert_output_contains "  Private vulnerability reporting: would enable"
  assert_output_contains "  Workflow token: would set to read-only"
  assert_output_contains "  Tag ruleset: would create tags"
  assert_no_writes

  run cat "${GH_READS}"
  assert_output ""

  github_visibility="private"

  run github_apply_security
  assert_success
  assert_output_contains "  Secret scanning: skipped (needs a public repository)"
  assert_output_contains "  Private vulnerability reporting: skipped (needs a public repository)"
}

#-------------------------------------------------------------------------------
# Ruleset
#-------------------------------------------------------------------------------

# Expected ruleset body, with extra rules ($1) and extra bypass actors ($2).
ruleset_body() {
  cat <<JSON
{
  "name": "default-branch",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
  "rules": [{"type": "deletion"}, {"type": "non_fast_forward"}${1:+, ${1}}],
  "bypass_actors": [{"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always"}${2:+, ${2}}]
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
  assert_output 'gh api repos/acme/app/rulesets --paginate --jq .[] | select(.name == "default-branch" and .target == "branch" and .source_type == "Repository") | .id'
}

@test "github_apply_ruleset updates the ruleset and keeps the rules and actors it does not manage" {
  github_setup
  GH_RULESET_ID="42"
  local rules='{"type":"required_status_checks","parameters":{"required_status_checks":[{"context":"test"}]}}, {"type":"pull_request"}'
  local actors='{"actor_id":1,"actor_type":"Integration","bypass_mode":"always"}'
  GH_RULESET_KEPT="${rules}"$'\n'"${actors}"

  run github_apply_ruleset
  assert_success
  assert_output "  Ruleset: updated default-branch"

  run cat "${GH_WRITES}"
  assert_output "gh api --method PUT repos/acme/app/rulesets/42 --silent --input -
$(ruleset_body "${rules}" "${actors}")"
}

@test "github_apply_ruleset keeps the unmanaged rules or actors when only 1 kind exists" {
  # Lines printed by the read, expected extra rules, expected extra actors.
  local cases=(
    '{"type":"pull_request"}' '{"type":"pull_request"}' ''
    $'\n{"actor_id":1,"actor_type":"Integration","bypass_mode":"always"}' '' '{"actor_id":1,"actor_type":"Integration","bypass_mode":"always"}'
    $'\n' '' ''
  )
  local i

  for ((i = 0; i < ${#cases[@]}; i += 3)); do
    github_setup
    GH_RULESET_ID="42"
    GH_RULESET_KEPT="${cases[i]}"

    run github_apply_ruleset
    assert_success

    run cat "${GH_WRITES}"
    assert_output "gh api --method PUT repos/acme/app/rulesets/42 --silent --input -
$(ruleset_body "${cases[i + 1]}" "${cases[i + 2]}")"
  done
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
  GH_IMMUTABLE="false false"
  GH_WORKFLOW_PERMISSIONS="write"

  run configure_github
  assert_success
  assert_output_contains "Configuring GitHub repository acme/app"
  assert_output_contains "  General settings: updated"
  assert_output_contains "  Labels: 12 created, 0 updated, 0 unchanged"
  assert_output_contains "  Workflow token: set to read-only"
  assert_output_contains "  Tag ruleset: created tags"
  assert_output_contains "  Immutable releases: enabled"
  assert_output_contains "  Ruleset: created default-branch"
  assert_output_contains "GitHub repository settings complete."
}

@test "configure_github runs only the selected sections" {
  github_setup
  GH_STATE="$(state_new)"
  github_settings="n"
  github_labels="n"
  github_security="n"
  github_immutable_releases="n"

  run configure_github
  assert_success
  assert_output_not_contains "  General settings:"
  assert_output_not_contains "  Labels:"
  assert_output_not_contains "  Secret scanning:"
  assert_output_not_contains "  Tag ruleset:"
  assert_output_not_contains "  Immutable releases:"
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
  GH_IMMUTABLE="false false"
  dry_run=1

  run configure_github
  assert_success
  assert_output_contains "  Dry run: nothing is changed."
  assert_output_contains "  General settings: would update"
  assert_output_contains "  Labels: 12 to create, 0 to update, 0 unchanged"
  assert_output_contains "  Secret scanning: unchanged"
  assert_output_contains "  Tag ruleset: would create tags"
  assert_output_contains "  Immutable releases: would enable"
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
  github_security=""
  github_immutable_releases=""
  github_ruleset=""
  parse_args --no-github-settings --no-github-security --no-github-immutable-releases --no-github-ruleset --github-labels-prune
  github_apply_defaults

  run github_main
  assert_success
  assert_output_not_contains "  General settings:"
  assert_output_contains "  Labels: 0 created, 0 updated, 12 unchanged, 0 deleted"
  assert_output_not_contains "  Secret scanning:"
  assert_output_not_contains "  Immutable releases:"
  assert_output_not_contains "  Ruleset:"
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

  # Owner, repository, general settings, description, labels, prune, security,
  # immutable releases, ruleset.
  run github_main <<<"$(printf 'acme\napp\ny\nNew description\ny\nn\nn\nn\nn\n')"
  assert_success
  assert_output_contains "  General settings: updated"
  assert_output_contains "  Labels: 12 created, 0 updated, 0 unchanged"
  assert_output_not_contains "  Secret scanning:"
  assert_output_not_contains "  Immutable releases:"
  assert_output_not_contains "  Ruleset:"
  assert_file_contains "${GH_WRITES}" "-f description=New description"
}

@test "github_collect_interactive keeps the current description on empty input" {
  github_setup
  interactive=1

  # Owner, repository, general settings, description, labels, security,
  # immutable releases, ruleset.
  github_collect_interactive <<<"$(printf '\n\ny\n\nn\nn\nn\nn\n')"

  assert_equal "${github_owner}" "acme"
  assert_equal "${github_repo}" "app"
  assert_equal "${github_settings}" "y"
  assert_equal "${github_description}" "Acme app"
  assert_equal "${github_labels}" "n"
  assert_equal "${github_labels_prune}" "n"
  assert_equal "${github_security}" "n"
  assert_equal "${github_immutable_releases}" "n"
  assert_equal "${github_ruleset}" "n"
}

@test "github_collect_interactive and the defaults delete labels not in the list" {
  github_setup
  interactive=1

  # Owner, repository, general settings, labels, prune, security, immutable
  # releases, ruleset.
  github_collect_interactive <<<"$(printf 'acme\napp\nn\ny\n\nn\nn\nn\n')"

  assert_equal "${github_labels_prune}" "y"

  github_labels_prune=""
  github_apply_defaults

  assert_equal "${github_labels_prune}" "y"
}

@test "github_collect_interactive stops when a missing repository is not created" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app --jq *"
  GH_FAIL_OUTPUT="gh: Not Found (HTTP 404)"

  # Owner, repository, create.
  run github_collect_interactive <<<"$(printf 'acme\napp\nn\n')"
  assert_failure

  run cat "${GH_WRITES}"
  assert_output ""
}

@test "github_collect_interactive offers to create a missing repository" {
  github_setup
  GH_FAIL_MATCH="api repos/acme/app --jq *"
  GH_FAIL_OUTPUT="gh: Not Found (HTTP 404)"

  # Owner, repository, create, visibility, settings, description, labels,
  # prune, security, immutable releases, ruleset, wait for CI.
  github_collect_interactive <<<"$(printf 'acme\napp\ny\nprivate\ny\nAcme\ny\nn\ny\ny\ny\nn\n')"

  assert_equal "${github_create}" "y"
  assert_equal "${github_visibility}" "private"
  assert_equal "${github_description}" "Acme"
  assert_equal "${github_security}" "y"
  assert_equal "${github_immutable_releases}" "y"
  assert_equal "${github_wait_checks}" "n"
  assert_equal "${github_required_checks}" "y"
}

@test "github_collect_interactive applies settings only when the repository to create exists" {
  github_setup
  github_create="y"

  # Owner, repository, settings, labels, security, immutable releases, ruleset,
  # required checks.
  run github_collect_interactive <<<"$(printf 'acme\napp\nn\nn\ny\ny\ny\nn\n')"
  assert_success
  assert_output_contains "acme/app already exists, so only its settings are applied."
}

@test "github_collect_interactive asks for the latest CI checks on an existing repository" {
  github_setup

  # Owner, repository, settings, labels, security, immutable releases, ruleset,
  # required checks.
  github_collect_interactive <<<"$(printf 'acme\napp\nn\nn\ny\ny\ny\nn\n')"

  assert_equal "${github_create}" "n"
  assert_equal "${github_required_checks}" "n"
  assert_equal "${github_wait_checks}" "y"
}

@test "collect_github_interactive configures the repository on request" {
  github_setup
  project="app"
  github_owner=""
  github_repo=""
  GH_LOGIN="acme"

  # Configure, owner, repository, settings, description, labels, prune,
  # security, immutable releases, ruleset.
  collect_github_interactive <<<"$(printf 'y\n\n\ny\n\ny\ny\ny\ny\ny\n')"

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

  # Configure, owner, repository, create.
  collect_github_interactive <<<"$(printf 'y\nacme\napp\nn\n')" 2>/dev/null

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
  github_security=""
  github_immutable_releases=""
  github_ruleset=""
  GH_LOGIN="acme"
  parse_args --namespace=AcmeApp --name=app --author="Jane Doe" --github --no-github-labels

  run collect_noninteractive
  assert_success
  assert_output_contains "Configure GitHub repository      : y"
  assert_output_contains "  Repository                     : acme/app"
  assert_output_contains "  General settings               : y"
  assert_output_contains "  Labels                         : n"
  assert_output_contains "  Security settings              : y"
  assert_output_contains "  Immutable releases             : y"
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
  parse_args --github --github-owner=acme --github-repo=app --no-github-settings --github-description="Acme app" --github-merge=merge,squash --no-github-labels --github-labels-prune --no-github-security --no-github-immutable-releases --no-github-ruleset --dry-run

  assert_equal "${use_github}" "y"
  assert_equal "${github_owner}" "acme"
  assert_equal "${github_repo}" "app"
  assert_equal "${github_settings}" "n"
  assert_equal "${github_description}" "Acme app"
  assert_equal "${github_merge}" "merge,squash"
  assert_equal "${github_labels}" "n"
  assert_equal "${github_labels_prune}" "y"
  assert_equal "${github_security}" "n"
  assert_equal "${github_immutable_releases}" "n"
  assert_equal "${github_ruleset}" "n"
  assert_equal "${dry_run}" "1"
  assert_equal "${interactive}" "0"
}

@test "parse_args sets the negated and positive GitHub toggles" {
  parse_args --no-github --github-settings --github-labels --no-github-labels-prune --github-security --github-immutable-releases --github-ruleset

  assert_equal "${use_github}" "n"
  assert_equal "${github_settings}" "y"
  assert_equal "${github_labels}" "y"
  assert_equal "${github_labels_prune}" "n"
  assert_equal "${github_security}" "y"
  assert_equal "${github_immutable_releases}" "y"
  assert_equal "${github_ruleset}" "y"
}

@test "parse_args fails on an invalid --github-merge value" {
  run parse_args --github-merge=squash,fast-forward
  assert_failure
  assert_output_contains "Error: Invalid merge method for --github-merge: fast-forward. Allowed values: merge, squash, rebase."
  assert_output_contains "Run with --help for usage."

  local value

  for value in "" "," ",,"; do
    run parse_args --github-merge="${value}"
    assert_failure
    assert_output_contains "Error: --github-merge needs at least 1 of: merge, squash, rebase."
  done
}

@test "usage documents the github command, its options and the token" {
  run usage
  assert_output_contains "./install.sh github [OPTIONS]"
  assert_output_contains "SCAFFOLD_GITHUB_TOKEN"
  assert_output_contains "--dry-run"
  assert_output_contains "--github-security, --no-github-security"
  assert_output_contains "The token needs"
  assert_output_contains "Administration: write."
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
  use_audit="y"
  use_schedule="y"
  use_windows="n"
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
  use_audit="n"
  use_schedule="n"
  use_windows="y"
  use_ai_arch_docs="plantuml"
  remove_self="n"
  run print_reproduce_command
  assert_equal "${lines[1]}" '  ./install.sh --namespace=AcmeApp --name=acme-app --author=Jane\ Doe --php-command-name=acme --no-phar --no-nodejs --shell-command-name=acme-sh --docker --no-release-drafter --no-pr-autoassign --no-funding --no-pr-template --no-renovate --no-docs --test-actions --no-audit --no-schedule --windows --ai-arch-docs=plantuml --keep'
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
  github_labels_prune="n"
  github_security="n"
  github_immutable_releases="n"
  github_ruleset="n"

  run print_reproduce_command
  assert_equal "${lines[1]}" '  ./install.sh --namespace=AcmeApp --name=acme-app --author=Jane\ Doe --github --github-owner=other --github-repo=repo --no-github-settings --github-description=New\ description --no-github-labels --no-github-security --no-github-immutable-releases --no-github-ruleset'

  github_labels="y"

  run print_reproduce_command
  assert_output_contains " --no-github-labels-prune "
}

#-------------------------------------------------------------------------------
# Required checks
#-------------------------------------------------------------------------------

@test "github_workflow_has_pull_request reads every form of the 'on' key" {
  # Workflow file, expected status.
  local cases=(
    $'on: pull_request\njobs: {}' "0"
    $'on: [push, pull_request]\njobs: {}' "0"
    $'on:\n  push:\n    branches: [main]\n  pull_request:\n    branches: [main]\njobs: {}' "0"
    $'on:\n  - push\n  - pull_request\njobs: {}' "0"
    $'name: Test\non:\n  pull_request:\njobs: {}' "0"
    $'on:\n  push:\n    branches: [main]\njobs:\n  pull_request:\n    runs-on: ubuntu-latest' "1"
    $'on: push\njobs: {}' "1"
    $'on: pull_request_target\njobs: {}' "1"
    $'on:\n  pull_request_target:\njobs: {}' "1"
    $'on: push # pull_request later\njobs: {}' "1"
    $'on:\n  # pull_request:\n  push:\njobs: {}' "1"
    $'jobs: {}' "1"
    $'\'on\':\n  pull_request:\njobs: {}' "0"
    $'"on": [push, pull_request]\njobs: {}' "0"
    $'on:\n  push:\n    branches:\n      - pull_request\njobs: {}' "1"
    $'on:\n  pull_request:\n    branches:\n      - main\n      - \'feature/**\'\njobs: {}' "0"
    $'on:\n  pull_request:\n    branches: [\'release/*\', "main"]\njobs: {}' "0"
    $'on:\n  pull_request:\n    branches:\n      - \'**\'\njobs: {}' "0"
    $'on:\n  pull_request:\n    branches:\n      - develop\njobs: {}' "1"
    $'on:\n  pull_request:\n    paths:\n      - src/**\njobs: {}' "1"
    $'on:\n  pull_request:\n    paths-ignore:\n      - docs/**\njobs: {}' "1"
    $'on:\n  pull_request:\n    branches-ignore:\n      - main\njobs: {}' "1"
    $'on:\n  pull_request:\n    types: [opened]\n  push:\n    paths:\n      - src/**\njobs: {}' "0"
  )
  local i

  for ((i = 0; i < ${#cases[@]}; i += 2)); do
    run github_workflow_has_pull_request <<<"${cases[i]}"
    assert_status "${cases[i + 1]}"
  done
}

@test "github_checks_rule_json builds the rule and escapes the names" {
  run github_checks_rule_json $'Test PHP\nSay "hi"'
  assert_output '{"type": "required_status_checks", "parameters": {"strict_required_status_checks_policy": false, "do_not_enforce_on_create": false, "required_status_checks": [{"context": "Test PHP", "integration_id": 15368}, {"context": "Say \"hi\"", "integration_id": 15368}]}}'

  run github_checks_rule_json ""
  assert_output ""
}

# Check runs on 'main': 2 from a pull-request workflow (suite 1), 1 from a
# push-only workflow (suite 2), and 1 from a suite with no workflow file.
checks_setup() {
  GH_CHECK_RUNS=$'1\tabc\tTest PHP\n1\tabc\tLint\n2\tabc\tRelease notes\n3\tabc\tDynamic\n1\tabc\tTest PHP\n'
  GH_SUITE_PATHS=$'1 .github/workflows/test.yml\n2 .github/workflows/release.yml\n3 '
  printf 'on:\n  push:\n  pull_request:\njobs: {}\n' >"${GH_WORKFLOWS}/test.yml"
  printf 'on:\n  push:\n    branches: [main]\njobs: {}\n' >"${GH_WORKFLOWS}/release.yml"
}

@test "github_compute_checks keeps only the checks of pull-request workflows" {
  github_setup
  github_load_repo
  checks_setup

  github_compute_checks >"${BATS_TEST_TMPDIR}/out"

  assert_file_contains "${BATS_TEST_TMPDIR}/out" "  Required checks: Lint; Test PHP"
  assert_equal "${github_checks_rule}" "$(github_checks_rule_json $'Lint\nTest PHP')"

  # Each check suite and each workflow file is read once.
  run grep -c "check_suite_id=1" "${GH_READS}"
  assert_output "1"
  run grep -c "contents/.github/workflows/test.yml?ref=abc" "${GH_READS}"
  assert_output "1"
  assert_file_contains "${GH_READS}" 'api repos/acme/app/commits/main/check-runs --paginate --jq .check_runs[] | select(.app.id == 15368 and .conclusion != "skipped" and .conclusion != "cancelled" and .conclusion != "neutral")'
}

@test "github_compute_checks reports when no check qualifies" {
  github_setup
  github_load_repo

  github_compute_checks >"${BATS_TEST_TMPDIR}/out"

  assert_file_contains "${BATS_TEST_TMPDIR}/out" "  Required checks: none found on main"
  assert_equal "${github_checks_rule}" ""
}

@test "github_compute_checks skips on a 403 and names the permission" {
  github_setup
  github_load_repo
  checks_setup

  GH_FAIL_MATCH="api repos/acme/app/commits/*"
  GH_FAIL_OUTPUT="gh: Resource not accessible by personal access token (HTTP 403)"
  run github_compute_checks
  assert_status 2
  assert_output "  Required checks: skipped (token lacks Checks: read)"

  GH_FAIL_MATCH="api repos/acme/app/actions/*"
  run github_compute_checks
  assert_status 2
  assert_output "  Required checks: skipped (token lacks Actions: read)"
}

@test "github_apply_ruleset puts a given checks rule in a new ruleset" {
  github_setup
  local rule
  rule="$(github_checks_rule_json "Test PHP")"

  run github_apply_ruleset "${rule}"
  assert_success
  assert_output "  Ruleset: created default-branch with required checks"

  run cat "${GH_WRITES}"
  assert_output "gh api --method POST repos/acme/app/rulesets --silent --input -
$(ruleset_body "${rule}")"
}

@test "github_apply_ruleset replaces the existing required checks with a given rule" {
  github_setup
  GH_RULESET_ID="42"
  GH_RULESET_KEPT='{"type":"pull_request"}'
  local rule
  rule="$(github_checks_rule_json "Test PHP")"

  run github_apply_ruleset "${rule}"
  assert_success
  assert_output "  Ruleset: updated default-branch with required checks"
  assert_file_contains "${GH_READS}" '.type != "required_status_checks"'

  run cat "${GH_WRITES}"
  assert_output "gh api --method PUT repos/acme/app/rulesets/42 --silent --input -
$(ruleset_body "{\"type\":\"pull_request\"}, ${rule}")"
}

@test "github_apply_ruleset keeps the existing required checks without a rule" {
  github_setup
  GH_RULESET_ID="42"

  github_apply_ruleset >/dev/null

  assert_file_not_contains "${GH_READS}" '.type != "required_status_checks"'
}

@test "github_apply_existing_ruleset adds the checks of the latest CI run" {
  github_setup
  github_load_repo
  checks_setup

  run github_apply_existing_ruleset
  assert_success
  assert_output "  Required checks: Lint; Test PHP
  Ruleset: created default-branch with required checks"
}

@test "github_apply_existing_ruleset prints the re-run command when no check qualifies" {
  github_setup
  github_load_repo

  run github_apply_existing_ruleset
  assert_success
  assert_output "  Required checks: none found on main
  Ruleset: created default-branch
  After CI finishes, run the following command to require its checks:
    curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github --github-owner=acme --github-repo=app --no-github-settings --no-github-labels"
}

@test "github_apply_existing_ruleset leaves the checks alone with --no-github-required-checks" {
  github_setup
  github_load_repo
  checks_setup
  github_required_checks="n"

  run github_apply_existing_ruleset
  assert_success
  assert_output "  Ruleset: created default-branch"
  assert_file_not_contains "${GH_READS}" "check-runs"
}

#-------------------------------------------------------------------------------
# Waiting for CI
#-------------------------------------------------------------------------------

@test "github_wait_for_runs waits until every run has finished" {
  github_setup
  github_pushed_sha="abc"
  github_runs_timeout=5
  GH_RUN_LISTS=(
    ""
    $'in_progress\t\tTest PHP\ncompleted\tsuccess\tLint'
    $'completed\tsuccess\tTest PHP\ncompleted\tsuccess\tLint'
  )

  run github_wait_for_runs
  assert_success
  assert_output "  Waiting for the CI runs of the pushed commit
  CI: 2 runs finished"
  assert_file_contains "${GH_READS}" "gh run list --repo acme/app --commit abc --limit 100 --json status,conclusion,name"

  run cat "${GH_RUN_LIST_COUNT}"
  assert_output "3"
}

@test "github_wait_for_runs warns about failed runs" {
  github_setup
  github_pushed_sha="abc"
  GH_RUN_LISTS=($'completed\tfailure\tTest PHP\ncompleted\tskipped\tDocs\ncompleted\tsuccess\tLint\ncompleted\tcancelled\tShell')

  run github_wait_for_runs
  assert_success
  assert_output "  Waiting for the CI runs of the pushed commit
  CI: 4 runs finished
  Warning: these runs failed, so pull requests stay blocked until CI passes: Test PHP; Shell"
}

@test "github_wait_for_runs gives up when no run starts" {
  github_setup
  github_pushed_sha="abc"

  run github_wait_for_runs
  assert_failure
  assert_output "  Waiting for the CI runs of the pushed commit
  CI: no runs started within 0s"
}

@test "github_wait_for_runs gives up at the deadline" {
  github_setup
  github_pushed_sha="abc"
  github_wait_timeout=0
  GH_RUN_LISTS=($'in_progress\t\tTest PHP')

  run github_wait_for_runs
  assert_failure
  assert_output "  Waiting for the CI runs of the pushed commit
  CI: runs still in progress after 0s"
}

@test "github_wait_interrupted prints the re-run command and exits 130" {
  github_setup

  run github_wait_interrupted
  assert_status 130
  assert_output_contains "CI: waiting was interrupted, so the ruleset has no required checks."
  assert_output_contains "bash -s -- github --github-owner=acme --github-repo=app --no-github-settings --no-github-labels"
}

#-------------------------------------------------------------------------------
# Repository creation
#-------------------------------------------------------------------------------

# Enter a project directory holding 1 file.
enter_project() {
  local dir="${BATS_TEST_TMPDIR}/${1}"
  mkdir -p "${dir}"
  echo "content" >"${dir}/README.md"
  cd "${dir}" || return 1
}

creation_setup() {
  github_setup
  GH_MISSING=1
  GH_STATE="$(state_new)"
  GH_LABELS=""
  github_create="y"
  remove_self="n"
}

@test "github_create_repo initialises git, commits, creates and pushes" {
  creation_setup
  enter_project "create_fresh"

  run github_create_repo
  assert_success
  assert_output "  Creating public repository acme/app
  Pushed main to https://github.com/acme/app.git"

  run cat "${GH_WRITES}"
  assert_output "gh repo create acme/app --public
git push https://github.com/acme/app.git HEAD:refs/heads/main [token=test-token prompt=0]"

  run git log --format=%s
  assert_output "Initial commit."
  run git ls-files
  assert_output "README.md"
  run git remote get-url origin
  assert_output "https://github.com/acme/app.git"
  run git config branch.main.merge
  assert_output "refs/heads/main"
}

@test "github_create_repo leaves this script out of the initial commit" {
  creation_setup
  enter_project "create_exclude"
  remove_self="y"
  echo "script" >install.sh
  self_removal_path() { echo "./install.sh"; }

  github_create_repo >/dev/null

  run git ls-files
  assert_output "README.md"
  assert_file_exists install.sh
}

@test "github_create_repo commits everything in a repository without commits" {
  creation_setup
  enter_project "create_no_commits"
  command git init -q

  run github_create_repo
  assert_success

  run git log --format=%s
  assert_output "Initial commit."
}

@test "github_create_repo adds origin to a repository with commits" {
  creation_setup
  enter_project "create_no_origin"
  command git init -q -b trunk
  command git add README.md
  command git commit -q -m "Existing."

  run github_create_repo
  assert_success
  assert_output_contains "Pushed trunk to https://github.com/acme/app.git"
  assert_output_not_contains "Warning"

  run git log --format=%s
  assert_output "Existing."
  run git remote get-url origin
  assert_output "https://github.com/acme/app.git"
}

@test "github_create_repo keeps an existing origin and warns about uncommitted changes" {
  creation_setup
  enter_project "create_origin"
  command git init -q -b main
  command git add README.md
  command git commit -q -m "Existing."
  command git remote add origin "git@github.com:acme/app.git"
  echo "changed" >README.md

  run github_create_repo
  assert_success
  assert_output_contains "  Warning: uncommitted changes are not pushed."

  run git remote get-url origin
  assert_output "git@github.com:acme/app.git"
  assert_file_contains "${GH_WRITES}" "git push https://github.com/acme/app.git HEAD:refs/heads/main"
}

@test "github_create_repo creates a private repository without pushing" {
  creation_setup
  enter_project "create_no_push"
  github_visibility="private"
  github_push="n"

  run github_create_repo
  assert_success
  assert_output_contains "  Push: skipped"

  run cat "${GH_WRITES}"
  assert_output "gh repo create acme/app --private"
}

@test "github_create_repo stops when the push fails" {
  creation_setup
  enter_project "create_push_fails"
  GIT_PUSH_STATUS=1

  run github_create_repo
  assert_failure
  assert_output_contains "  Push: failed"
}

@test "github_create_repo stops when the repository cannot be created" {
  creation_setup
  enter_project "create_fails"
  GH_FAIL_MATCH="repo create *"
  GH_FAIL_OUTPUT="gh: Resource not accessible by personal access token (HTTP 403)"

  run github_create_repo
  assert_failure
  assert_file_not_contains "${GH_WRITES}" "git push"
}

@test "github_create_repo skips creation without git or a git email" {
  creation_setup
  enter_project "create_no_email"
  command git config --global --unset user.email

  run github_create_repo
  assert_failure
  assert_output_contains "Skipping repository creation: git user.email is not set."
  assert_dir_not_exists .git

  has_command() { [ "${1}" != "git" ]; }
  run github_create_repo
  assert_failure
  assert_output "Skipping repository creation: 'git' is not installed."
  assert_no_writes
}

@test "github_create_repo prints every step under --dry-run" {
  creation_setup
  enter_project "create_dry_run"
  dry_run=1

  run github_create_repo
  assert_success
  assert_output_contains "  [dry-run] git init -q"
  assert_output_contains "  [dry-run] git add -A -- ."
  assert_output_contains "  [dry-run] gh repo create acme/app --public"
  assert_output_contains "  [dry-run] git remote add origin https://github.com/acme/app.git"
  assert_output_contains "  [dry-run] git -c credential.helper= -c credential.helper"
  assert_dir_not_exists .git
  assert_no_writes
}

@test "configure_github creates the repository, waits for CI and requires its checks" {
  creation_setup
  enter_project "configure_create"
  checks_setup
  GH_RUN_LISTS=($'completed\tsuccess\tTest PHP')

  run configure_github
  assert_success
  assert_output_contains "  Creating public repository acme/app"
  assert_output_contains "  General settings: updated"
  assert_output_contains "  Labels: 12 created, 0 updated, 0 unchanged"
  assert_output_contains "  Ruleset: created default-branch"
  assert_output_contains "  CI: 1 runs finished"
  assert_output_contains "  Required checks: Lint; Test PHP"
  assert_output_contains "  Ruleset: updated default-branch with required checks"
  assert_output_contains "GitHub repository settings complete."

  # The first ruleset goes on before CI, the second adds its checks.
  assert_file_contains "${GH_WRITES}" "gh api --method POST repos/acme/app/rulesets --silent --input -"
  assert_file_contains "${GH_WRITES}" "gh api --method PUT repos/acme/app/rulesets/7 --silent --input -"
}

@test "configure_github prints the re-run command when CI never starts" {
  creation_setup
  enter_project "configure_no_ci"

  run configure_github
  assert_success
  assert_output_contains "  CI: no runs started within 0s"
  assert_output_contains "  After CI finishes, run the following command to require its checks:"
  assert_file_not_contains "${GH_WRITES}" "--method PUT"
}

@test "configure_github skips waiting with --no-github-wait-checks" {
  creation_setup
  enter_project "configure_no_wait"
  github_wait_checks="n"

  run configure_github
  assert_success
  assert_output_contains "  After CI finishes, run the following command to require its checks:"
  assert_file_not_contains "${GH_READS}" "run list"
}

@test "configure_github previews a creation under --dry-run" {
  creation_setup
  enter_project "configure_dry_run"
  dry_run=1

  run configure_github
  assert_success
  assert_output_contains "  [dry-run] gh repo create acme/app --public"
  assert_output_contains "  Labels: 12 to create, 0 to update, 0 unchanged"
  assert_output_contains "  Ruleset: would create default-branch"
  assert_output_contains "  CI: would wait for the first CI run and require its checks"
  assert_no_writes
  assert_dir_not_exists .git
}

@test "configure_github fails for a missing repository without --github-create" {
  creation_setup
  github_create="n"

  run configure_github
  assert_failure
  assert_output_contains "Pass --github-create to create it."
  assert_no_writes
}

@test "collect_github_interactive offers to create a repository without .git" {
  creation_setup
  enter_project "interactive_create"
  github_create=""
  project="app"
  github_owner=""
  github_repo=""
  GH_LOGIN="acme"

  # Create, owner, repository, visibility, settings, description, labels,
  # prune, security, immutable releases, ruleset, wait for CI.
  collect_github_interactive <<<"$(printf 'y\n\n\n\ny\n\ny\nn\ny\ny\ny\ny\n')"

  assert_equal "${use_github}" "y"
  assert_equal "${github_create}" "y"
  assert_equal "${github_visibility}" "public"
  assert_equal "${github_wait_checks}" "y"
}

@test "collect_github_interactive offers settings without .git when git cannot commit" {
  creation_setup
  enter_project "interactive_no_email"
  command git config --global --unset user.email
  github_create=""

  run collect_github_interactive <<<"$(printf 'n\n')"
  assert_success
  assert_output_contains "Skipping repository creation: git user.email is not set."
  assert_equal "${github_create}" ""
}

@test "print_reproduce_command lists the creation answers that differ" {
  github_setup
  default_answers
  use_github="y"
  github_create="y"
  github_visibility="private"
  github_wait_checks="n"
  github_owner_default="acme"
  github_repo_default="app"

  run print_reproduce_command
  assert_equal "${lines[1]}" '  ./install.sh --namespace=AcmeApp --name=acme-app --author=Jane\ Doe --github --github-create --github-visibility=private --no-github-wait-checks'

  github_create="n"
  github_required_checks="n"
  run print_reproduce_command
  assert_equal "${lines[1]}" '  ./install.sh --namespace=AcmeApp --name=acme-app --author=Jane\ Doe --github --no-github-required-checks'
}

@test "parse_args sets the creation and CI options" {
  parse_args --github-create --github-visibility=private --no-github-push --no-github-wait-checks --github-wait-timeout=60 --no-github-required-checks

  assert_equal "${use_github}" "y"
  assert_equal "${github_create}" "y"
  assert_equal "${github_visibility}" "private"
  assert_equal "${github_push}" "n"
  assert_equal "${github_wait_checks}" "n"
  assert_equal "${github_wait_timeout}" "60"
  assert_equal "${github_required_checks}" "n"

  parse_args --no-github-create --github-push --github-wait-checks --github-required-checks
  assert_equal "${github_create}" "n"
  assert_equal "${github_push}" "y"
  assert_equal "${github_wait_checks}" "y"
  assert_equal "${github_required_checks}" "y"
}

@test "parse_args rejects an invalid visibility or wait timeout" {
  run parse_args --github-visibility=internal
  assert_failure
  assert_output_contains "Error: Invalid value for --github-visibility: internal. Allowed values: public, private."

  run parse_args --github-wait-timeout=soon
  assert_failure
  assert_output_contains "Error: Invalid value for --github-wait-timeout: soon. Pass a number of seconds."
}

#-------------------------------------------------------------------------------
# Self-removal
#-------------------------------------------------------------------------------

@test "remove_self_script removes the script unless it is kept" {
  local dir="${BATS_TEST_TMPDIR}/self_removal"
  mkdir -p "${dir}"
  echo "script" >"${dir}/install.sh"
  cd "${dir}" || return 1
  self_removal_path() { [ "${remove_self}" = "n" ] || echo "./install.sh"; }

  remove_self="n"
  remove_self_script
  assert_file_exists "${dir}/install.sh"

  remove_self="y"
  remove_self_script
  assert_file_not_exists "${dir}/install.sh"
}

@test "self_removal_path prints nothing for --keep or a missing file" {
  remove_self="n"
  run self_removal_path
  assert_output ""

  remove_self="y"
  run self_removal_path
  assert_output_contains "install.sh"
}

@test "github_self_exclude names the script relative to the current directory" {
  local dir="${BATS_TEST_TMPDIR}/self_exclude"
  mkdir -p "${dir}"
  cd "${dir}" || return 1

  # Script path, expected pathspec.
  local cases=(
    "./install.sh" ":(exclude)install.sh"
    "${dir}/install.sh" ":(exclude)install.sh"
    "/elsewhere/install.sh" ""
    "" ""
  )
  local i

  for ((i = 0; i < ${#cases[@]}; i += 2)); do
    SELF_PATH="${cases[i]}"
    self_removal_path() { [ -z "${SELF_PATH}" ] || echo "${SELF_PATH}"; }
    run github_self_exclude
    assert_output "${cases[i + 1]}"
  done
}

@test "main removes the script last, and keeps it when the GitHub step fails" {
  github_setup
  local dir="${BATS_TEST_TMPDIR}/main_self_removal"
  mkdir -p "${dir}/.scaffold"
  cd "${dir}" || return 1
  self_removal_path() { echo "${dir}/install.sh"; }
  process_project() { echo "processed"; }

  echo "script" >"${dir}/install.sh"
  configure_github() { return 1; }
  run main --namespace=AcmeApp --name=acme-app --author="Jane Doe" --github
  assert_failure
  assert_file_exists "${dir}/install.sh"

  configure_github() { echo "configured"; }
  run main --namespace=AcmeApp --name=acme-app --author="Jane Doe"
  assert_success
  assert_file_not_exists "${dir}/install.sh"
}

#-------------------------------------------------------------------------------
# Edge cases
#-------------------------------------------------------------------------------

@test "github_workflow_has_pull_request matches the branch it is given" {
  local workflow=$'on:\n  pull_request:\n    branches: [develop]\njobs: {}'

  run github_workflow_has_pull_request "develop" <<<"${workflow}"
  assert_success

  run github_workflow_has_pull_request "main" <<<"${workflow}"
  assert_failure
}

@test "github_compute_checks encodes the default branch in the check-runs path" {
  github_setup
  GH_STATE="${GH_STATE/default_branch=main/default_branch=release#1?}"
  github_load_repo

  github_compute_checks >/dev/null

  assert_file_contains "${GH_READS}" "gh api repos/acme/app/commits/release%231%3F/check-runs"
}

@test "parse_args removes spaces from merge methods and reads the timeout as decimal" {
  parse_args --github-merge="squash, rebase" --github-wait-timeout=08

  assert_equal "${github_merge}" "squash,rebase"
  assert_equal "${github_wait_timeout}" "8"
}

@test "github_desired_settings keeps a multi-line description on 1 line" {
  github_setup
  github_description=$'First line\nprivate=false'

  run github_desired_settings
  assert_output_contains "description=First line private=false"
  assert_output_not_contains $'\nprivate=false'
}

@test "github_wait_for_runs reports a run list that fails" {
  github_setup
  github_pushed_sha="abc"
  GH_FAIL_MATCH="run list *"
  GH_FAIL_OUTPUT="gh: Resource not accessible by personal access token (HTTP 403)"

  run github_wait_for_runs
  assert_failure
  assert_output_contains "  CI: could not list the runs (gh: Resource not accessible by personal access token (HTTP 403))"
}

@test "github_collect_interactive rejects a repository other than origin" {
  github_setup
  enter_repo "interactive_mismatch" "git@github.com:acme/app.git"

  # Owner, repository.
  run github_collect_interactive <<<"$(printf 'acme\nother\n')"
  assert_failure
  assert_output_contains "Error: GitHub repository acme/other does not match the 'origin' remote acme/app."

  run cat "${GH_READS}"
  assert_output ""
}

@test "gh_run, github_token_set and github_git_push keep the token out of a trace" {
  github_setup
  SCAFFOLD_GITHUB_TOKEN="secret-token-value"
  dry_run=1

  {
    set -x
    gh_run api user --jq .login
    github_token_set
    github_git_push "https://github.com/acme/app.git" "main"
    set +x
  } >"${BATS_TEST_TMPDIR}/out" 2>"${BATS_TEST_TMPDIR}/trace"

  assert_file_not_contains "${BATS_TEST_TMPDIR}/trace" "secret-token-value"
  assert_file_not_contains "${BATS_TEST_TMPDIR}/out" "secret-token-value"
}

@test "print_summary shows the creation and push choices separately" {
  github_setup
  default_answers
  use_github="y"
  github_create="y"
  github_push="n"

  run print_summary
  assert_output_contains "  Create repository              : y"
  assert_output_contains "    Push                         : n"
}

@test "github_create_repo prints how to finish after a failed push" {
  creation_setup
  enter_project "create_push_hint"
  GIT_PUSH_STATUS=1

  run github_create_repo
  assert_failure
  assert_output_contains "Push with 'git push -u origin main', then run 'curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github' to apply the settings."
}

@test "github_wait_for_runs reports a run list that fails after the runs appeared" {
  github_setup
  github_pushed_sha="abc"
  GH_RUN_LISTS=($'in_progress\t\tTest PHP')
  GH_RUN_LIST_FAIL_AT=2

  run github_wait_for_runs
  assert_failure
  assert_output_contains "  CI: could not list the runs (gh: Server Error (HTTP 500))"
}

@test "parse_args sets every feature toggle" {
  # Option, variable, expected value.
  local cases=(
    "--php" "use_php" "y"
    "--phar" "use_php_command_build" "y"
    "--no-phar" "use_php_command_build" "n"
    "--nodejs" "use_nodejs" "y"
    "--no-nodejs" "use_nodejs" "n"
    "--shell" "use_shell" "y"
    "--no-shell" "use_shell" "n"
    "--shell-command-name=tool" "shell_command_name" "tool"
    "--no-docker" "use_docker" "n"
    "--php-script-name=tool" "php_script_name" "tool"
    "--release-drafter" "use_release_drafter" "y"
    "--no-release-drafter" "use_release_drafter" "n"
    "--pr-autoassign" "use_pr_autoassign" "y"
    "--no-pr-autoassign" "use_pr_autoassign" "n"
    "--funding" "use_funding" "y"
    "--no-funding" "use_funding" "n"
    "--pr-template" "use_pr_template" "y"
    "--no-pr-template" "use_pr_template" "n"
    "--renovate" "use_renovate" "y"
    "--no-renovate" "use_renovate" "n"
    "--docs" "use_docs" "y"
    "--no-docs" "use_docs" "n"
  )
  local i

  for ((i = 0; i < ${#cases[@]}; i += 3)); do
    parse_args "${cases[i]}"
    assert_equal "${!cases[i + 1]}" "${cases[i + 2]}"
  done
}

@test "github_apply_existing_ruleset applies the ruleset to an empty repository" {
  github_setup
  github_load_repo
  GH_FAIL_MATCH="api repos/acme/app/commits/*"
  GH_FAIL_OUTPUT='{"message":"No commit found for SHA: main","status":"422"}gh: No commit found for SHA: main (HTTP 422)'

  run github_apply_existing_ruleset
  assert_success
  assert_output "  Required checks: none found, because main has no commits
  Ruleset: created default-branch
  After CI finishes, run the following command to require its checks:
    curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github --github-owner=acme --github-repo=app --no-github-settings --no-github-labels"
  assert_file_contains "${GH_WRITES}" "gh api --method POST repos/acme/app/rulesets --silent --input -"
}

@test "github_compute_checks reports any other 422 as a failure" {
  github_setup
  github_load_repo
  GH_FAIL_MATCH="api repos/acme/app/commits/*"
  GH_FAIL_OUTPUT="gh: Validation Failed (HTTP 422)"

  run github_compute_checks
  assert_status 1
  assert_output "  Required checks: failed (gh: Validation Failed (HTTP 422))"
}

@test "configure_github prints the re-run command when the first CI run has no qualifying checks" {
  creation_setup
  enter_project "configure_no_checks"
  GH_RUN_LISTS=($'completed\tsuccess\tTest PHP')

  run configure_github
  assert_success
  assert_output_contains "  CI: 1 runs finished"
  assert_output_contains "  Required checks: none found on main"
  assert_output_contains "  After CI finishes, run the following command to require its checks:"
  assert_file_not_contains "${GH_WRITES}" "--method PUT"
}
