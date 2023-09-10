---
title: Test
layout: default
parent: CI
nav_order: 1
---

# Test

The [`test.yml`](https://github.com/AlexSkrypnyk/scaffold/blob/main/.github/workflows/test.yml)
file configures GitHub Actions for your repository to automatically run tests on
pull requests and pushes to specific branches. The workflow is set up for both
PHP and Node.js environments, and it includes steps for linting, testing, and
code coverage.

## Trigger conditions

- **Pull Requests**: The workflow activates whenever a new pull request is
  created or an existing one is updated. It triggers for pull requests targeting
  the `main` branch, any branch that begins with `feature/`, or even between
  feature branches themselves. For example, a pull request
  from `feature/new-button` to `feature/new-layout` would also activate the
  workflow. This ensures automated testing for changes aimed at both the
  stable `main` branch and ongoing work in feature-specific branches.

- **Pushes**: The workflow also activates whenever new commits are pushed
  directly to the `main` branch. This could be a direct commit or a merge from a
  pull request. This action ensures that the `main` branch is continually in a
  deployable and stable state according to the defined tests and checks.

## PHP job

- Runs on `ubuntu-latest`.
- Checks out code and caches Composer dependencies.
- Installs dependencies via Composer.
- Runs linting and tests with code coverage.
- Publishes coverage report with a 90% threshold to the associated pull
  request.

## Node.js job

- Runs on `ubuntu-latest`.
- Checks out code.
- Sets up Node.js environment.
- Installs npm dependencies.
- Runs linting and tests.

## Code coverage

The workflow publishes code coverage reports for PHP and Node.js projects to
the relevant pull request. This helps you keep track of code coverage and make
sure that new code is sufficiently tested.

The [`insightsengineering/coverage-action`](https://github.com/insightsengineering/coverage-action) 
action is used to analyze and report code coverage: it reads the coverage reports
provided by tools like PHPUnit, Jest, and Bats, and publishes the results to the
pull request.

Here's what each parameter does:

- `publish: true`: Publishes the code coverage report to the pull request.
- `diff: true`: Compares the current code coverage with the base commit to
  identify changes.
- `threshold: 90`: Sets a minimum acceptable code coverage percentage at 90%.
- `fail: true`: Fails the workflow if any of the conditions are not met.
- `coverage-reduction-failure: true`: Fails the workflow if there is a reduction
  in coverage compared to the base commit.
- `new-uncovered-statements-failure: true`: Fails the workflow if new code that
  is not covered by tests is introduced.

If any of these conditions are not met, the workflow will fail, signaling that
there are issues needing attention.

An example of a coverage comment in a [pull request](https://github.com/AlexSkrypnyk/scaffold/pull/39):

![Code Coverage in PR Comment](../../assets/coverage.png)

Read more about code coverage reporting in the [Code Coverage Report Action Github page](https://github.com/insightsengineering/coverage-action).
