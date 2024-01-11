---
title: Composer
layout: default
parent: PHP
nav_order: 1
---

# Composer

[Composer](https://getcomposer.org/) is a dependency manager for PHP. It allows you to declare the libraries
your project depends on and it will manage (install/update) them for you.

This template uses Composer to manage dependencies and provide scripts for
linting and testing code.

The provided [`composer.json`](https://github.com/AlexSkrypnyk/scaffold/blob/main/composer.json) file contains the following sections:

- **Project Information**:
  Metadata like name, description, and license.

- **Author and Support**:
  Includes maintainer details and URLs for issues and source code.

- **Dependencies**:
  Requires PHP version `>= 8.1`. If using as base for CLI command -
  `symfony/console` is provided as a dependency as well.

- **Development Dependencies**:
  Tools like [PHP Code Sniffer](https://github.com/squizlabs/PHP_CodeSniffer),[PHP Mess Detector](https://phpmd.org/) and [PHPStan](https://phpstan.org/)
  for development are listed.

- **Autoloading**:
  If using as base for CLI commandm, PSR-4 standard is used for autoloading
  classes from `src` directory.

- **Dev Autoloading**:
  Autoloads classes for development from `tests/phpunit` directory.

- **Custom Scripts**:
  Defines CLI scripts for tasks:
    - `lint` and `lint:fix` - to lint and fix code using [PHP Code Sniffer](https://github.com/squizlabs/PHP_CodeSniffer),
      [PHP Mess Detector](https://phpmd.org/) and [PHPStan](https://phpstan.org/)
    - `test` - to run PHPUnit tests and generate coverage report
    - `build` - to build a PHAR file (if using as base for CLI command)

- **Executable Binaries**:
  Executable binaries are defined as executable scripts in `bin` directory,
  which makes them easily accessible without cluttering the global scope.
