# CLAUDE.md - Scaffold Template Maintenance

This file provides guidance for **maintaining and developing the scaffold
template itself**, not for projects created from it.

> **⚠️ MAINTENANCE MODE**: This file contains guidance for **maintaining the Scaffold template itself**.
>
> For working with **custom projects created from this template**, see the main project guide: `../CLAUDE.md`

## Overview

This scaffold template provides a multi-stack project initialization system. It
contains working examples for Shell, PHP, and NodeJS projects that users
customize via `./install.sh`. The `.scaffold/` directory contains template-specific
infrastructure that gets removed after initialization.

## Template Architecture

### Initialization System (`install.sh`)

The initialization script performs three main operations:

1. **String Replacement** - Converts template placeholders:
  - `yournamespace` → User's namespace
  - `yourproject` → User's project name
  - `Your Name` → User's author name
  - `yournamespace/yourdockerimage` → Docker image name, used only in Docker
    references (Docker workflows, `DOCKER` blocks, Claude `docker` rules).
    It is a separate placeholder because the default image name equals the
    Composer package name, and both appear in the same files

2. **Feature Selection** - Enables/disables template features using token system

3. **Cleanup** - Removes `.scaffold/` directory and template-specific files

### Curl bootstrap

When `install.sh` runs without the template present (for example fetched and piped straight from `curl` into an empty directory), it downloads the Scaffold archive into the current directory, extracts it with `tar --strip-components=1`, and re-executes the on-disk copy so init proceeds normally. Presence of the `.scaffold/` directory is the sentinel for "template already here". The archive URL is resolved in precedence order: the `SCAFFOLD_ARCHIVE_URL` environment variable, the `--ref=<tag|branch|commit>` option, then the tag in `SCAFFOLD_VERSION` for a release installer, or the `main` branch for the `dev` installer. The re-exec reconnects stdin to `/dev/tty` in interactive mode so prompts work despite the pipe, and bootstrapping refuses a non-empty directory. The curl-bootstrap PHPUnit tests (`testInstallViaCurlBootstrapsIntoEmptyDir`, `testInstallViaCurlBootstrapRefusesNonEmptyDir`) stay off the network by pointing `SCAFFOLD_ARCHIVE_URL` at a local `file://` tarball built from the SUT.

### Token System for Conditional Content

Content blocks can be conditionally included/excluded using special tokens:

```xml
<!-- #;< TOKEN_NAME -->
  Content included when TOKEN_NAME feature is enabled
  <!-- #;> TOKEN_NAME -->

  <!-- #;< !TOKEN_NAME -->
  Content included when TOKEN_NAME feature is DISABLED (negation)
  <!-- #;> !TOKEN_NAME -->
```

**How it works:**

- `install.sh` calls `remove_tokens_with_content()` for disabled features
- Uses `sed` to delete lines between `#;< TOKEN` and `#;> TOKEN` markers
- Removal prefix-matches token names (removing `AI` also removes `AI_ARCH_DOCS*` blocks), so blocks of the same token family must be siblings, never nested
- Prefix `!` inverts the condition
- After removal, `remove_special_comments()` cleans up remaining `#;` markers

**Common tokens:**

- `PHP_COMMAND` - Symfony Console application features
- `PHP_SCRIPT` - Standalone script features
- `PHP_LIBRARY` - Class-library features, selected by declining both PHP entry
  points; `!PHP_SCRIPT` marks what the command app and the library share (the
  `src` directory), `!PHP_LIBRARY` what the two entry points share
- `PHP_PHAR` - PHAR packaging. `composer.json` can't carry markers, so
  `remove_php_command_build()` also deletes the Box `build` script, the
  `bamarni/composer-bin-plugin` requirement and its `allow-plugins` entry, and
  `vendor-bin` from the `reset` script
- `PHP_RELEASE` - Documentation of `release-php.yml`, which exists only to attach
  an asset to a tag. `remove_php_release()` deletes the workflow, its `zizmor.yml`
  suppression entries and these blocks for the two modes that release no asset: a
  class library, and a command app built without a PHAR
- `SHELL` - Shell script features
- `NODEJS` - NodeJS features
- `SCHEDULE` - Daily scheduled "is it buildable?" trigger in the test workflows
- `WINDOWS` - The `windows-latest` matrix entries and Windows-only steps in the
  PHP, Node.js and Shell test workflows, removed by `remove_windows()` unless
  `--windows` is passed (off by default)
- `AUDIT` - Documentation of the `audit.yml` security audit workflow, removed
  with the workflow by `remove_audit()`. When neither Node.js nor the docs
  site is selected, `process_audit()` drops `javascript-typescript` from the
  CodeQL `languages` line, because CodeQL fails on a language with no source
  files
- `DOCS` - Documentation-site content outside `docs/`, such as the docs section
  of `CONTRIBUTING.dist.md`, removed by `remove_docs()`
- `AI` - AI agents configuration (`CLAUDE.md`, `AGENTS.md`, `.claude/`)
- `AI_ARCH_DOCS` - AI architecture documentation in `docs/content/architecture/` (relocated to `docs/architecture/` by `remove_docs()` when the docs site is disabled, with path references rewritten)
- `AI_ARCH_DOCS_MERMAID` - Mermaid-specific sections of the `update-architecture-docs` skill
- `AI_ARCH_DOCS_PLANTUML` - PlantUML-specific sections of the `update-architecture-docs` skill

**Token usage locations:**

- `phpunit.xml` - Conditional coverage sources
- `phpcs.xml` - Conditional file scanning
- `phpstan.neon` - Conditional analysis paths
- `composer.json` - Conditional scripts/dependencies
- `.github/workflows/` - Conditional CI jobs

### String Conversion Functions

`install.sh` provides `convert_string()` for consistent naming:

- `namespace` / `class_name` - PascalCase for PHP classes
- `package_name` - kebab-case for package identifiers
- `package_namespace` - lowercase, no hyphens
- `file_name` - snake_case for files
- `function_name` / `cli_command` - snake_case

### Template Replacement Functions

- `replace_string_content()` - Global find/replace across all files
- `remove_string_content()` - Remove lines starting with token
- `remove_string_content_line()` - Remove lines containing token
- `uncomment_line()` - Activate commented configuration

### Sweep scope and the `.claude` allowlist

Five helpers sweep the project for a needle and edit whatever they find:
`replace_string_content()`, `remove_string_content()`,
`remove_string_content_line()`, `remove_tokens_with_content()` and
`remove_special_comments()`. All five get their file list from `sweep_files()`.
(`uncomment_line()` is not one of them - it edits the single file named in its
argument.) `sweep_files()` searches the project root recursively, skipping
`.git`, `.idea`, `.claude`, `vendor` and `node_modules`, then searches the
template-owned `.claude` paths explicitly:

- `.claude/settings.json`
- `.claude/skills/update-architecture-docs`

`.claude` needs that split because it is the one directory holding both
template-owned and consumer-owned files. The `update-consumer-scaffold` skill
carries the consumer's `.claude` across its clean-the-root step and then extracts
a fresh template on top, so `install.sh` runs over a merged tree. Sweeping the whole
of `.claude` rewrites the consumer's own skills, agents and local settings -
including the fetched copy of the update skill, which then names the consumer's
repository and makes the next update pull the wrong project. Excluding the whole
of `.claude` instead strands the `AI_ARCH_DOCS_MERMAID` / `AI_ARCH_DOCS_PLANTUML`
blocks in the shipped `update-architecture-docs` skill.

**Shipping a new file under `.claude` means adding its path to `sweep_files()`.**
`testInstallProcessesShippedClaudeFiles` fails when a shipped `.claude` file keeps a
`#;` marker or an unsubstituted placeholder, and
`testInstallPreservesConsumerClaudeFiles` fails when a consumer-owned `.claude` file
is modified at all.

## PHP Template Features

### PHP Modes

The template carries every PHP pattern at once and `install.sh` keeps the selected
one:

1. **`src/` + `bin/php-command`** - Symfony Console app
  - Multi-command structure
  - OOP architecture
  - Example commands: `RollDiceCommand`, `SayHelloCommand`

2. **`php-script`** - Standalone script
  - Zero dependencies
  - Self-contained bootstrap
  - Testable via `SCRIPT_RUN_SKIP=1`

3. **`src/Example.php`** - Class library
  - Selected by declining both entry points (`--no-php-command
    --no-php-script`, or "n" to both prompts)
  - Ships the tooling with no entry point: `process_php_library()` drops the
    `bin` section from `composer.json`
  - Disables Renovate updates to `require` in the root `composer.json`
    (`disable_renovate_require_updates()`), since those constraints are the
    package's public contract and there is no committed lock to refresh
  - Keeps one placeholder class and its unit test, because PHPCS and PHPStan
    both error out when pointed at a project holding no PHP file
  - The other two modes drop that pair in `remove_php_library()`

`php-script` and `bin/php-command` have no `.php` extension, so `phpcs.xml`,
`phpstan.neon` and `rector.php` list them by name inside `PHP_SCRIPT` and
`PHP_COMMAND` token blocks. Each tool checks a file named explicitly whatever
its extension.

## Testing the Template

### Template Test Types

1. **Unit Tests** - Test individual functions/classes
  - Location: `tests/phpunit/Unit/`
  - Purpose: Validate business logic

2. **Functional Tests** - Test commands end-to-end
  - Location: `tests/phpunit/Functional/`
  - Purpose: Validate CLI behavior, outputs

3. **BATS Tests** - Test shell scripts
  - Location: `tests/bats/`
  - Purpose: Validate `shell-command.sh` functionality
  - Includes: TUI testing helpers, mocking system via `steps_run()`

### Rules for Template Changes

The init/template machinery has its OWN test suite in `.scaffold/tests/phpunit/`,
separate from the repo root, with its own `composer.json`, `phpcs.xml`,
`phpstan.neon`, and `vendor/`.

- **Run the suite that matches your change.** Repo-root `composer lint` /
  `composer test` cover ONLY the example application (`src/`, `tests/`) and pass
  even when the template is broken. A green root lint is NOT proof the init suite
  is green - any change to `install.sh`, template files, or fixtures must be
  validated from the init suite:

```bash
cd .scaffold/tests/phpunit
composer lint    # phpcs (Drupal standard), phpstan level 9, rector
composer test    # InstallTest snapshot suite
```

- **Coding standard is Drupal.** Comment lines wrap at 80 characters
  (`Drupal.Files.LineLength.TooLong`); code lines have no length limit. Tests may
  omit parameter docblocks, but annotate any `mixed` value (e.g. a data-provider
  row) with `@param list<string>` so phpstan level 9 stays clean.

- **Shell scripts must pass `shfmt`.** The `Shell` and `Test Scaffold` CI jobs
  run `shfmt -i 2 -ci -s` (via `luizm/action-sh-checker`) over `install.sh` and the
  `*.sh` / `.bats` files, and it is strict about redirect spacing (`>"$f"`, not
  `> "$f"`). Format shell edits to match before pushing.

- **Use the maintainer helper libraries, never Symfony or raw PHP.** File work
  goes through `alexskrypnyk/file` (`File::copyIfExists()`, `File::dir()`,
  `File::exists()`, `File::dump()`, `File::remove()`, ...); test scaffolding
  comes from `alexskrypnyk/phpunit-helpers` traits on `UnitTestCase`
  (`LocationsTrait` -> `locationsCopy()` / `self::$sut`; `ProcessTrait` ->
  `processRun()` / `assertProcess*()`; `TuiTrait` for interactive prompts) and
  `alexskrypnyk/snapshot` (`SnapshotTrait`, `update-snapshots`).

- **After changing template files, regenerate fixtures** with
  `composer update-snapshots` from `.scaffold/tests/phpunit` (see "Updating
  Fixtures"). It auto-commits the regenerated fixtures itself, so review the diff
  before running it.

- **Gotcha: a global gitignore of `.claude` / `.artifacts` silently drops fixture
  dirs.** Fixture scenarios ship `.claude/settings.json`; an unanchored
  `~/.gitignore` `.claude` rule makes `git add` skip them with no error.
  `fixtures/.gitignore` carries a `!.claude/` negation to override it - keep it,
  and confirm staged files with `git ls-files --others --exclude-standard`.

### Running Template Tests

```bash
# PHP tests (runs tests in CURRENT scaffold state)
composer test
composer test-coverage

# Shell tests
./tests/bats/node_modules/bats/bin/bats tests/bats/

# Test specific BATS tests with tags
./tests/bats/node_modules/bats/bin/bats --filter-tags smoke tests/bats/
```

### BATS Testing Features

The scaffold includes advanced BATS testing utilities:

- **TUI Testing** - `tui_run()` function simulates interactive input
- **Command Mocking** - `steps_run()` system mocks external commands
- **Fixture Exports** - `BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1`

Example from `tests/bats/shell-command.bats`:

```bash
@test "Die can be rolled with user input" {
  tui_run 6 y
  assert_success
  assert_output_contains "Rolling a 6-sided die..."
  assert_output_contains "Rolled: "
}
```

The example script makes no external calls, so `shell-command.bats` has no
`steps_run()` mock. A script that calls an external command mocks it like this:

```bash
@test "Mocked endpoint" {
  declare -a STEPS=(
    '@curl -sL https://api.example.com # [{"data":"mocked"}]'
  )
  mocks="$(steps_run "setup")"

  tui_run
  assert_success
  assert_output_contains "mocked"

  steps_run "assert" "${mocks[@]}"
}
```

### Init Script Testing with Fixtures

The `install.sh` script is tested in `.scaffold/tests/phpunit/` using a
**baseline + diff** fixture pattern similar to Vortex.

#### Fixture Structure

- **`fixtures/install/_baseline/`** - Full expected state after running `install.sh`
  with default answers
- **`fixtures/install/<test-name>/`** - Contains only DIFFERENCES (patches) from
  baseline for specific test scenarios
- **`.expected/`** - Stores the baseline state for comparison

#### Test Scenarios

Each test scenario in `InstallTest.php` validates a specific configuration:

- `_baseline` - Default configuration (all features enabled)
- `name` - Custom namespace/project/author names
- `php_command`, `php_script`, `php_library`, `nodejs`, `shell` - Individual
  language selections
- `no_languages` - No languages selected
- `docker`, `docker_custom_image_name` - Docker enabled, with the default and
  a custom image name
- Feature toggles: `no_release_drafter`, `no_pr_autoassign`, `no_funding`,
  `no_pr_template`, `no_renovate`, `no_docs`, `no_schedule`, `no_phar`,
  `windows`, `no_audit`
- AI options: `no_ai`, `ai_arch_docs_plantuml`, `no_ai_arch_docs`, `no_docs_no_ai_arch_docs`

#### Running Init Tests

```bash
cd .scaffold/tests/phpunit

# Run all init tests
composer test

# Run specific test scenario
./vendor/bin/phpunit --filter testInstall
./vendor/bin/phpunit --filter 'testInstall with data set "name"'
```

#### Updating Fixtures

**IMPORTANT:** Only update fixtures when you intentionally changed the
`install.sh` behavior or template files.

```bash
cd .scaffold/tests/phpunit

# Regenerate the baseline and all diff fixtures (test scenarios).
composer update-snapshots
```

**How fixture updates work:**

1. Tests run and detect differences between actual output and expected fixtures
2. `UPDATE_FIXTURES=1` environment variable triggers automatic fixture updates
3. For baseline tests: syncs entire result to `_baseline/` directory
4. For diff tests: generates patches showing only differences from baseline
5. Version numbers, hashes, and integrity strings are normalized to prevent
   fixture churn

**When to update fixtures:**

- After changing `install.sh` logic (string replacement, token removal)
- After modifying template files that `install.sh` processes
- After adding/removing conditional features
- After updating dependencies that affect generated files

**Workflow:**

1. Make changes to `install.sh` or template files
2. Run tests: `composer test` (will fail with "Differences between directories")
3. Review the differences carefully
4. If changes are correct: `composer update-snapshots`
5. Verify updated fixtures with: `composer test`
6. Commit updated fixtures with your changes

## Template Documentation Testing

The `docs/` directory contains a Docusaurus site that documents the scaffold
itself.

**Important:** This is documentation ABOUT the scaffold template, not for
projects created from it.

```bash
cd docs
npm install
npm test # Jest tests for React components
npm run spellcheck # CSpell validation
npm run build # Build static site
```

### npm overrides

`docs/package.json` and `.scaffold/docs/package.json` carry the same 5 `overrides`. Each one replaces a vulnerable package that its parent, at its latest release, still pins to a range without the fix:

| Override | Parent's range | Runs in |
|---|---|---|
| `@docusaurus/core` > `tinypool` `^2.1.2` | `^1.0.2` | Every build |
| `copy-webpack-plugin` > `serialize-javascript` `^7.1.3` | `^6.0.0` | Every build |
| `css-minimizer-webpack-plugin` > `serialize-javascript` `^7.1.3` | `^6.0.1` | Every build |
| `sockjs` > `uuid` `^11.1.1` | `^8.3.2` | Nothing by default: the dev server uses `ws` |
| `@ai-sdk/provider-utils` > `undici` `^7.30.2` | `^5.29.0` | Nothing: both sites search with `@easyops-cn/docusaurus-search-local`, so DocSearch stays inactive |

Renovate updates the parents but leaves the overrides in place. To check whether an override is still needed, remove it in both files, then run `npm install --package-lock-only --ignore-scripts` and `npm audit --package-lock-only` in each docs directory. Drop the override when the audit reports no advisory for its package.

## Terminal recordings

The `install.sh` walkthroughs shown in `README.md` and on the getscaffold.dev site
are 3 asciinema recordings, each rendered two ways by
`.scaffold/assets/update-assets.php`:

- `install` declines the **Create a GitHub repository** prompt.
- `install-github` accepts it and walks through repository creation, the
  settings and the CI wait.
- `github` runs `./install.sh github` in an existing project, a git repository
  whose `origin` remote names a repository the `gh` stand-in reports as
  existing, and applies every section.

Each recording produces:

- `.scaffold/assets/<name>.svg` - an animated SVG embedded in `README.md`
  (GitHub renders animated SVG but cannot run JavaScript).
- `.scaffold/docs/static/img/<name>.cast` - an asciicast played by the
  `AsciinemaPlayer` component in `.scaffold/docs/content/README.mdx` and
  `.scaffold/docs/content/github.mdx`.

The recorded shell puts `.scaffold/assets/record-bin/` first on `PATH`. Its
`gh` stand-in answers every call the GitHub step makes, and its `git` wrapper
turns `push` into a no-op, so no recording reaches GitHub. A new `gh` call
in `install.sh` needs a matching case in the stand-in, or the recording shows
the call failing.

Regenerate all 3 after changing `install.sh` or its prompts:

```bash
php .scaffold/assets/update-assets.php
```

The generator records `./install.sh` against a disposable `git stash create` export
of the working tree, so it captures uncommitted `install.sh` changes and never
touches the real tree. It needs `asciinema`, `expect`, `node`, and `npm`;
svg-term is installed on demand into the git-ignored
`.scaffold/assets/node_modules`.

Regeneration is reproducible: recording an unchanged session produces the same
bytes, so `git status` after a regeneration is the check - a clean tree means
the rendering did not change. The expect script writes an invisible marker
before each answer, and `canonicalizeCast()` cuts the recorded output into 1
event per step at those markers, spaced `STEP_DELAY` apart. The recorded
timing and the terminal's chunking never reach the committed files. Any output
that varies between runs (a progress meter, a timestamp) breaks this, so keep
`install.sh`'s interactive output deterministic.

The pure cast helpers are unit-tested in
`.scaffold/tests/phpunit/src/UpdateAssetsTest.php`, which also guards that the
`AsciinemaPlayer` component stays byte-identical between `docs/` and
`.scaffold/docs/`.

## CI/CD for the Template

GitHub Actions workflows test the **scaffold template itself**:

### Test Workflows

- `.github/workflows/test-php.yml` - Validate PHP components
- `.github/workflows/test-shell.yml` - Validate shell scripts
- `.github/workflows/test-nodejs.yml` - Validate NodeJS components
- `.github/workflows/test-docs.yml` - Validate documentation site
- `.github/workflows/test-actions.yml` - Lint workflow files (yamllint,
  actionlint) and audit them for security with zizmor
- `.github/workflows/scaffold-test.yml` - Integration test of `install.sh`

### GitHub Actions linting (`test-actions.yml`)

`test-actions.yml` runs three checks over `.github/workflows`: `yamllint`,
`actionlint`, and `zizmor` (GitHub Actions security static analysis, uploaded as
SARIF to the Security tab). Accepted zizmor findings are documented per-rule in
the repository-root `zizmor.yml`.

`.scaffold/tests/phpunit/src/WorkflowPolicyTest.php` parses every workflow of
the template and of a generated project with every workflow selected. It fails
when a workflow lacks top-level `permissions: {}`, a job declares no
`permissions`, an action isn't pinned to a commit SHA, `actions/checkout`
lacks `persist-credentials: false`, an npm install lacks `--ignore-scripts`
or a Composer install or update lacks `--no-scripts`.

Unlike the other `scaffold-*` maintenance workflows, this one is a **selectable
consumer feature**: `install.sh` offers "Use GitHub Actions linting" (off by
default; `--test-actions` / `--no-test-actions` non-interactively). When not
selected, `install.sh` removes `test-actions.yml`, `.github/.yamllint-for-gha.yml`
and `zizmor.yml`. The `scaffold-release-docs.yml` entry in `zizmor.yml` is
stripped on init because that workflow is template-only.

### Release Workflows

- `.github/workflows/release-php.yml` - Build and publish PHAR
- `.github/workflows/release-docs.yml` - Deploy documentation
- `.github/workflows/draft-release-notes.yml` - Auto-generate release notes
- `.github/workflows/scaffold-release-installer.yml` - Attach the signed and
  attested installer to the draft release of a pushed tag, then publish it
- `.github/workflows/scaffold-release-docs.yml` - Deploy getscaffold.dev on a tag

`install.sh` removes every `.github/workflows/scaffold-*.yml` from a generated
project, so a workflow for the template alone takes the `scaffold-` prefix.

### Installer releases

getscaffold.dev/install.sh and /init.sh serve the `install.sh` attached to the latest release, so a release build of the docs site holds no `install.sh` or `init.sh`. `.scaffold/docs/scripts/copy-installer.js` removes both when `RELEASE_VERSION` is set, and `scaffold-release-docs.yml` fails when either is in the build. Every other build copies the repository-root `install.sh` to both paths, so the Netlify development site (`scaffold-docs.netlify.app`, the `main` branch) and local builds serve the `dev` installer.

`scaffold-release-installer.yml` runs when a version tag is pushed:

1. Checks that the tag is a version on `main`, then stamps `SCAFFOLD_VERSION="dev"` in `install.sh` with the tag.
2. Pipes the stamped installer into `bash` in an empty directory, so it bootstraps and initializes the tag's template.
3. Writes `SHA256SUMS` and signs it as `SHA256SUMS.asc` with `GPG_PRIVATE_KEY`, and `GPG_PASSPHRASE` when the key has one. Both are secrets of the `release` environment.
4. Checks the signature against `install-key.asc` and its pinned fingerprint with `.scaffold/installer/verify-release.sh`.
5. Attests `install.sh` and `SHA256SUMS`, and saves the attestation bundle as `scaffold-installer-TAG.intoto.jsonl`.
6. Waits for the tag's `Release PHP` run, which attaches its assets to the draft release. Then it uploads the 4 installer files to the draft, publishes the release and verifies the uploaded copies.
7. For the latest release, checks that `releases/latest/download/install.sh`, getscaffold.dev/install.sh and getscaffold.dev/init.sh all serve the uploaded installer.

Steps 1-5 run in the `build` job, which reads the repository only. Steps 6-7 run in the `publish` job, which writes the release.

Publish a release only by pushing its tag. A release published with the **Publish release** button gets the installer only while releases are mutable. On an immutable release, `Release PHP` and this workflow both fail, and the fix is a new version with a tag push. A re-run on a published release that already holds the same `install.sh` succeeds without uploading. The workflow also rejects a tag whose installer has no `SCAFFOLD_VERSION="dev"` line.

Push 1 version tag at a time. The `publish` jobs share the `scaffold-release` concurrency group, which keeps 1 run waiting and cancels the one it replaces. Re-run a canceled `Publish Scaffold release` job.

`install-key.asc` in the repository root is the public half of the `Scaffold Release Signing` key, fingerprint `86F0 77A2 E806 67D7 CF4A 3320 EDEA F2FC D434 756C`. It expires on 2028-11-08. `process_internal()` removes it from generated projects.

To extend the key before it expires, run `gpg --quick-set-expire 86F077A2E80667D7CF4A3320EDEAF2FCD434756C 2y`, then export the public half again. The fingerprint stays the same:

```bash
gpg --armor --output install-key.asc --export 86F077A2E80667D7CF4A3320EDEAF2FCD434756C
```

A new key needs a new `install-key.asc`, the new fingerprint in `verify-release.sh` and in the "Verify the installer" section of `.scaffold/docs/content/README.mdx`, and a note in the release notes.

To give the workflow the signing key, create the `release` environment, then store the private key and its passphrase there:

```bash
gh api -X PUT repos/AlexSkrypnyk/scaffold/environments/release
gpg --armor --export-secret-keys 86F077A2E80667D7CF4A3320EDEAF2FCD434756C | gh secret set GPG_PRIVATE_KEY --env release --repo AlexSkrypnyk/scaffold
gh secret set GPG_PASSPHRASE --env release --repo AlexSkrypnyk/scaffold
```

### Testing `install.sh`

The `scaffold-test.yml` workflow validates initialization:

1. Runs `install.sh` with test values
2. Verifies string replacements
3. Confirms token removal
4. Tests that generated project passes linting/tests

## Adding New Template Features

### Adding a New Stack (e.g., Python)

1. **Add source files** with working example code
2. **Add token markers** in config files:
   ```yaml
   # #;< PYTHON
   python-specific-config
   # #;> PYTHON
   ```
3. **Update `install.sh`**:
  - Add feature selection prompt
  - Call `remove_tokens_with_content "PYTHON"` if disabled
4. **Add CI workflow** `.github/workflows/test-python.yml`
5. **Add tests** for the example Python code
6. **Update documentation** in `docs/`

### Adding Conditional Dependencies

In `composer.json`:

```json
{
  "require-dev": {
    "#;< FEATURE": true,
    "vendor/package": "^1.0",
    "#;> FEATURE": true
  }
}
```

Note: This requires careful handling as JSON comments aren't valid. Use in
scripts section instead.

### Adding Conditional CI Jobs

In `.github/workflows/`:

```yaml
# #;< FEATURE
- name: Feature-specific job
  run: composer feature-command
# #;> FEATURE
```

## File Ending Requirements

**Critical:** All template files must end with a newline character.

This matches `.editorconfig` setting `insert_final_newline = true` and prevents
issues when files are concatenated or processed by install.sh.

## Maintenance Commands

```bash
# Reset and reinstall all dependencies
composer reset
composer install

# Update code quality tools (in vendor-bin/)
composer update --with-all-dependencies

# Rebuild PHAR after changes
composer build

# Test install.sh locally (creates test project)
./install.sh --namespace=TestProject --name=test-project --author="Test Author"
```

## Template Release Process

1. Update version references if needed
2. Run full test suite: `composer test && composer lint`
3. Merge to `main`. Release Drafter keeps a draft release with notes from the PR labels.
4. Push a version tag from `main`, such as `git tag 1.2.3` and then `git push origin 1.2.3`.
5. `Release PHP` attaches the PHAR and the PHP script to the draft. `Release Scaffold installer` then attaches the installer files and publishes the release.
6. `Release Scaffold docs` deploys getscaffold.dev to GitHub Pages from the tag, in parallel with the release workflows.

## Key Differences from User Projects

When maintaining the template:

- **Test both template AND initialized projects** - Template tests run on
  scaffold itself; also test that `install.sh` produces working projects
- **Preserve token markers** - Don't accidentally remove `#;< TOKEN` markers
  when editing
- **Consider all stack combinations** - Features can be enabled/disabled
  independently
- **The `.scaffold/` directory is temporary** - Users never see it after
  initialization
