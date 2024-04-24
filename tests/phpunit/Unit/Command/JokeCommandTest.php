<?php

declare(strict_types=1);

namespace YourNamespace\App\Tests\Unit\Command;

use Symfony\Component\Console\Command\Command;
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
   * @covers ::getJoke
   * @dataProvider dataProviderExecute
   * @group command
   */
  public function testExecute(string $content, int $expected_code, array|string $expected_output = []): void {
    /** @var \YourNamespace\App\Command\JokeCommand $mock */
    $mock = $this->prepareMock(JokeCommand::class, [
      'getContent' => $content,
    ], TRUE);
    $mock->setName('joke');

    $output = $this->runExecute($mock);

    $this->assertEquals($expected_code, $this->commandTester->getStatusCode());
    $expected_output = is_array($expected_output) ? $expected_output : [$expected_output];
    foreach ($expected_output as $expected_output_string) {
      $this->assertArrayContainsString($expected_output_string, $output);
    }
  }

  public static function dataProviderExecute(): array {
    return [
      [static::fixturePayload(['setup' => 'Test setup', 'punchline' => 'Test punchline']), Command::SUCCESS, ['Test setup', 'Test punchline']],
      ['', Command::FAILURE, ['Unable to retrieve a joke.']],
      ['non-json', Command::FAILURE, ['Unable to retrieve a joke.']],
      [static::fixturePayload(['setup' => 'Test setup']), Command::FAILURE, ['Unable to retrieve a joke.']],
    ];
  }

  /**
   * Get a fixture payload.
   *
   * @param array<string, string> $data
   *   Data to be encoded.
   *
   * @return string
   *   Encoded data.
   */
  protected static function fixturePayload(array $data): string {
    $json = json_encode([(object) $data]);

    if ($json === FALSE) {
      throw new \Exception('Unable to encode test data.');
    }

    return $json;
  }

}
