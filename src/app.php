<?php

/**
 * @file
 * Main entry point for the application.
 */

use Symfony\Component\Console\Application;
use YourNamespace\App\Command\JokeCommand;
use YourNamespace\App\Command\SayHelloCommand;

// @codeCoverageIgnoreStart
$application = new Application();

$command = new JokeCommand();
$application->add($command);
$application->setDefaultCommand((string) $command->getName());

$command = new SayHelloCommand();
$application->add($command);

$application->run();
// @codeCoverageIgnoreEnd
