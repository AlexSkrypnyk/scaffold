<?php

namespace YourNamespace\App\Tests\Command;

use PHPUnit\Framework\TestCase;
use Symfony\Component\Console\Application;
use Symfony\Component\Console\Tester\CommandTester;
use YourNamespace\App\Command\JokeCommand;

/**
 * Class JokeCommandTest.
 *
 * This is a unit test for the JokeCommand class.
 *
 * @package YourNamespace\App\Tests\Command
 */
class JokeCommandTest extends TestCase {

  /**
   * Test the execute method.
   */
  public function testExecute() {
    $application = new Application();
    $application->add(new JokeCommand());

    $command = $application->find('app:joke');
    $commandTester = new CommandTester($command);

    $commandTester->execute(['--topic' => 'general']);

    // The output of the command in the console.
    $output = $commandTester->getDisplay();
    $this->assertStringContainsString('Setup', $output);
    $this->assertStringContainsString('Punchline', $output);
  }

}

// Override the file_get_contents function in the JokeCommand namespace.
namespace YourNamespace\App\Command;

/**
 * Fake file_get_contents function.
 *
 * @SuppressWarnings(PHPMD.UnusedFormalParameter)
 */
function file_get_contents($url) {
  // Fake a successful joke response.
  return json_encode([
    [
      'setup' => 'Setup',
      'punchline' => 'Punchline',
    ],
  ]);
}
