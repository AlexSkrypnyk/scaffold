# PHPUnit tests for Scaffold

This suite tests the Scaffold template itself. It runs `init.sh` in each configuration and compares the result with the fixtures in this directory's `fixtures/init`. It also tests the Composer scripts in the root `composer.json` and the terminal recorder script in `.scaffold/assets`. Run it after every change to the repository, including the example app.

The suite needs PHP 8.3 or later with the `pcov` extension, because it runs the root `composer test-coverage` script in a copy of the template.

## Setup

To install the suite's dependencies, run the following commands from the repository root:

```bash
cd .scaffold/tests/phpunit
composer install
```

## Run the tests

To run every test, run the following command in `.scaffold/tests/phpunit`:

```bash
# Run all tests
composer test
```

In the same directory, `composer lint` checks the suite's own code with PHP_CodeSniffer, PHPStan and Rector. To update the fixtures after a change, see [Update the fixtures](../../../CONTRIBUTING.md#update-the-fixtures).
