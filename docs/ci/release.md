---
title: Release
layout: default
parent: CI
nav_order: 2
---

# Release

The [`Release`](https://github.com/AlexSkrypnyk/scaffold/blob/main/.github/workflows/release.yml)
workflow is designed to automate the release process for the
repository. It is triggered on pushes to the `main` branch and when a new tag is
created. This workflow has specific jobs for handling release drafting, PHP
releases, and Node.js releases.

## Trigger Conditions

- **Runs on Pushes to the `main` Branch**: The workflow is activated every time
  new commits are pushed to the `main` branch. This ensures that any changes
  merged into `main` — either directly or through pull requests — automatically
  trigger the release process. This functionality ensures that the `main` branch
  is always in a release-ready state.

- **Triggers on New Git Tags**: The workflow is also activated when a new Git
  tag is created. Tags in Git are often used to mark specific points in your
  repository history as being important, usually to indicate a new version
  release. Whenever a new tag is pushed to the repository or created through
  GitHub's interface, the workflow is triggered. This allows for
  version-specific releases and assets to be automatically generated and
  published.

## Permissions

The workflow has write access to the repository content.

## Release Drafter job

- Runs on `ubuntu-latest`.
- Runs on code `push` to `main` branch or on `create` tag.
- Uses the [`release-drafter/release-drafter`](https://github.com/release-drafter/release-drafter)
  action to draft GitHub releases.
- Requires write access to both contents and pull requests.

See the [Release Drafter](release-drafter) page for more information.

## PHP Release job

- Activates if the workflow is triggered by a tag creation.
- Runs on `ubuntu-latest`.
- Checks out code, caches Composer dependencies, and installs them.
- Builds and tests a PHP PHAR file
  using [Box](https://github.com/box-project/box).
- Retrieves the tag name.
- Creates a new GitHub release and attaches the PHAR file as a release asset.

See the [PHP packaging](php-packaging) page for more information.

## Node.js Release job:

- Activates if the workflow is triggered by a tag creation.
- Runs on `ubuntu-latest`.
- Checks out code and sets up a Node.js environment.
- Installs npm dependencies and builds the project.
