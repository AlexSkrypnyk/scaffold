---
title: PHP CLI Script
layout: default
parent: PHP
nav_order: 3
---

# CLI Script

[`php-script`](https://github.com/AlexSkrypnyk/scaffold/blob/main/php-script)
is a PHP template for writing a single-file command-line interface (CLI)
scripts. It's designed to be a single-file script without relying on any
external packages, making it a self-contained program.

Below are some of its main features:

1. **Environment-agnostic**: It starts with `#!/usr/bin/env php`, which helps
   the script find the PHP executable irrespective of its location.

2. **Usage Information**: It includes a `print_help()` function that prints out
   how to use the script. Users can trigger this function by providing `help()`,
   `--help`, `-h`, or `-?` as arguments.

3. **Error Handling**: The template is equipped to handle errors gracefully. It
   uses PHP's `set_error_handler()` function to throw exceptions on errors, making
   debugging easier.

4. **Argument Checking**: The `main()` function looks at the number of arguments
   passed and throws an exception if it doesn't meet the expected count.

5. **Verbose Output**: The `verbose()` function takes care of outputting messages
   to the console. An environment variable `SCRIPT_QUIET` can suppress these
   messages if set to '1'.

6. **Environment Variables for Control**: `SCRIPT_QUIET` for silencing verbose
   output, and `SCRIPT_RUN_SKIP` for skipping the actual running of the script.
   These can be useful for testing or other conditional executions.

7. **Security**: The script checks to ensure that it is being run from the
   command line and not from a web server, preventing unintended external
   access.

8. **Entrypoint**: The script identifies its entry point and goes through an
   error-handling mechanism before running the `main()` function.

9. **Testability**: The template is designed to be test-friendly. It allows you
   to skip the script's run for unit testing by setting an environment variable.
   Example unit tests are provided in the `tests/phpunit` directory.

Overall, this template offers a robust starting point for developing your own
PHP CLI scripts.

## Getting Started

Begin by updating the script name and file name in the script comments. This
will clarify the script's functionality for anyone who reads the code.

Next, adjust the `main` function to validate and handle the CLI arguments
specific to your script. You should also revise the `print_help` function to
include relevant usage instructions.

Your core logic will be housed in the `main` function. Simply replace the
placeholder comment "Add your logic here" with the code that accomplishes your
task. If you're interested in testing the script before running it, you can use
environment variables like `SCRIPT_QUIET` and `SCRIPT_RUN_SKIP` to modify its
behavior.

You can then run your script from the command line using `./php-script`.

## Authoring tests

This template includes a [`tests/phpunit`](https://github.com/AlexSkrypnyk/scaffold/tree/main/tests/phpunit)
directory with a sample Unit and Functional tests.

[`ScriptUnitTestCase.php`](https://github.com/AlexSkrypnyk/scaffold/blob/main/tests/phpunit/Unit/ScriptUnitTestCase.php)
is a base class for all Unit tests. It provides all required functionality for
testing the script without actually running it. It also includes several traits.

[`ExampleScriptUnitTest.php`](https://github.com/AlexSkrypnyk/scaffold/blob/main/tests/phpunit/Unit/ExampleScriptUnitTest.php)
is an example of a Unit test for running the script with different arguments and
options.

[`ScriptFunctionalTestCase.php`](https://github.com/AlexSkrypnyk/scaffold/blob/main/tests/phpunit/Functional/ScriptFunctionalTestCase.php)
is a base class for all Functional tests. It provides all required functionality
for testing the script by running it as your script users would do. It also i
ncludes several traits.

[`ExampleScriptFunctionalTest.php`](https://github.com/AlexSkrypnyk/scaffold/blob/main/tests/phpunit/Functional/ExampleScriptFunctionalTest.php)
is an example of a Functional test for running the script with different
arguments and options.
