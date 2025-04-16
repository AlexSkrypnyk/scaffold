<p align="center">
  <a href="" rel="noopener">
  <img width=200px height=200px src="https://placehold.jp/000000/ffffff/200x200.png?text=Yourproject&css=%7B%22border-radius%22%3A%22%20100px%22%7D" alt="Yourproject logo"></a>
</p>

<h1 align="center">Few lines describing your project</h1>

<div align="center">

[![GitHub Issues](https://img.shields.io/github/issues/yournamespace/yourproject.svg)](https://github.com/yournamespace/yourproject/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/yournamespace/yourproject.svg)](https://github.com/yournamespace/yourproject/pulls)
[![Test PHP](https://github.com/yournamespace/yourproject/actions/workflows/test-php.yml/badge.svg)](https://github.com/yournamespace/yourproject/actions/workflows/test-php.yml)
[![Test Node.js](https://github.com/yournamespace/yourproject/actions/workflows/test-nodejs.yml/badge.svg)](https://github.com/yournamespace/yourproject/actions/workflows/test-nodejs.yml)
[![Test Shell](https://github.com/yournamespace/yourproject/actions/workflows/test-shell.yml/badge.svg)](https://github.com/yournamespace/yourproject/actions/workflows/test-shell.yml)
[![codecov](https://codecov.io/gh/yournamespace/yourproject/graph/badge.svg?token=7WEB1IXBYT)](https://codecov.io/gh/yournamespace/yourproject)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/yournamespace/yourproject)
![LICENSE](https://img.shields.io/github/license/yournamespace/yourproject)
![Renovate](https://img.shields.io/badge/renovate-enabled-green?logo=renovatebot)

</div>

---

## Features

- Your first feature as a list item
- Your second feature as a list item
- Your third feature as a list item

## Installation

[//]: # (#;< PHP)

    composer require yournamespace/yourproject

[//]: # (#;> PHP)

[//]: # (#;< NODEJS)

    npm install @yournamespace/yourproject

[//]: # (#;> NODEJS)

[//]: # (#;< SHELL)

Download the latest release from GitHub releases page.

[//]: # (#;> SHELL)

## Usage

[//]: # (#;< PHP)

    vendor/bin/yourproject

[//]: # (#;> PHP)

[//]: # (#;< NODEJS)

    node_modules/.bin/yourproject

[//]: # (#;> NODEJS)

[//]: # (#;< SHELL)

    ./shell-command.sh

[//]: # (#;> SHELL)

[//]: # (#;< PHP)

### CLI options

| Name        | Default value | Description                        |
|-------------|---------------|------------------------------------|
| `arg1`      |               | Description of the first argument. |
| `--option1` | `default1`    | Option with a default value.       |
| `--option2` | None          | Option wihtout a value.            |

[//]: # (#;> PHP)

## Maintenance

[//]: # (#;< PHP)

    composer install
    composer lint
    composer test

[//]: # (#;> PHP)

[//]: # (#;< NODEJS)

    npm install
    npm run lint
    npm run test

[//]: # (#;> NODEJS)

[//]: # (#;< SHELL)

    shellcheck shell-command.sh tests/bats/*.bash tests/bats/*.bats
    shfmt -i 2 -ci -s -d shell-command.sh tests/bats/*.bash tests/bats/*.bats

    npm ci --prefix tests/bats
    ./tests/bats/node_modules/.bin/bats tests/bats

[//]: # (#;> SHELL)

---
_This repository was created using the [Scaffold](https://getscaffold.dev/) project template_
