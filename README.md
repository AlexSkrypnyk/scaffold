<p align="center">
  <a href="" rel="noopener"><img src=".scaffold/docs/static/img/logo.png" alt="Scaffold logo" height=100px/></a>
</p>

<h1 align="center">Generic project scaffold template</h1>

<div align="center">

[![GitHub Issues](https://img.shields.io/github/issues/AlexSkrypnyk/scaffold.svg)](https://github.com/AlexSkrypnyk/scaffold/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/AlexSkrypnyk/scaffold.svg)](https://github.com/AlexSkrypnyk/scaffold/pulls)
[![Test Scaffold](https://github.com/AlexSkrypnyk/scaffold/actions/workflows/scaffold-test.yml/badge.svg)](https://github.com/AlexSkrypnyk/scaffold/actions/workflows/scaffold-test.yml)
[![codecov](https://codecov.io/gh/AlexSkrypnyk/scaffold/graph/badge.svg?token=7WEB1IXBYT)](https://codecov.io/gh/AlexSkrypnyk/scaffold)
![LICENSE](https://img.shields.io/github/license/AlexSkrypnyk/scaffold?label=License)
![Release (latest by date)](https://img.shields.io/github/v/release/AlexSkrypnyk/scaffold?label=Release)
![Renovate](https://img.shields.io/badge/renovate-enabled-green?logo=renovatebot&label=Renovate)

</div>

<div align="center">

📘 [Scaffold documentation](https://getscaffold.dev)

</div>

## Features

- **Shell**
  - [Simple single-file script scaffold](shell-command.sh)
    with [BATS tests](tests/bats) (with coverage)
  - CI config to [Lint and test](.github/workflows/test-shell.yml) (with
    coverage)
- **PHP**
  - [`composer.json`](composer.json)
  - [Symfony CLI command app scaffold](php-command)
    with [unit tests](tests/phpunit/Unit/Command) (with coverage)
    and [traits](tests/phpunit/Traits)
  - [Simple single-file script scaffold](php-script)
    with [unit tests](tests/phpunit/Functional) (with coverage)
  - Code quality tools with
    configurations: [PHP Code Sniffer](phpcs.xml),
    [PHPStan](phpstan.neon), [Rector](rector.php)
  - CI config to [Lint, test](.github/workflows/test-php.yml)
    and [publish](.github/workflows/release-php.yml) PHP as [PHAR](box.json)
- **NodeJS**
  - [`package.json`](package.json)
  - CI config to [build and test](.github/workflows/test-nodehs.yml) and test
    for NodeJS
- **Docker**
  - [`Dockerfile`](Dockerfile) with minimal Alpine-based image and [`entrypoint.sh`](entrypoint.sh)
  - CI config to [lint and test](.github/workflows/test-docker.yml) Docker
    image (Hadolint + Buildx build)
  - CI config to [publish](.github/workflows/release-docker.yml) multi-arch
    images (`linux/amd64`, `linux/arm64`) to Docker Hub
- **CI**
  - [Release drafter](.github/workflows/release-drafter.yml)
  - Release asset packaging and upload
  - [PR auto-assign](.github/workflows/assign-author.yml)
- **Documentation**
  - [Readme with badges](README.dist.md) and [generated logo](logo.png)
  - [Scaffold](docs) for the documentation site using [Docusaurus](https://docusaurus.io/)
  - Spell check with [CSpell](https://cspell.org/)
  - [Terminal recorder](.scaffold/assets/update-assets.php) rendering an animated SVG plus an [`AsciinemaPlayer`](docs/src/components/AsciinemaPlayer) docs component
- **Utility files**
  - [`.editorconfig`](.editorconfig), [`.gitignore`](.gitignore), [`.gitattributes`](.gitattributes)
  - [Renovate bot configuration](renovate.json)
  - [Pull request template](.github/PULL_REQUEST_TEMPLATE.md)
  - [Funding](.github/FUNDING.yml)
  - Init shell script to chose features
- **AI agents**
  - [`AGENTS.md`](AGENTS.md) and [`CLAUDE.md`](CLAUDE.md) guidance for AI coding agents
  - Bundled [`update-consumer-scaffold`](.scaffold/skills/update-consumer-scaffold/SKILL.md)
    skill that updates a generated project to the latest scaffold release

## How to use this scaffold repository

1. Click on **Use this template** > **Create a new repository**
2. Checkout locally
3. Run [`./init.sh`](init.sh) to replace `yournamespace`, `yourproject`,
   `Your Name` strings with your own and choose the features.<br/>
   ![init](.scaffold/assets/init.svg)

### Non-interactive setup

Pass options instead of answering prompts to initialise without any interaction - useful for automation and AI agents. Any option enables non-interactive mode; `--namespace`, `--name` and `--author` are required, and every other choice falls back to its default.

```bash
./init.sh --namespace=AcmeApp --name=acme-app --author="Jane Doe"
```

The same works as a one-liner straight from getscaffold.dev, with no prior checkout - run it in an **empty directory** and the script downloads the Scaffold into the current directory, then prompts you for the details:

```bash
curl -fsSL https://getscaffold.dev/init.sh | bash
```

To stay fully unattended, pass the details as options instead:

```bash
curl -fsSL https://getscaffold.dev/init.sh | \
  bash -s -- --namespace=AcmeApp --name=acme-app --author="Jane Doe"
```

The latest release is used by default; to pin a specific tag, branch, or commit, pass `--ref` to the script after `bash -s --` (for example `bash -s -- --ref=1.2.3`). Run `./init.sh --help` for the full list of options.

## Updating a generated project

Projects generated from this scaffold can pull later template improvements
without losing their own code. If you use Claude Code, the bundled
[`update-consumer-scaffold`](.scaffold/skills/update-consumer-scaffold/SKILL.md)
skill automates it: in your generated project, ask Claude to "update scaffold"
and it fetches the skill, downloads the latest scaffold release, re-runs
`init.sh` with your original answers, restores your project-specific files from
git, and reconciles the differences. The generated project's
[`AGENTS.md`](AGENTS.md) carries the same instructions for any AI agent.
