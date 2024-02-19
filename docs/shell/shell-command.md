---
title: Shell CLI Command
layout: default
parent: Shell
nav_order: 2
---

# CLI Command

[`shell-command.sh`](https://github.com/AlexSkrypnyk/scaffold/blob/main/shell-command.sh)
is a Bash script template for writing a single-file command-line interface (CLI)
scripts. It's designed to be a single-file script without relying on any
external packages, making it a self-contained program.

Below are some of its main features:

1. **Error Handling**: Implements `set -euo pipefail` to prevent the
script from continuing execution in case of errors, uninitialized variables, or
failed commands, enhancing reliability.

**Debug Mode**: Controlled by the `SCRIPT_DEBUG` environment variable. When
  set to `1`, the script runs in debug mode, providing verbose output to assist
  with debugging.

- **Utility Functions for User Interaction**:
  - `ask`: Gathers input from the user with an option to specify a default
    value.
  - `ask_yesno`: Simplifies collecting `yes`/`no` responses from the user,
    incorporating default responses and input normalization.

- **Conditional Execution Based on User Confirmation**: Features a check to
  confirm whether the user wishes to proceed with the operation, allowing for an
  early exit if desired.

- **Structured Script Design**: Encapsulates the main logic within a `main`
  function, promoting code organization and readability. This structure also
  ensures that the script's main functionality is executed only when the script
  is not being sourced into another shell script.

Overall, this template offers a robust starting point for developing your own
Shell CLI scripts.

## Getting Started

Begin by updating the script name and file name in the script comments. This
will clarify the script's functionality for anyone who reads the code.

Next, adjust the `main` function to validate and handle the CLI arguments
specific to your script.

Your core logic will be housed in the `main` function.

You can then run your script from the command line using `./shell-script`.

## Authoring tests

This template includes
a [`tests/bats`](https://github.com/AlexSkrypnyk/scaffold/tree/main/tests/bats)
directory with a sample Unit and Functional tests written in [BATS](https://github.com/bats-core/bats-core).

The tests also include a `test_helpers.bash` file that provides a set of

[`shell-command.bats`](https://github.com/AlexSkrypnyk/scaffold/blob/main/tests/bats/shell-command.bats)
is an example of Unit and Functional tesst for running the script with different
arguments.

The CI supports running the tests with coverage reports uploaded to Codecov.
