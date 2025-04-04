# PHPUnit Tests for Scaffold

This directory contains PHPUnit tests for the Scaffold project.

## Setup

```bash
cd .scaffold/tests/phpunit
composer install
```

## Running tests

```bash
# Run all tests
composer test

# Run with coverage report
composer test-coverage
```

## Test structure

- `Functional/` - Functional tests for shell scripts
- `Helper/` - Helper classes for tests
- `Traits/` - Reusable test traits

## Notable components

### FixtureTrait

Provides methods to create and manage test fixtures:

- `fixtureInit()` - Initialize fixture directory
- `fixtureCopyRepository()` - Copy repository to fixture directory
- `fixtureCleanup()` - Clean up fixture directory
- `fixtureCreateFile()` - Create a file in the fixture directory

### ProcessTrait

Provides methods to run and test shell processes:

- `runProcess()` - Run a process with arguments and input
- `assertProcessSuccessful()` - Assert process was successful
- `assertProcessFailed()` - Assert process was not successful
- `assertProcessOutputContains()` - Assert process output contains a string
- `assertFileExists()` - Assert a file exists in the fixture directory
- etc.

### InitTestHelper

Helper class for init.sh tests with static methods to check file presence and contents:

- `assertFilesCommonPresent()` - Assert common files are present
- `assertFilesPhpPresent()` - Assert PHP files are present
- `assertFilesPhpAbsent()` - Assert PHP files are absent
- etc.
