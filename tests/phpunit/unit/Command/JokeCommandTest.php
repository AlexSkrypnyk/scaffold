<?php

namespace YourNamespace\App\Tests\Unit\Command;

use YourNamespace\App\Command\JokeCommand;

/**
 * Class JokeCommandTest.
 *
 * This is a unit test for the JokeCommand class.
 *
 * @coversDefaultClass \YourNamespace\App\Command\JokeCommand
 */
class JokeCommandTest extends CommandTestCase {

  /**
   * Test the execute method.
   *
   * @covers ::execute
   * @covers ::configure
   * @group command
   */
  public function testExecute(): void {
    $output = $this->runExecute(JokeCommand::class, ['--topic' => 'general']);
    $this->assertArrayContainsString('Setup', $output);
    $this->assertArrayContainsString('Punchline', $output);
  }

}

// Override the file_get_contents function in the JokeCommand namespace.
namespace YourNamespace\App\Command;

/**
 * Fake file_get_contents function.
 *
 * @SuppressWarnings(PHPMD.UnusedFormalParameter)
 */
function file_get_contents(string $url): string|false {
  // Fake a successful joke response.
  return json_encode([
    [
      'setup' => 'Setup',
      'punchline' => 'Punchline',
    ],
  ]);
}
