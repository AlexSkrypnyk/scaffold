# Contributing

Thank you for considering a contribution to this project. Follow this guide to install the dependencies and run the same linters and tests that CI runs on your pull request. Run the section for each stack your change touches, from the repository root.

## PHP

Install the dependencies, then run the linters and the tests:

```bash
composer install
composer lint
composer test
```

To fix the PHP_CodeSniffer and Rector issues that the linters report, run `composer lint-fix`. To write a coverage report to `.logs/`, enable the PCOV or Xdebug extension and run `composer test-coverage`. Xdebug also needs `XDEBUG_MODE=coverage`.

## Node.js

Install the dependencies, then run the linters and the tests:

```bash
npm install
npm run lint
npm run test
```

To fix the ESLint and Prettier issues that the linters report, run `npm run lint-fix`. To write a coverage report to `.logs/`, run `npm run test-coverage`.

## Shell

The linters need [ShellCheck](https://www.shellcheck.net/) and [shfmt](https://github.com/mvdan/sh) on your `PATH`. Install the BATS test dependencies, then run the linters and the tests:

```bash
npm ci --prefix tests/bats
shellcheck force-crystal.sh tests/bats/*.bash tests/bats/*.bats
shfmt -i 2 -ci -s -d force-crystal.sh tests/bats/*.bash tests/bats/*.bats
./tests/bats/node_modules/.bin/bats tests/bats
```

To apply the formatting that shfmt reports, run the shfmt command with `-w` in place of `-d`.

## Documentation site

Install the documentation site's dependencies, build the site, then run its Jest tests and spell check:

```bash
npm --prefix docs install
npm --prefix docs run build
npm --prefix docs test
```

[`docs/README.md`](docs/README.md) shows how to preview the site locally.

## Submit a change

Follow these rules for every pull request:

- Open the pull request against `main`.
- Add tests with every feature and every bug fix. A test for a bug fix fails without the fix.
- Make every check on the pull request pass. The `main` branch ruleset blocks the merge until they do.

The checks come from these workflows:

- `Test PHP`
- `Test Node.js`
- `Test shell`
- `Test Docs`
- `Audit`, which scans the code with CodeQL

To report a security issue, follow [`SECURITY.md`](SECURITY.md) instead of opening a pull request.
