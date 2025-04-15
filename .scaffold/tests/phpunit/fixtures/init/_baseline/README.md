<p align="center">
  <a href="" rel="noopener">
  <img width=200px height=200px src="https://placehold.jp/000000/ffffff/200x200.png?text=force-crystal&css=%7B%22border-radius%22%3A%22%20100px%22%7D" alt="force-crystal logo"></a>
</p>

<h1 align="center">Few lines describing your project</h1>

<div align="center">

[![GitHub Issues](https://img.shields.io/github/issues/yodashut/force-crystal.svg)](https://github.com/yodashut/force-crystal/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/yodashut/force-crystal.svg)](https://github.com/yodashut/force-crystal/pulls)
[![Test PHP](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml)
[![Test Node.js](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml)
[![Test Shell](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml)
[![codecov](https://codecov.io/gh/yodashut/force-crystal/graph/badge.svg?token=7WEB1IXBYT)](https://codecov.io/gh/yodashut/force-crystal)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/yodashut/force-crystal)
![LICENSE](https://img.shields.io/github/license/yodashut/force-crystal)
![Renovate](https://img.shields.io/badge/renovate-enabled-green?logo=renovatebot)

</div>

---

## Features

- Your first feature as a list item
- Your second feature as a list item
- Your third feature as a list item

## Installation


    composer require yodashut/force-crystal



    npm install @yodashut/force-crystal



Download the latest release from GitHub releases page.


## Usage


    vendor/bin/force-crystal



    node_modules/.bin/force-crystal



    ./force-crystal.sh


### CLI options

| Name        | Default value | Description                        |
|-------------|---------------|------------------------------------|
| `arg1`      |               | Description of the first argument. |
| `--option1` | `default1`    | Option with a default value.       |
| `--option2` | None          | Option wihtout a value.            |

## Maintenance


    composer install
    composer lint
    composer test



    npm install
    npm run lint
    npm run test



    shellcheck force-crystal.sh tests/bats/*.bash tests/bats/*.bats
    shfmt -i 2 -ci -s -d force-crystal.sh tests/bats/*.bash tests/bats/*.bats

    npm ci --prefix tests/bats
    ./tests/bats/node_modules/.bin/bats tests/bats


---
_This repository was created using the [force-crystal](https://getforce-crystal.dev/) project template_
