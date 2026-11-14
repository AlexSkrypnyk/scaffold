<p align="center">
  <a href="" rel="noopener">
  <img width=200px height=200px src="https://placehold.jp/000000/ffffff/200x200.png?text=Yourproject&css=%7B%22border-radius%22%3A%22%20100px%22%7D" alt="Yourproject logo"></a>
</p>

<h1 align="center">Few lines describing your project</h1>

<div align="center">

[![GitHub Issues](https://img.shields.io/github/issues/yournamespace/yourproject.svg)](https://github.com/yournamespace/yourproject/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/yournamespace/yourproject.svg)](https://github.com/yournamespace/yourproject/pulls)
[//]: # (#;< PHP)
[![Test PHP](https://github.com/yournamespace/yourproject/actions/workflows/test-php.yml/badge.svg)](https://github.com/yournamespace/yourproject/actions/workflows/test-php.yml)
[//]: # (#;> PHP)
[//]: # (#;< NODEJS)
[![Test Node.js](https://github.com/yournamespace/yourproject/actions/workflows/test-nodejs.yml/badge.svg)](https://github.com/yournamespace/yourproject/actions/workflows/test-nodejs.yml)
[//]: # (#;> NODEJS)
[//]: # (#;< SHELL)
[![Test Shell](https://github.com/yournamespace/yourproject/actions/workflows/test-shell.yml/badge.svg)](https://github.com/yournamespace/yourproject/actions/workflows/test-shell.yml)
[//]: # (#;> SHELL)
[![codecov](https://codecov.io/gh/yournamespace/yourproject/graph/badge.svg)](https://codecov.io/gh/yournamespace/yourproject)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/yournamespace/yourproject)
![LICENSE](https://img.shields.io/github/license/yournamespace/yourproject)
![Renovate](https://img.shields.io/badge/renovate-enabled-green?logo=renovatebot)
[//]: # (#;< AUDIT)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/yournamespace/yourproject/badge)](https://scorecard.dev/viewer/?uri=github.com/yournamespace/yourproject)
[//]: # (#;> AUDIT)
<!-- To show the OpenSSF Best Practices badge, register the project at https://www.bestpractices.dev, replace PROJECT_ID with its ID and move the badge out of this comment.
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/PROJECT_ID/badge)](https://www.bestpractices.dev/projects/PROJECT_ID)
-->

</div>

---

## Features

- Your first feature as a list item
- Your second feature as a list item
- Your third feature as a list item
[//]: # (#;< AI_ARCH_DOCS)
- Architecture documentation in `docs/content/architecture/`, which an AI agent regenerates with the `update-architecture-docs` skill when you ask it to "update architecture docs"
[//]: # (#;> AI_ARCH_DOCS)

## Installation

[//]: # (#;< PHP)
Install the PHP package with Composer:

```bash
composer require yournamespace/yourproject
```

[//]: # (#;> PHP)
[//]: # (#;< NODEJS)
Install the Node.js package with npm:

```bash
npm install --global @yournamespace/yourproject
```

Or download the Node.js script, `nodejs-script`, from the [latest release](https://github.com/yournamespace/yourproject/releases/latest) and make it executable:

```bash
chmod +x nodejs-script
```

[//]: # (#;> NODEJS)
[//]: # (#;< SHELL)
Copy the shell script, `shell-command.sh`, from this repository and make it executable:

```bash
chmod +x shell-command.sh
```

[//]: # (#;> SHELL)
[//]: # (#;< DOCKER)
Pull the Docker image from Docker Hub:

```bash
docker pull yournamespace/yourdockerimage
```

[//]: # (#;> DOCKER)
## Usage

[//]: # (#;< PHP)
[//]: # (#;< PHP_COMMAND)
Run the PHP command that Composer installs:

```bash
vendor/bin/php-command
```

The command takes the following arguments and options:

| Name        | Default value | Description                        |
|-------------|---------------|------------------------------------|
| `arg1`      | None          | Description of the first argument. |
| `--option1` | `default1`    | Option with a default value.       |
| `--option2` | None          | Flag that takes no value.          |

[//]: # (#;> PHP_COMMAND)
[//]: # (#;< PHP_SCRIPT)
Run the PHP script that Composer installs:

```bash
vendor/bin/php-script
```

[//]: # (#;> PHP_SCRIPT)
[//]: # (#;< PHP_LIBRARY)
Call the PHP library's classes from your code:

```php
use YourNamespace\App\Example;

echo (new Example())->greet('World');
```

[//]: # (#;> PHP_LIBRARY)
[//]: # (#;> PHP)
[//]: # (#;< NODEJS)
Run the Node.js script:

```bash
./nodejs-script value/of/argument
```

[//]: # (#;> NODEJS)
[//]: # (#;< SHELL)
Run the shell script:

```bash
./shell-command.sh
```

[//]: # (#;> SHELL)
[//]: # (#;< DOCKER)
Run a container from the Docker image:

```bash
docker run --rm yournamespace/yourdockerimage
```

[//]: # (#;> DOCKER)
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

[//]: # (#;< AI)
## Update from the template

To pull the latest infrastructure from the Scaffold template into this project, ask Claude Code to "update scaffold". Claude Code follows the instructions in [`AGENTS.md`](AGENTS.md).

[//]: # (#;> AI)
---
_This repository was created using the [Scaffold](https://getscaffold.dev/) project template_
