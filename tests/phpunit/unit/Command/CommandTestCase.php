<?php

namespace YourNamespace\App\Tests\Unit\Command;

use PHPUnit\Framework\TestCase;
use Symfony\Component\Console\Application;
use Symfony\Component\Console\Tester\CommandTester;
use YourNamespace\App\Tests\Traits\AssertTrait;
use YourNamespace\App\Tests\Traits\ReflectionTrait;

/**
 * Class CommandTestCase.
 *
 * Base class to unit test commands.
 */
abstract class CommandTestCase extends TestCase {

  use AssertTrait;
  use ReflectionTrait;

  /**
   * CommandTester instance.
   *
   * @var \Symfony\Component\Console\Tester\CommandTester
   */
  protected $commandTester;

  /**
   * Run main() with optional arguments.
   *
   * @param string $class
   *   Command class.
   * @param array<string> $input
   *   Optional array of input arguments.
   * @param array<string, string> $options
   *   Optional array of options. See CommandTester::execute() for details.
   *
   * @return array<string>
   *   Array of output lines.
   */
  protected function runExecute(string $class, array $input = [], array $options = []): array {
    $application = new Application();
    /** @var \Symfony\Component\Console\Command\Command $instance */
    $instance = new $class();
    $application->add($instance);

    /** @var string $name */
    $name = $this->getProtectedValue($instance, 'defaultName');
    $command = $application->find($name);
    $this->commandTester = new CommandTester($command);

    $this->commandTester->execute($input, $options);

    return explode(PHP_EOL, $this->commandTester->getDisplay());
  }

}
