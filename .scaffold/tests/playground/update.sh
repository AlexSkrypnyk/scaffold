#!/usr/bin/env bash
##
# Run 'install.sh github' from HEAD against an existing test repository.
#
# The repository is reused by every run, so repeat runs exercise the update
# path. Extra arguments are passed through to 'install.sh'.
#
# @usage
# .scaffold/tests/playground/update.sh [--dry-run] [--github-labels-prune] ...

set -euo pipefail

# shellcheck source=.scaffold/tests/playground/_helper.sh
. "$(dirname "${BASH_SOURCE[0]}")/_helper.sh"

repo="scaffold-test-install"

playground_check_prerequisites

dir="$(playground_workdir update)"

# The 'github' command needs no template, so the script alone is enough.
git -C "${PLAYGROUND_ROOT}" show HEAD:install.sh >"${dir}/install.sh"
chmod +x "${dir}/install.sh"

cd "${dir}"

status=0
./install.sh github --github-owner="${PLAYGROUND_GITHUB_OWNER}" --github-repo="${repo}" "$@" || status=$?

slug="$(playground_option --github-owner "${PLAYGROUND_GITHUB_OWNER}" "$@")/$(playground_option --github-repo "${repo}" "$@")"

playground_summary "https://github.com/${slug}" "${dir}"

exit "${status}"
