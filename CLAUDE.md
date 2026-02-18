# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

[//]: # (#;< META)

> **🚀 PROJECT MODE**: This guide helps with **developing custom projects**
> created from the Scaffold template.
>
> For **maintaining the Scaffold template itself**, see the maintenance guide:
`.scaffold/CLAUDE.md`

[//]: # (#;> META)

## Project Overview

This project was created from the scaffold template and provides a foundation
for Shell scripts, PHP CLI applications, and/or NodeJS projects with integrated
testing, code quality tools, and CI/CD workflows.

[//]: # (#;< PHP)

## PHP Application Architecture

[//]: # (#;< PHP_COMMAND)

### Symfony Console Application

Multi-command CLI application structure:

- **Location:** `src/Command/` directory
- **Entry point:** `php-command` (wraps `src/app.php`)
- **Use for:** Complex applications with multiple commands, shared logic, OOP
  architecture

### Adding New Commands

To add a Symfony Console command:

1. Create class in `src/Command/YourCommand.php` extending
   `Symfony\Component\Console\Command\Command`
2. Register in `src/app.php`: `$application->add(new YourCommand());`
3. Add functional test in `tests/phpunit/Functional/YourCommandTest.php`

[//]: # (#;> PHP_COMMAND)
[//]: # (#;< !PHP_COMMAND)

### Standalone Single-File Script

Single-file CLI script structure:

- **Location:** `php-script` file (or custom name)
- **Dependencies:** None - self-contained
- **Use for:** Simple utilities, deployment scripts, one-off tasks

### Environment Variables

- `SCRIPT_QUIET=1` - Suppress output (useful in tests)
- `SCRIPT_RUN_SKIP=1` - Skip execution (useful when requiring file)

### Testing Standalone Scripts

The script uses a testable pattern:

- Business logic in `main()` function
- Output via `verbose()` with internal buffer
- Set `SCRIPT_QUIET=1` in tests, then assert on `verbose()` return value

Example test:

```php
putenv('SCRIPT_QUIET=1');
putenv('SCRIPT_RUN_SKIP=1');
require 'php-script';
$output = main(['php-script', 'arg1'], 2);
$this->assertStringContainsString('expected', implode("\n", $output));
```

[//]: # (#;> !PHP_COMMAND)

### Namespace Structure

- Source code: `YourNamespace\App\`
- Tests: `YourNamespace\App\Tests\`
- Autoloading: PSR-4 via Composer

## Commands

### Code Quality

```bash
# Run all linters (PHPCS, PHPStan, Rector)
composer lint

# Auto-fix code style issues
composer lint-fix

# Individual tools
./vendor/bin/phpcs # Check coding standards
./vendor/bin/phpcbf # Fix coding standards
./vendor/bin/phpstan # Static analysis (level 9)
./vendor/bin/rector --dry-run # Check Rector suggestions
```

### Testing

```bash
# Run all PHPUnit tests (fast, no coverage)
composer test

# Run with coverage reports
composer test-coverage
# Coverage reports: .logs/.coverage-html/index.html, .logs/cobertura.xml

# Run specific test file
./vendor/bin/phpunit tests/phpunit/Functional/JokeCommandTest.php

# Run specific test method
./vendor/bin/phpunit --filter testMethodName
```

[//]: # (#;> PHP)
[//]: # (#;< SHELL)

```bash
# Shell script tests
./tests/bats/node_modules/bats/bin/bats tests/bats/
```

[//]: # (#;> SHELL)
[//]: # (#;< PHP)

### Building

[//]: # (#;< PHP_PHAR)

```bash
# Build PHAR executable (installs Box first)
composer build
```

[//]: # (#;> PHP_PHAR)

```bash
# Clean and reinstall dependencies
composer reset # removes vendor/, vendor-bin/, composer.lock
composer install
```

## Code Quality Standards

### Three-Layer Quality Stack

1. **PHP_CodeSniffer** - Drupal coding standards + strict types requirement
  - Config: `phpcs.xml`
  - Rules: Drupal standard, Generic.PHP.RequireStrictTypes
  - Relaxed rules in test files (long arrays, missing function docs)

2. **PHPStan** - Level 9 static analysis
  - Config: `phpstan.neon`
  - Ignores: Untyped iterables in tests/data providers

3. **Rector** - PHP 8.2/8.3 modernization + code quality
  - Config: `rector.php`
  - Sets: PHP_82, PHP_83, CODE_QUALITY, CODING_STYLE, DEAD_CODE,
    TYPE_DECLARATION

### Coding Conventions

- All PHP files must declare `strict_types=1`
- Use single quotes for strings (double quotes if containing single quote)
- All files must end with a newline character
- Local variables/method arguments: `snake_case`
- Method names/class properties: `camelCase`

## Testing Patterns

### PHPUnit Structure

- `tests/phpunit/Unit/` - Unit tests with mocks, no I/O
- `tests/phpunit/Functional/` - Integration tests, real file system
- `tests/phpunit/Traits/` - Shared test utilities

### Writing Tests

Tests should use PHPUnit 11 features:

- Coverage attributes: `#[CoversClass(ClassName::class)]`
- Test attributes: `#[Test]` (optional, using `test` prefix is also fine)
- Data providers: `#[DataProvider('providerMethodName')]`

[//]: # (#;> PHP)
[//]: # (#;< SHELL)

### Shell Script Testing with BATS

Shell script tests use BATS:

- Tests in `tests/bats/` with `.bats` extension
- Helper functions in `tests/bats/_helper.bash`
- Coverage exclusions: `# LCOV_EXCL_START` / `# LCOV_EXCL_END`

[//]: # (#;> SHELL)
[//]: # (#;< PHP)

## CI/CD

GitHub Actions workflows test across:

- PHP versions: 8.2, 8.3
- Separate jobs: lint, test, coverage upload (Codecov)

Key workflows:

- `.github/workflows/test-php.yml` - PHP testing
[//]: # (#;< PHP_PHAR)
- `.github/workflows/release-php.yml` - PHAR packaging and release
[//]: # (#;> PHP_PHAR)

[//]: # (#;> PHP)
[//]: # (#;< SHELL)

- `.github/workflows/test-shell.yml` - Shell script testing

[//]: # (#;> SHELL)
[//]: # (#;< NODEJS)

- `.github/workflows/test-nodejs.yml` - NodeJS testing

[//]: # (#;> NODEJS)
[//]: # (#;< DOCKER)

## Docker

### Building

```bash
# Build the Docker image
docker build -t yournamespace/yourproject .

# Run the container
docker run --rm yournamespace/yourproject
```

### Linting

```bash
# Lint Dockerfile with hadolint
docker run --rm -i hadolint/hadolint < Dockerfile
```

### CI/CD

- `.github/workflows/test-docker.yml` - Build and lint Docker image
- `.github/workflows/release-docker.yml` - Build and push multi-arch image to Docker Hub on tag

Docker Hub credentials are stored as repository secrets:
- `DOCKER_USER` - Docker Hub username
- `DOCKER_PASS` - Docker Hub access token

[//]: # (#;> DOCKER)

## Documentation

If using the documentation site (Docusaurus):

```bash
cd docs
npm install
npm start # Local dev server
npm run build # Production build
npm run spellcheck # CSpell validation
```

Documentation deploys automatically on releases via GitHub Actions.
