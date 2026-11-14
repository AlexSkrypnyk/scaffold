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
[![codecov](https://codecov.io/gh/yodashut/force-crystal/graph/badge.svg)](https://codecov.io/gh/yodashut/force-crystal)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/yodashut/force-crystal)
![LICENSE](https://img.shields.io/github/license/yodashut/force-crystal)
![Renovate](https://img.shields.io/badge/renovate-enabled-green?logo=renovatebot)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/yodashut/force-crystal/badge)](https://scorecard.dev/viewer/?uri=github.com/yodashut/force-crystal)
<!-- To show the OpenSSF Best Practices badge, register the project at https://www.bestpractices.dev, replace PROJECT_ID with its ID and move the badge out of this comment.
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/PROJECT_ID/badge)](https://www.bestpractices.dev/projects/PROJECT_ID)
-->

</div>

---

## Features

- Your first feature as a list item
- Your second feature as a list item
- Your third feature as a list item
- Architecture documentation in `docs/content/architecture/`, which an AI agent regenerates with the `update-architecture-docs` skill when you ask it to "update architecture docs"

## Installation

Install the PHP package with Composer:

```bash
composer require yodashut/force-crystal
```

Install the Node.js package with npm:

```bash
npm install --global @yodashut/force-crystal
```

Or download the Node.js script, `nodejs-script`, from the [latest release](https://github.com/yodashut/force-crystal/releases/latest) and make it executable:

```bash
chmod +x nodejs-script
```

Copy the shell script, `force-crystal.sh`, from this repository and make it executable:

```bash
chmod +x force-crystal.sh
```

## Usage

Run the PHP command that Composer installs:

```bash
vendor/bin/force-crystal
```

The command takes the following arguments and options:

| Name        | Default value | Description                        |
|-------------|---------------|------------------------------------|
| `arg1`      | None          | Description of the first argument. |
| `--option1` | `default1`    | Option with a default value.       |
| `--option2` | None          | Flag that takes no value.          |

Run the Node.js script:

```bash
./nodejs-script value/of/argument
```

Run the shell script:

```bash
./force-crystal.sh
```

## Contribute

[`CONTRIBUTING.md`](CONTRIBUTING.md) lists the commands that install the dependencies and run the linters and tests.

## Security

To report a vulnerability privately, follow [`SECURITY.md`](SECURITY.md). It also lists the versions that get security fixes.

## Configure the GitHub repository

To apply the Scaffold repository settings, labels, security settings and rulesets to this project's GitHub repository, run the following command in the project's root directory:

```bash
curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github
```

The command needs [GitHub CLI](https://cli.github.com) and a GitHub token in `SCAFFOLD_GITHUB_TOKEN`. The [GitHub repository setup](https://getscaffold.dev/github) page lists the permissions the token needs.

After the repository is configured, follow [Harden your project](https://getscaffold.dev/harden) for the security steps that only the project's owner can take, such as earning the OpenSSF Best Practices badge.

## Update from the template

To pull the latest infrastructure from the Scaffold template into this project, ask Claude Code to "update scaffold". Claude Code follows the instructions in [`AGENTS.md`](AGENTS.md).

---
_This repository was created using the [Scaffold](https://getscaffold.dev/) project template_
