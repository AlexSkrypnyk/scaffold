<?php

namespace YourNamespace\Tests\Unit;

/**
 * Class ExampleScriptUnitTest.
 *
 * Unit tests for template-simple-script.
 *
 * @group scripts
 */
class ExampleScriptUnitTest extends ScriptUnitTestBase {

  /**
   * {@inheritdoc}
   */
  protected $script = 'template-simple-script';

  /**
   * Test main() method.
   *
   * @dataProvider dataProviderMain
   * @runInSeparateProcess
   */
  public function testMain($args, $expected_code, $expected_output) {
    $args = is_array($args) ? $args : [$args];
    $result = $this->runScript($args, TRUE);
    $this->assertEquals($expected_code, $result['code']);
    $this->assertStringContainsString($expected_output, $result['output']);
  }

  /**
   * Data provider for testMain().
   */
  public static function dataProviderMain() {
    return [
      [
        '--help',
        0,
        'PHP CLI script template.',
      ],
      [
        '-help',
        0,
        'PHP CLI script template.',
      ],
      [
        '-h',
        0,
        'PHP CLI script template.',
      ],
      [
        '-?',
        0,
        'PHP CLI script template.',
      ],
      [
        [],
        1,
        'PHP CLI script template.',
      ],
      [
        [1, 2],
        1,
        'PHP CLI script template.',
      ],

      // Validation of business logic.
      [
        'arg1value',
        0,
        'Would execute script business logic with argument arg1value.',
      ],
    ];
  }

}
