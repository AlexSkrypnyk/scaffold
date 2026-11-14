# Contributing

Contributions to Scaffold are welcome. Follow this guide to run the checks that cover your change before you open a pull request.

Scaffold is a multi-stack project template. The `.scaffold/` directory holds the template's own infrastructure, and [`install.sh`](install.sh) removes it from generated projects. Before you change template files, read the maintenance guide in [`.scaffold/CLAUDE.md`](.scaffold/CLAUDE.md). It documents the template architecture, the `install.sh` token system and the test and fixture workflow.

## Before you begin

Make sure you have the following:

- PHP 8.3 or later with the `pcov` extension
- Composer 2.10.3 or later
- Node.js 20.20.1 or later, with npm

## Local development

The example app is the code at the repository root that `install.sh` turns into a generated project. To test it, run the following commands from the repository root:

```bash
composer install
composer lint
composer test
```

The example app also holds NodeJS and shell code. [`CONTRIBUTING.dist.md`](CONTRIBUTING.dist.md) lists the lint and test commands for every stack.

The template suite runs `install.sh` and compares its output with fixtures that hold the generated example app. The root suite can pass even when the template is broken, so run the template suite from the repository root for every change:

```bash
cd .scaffold/tests/phpunit
composer install
composer lint
composer test
```

For a change to `install.sh`, also run its BATS unit tests in `.scaffold/tests/bats`. Run the following commands from the repository root:

```bash
npm --prefix=.scaffold/tests/bats ci
./.scaffold/tests/bats/node_modules/.bin/bats .scaffold/tests/bats
```

For a change to the getscaffold.dev pages in `.scaffold/docs`, follow [`.scaffold/docs/README.md`](.scaffold/docs/README.md) to build the site and run its tests.

### Update the fixtures

The fixtures live in `.scaffold/tests/phpunit/fixtures/install`. When a change alters the `install.sh` output, the template suite fails with `Differences between directories`. To update the fixtures:

1. Review the differences, and confirm that each one comes from your change.
2. Unstage any other work. `composer update-snapshots` commits everything staged, together with the regenerated fixtures.
3. From the repository root, regenerate the fixtures:

   ```bash
   cd .scaffold/tests/phpunit
   composer update-snapshots
   ```

4. In `.scaffold/tests/phpunit`, run `composer test` again. Confirm that every test passes.

## Submit a change

Every change reaches `main` through a pull request. The pull request merges after its required checks pass and its branch is up to date with `main`.

1. Fork the repository, or create a branch if you have write access.
2. Make your change. Add or update tests for every new feature and every bug fix, in the suite that covers the code you changed.
3. Run the lint and test commands from [Local development](#local-development) for every suite your change touches. The linters check the coding standard. Confirm that each command exits with code `0`.
4. Open a pull request against `main`, and fill in the pull request template.
5. Confirm that the required checks pass. The `main` ruleset requires the following checks:

   | Area | Checks |
   |---|---|
   | PHP | `PHP VERSION, Deps lowest, OS` and `PHP VERSION, Deps normal, OS` for PHP 8.3, 8.4 and 8.5 on `ubuntu-latest` and `windows-latest` |
   | PHAR | `Build PHAR` |
   | Shell | `Shell, ubuntu-latest`, `Shell, ubuntu-24.04`, `Shell, macos-latest`, `Shell, macos-15` and `Shell, windows-latest` |
   | Node.js | `Node.js VERSION, OS` for Node.js 20, 22 and 24 on `ubuntu-latest` and `windows-latest` |
   | Docker | `Docker` |
   | Documentation | `Test documentation` and `Test Scaffold documentation` |
   | Workflows | `Test Actions` |
   | Template | `Test Scaffold` |
