#!/usr/bin/env bash
##
# Run a first install from HEAD that creates and configures a new repository.
#
# Each run creates 'scaffold-test-install-<timestamp>' and never deletes it;
# the cleanup command is printed at the end. Extra arguments are passed through
# to 'install.sh'.
#
# @usage
# .scaffold/tests/playground/create.sh [--dry-run] [--github-visibility=private] ...

set -euo pipefail

# shellcheck source=.scaffold/tests/playground/_helper.sh
. "$(dirname "${BASH_SOURCE[0]}")/_helper.sh"

repo="scaffold-test-install-${PLAYGROUND_TIMESTAMP}"
author="$(git config user.name || true)"

playground_check_prerequisites

if [ -z "${author}" ]; then
  echo "Error: git user.name is not set." >&2
  exit 1
fi

dir="$(playground_workdir create)"

# The whole template is exported, because 'install.sh' alone in an empty
# directory would bootstrap the latest release instead of HEAD.
git -C "${PLAYGROUND_ROOT}" archive HEAD | tar -x -C "${dir}"

cd "${dir}"

# Namespace and name are left out, so they are derived from the GitHub owner
# and repository.
status=0
./install.sh \
  --github-owner="${PLAYGROUND_GITHUB_OWNER}" \
  --github-repo="${repo}" \
  --author="${author}" \
  --github \
  --github-create \
  --github-visibility=public \
  --github-description='Test repo for Scaffold installer' \
  "$@" || status=$?

slug="$(playground_option --github-owner "${PLAYGROUND_GITHUB_OWNER}" "$@")/$(playground_option --github-repo "${repo}" "$@")"

playground_summary "https://github.com/${slug}" "${dir}"
echo "Cleanup        : gh repo delete ${slug} --yes"

exit "${status}"
