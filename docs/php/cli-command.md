---
title: CLI Command
layout: default
parent: PHP
nav_order: 2
---

# CLI Command

The [`template-command-script`](https://github.com/AlexSkrypnyk/scaffold/blob/main/template-command-script)
serves as an advanced foundation for developing robust CLI applications.
Leveraging the capabilities of
the [Symfony Console component](https://symfony.com/doc/current/components/console.html),
this template is designed to accommodate complex business logic and extensive
functionalities. Unlike [single-file script](cli-script), which is intended for
simpler tasks, this template is structured to evolve into a comprehensive CLI
tool.

## Symfony Console

The Symfony Console component brings a wealth of features for building CLI
applications, making it a go-to choice for developers looking to create robust,
scalable command-line tools. One of its main features is the ability to define
commands, options, and arguments in a structured manner. This is beneficial for
applications that have multiple functionalities, as each can be encapsulated
into separate commands.

For instance, in the `app.php` example, two commands—`JokeCommand`
and `SayHelloCommand`—are defined and added to the application. The `add` method
allows you to register multiple commands easily, creating a modular CLI tool. By
doing this, you enable your application to handle diverse tasks, each accessed
via its own command.

Another advantage is the ability to set a default command
using `setDefaultCommand`, which is executed when no command is explicitly
specified. This is particularly useful for applications that have a primary
function which is most commonly used.

Beyond commands, Symfony Console also offers robust error handling, input/output
abstraction, and helpers for generating styled console output. All these
features collectively contribute to creating a professional-grade CLI
application.

## Example commands

This template includes two example commands: `SayHelloCommand`
and `JokeCommand`.

The `SayHelloCommand` command:

- Called using `app:say-hello`.
- Provides additional help details for the user.
- Prints `Hello, Symfony console!` when run.
- Signals successful execution by returning a success status.

This command is a good example of a simple command that can be used as a
starting
point.

The `JokeCommand` command:

- Called with the command `app:joke`.
- Accepts an optional `topic` parameter for the joke.
- Retrieves a joke from an external API based on the topic.
- Displays the setup and punchline of the joke.
- Shows an error message if it can't retrieve a joke.
- Returns a success status if the joke is displayed, or a failure status
  otherwise.

This is a more complex command that demonstrates how to handle arguments and
options, as well as how to make external API calls.

Both commands are registered in the `app.php` file and can be tested with unit
tests.

This template provides a robust set of unit tests to get you started.

## Command structure

In the CLI application, three key components build the overall structure:

1. **Bootstrap file**: This
   is [the script](https://github.com/AlexSkrypnyk/scaffold/blob/main/template-command-script)
   that initializes your application. It looks for Composer's autoload file to
   include all dependencies. Once it finds it, it then loads your application by
   requiring the [`app.php`](https://github.com/AlexSkrypnyk/scaffold/blob/main/src/app.php)
   file.

2. **Application loader**: Defined in [`app.php`](https://github.com/AlexSkrypnyk/scaffold/blob/main/src/app.php),
   this file is where you initialize the Symfony Console Application object. 
   You add commands to it, like `JokeCommand` and `SayHelloCommand`, and finally 
   run the application.
   This acts as the heart of your CLI application, tying together all the
   commands you've created.

3. **Command class(es)**: These are the actual commands your application will
   execute. Each [command class](https://github.com/AlexSkrypnyk/scaffold/tree/main/src/Command)
   is responsible for a specific action like saying hello or telling a joke. 
   These classes extend Symfony's Command class and are
   where you define your business logic. Optionally, you may also include unit
   tests for your commands to verify they work as expected.

These components work together to create a cohesive CLI application, allowing
for extensible and maintainable code.

## Getting Started

Depending on the complexity of your CLI application, you may chose a simpler
`SayHelloCommand` or a more complex `JokeCommand` as a starting point.

Start by renaming the command class and file to match your application.

Next, adjust the `configure` function to define the command name, description,
and other details. You can also add arguments and options here.

Your core logic will be housed in the `execute` function. Simply replace the
existing code with your own.

Lastly, you can update unit tests in the `tests/phpunit/Command` directory.

You can then run your script from the command line
using `./template-command-script`.

## Authoring tests

This template includes
a [`tests/phpunit/Unit/Commands`](https://github.com/AlexSkrypnyk/scaffold/tree/main/tests/phpunit/Commands)
directory with a sample Unit tests.

The Symfony Console component provides a `CommandTester` class that allows you
to
test commands in a controlled environment. This is useful for testing commands
that make external API calls or interact with the file system.
The `CommandTester` class provides methods for simulating user input and
capturing output, allowing you to test the command's behavior without actually
running it.

This template
provides [`CommandUnitTestCase.php`](https://github.com/AlexSkrypnyk/scaffold/blob/main/tests/phpunit/Unit/Command/CommandTestCase.php)
base class for all command Unit tests. It also includes several traits.

[`SayHelloCommandTest.php`](https://github.com/AlexSkrypnyk/scaffold/blob/main/tests/phpunit/Unit/Command/SayHelloCommandTest.php)
and
[`JokeCommandTest.php`](https://github.com/AlexSkrypnyk/scaffold/blob/main/tests/phpunit/Unit/Command/JokeCommandTest.php)
are two examples of Unit tests for `SayHelloCommand` and `JokeCommand` commands.

## Distribution

Distribution of CLI applications is a bit more complex than that of web.
While web applications can be distributed as source code, CLI applications
are usually distributed as a single executable file. This is called a PHAR file.

This template provides a `composer build` command and GitHub action for building
a PHAR file. See [PHP Packaging](php-packaging) for more details.

An alternative approach is to use your command as a Composer package.
Once published to the Packagist.org, the Composer packages registry, the command
binary file will be available to be called from within Composer scripts.

This template provides a configuration entry within `composer.json` that would
place the command bootstrap file in the `vendor/bin` directory of the project
requiring the command as dependency.
