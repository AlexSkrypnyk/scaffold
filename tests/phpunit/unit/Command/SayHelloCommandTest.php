<?php

namespace YourNamespace\App\Tests\Command;

use PHPUnit\Framework\TestCase;
use Symfony\Component\Console\Application;
use Symfony\Component\Console\Tester\CommandTester;
use YourNamespace\App\Command\SayHelloCommand;

/**
 * Class SayHelloCommandTest.
 *
 * This is a unit test for the SayHelloCommand class.
 *
 * @package YourNamespace\App\Tests\Command
 */
class SayHelloCommandTest extends TestCase {

  /**
   * Test the execute method.
   */
  public function testExecute() {
    $application = new Application();
    $application->add(new SayHelloCommand());

    $command = $application->find('app:say-hello');
    $commandTester = new CommandTester($command);

    $commandTester->execute([]);

    // The output of the command in the console.
    $output = $commandTester->getDisplay();
    $this->assertStringContainsString('Hello, Symfony console!', $output);
  }

}
