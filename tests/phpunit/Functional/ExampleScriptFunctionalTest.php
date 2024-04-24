<?php

declare(strict_types=1);

namespace YourNamespace\App\Tests\Functional;

/**
 * Class ExampleScriptFunctionalTest.
 *
 * Functional tests for php-script.
 */
class ExampleScriptFunctionalTest extends ScriptFunctionalTestCase {

  /**
   * @covers ::main
   * @dataProvider dataProviderMain
   * @runInSeparateProcess
   * @group script
   */
  public function testMain(array|string $args, int $expected_code, string $expected_output): void {
    $result = $this->runScript($args);
    $this->assertEquals($expected_code, $result['code']);
    $this->assertArrayContainsString($expected_output, $result['output']);
  }

  public static function dataProviderMain(): array {
    return [
      ['help', static::EXIT_SUCCESS, 'PHP CLI script template.'],
      ['--help', static::EXIT_SUCCESS, 'PHP CLI script template.'],
      ['-h', static::EXIT_SUCCESS, 'PHP CLI script template.'],
      ['-?', static::EXIT_SUCCESS, 'PHP CLI script template.'],
      ['-help', static::EXIT_SUCCESS, 'Would execute script business logic with argument -help.'],
      ['', static::EXIT_ERROR, 'Please provide a value of the first argument.'],
      ['testarg1', static::EXIT_SUCCESS, 'Would execute script business logic with argument testarg1.'],
      [['testarg1', 'testarg2'], static::EXIT_ERROR, 'Please provide a value of the first argument.'],
    ];
  }

}
