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

Scaffold is a project template for Shell, PHP, NodeJS and Docker projects. The template ships working example code with tests, linters and GitHub Actions workflows. You run `install.sh` to name your project and keep only the stacks and features you pick.

## Features

The template holds every feature, and `install.sh` removes the ones you don't select:

- **Shell**
  - [Single-file script](shell-command.sh) with [BATS tests](tests/bats) and coverage
  - CI workflow to [lint and test](.github/workflows/test-shell.yml) with coverage
- **PHP**
  - [`composer.json`](composer.json)
  - [Symfony Console command app](bin/php-command) with [functional tests](tests/phpunit/Functional) and coverage
  - [Single-file script](php-script) with [unit](tests/phpunit/Unit) and [functional](tests/phpunit/Functional) tests and coverage
  - Class library with the PHP tooling and no entry point, for packages that ship only classes
  - Code quality configuration for [PHP_CodeSniffer](phpcs.xml), [PHPStan](phpstan.neon) and [Rector](rector.php)
  - CI workflows to [lint and test](.github/workflows/test-php.yml) and to [publish](.github/workflows/release-php.yml) a release, packaging the command app as a [PHAR](box.json)
- **NodeJS**
  - [`package.json`](package.json)
  - [Single-file script](nodejs-script) with [tests](tests/nodejs) and coverage
  - CI workflow to [lint and test](.github/workflows/test-nodejs.yml)
- **Docker**, off by default
  - [`Dockerfile`](Dockerfile) for a minimal Alpine-based image, with an [`entrypoint.sh`](entrypoint.sh)
  - CI workflow to [lint and test](.github/workflows/test-docker.yml) the image with Hadolint and a Buildx build
  - CI workflow to [publish](.github/workflows/release-docker.yml) multi-arch images (`linux/amd64`, `linux/arm64`) to Docker Hub
- **CI**
  - [Release drafter](.github/workflows/draft-release-notes.yml)
  - Release workflows that attach the [PHAR or PHP script](.github/workflows/release-php.yml) and the [Node.js script](.github/workflows/release-nodejs.yml) to each GitHub release
  - [PR auto-assign](.github/workflows/assign-author.yml)
  - [On-demand Renovate run](.github/workflows/update-dependencies.yml) that you start from the **Actions** tab
  - [GitHub Actions linting](.github/workflows/test-actions.yml) with yamllint, actionlint and zizmor, off by default
- **Documentation**
  - [README with badges](README.dist.md), a [contributing guide](CONTRIBUTING.dist.md) and a [generated logo](logo.png)
  - A [documentation site](docs) built with [Docusaurus](https://docusaurus.io/)
  - Spell check with [CSpell](https://cspell.org/)
  - An [`AsciinemaPlayer`](docs/src/components/AsciinemaPlayer) docs component, and the [terminal recorder](.scaffold/assets/update-assets.php) that renders Scaffold's `install.sh` walkthrough as an animated SVG
- **Utility files**
  - [`.editorconfig`](.editorconfig), [`.gitignore`](.gitignore), [`.gitattributes`](.gitattributes)
  - [Renovate bot configuration](renovate.json)
  - [Pull request template](.github/PULL_REQUEST_TEMPLATE.md)
  - [Funding](.github/FUNDING.yml)
  - [`install.sh`](install.sh), which applies the features you choose
- **AI agents**
  - [`AGENTS.md`](AGENTS.md) and [`CLAUDE.md`](CLAUDE.md) guidance for AI coding agents
  - Optional [architecture documentation](docs/content/architecture/README.md) with Mermaid or PlantUML diagrams, which an AI agent generates and updates with the [`update-architecture-docs`](.claude/skills/update-architecture-docs/SKILL.md) skill
  - An [`update-consumer-scaffold`](.scaffold/skills/update-consumer-scaffold/SKILL.md) skill that updates a generated project to the latest Scaffold release

## Create a project

`install.sh` replaces the `yournamespace`, `yourproject` and `Your Name` strings with your own values. It then keeps the features you choose and removes the rest.

To create a project, run the following command in a new **empty directory**. It runs the install script of the latest published Scaffold release, which downloads that release into the directory and then prompts you for the details:

```bash
curl -fsSL https://getscaffold.dev/install.sh | bash
```

Answer the prompts, and confirm that the script ends with `Initialization complete.`

![An interactive install.sh run, from the first prompt to the summary](.scaffold/assets/install.svg)

<details>
<summary>Verify the install script before you run it</summary>

getscaffold.dev/install.sh serves the `install.sh` attached to the latest published release. Each release signs the checksum of that file with GPG and records a GitHub build attestation for it.

1. Download the install script of the latest published release:

   ```bash
   curl -fsSLO https://getscaffold.dev/install.sh
   ```

2. Verify the install script with [GitHub CLI](https://cli.github.com):

   ```bash
   gh attestation verify install.sh --repo AlexSkrypnyk/scaffold
   ```

   Or verify it with GPG:

   ```bash
   BASE=https://github.com/AlexSkrypnyk/scaffold/releases/latest/download
   RAW=https://raw.githubusercontent.com/AlexSkrypnyk/scaffold/main

   curl -fsSLO $BASE/SHA256SUMS
   curl -fsSLO $BASE/SHA256SUMS.asc
   curl -fsSLO $RAW/install-key.asc

   gpg --show-keys --with-fingerprint install-key.asc
   gpg --import install-key.asc
   gpg --verify SHA256SUMS.asc SHA256SUMS
   sha256sum -c SHA256SUMS    # macOS: shasum -a 256 -c SHA256SUMS
   ```

   Confirm that `gpg --verify` reports a good signature from the key with this fingerprint:

   ```text
   86F0 77A2 E806 67D7 CF4A  3320 EDEA F2FC D434 756C
   ```

   `gpg` also warns that the key isn't certified with a trusted signature. That warning is normal for a newly imported key, and the fingerprint match is the check that counts.

3. Create an empty project directory and run the verified install script from it:

   ```bash
   mkdir my-project
   cd my-project
   bash ../install.sh
   ```

[Verify the install script](https://getscaffold.dev/#verify-the-install-script) explains what each check proves.

</details>

### Non-interactive setup

Pass options to `install.sh` to skip the prompts, for example in automation or from an AI agent. Any option switches the script to non-interactive mode. The `--namespace`, `--name` and `--author` options are required, and every other choice uses its default:

```bash
curl -fsSL https://getscaffold.dev/install.sh | \
  bash -s -- --namespace=AcmeApp --name=acme-app --author="Jane Doe"
```

To pin a tag, branch or commit in place of the latest release, add `--ref` after `bash -s --`, for example `--ref=1.2.3`. To list every option, run `curl -fsSL https://getscaffold.dev/install.sh | bash -s -- --help`.

### Start from a GitHub template

To create a project from a GitHub repository:

1. On GitHub, click **Use this template > Create a new repository**.
2. Clone your new repository.
3. In the repository root, run [`./install.sh`](install.sh) and answer the prompts. The same options work here, such as `./install.sh --namespace=AcmeApp --name=acme-app --author="Jane Doe"`.

### Set up the GitHub repository

With [GitHub CLI](https://cli.github.com) installed and a token in `SCAFFOLD_GITHUB_TOKEN`, the last prompt sets up the project's GitHub repository. In an empty directory it offers to create the repository, push the project and protect its default branch with the checks of the first CI run:

![An interactive install.sh run that creates the GitHub repository](.scaffold/assets/install-github.svg)

In a clone, the same prompt applies the settings, labels and ruleset to the existing repository. To set up the repository of an existing project later, run `curl -fsSL https://getscaffold.dev/install.sh | bash -s -- github`. The [GitHub repository setup](https://getscaffold.dev/github) page lists the token permissions and every option.

## Update a generated project

You can pull later template changes into a project generated from Scaffold and keep its own code. In Claude Code, ask Claude to "update scaffold" in your generated project. Claude fetches the [`update-consumer-scaffold`](.scaffold/skills/update-consumer-scaffold/SKILL.md) skill and follows its steps:

1. Download the latest Scaffold release.
2. Run `install.sh` again with your project's original answers.
3. Restore your project-specific files from git.
4. Reconcile the differences.

The generated project's [`AGENTS.md`](AGENTS.md) holds these instructions, so any AI agent can follow them. A project generated with `--no-ai` has no `AGENTS.md`, so it can't update this way.
