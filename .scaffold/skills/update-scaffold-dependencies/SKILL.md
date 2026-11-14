---
name: update-scaffold-dependencies
description: Use when a Scaffold maintainer asks to update the template's dependencies to their latest versions - Composer and npm packages, the documentation sites, the BATS helpers, the Dockerfile base image or the pinned GitHub Actions - including the major versions Renovate leaves alone.
user-invocable: true
disable-model-invocation: true
---

# Update Scaffold dependencies

This skill moves every dependency of the Scaffold template to its latest release as of today, then proves the template still works and commits the result. It's for Scaffold maintainers and runs only when a maintainer asks for it. `install.sh` deletes `.scaffold/`, so generated projects never get it.

Renovate already handles minor and patch updates (see `renovate.json`). This run exists for everything Renovate deliberately skips, so **`renovate.json` doesn't limit it**:

- **Take major versions.** Don't use `--target minor`, don't stop to ask about each major. A major that breaks the build is fixed or held back (see "When a major breaks"), never skipped up front.
- **No cooldown.** Ignore Renovate's 7-day `minimumReleaseAge`. "Latest" means the newest release today.
- **Runtime dependencies count too.** Update `require` and `dependencies` as well as the dev ones.

What stays fixed is the **support floor**: the versions of PHP, Composer, Node.js and npm the template promises to run on. Those are support policy. Don't change them; pick the newest package versions that still run on them, and report newer runtimes in the PR.

| Floor | Where it's set |
|---|---|
| PHP | `php` in `composer.json` and `.scaffold/tests/phpunit/composer.json`, the `php-versions` matrix in `test-php.yml` |
| Composer | `composer` in `composer.json` `require-dev` |
| Node.js and npm | the lowest entry of the `node` matrix in `test-nodejs.yml`, carried by `engines` in `package.json` |

The docs sites are private and never installed by users, so their `engines.node` only mirrors the root one. When it lags behind the root value, Step 5 raises it to match before updating, and the PR says so.

## What gets updated

| Area | Files | How |
|---|---|---|
| Init test suite | `.scaffold/tests/phpunit/composer.json` and `composer.lock` | Composer, Step 2 |
| Root Composer | `composer.json` (its lock is git-ignored) | Composer, Step 3 |
| Root npm | `package.json` (its lock is git-ignored) | npm, Step 4 |
| BATS helpers | `tests/bats/` and `.scaffold/tests/bats/` `package.json` and `package-lock.json` | npm, Step 4 |
| Docs sites | `.scaffold/docs/` (getscaffold.dev) and `docs/` (the consumer starter), `package.json` and `package-lock.json` | npm, Step 5 |
| Docker | `Dockerfile` base image tag and digest | Step 6 |
| GitHub Actions | every `uses: owner/repo@<sha> # <tag>` in `.github/workflows/`, and the images workflows start with `docker run` | Step 7 |
| Asset recorder | the `svg-term@x.y.z` pin in `.scaffold/assets/update-assets.php` | Step 8 |
| Docs prose | version mentions in `*.md` and `*.mdx` | Step 9 |
| Fixtures | `.scaffold/tests/phpunit/fixtures/install/` | regenerated in Step 11, never edited by hand |

`humbug/box` has no pin: `composer build` installs its latest version into `vendor-bin/` on every build.

Run the steps in order. The order matters in 2 places. First, the init suite copies the working tree into its sandbox and asserts no `composer.lock` exists there, so its tests run with no root `composer.lock`, `vendor/` or `node_modules/`. Second, every source change must be committed before Step 11, because `update-snapshots` commits the fixtures it writes.

## Step 1: Branch

Start from a clean tree. When `git status` shows changes, stop and ask the maintainer to commit or stash them, because every later step commits by path and a stray edit would end up in the update.

On the default branch, create a feature branch:

```bash
git switch -c feature/update-deps
```

On any other branch, stay on it: the maintainer chose it.

## Step 2: Init test suite (Composer)

Install the suite from its lock, because `composer outdated` reports only installed packages:

```bash
composer install --working-dir=.scaffold/tests/phpunit
```

List what's outdated. `latest-status: update-possible` marks a new major:

```bash
composer outdated --direct --format=json --working-dir=.scaffold/tests/phpunit
```

Raise every package with a new major to that major's latest version, one call per package (all of this suite's packages are in `require`, so no `--dev`):

```bash
composer require --no-update --working-dir=.scaffold/tests/phpunit vendor/package:^X.Y.Z
```

Then resolve everything. `bump-after-update` in that `composer.json` raises the remaining constraints to the installed versions:

```bash
composer update --with-all-dependencies --working-dir=.scaffold/tests/phpunit
```

Check the PHP floor (it's `>=8.3` today - read it from the `php` constraint). This must print "There is no installed package depending on "php" in versions not matching". Any package it names needs a newer PHP than the floor, so step that package back to the newest major that supports the floor and run the update again:

```bash
composer why-not php 8.3.0 --working-dir=.scaffold/tests/phpunit
```

Normalize the file, then run the suite's linters. Don't run its tests yet (Step 11):

```bash
composer normalize --working-dir=.scaffold/tests/phpunit
```

```bash
composer lint --working-dir=.scaffold/tests/phpunit
```

A new major of this suite's helpers (`alexskrypnyk/file`, `alexskrypnyk/phpunit-helpers`, `alexskrypnyk/snapshot`) can move or rename methods that `.scaffold/tests/phpunit/src/` calls. PHPStan reports them as unknown classes or methods; read each package's README and fix the call sites. A Rector release can also drop rules or sets that `rector.php` names, and Rector then prints the replacement. Commit once the linters pass:

```bash
git add .scaffold/tests/phpunit
```

```bash
git commit -m "Updated init test suite dependencies."
```

## Step 3: Root Composer

The root has no committed lock, so install first to have something to compare against:

```bash
composer install
```

```bash
composer outdated --direct --format=json
```

Raise each new major, adding `--dev` for packages in `require-dev`:

```bash
composer require --no-update --dev vendor/package:^X.Y.Z
```

```bash
composer update --with-all-dependencies
```

Raise the constraints to the installed versions. This matters because CI's `lowest` leg installs the constraint floors, so a stale `^1.2.0` would test a version nobody else gets. `bump` leaves `>=` constraints such as `composer` and platform packages such as `php` alone:

```bash
composer bump
```

Check the floor exactly as in Step 2. `symfony/console` is the usual offender, since a new Symfony major tends to raise its PHP minimum:

```bash
composer why-not php 8.3.0
```

```bash
composer normalize
```

Now run what CI runs, on the latest versions and then on the lowest ones:

```bash
composer validate
```

```bash
composer lint
```

```bash
composer test
```

```bash
composer update --prefer-lowest --prefer-stable
```

```bash
composer test
```

```bash
composer update
```

Stage `composer.json` and every file you fixed for a major, such as `src/`, `tests/` or `phpunit.xml`, by path:

```bash
git add composer.json src tests
```

```bash
git commit -m "Updated root Composer dependencies."
```

## Step 4: Root npm and BATS helpers

[npm-check-updates](https://github.com/raineorshine/npm-check-updates) rewrites `package.json` to the latest versions. `--enginesNode` limits it to versions that run on that file's `engines.node`, which is how the Node.js floor is kept. Without `-u` it only previews.

```bash
npx --yes npm-check-updates@latest --enginesNode -u
```

```bash
npm update --ignore-scripts
```

```bash
npm run lint
```

```bash
npm test
```

Then each BATS helper directory. `bats-helpers` is an npm alias (`npm:@drevops/bats-helpers@^2.0`), and npm-check-updates follows it; confirm with `npm view @drevops/bats-helpers version`:

```bash
npx --yes npm-check-updates@latest --cwd tests/bats --enginesNode -u
```

```bash
npm update --ignore-scripts --prefix tests/bats
```

```bash
./tests/bats/node_modules/.bin/bats tests/bats
```

Repeat npm-check-updates and `npm update` for `.scaffold/tests/bats`. `npm update` also moves transitive packages in each lock to the newest versions their ranges allow. Stage the manifests, the locks and every file you fixed for a major, such as `eslint.config.js`, `nodejs-script` or `tests/nodejs/`:

```bash
git add package.json eslint.config.js nodejs-script tests/nodejs tests/bats/package.json tests/bats/package-lock.json .scaffold/tests/bats/package.json .scaffold/tests/bats/package-lock.json
```

```bash
git commit -m "Updated root npm and BATS dependencies."
```

## Step 5: Docs sites

`docs/` and `.scaffold/docs/` carry the same dependencies, and they must stay identical. First compare `engines.node` in both docs files with the root `package.json`. When a docs value is lower, set it to the root value, so `--enginesNode` filters by the real floor instead of a stale one.

Update `.scaffold/docs` first:

```bash
npx --yes npm-check-updates@latest --cwd .scaffold/docs --enginesNode -u
```

Then copy its `dependencies`, `devDependencies` and `overrides` blocks into `docs/package.json` unchanged, leaving the `name`, `scripts` and `engines` of each file alone. Compare the 2 files; the only differences left should be the `name` and the `scripts`:

```bash
git diff --no-index docs/package.json .scaffold/docs/package.json
```

All `@docusaurus/*` packages move together. Some are pinned exactly (`3.10.2`) and some with a caret, so keep each one's style and give them all the same version.

npm-check-updates leaves `overrides` alone. Each one patches a vulnerable package that its parent pins to an old range, and a parent's new major can ship the fix. For each override, follow the check in "npm overrides" in `.scaffold/CLAUDE.md`: remove the override from both files, then run `npm install --package-lock-only --ignore-scripts` and `npm audit --package-lock-only` in each docs directory. Drop the override when the audit reports no advisory for its package. Otherwise restore it and raise its version to the newest fixed release, then update the table in `.scaffold/CLAUDE.md` to match.

Refresh both locks with `npm update`, which also moves transitive packages to the newest versions their ranges allow. Then build and test both sites the way `test-docs.yml` does:

```bash
npm update --ignore-scripts --prefix .scaffold/docs
```

```bash
npm run build --prefix .scaffold/docs
```

```bash
npm test --prefix .scaffold/docs
```

Repeat the 3 commands for `docs`. CI builds only `docs/` on pull requests, so the local build is the only check `.scaffold/docs` gets before a release. `npm test` also runs cspell, so a cspell major can flag new words; add them to the site's `cspell.json` rather than rewording. Commit both sites together:

```bash
git add docs/package.json docs/package-lock.json docs/cspell.json .scaffold/docs/package.json .scaffold/docs/package-lock.json .scaffold/docs/cspell.json .scaffold/CLAUDE.md
```

```bash
git commit -m "Updated documentation site dependencies."
```

## Step 6: Dockerfile

The base image is a floating major tag pinned to a digest: `alpine:3@sha256:...`. First check whether a newer major tag exists on Docker Hub (for example `alpine:4`); if it does, move the tag to it. Then read the current index digest for the tag:

```bash
docker buildx imagetools inspect alpine:3 --format "{{.Manifest.Digest}}"
```

Replace the digest after `@` in `Dockerfile`. Build and lint the image:

```bash
docker build -t yournamespace/yourdockerimage:test .
```

```bash
docker run --rm yournamespace/yourdockerimage:test
```

```bash
docker run --rm -v $PWD:/work -w /work hadolint/hadolint hadolint Dockerfile
```

Commit:

```bash
git add Dockerfile
```

```bash
git commit -m "Updated the Docker base image."
```

## Step 7: GitHub Actions

Every action is pinned to a commit SHA, which `WorkflowPolicyTest` requires, with the tag in a comment: `uses: actions/checkout@3d3c42e5... # v7`. List them:

```bash
grep -rhoE "uses: [^ ]+@[0-9a-f]{40} # v[0-9.]+" .github/workflows
```

For each distinct repository (`github/codeql-action/init` and `github/codeql-action/analyze` are both `github/codeql-action`), find the latest release tag:

```bash
gh api repos/actions/checkout/releases/latest --jq .tag_name
```

Keep the comment's precision. A major-only comment (`# v7`) moves to the newest major tag, so for a latest release of `v8.1.0` resolve `v8`. A full-version comment (`# v4.2.2`) moves to the full release tag. If the major tag doesn't exist, use the full tag and a full comment. Resolve the tag to its commit SHA (this dereferences annotated tags):

```bash
gh api repos/actions/checkout/commits/v8 --jq .sha
```

Replace every occurrence of the old `<sha> # <tag>` with the new pair in all workflow files, with the Edit tool and `replace_all`. For every major bump, read the action's release notes for renamed or removed inputs and update the `with:` blocks that use them.

Some steps start a tool image with `docker run` instead of `uses:`. List them:

```bash
grep -rn "docker run" .github/workflows
```

Skip `yournamespace/yourdockerimage`, which is the image the template builds. For each tool image, find the latest release with `gh api repos/<owner>/<repo>/releases/latest --jq .tag_name` (`rhysd/actionlint`, `semgrep/semgrep`) and set the image tag to it. An image pinned to a digest, such as `semgrep/semgrep:1.185.0@sha256:...`, also gets the new tag's digest:

```bash
docker buildx imagetools inspect semgrep/semgrep:1.190.0 --format "{{.Manifest.Digest}}"
```

Leave `php-version`, `node-version` and the version matrices alone; they're the support floor. Commit:

```bash
git add .github/workflows
```

```bash
git commit -m "Updated GitHub Actions."
```

## Step 8: Asset recorder

`.scaffold/assets/update-assets.php` installs svg-term on demand with a pinned version. Compare the pin with:

```bash
npm view svg-term version
```

If it's behind, update the pin and regenerate the recordings to prove the renderer still works. The script reuses any svg-term already in `.scaffold/assets/node_modules`, so remove that first or the old version renders:

```bash
rm -rf .scaffold/assets/node_modules
```

```bash
php .scaffold/assets/update-assets.php
```

A clean `git status` after the run means the rendering didn't change. The recorder needs `asciinema` and `expect`; when they aren't installed, update the pin anyway and say in the PR that the recordings weren't regenerated.

Commit the pin together with any re-rendered assets:

```bash
git add .scaffold/assets .scaffold/docs/static/img
```

```bash
git commit -m "Updated the svg-term recorder dependency."
```

## Step 9: Docs prose

A major bump can make prose wrong: `AGENTS.md` says "Tests should use PHPUnit 12 features", for example. For each package that changed major, search the docs for its name and old major, outside `node_modules`, `vendor` and the fixtures:

```bash
grep -rn --include=*.md --include=*.mdx -e "PHPUnit 12" . --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=fixtures
```

Update what you find, then stage the files you changed by path and commit:

```bash
git add AGENTS.md
```

```bash
git commit -m "Updated version references in the documentation."
```

## Step 10: Clean the root

Remove the root dependencies, so they don't leak into the init suite's sandbox:

```bash
composer reset
```

```bash
npm run reset
```

## Step 11: Fixtures and the init suite

Confirm `git status` is clean: every source change from Steps 2-9 must already be committed. The template files changed (`composer.json`, the locks, the workflows, the `Dockerfile`), so the fixtures are now stale. Regenerate them with the runner directly, because the `composer update-snapshots` script uses a 30-second timeout that the `php library` dataset exceeds, and the run stops there. The paths must be absolute. When Step 2 moved `alexskrypnyk/snapshot` to a new major, check the flags with `update-snapshots --help` first and adapt the command, and the `update-snapshots` script in that `composer.json`, to match:

```bash
/abs/path/to/repo/.scaffold/tests/phpunit/vendor/bin/update-snapshots --root=/abs/path/to/repo/.scaffold/tests/phpunit --test-dir=src --timeout=180 testInstall fixtures/install
```

It commits the fixtures as "Updated snapshots." itself. `✗` lines in its output mean a dataset was updated, not that it failed. If a scenario reports "Source file verification failed", its patch no longer applies to the new baseline: delete that scenario's stale patch file (never `_baseline`) and run again.

Then run the full init suite. It must pass:

```bash
composer test --working-dir=.scaffold/tests/phpunit
```

```bash
composer lint --working-dir=.scaffold/tests/phpunit
```

## Step 12: Report and open the PR

Open the PR with the `/open-pr` skill. Its description lists:

- The majors that moved, each with a 1-line note on what changed for the template.
- **Held back**: every package left below its latest version, with the reason: the support floor (which runtime it needs) or a break too large to fix in this run.
- **Support floor**: any runtime newer than the floor (a new PHP or Node.js release), as a suggestion for a separate change.

## When a major breaks

Fix it in the same run when the fix is contained: a config change, a renamed option, a handful of call sites or a deprecation the tool reports with its replacement. Commit the fix with the update it belongs to.

Hold it back when the fix means rewriting test infrastructure or touching most files of a suite. Put the constraint back on the previous major (`composer require --no-update vendor/package:^<old>`, or the old range in `package.json`), refresh the lock and list it under "Held back". File each held-back major as a follow-up issue.

## Common mistakes

| Mistake | What goes wrong |
|---|---|
| Applying `renovate.json` rules (minor only, 7-day cooldown) | The run does what Renovate already does and none of what it was asked for |
| Asking about each major before trying it | The maintainer asked for latest; try it, then fix or hold back |
| Raising `php`, `node` or a CI matrix | Drops users on supported runtimes; the floor is policy |
| Skipping `composer why-not php <floor>` | A package that needs a newer PHP passes locally and fails CI's lowest PHP leg |
| Skipping `composer bump` | CI's `lowest` leg tests the old constraint floors |
| Running the init suite with a root `composer.lock` present | The suite fails on "composer.lock does not exist" |
| Running `update-snapshots` with uncommitted sources | Its own commit lands ahead of the sources that produced the fixtures |
| Editing fixtures by hand | The baseline and the scenario patches disagree; always regenerate |
| Updating `docs/` and `.scaffold/docs/` separately | The 2 sites drift apart |
| Forgetting the `svg-term` pin, the action SHAs or the `docker run` images | They aren't in any manifest, so a manifest-only sweep misses them |
| Trusting the docs sites' `engines.node` | It can lag behind the root floor and hold back updates the template supports |

## Command pattern rules

Run 1 simple command per Bash call, so each matches the allowed permission prefixes. Don't use `&&`, `||`, `;`, `|`, `$(...)` or heredocs. Use `--working-dir` (Composer), `--prefix` (npm) and `--cwd` (npm-check-updates) instead of `cd`.
