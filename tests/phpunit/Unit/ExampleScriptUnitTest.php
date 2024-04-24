<?php

declare(strict_types=1);

namespace YourNamespace\App\Tests\Unit;

/**
 * Class ExampleScriptUnitTest.
 *
 * Unit tests for php-script.
 *
 * @group scripts
 */
class ExampleScriptUnitTest extends ScriptUnitTestCase {

  /**
   * @covers ::main
   * @covers ::print_help
   * @covers ::verbose
   * @dataProvider dataProviderMain
   * @group script
   */
  public function testMain(string|array $args = [], array|string $expected_output = [], string|null $expected_exception_message = NULL): void {
    if ($expected_exception_message) {
      $this->expectException(\Exception::class);
      $this->expectExceptionMessage($expected_exception_message);
    }

    $output = $this->runMain($args);

    $expected_output = is_array($expected_output) ? $expected_output : [$expected_output];
    foreach ($expected_output as $expected_output_string) {
      $this->assertArrayContainsString($expected_output_string, $output);
    }
  }

  public static function dataProviderMain(): array {
    return [
      ['help', 'PHP CLI script template.'],
      ['--help', 'PHP CLI script template.'],
      ['-h', 'PHP CLI script template.'],
      ['-?', 'PHP CLI script template.'],
      ['-help', 'Would execute script business logic with argument -help.'],
      ['', [], 'Please provide a value of the first argument.'],
      ['testarg1', 'Would execute script business logic with argument testarg1.'],
      [['testarg1', 'testarg2'], [], 'Please provide a value of the first argument.'],
    ];
  }

}
