# CLAUDE.md - Scaffold Template Maintenance

This file provides guidance for **maintaining and developing the scaffold
template itself**, not for projects created from it.

> **⚠️ MAINTENANCE MODE**: This file contains guidance for **maintaining the Scafoold template itself**.
>
> For working with **custom projects created from this template**, see the main project guide: `../CLAUDE.md`

## Overview

This scaffold template provides a multi-stack project initialization system. It
contains working examples for Shell, PHP, and NodeJS projects that users
customize via `./init.sh`. The `.scaffold/` directory contains template-specific
infrastructure that gets removed after initialization.

## Template Architecture

### Initialization System (`init.sh`)

The initialization script performs three main operations:

1. **String Replacement** - Converts template placeholders:
  - `yournamespace` → User's namespace
  - `yourproject` → User's project name
  - `Your Name` → User's author name

2. **Feature Selection** - Enables/disables template features using token system

3. **Cleanup** - Removes `.scaffold/` directory and template-specific files

### Curl bootstrap

When `init.sh` runs without the template present (for example fetched and piped straight from `curl` into an empty directory), it downloads the Scaffold archive into the current directory, extracts it with `tar --strip-components=1`, and re-executes the on-disk copy so init proceeds normally. Presence of the `.scaffold/` directory is the sentinel for "template already here". The archive URL is resolved in precedence order: the `SCAFFOLD_ARCHIVE_URL` environment variable, the `--ref=<tag|branch|commit>` option, then the latest GitHub release (falling back to the `main` branch). The re-exec reconnects stdin to `/dev/tty` in interactive mode so prompts work despite the pipe, and bootstrapping refuses a non-empty directory. The curl-bootstrap PHPUnit tests (`testInitViaCurlBootstrapsIntoEmptyDir`, `testInitViaCurlBootstrapRefusesNonEmptyDir`) stay off the network by pointing `SCAFFOLD_ARCHIVE_URL` at a local `file://` tarball built from the SUT.

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

- `init.sh` calls `remove_tokens_with_content()` for disabled features
- Uses `sed` to delete lines between `#;< TOKEN` and `#;> TOKEN` markers
- Prefix `!` inverts the condition
- After removal, `remove_special_comments()` cleans up remaining `#;` markers

**Common tokens:**

- `PHP_COMMAND` - Symfony Console application features
- `PHP_SCRIPT` - Standalone script features
- `SHELL` - Shell script features
- `NODEJS` - NodeJS features
- `SCHEDULE` - Daily scheduled "is it buildable?" trigger in the test workflows

**Token usage locations:**

- `phpunit.xml` - Conditional coverage sources
- `phpcs.xml` - Conditional file scanning
- `phpstan.neon` - Conditional analysis paths
- `composer.json` - Conditional scripts/dependencies
- `.github/workflows/` - Conditional CI jobs

### String Conversion Functions

`init.sh` provides `convert_string()` for consistent naming:

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

## PHP Template Features

### Dual Implementation Pattern

The template provides two PHP patterns simultaneously:

1. **`src/` + `php-command`** - Symfony Console app
  - Multi-command structure
  - OOP architecture
  - Example commands: `JokeCommand`, `SayHelloCommand`

2. **`php-script`** - Standalone script
  - Zero dependencies
  - Self-contained bootstrap
  - Testable via `SCRIPT_RUN_SKIP=1`

**Key Challenge:** PHP_CodeSniffer cannot scan files without `.php` extension.

**Solution:** Temporary rename workaround in `composer.json`:

```json
"lint": [
"cp php-script php-script.php && phpcs; rm php-script.php"
]
```

Same pattern used in `phpcs.xml` (`<file>php-script.php</file>`).

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
  - Includes: TUI testing helpers, mocking system via `run_steps()`

### Rules for Template Changes

The init/template machinery has its OWN test suite in `.scaffold/tests/phpunit/`,
separate from the repo root, with its own `composer.json`, `phpcs.xml`,
`phpstan.neon`, and `vendor/`.

- **Run the suite that matches your change.** Repo-root `composer lint` /
  `composer test` cover ONLY the example application (`src/`, `tests/`) and pass
  even when the template is broken. A green root lint is NOT proof the init suite
  is green - any change to `init.sh`, template files, or fixtures must be
  validated from the init suite:

```bash
cd .scaffold/tests/phpunit
composer lint    # phpcs (Drupal standard), phpstan level 9, rector
composer test    # InitTest snapshot suite
```

- **Coding standard is Drupal.** Comment lines wrap at 80 characters
  (`Drupal.Files.LineLength.TooLong`); code lines have no length limit. Tests may
  omit parameter docblocks, but annotate any `mixed` value (e.g. a data-provider
  row) with `@param list<string>` so phpstan level 9 stays clean.

- **Shell scripts must pass `shfmt`.** The `Shell` and `Test Scaffold` CI jobs
  run `shfmt -i 2 -ci -s` (via `luizm/action-sh-checker`) over `init.sh` and the
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
- **Command Mocking** - `run_steps()` system mocks external commands
- **Fixture Exports** - `BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1`

Example from `tests/bats/shell-command.bats`:

```bash
@test "Mocked endpoint" {
  declare -a STEPS=(
    '@curl -sL https://api.example.com # [{"data":"mocked"}]'
  )
  mocks="$(run_steps "setup")"

  tui_run topic_name
  assert_success
  assert_output_contains "mocked"

  run_steps "assert" "${mocks[@]}"
}
```

### Init Script Testing with Fixtures

The `init.sh` script is tested in `.scaffold/tests/phpunit/` using a
**baseline + diff** fixture pattern similar to Vortex.

#### Fixture Structure

- **`fixtures/init/_baseline/`** - Full expected state after running `init.sh`
  with default answers
- **`fixtures/init/<test-name>/`** - Contains only DIFFERENCES (patches) from
  baseline for specific test scenarios
- **`.expected/`** - Stores the baseline state for comparison

#### Test Scenarios

Each test scenario in `InitTest.php` validates a specific configuration:

- `_baseline` - Default configuration (all features enabled)
- `name` - Custom namespace/project/author names
- `php_command`, `php_script`, `nodejs`, `shell` - Individual language
  selections
- `no_languages` - No languages selected
- Feature toggles: `no_release_drafter`, `no_pr_autoassign`, `no_funding`,
  `no_pr_template`, `no_renovate`, `no_docs`, `no_schedule`

#### Running Init Tests

```bash
cd .scaffold/tests/phpunit

# Run all init tests
composer test

# Run specific test scenario
./vendor/bin/phpunit --filter testInit
./vendor/bin/phpunit --filter 'testInit with data set "name"'
```

#### Updating Fixtures

**IMPORTANT:** Only update fixtures when you intentionally changed the
`init.sh` behavior or template files.

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

- After changing `init.sh` logic (string replacement, token removal)
- After modifying template files that `init.sh` processes
- After adding/removing conditional features
- After updating dependencies that affect generated files

**Workflow:**

1. Make changes to `init.sh` or template files
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

## Terminal recordings

The `init.sh` walkthrough shown in `README.md` and on the getscaffold.dev site
is a single asciinema recording rendered two ways by
`.scaffold/assets/update-assets.php`:

- `.scaffold/assets/init.svg` - an animated SVG embedded in `README.md`
  (GitHub renders animated SVG but cannot run JavaScript).
- `.scaffold/docs/static/img/init.cast` - an asciicast played by the
  `AsciinemaPlayer` component in `.scaffold/docs/content/README.mdx`.

Regenerate both after changing `init.sh` or its prompts:

```bash
php .scaffold/assets/update-assets.php
```

The generator records `./init.sh` against a disposable `git stash create` export
of the working tree, so it captures uncommitted `init.sh` changes and never
touches the real tree. It needs `asciinema`, `expect`, `node`, and `npm`;
svg-term is installed on demand into the git-ignored
`.scaffold/assets/node_modules`.

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
- `.github/workflows/scaffold-test.yml` - Integration test of `init.sh`

### GitHub Actions linting (`test-actions.yml`)

`test-actions.yml` runs three checks over `.github/workflows`: `yamllint`,
`actionlint`, and `zizmor` (GitHub Actions security static analysis, uploaded as
SARIF to the Security tab). Accepted zizmor findings are documented per-rule in
the repository-root `zizmor.yml`.

Unlike the other `scaffold-*` maintenance workflows, this one is a **selectable
consumer feature**: `init.sh` offers "Use GitHub Actions linting" (off by
default; `--test-actions` / `--no-test-actions` non-interactively). When not
selected, `init.sh` removes `test-actions.yml`, `.github/.yamllint-for-gha.yml`,
and `zizmor.yml`. The `scaffold-release-docs.yml` entry in `zizmor.yml` is
stripped on init because that workflow is template-only.

### Release Workflows

- `.github/workflows/release-php.yml` - Build and publish PHAR
- `.github/workflows/release-docs.yml` - Deploy documentation
- `.github/workflows/draft-release-notes.yml` - Auto-generate release notes

### Testing `init.sh`

The `scaffold-test.yml` workflow validates initialization:

1. Runs `init.sh` with test values
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
3. **Update `init.sh`**:
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
issues when files are concatenated or processed by init.sh.

## Maintenance Commands

```bash
# Reset and reinstall all dependencies
composer reset
composer install

# Update code quality tools (in vendor-bin/)
composer update --with-all-dependencies

# Rebuild PHAR after changes
composer build

# Test init.sh locally (creates test project)
./init.sh --namespace=TestProject --name=test-project --author="Test Author"
```

## Template Release Process

1. Update version references if needed
2. Run full test suite: `composer test && composer lint`
3. Merge to `main` branch
4. Create GitHub release (triggers PHAR build)
5. Release drafter automatically generates notes from PR labels
6. Documentation auto-deploys to GitHub Pages

## Key Differences from User Projects

When maintaining the template:

- **Test both template AND initialized projects** - Template tests run on
  scaffold itself; also test that `init.sh` produces working projects
- **Preserve token markers** - Don't accidentally remove `#;< TOKEN` markers
  when editing
- **Consider all stack combinations** - Features can be enabled/disabled
  independently
- **The `.scaffold/` directory is temporary** - Users never see it after
  initialization
