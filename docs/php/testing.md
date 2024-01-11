---
title: Testing
layout: default
parent: PHP
nav_order: 5
---

# Testing

This template provides PHPUnit 10 configuration and example tests for your
project.

## PHPUnit

[PHPUnit](https://phpunit.de/) is a widely used testing framework for PHP
applications. It provides an extensive set of tools to create unit tests,
perform assertions, and generate test reports. By integrating PHPUnit into your
development workflow, you can ensure that your code remains robust and
error-free as it evolves. It is an essential tool for anyone aiming to maintain
high code quality and adhere to best practices in PHP development.

This template includes a [phpunit.xml](https://github.com/AlexSkrypnyk/scaffold/blob/main/phpunit.xml)
file with some sensible defaults to get you started.

Some of the features include:

- Orders test execution based on dependencies and defects.
- Strict about output during tests.
- Fails on risky tests and warnings.
- Displays detailed information on tests that trigger warnings, errors, and notices.
- Restricts deprecations, notices, and warnings from the code.
- Provides coverage generation configuration.

Running the following command will execute all the tests:

```bash
composer test
```

To exacute a specific test tagged with a `@group wip`, use the following command:

```bash
composer test -- --group=wip
```

## Namespaces

The tests are automatically loaded using Composer's autoloader by specifying
the `YourNamespace\App\Tests\` namespace in the `autoload-dev` section of the
`composer.json` file.

You would need to update the namespace in tests and `composer.json` to match
your project's namespace.

## Coverage

The template is configured to generate code coverage reports in HTML and
Cobertura formats (`cuberatura.xml`).

Here are some of the coverage settings specified in the [phpunit.xml](https://github.com/AlexSkrypnyk/scaffold/blob/main/phpunit.xml) file:
- Requires coverage metadata but is not strict about it.
- Includes uncovered files in the code coverage report.
- Does not use path-based code coverage.
- Ignores deprecated code units in the code coverage.
- Generates HTML coverage reports, which are useful for visualizing code
  coverage in a browser.
- Generates Cobertura coverage reports, which are machine-readable reports
  useful for integrating with other tools. This template [provides a GitHub
  Action](../ci/test#code-coverage) that uses this report to publish code
  coverage to the related pull request as a sticky comment.

To generate the coverage reports, run the following command:

```bash
XDEBUG_MODE=coverage composer test
```
