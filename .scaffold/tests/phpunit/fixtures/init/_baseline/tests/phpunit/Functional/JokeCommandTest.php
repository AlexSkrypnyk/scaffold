<?php

declare(strict_types=1);

namespace YodasHut\App\Tests\Functional;

use PHPUnit\Framework\Attributes\CoversMethod;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Group;
use YodasHut\App\Command\JokeCommand;
use YodasHut\App\Tests\Traits\ConsoleTrait;
use YodasHut\App\Tests\Traits\MockTrait;

/**
 * Class JokeCommandTest.
 *
 * This is a unit test for the JokeCommand class.
 */
#[CoversMethod(JokeCommand::class, 'execute')]
#[CoversMethod(JokeCommand::class, 'configure')]
#[CoversMethod(JokeCommand::class, 'getJoke')]
#[Group('command')]
class JokeCommandTest extends ApplicationFunctionalTestCase {

  use ConsoleTrait;
  use MockTrait;

  #[DataProvider('dataProviderExecute')]
  public function testExecute(string $content, array $expected_output, bool $expected_fail = FALSE): void {
    /** @var \YodasHut\App\Command\JokeCommand $mock */
    // @phpstan-ignore varTag.nativeType
    $mock = $this->prepareMock(JokeCommand::class, [
      'getContent' => $content,
    ]);
    $mock->setName('joke');

    $this->consoleInitApplicationTester($mock);
    $output = $this->consoleApplicationRun([], [], $expected_fail);
    foreach ($expected_output as $expected_output_string) {
      $this->assertStringContainsString($expected_output_string, $output);
    }
  }

  public static function dataProviderExecute(): array {
    return [
      [static::fixturePayload(['setup' => 'Test setup', 'punchline' => 'Test punchline']), ['Test setup', 'Test punchline']],
      ['', ['Unable to retrieve a joke.'], TRUE],
      ['non-json', ['Unable to retrieve a joke.'], TRUE],
      [static::fixturePayload(['setup' => 'Test setup']), ['Unable to retrieve a joke.'], TRUE],
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
