<?php

declare(strict_types=1);

namespace YourNamespace\App\Tests\Functional;

use YourNamespace\App\Tests\Unit\ScriptUnitTestCase;

/**
 * Class ScriptFunctionalTestCase.
 *
 * Base class to functional test scripts.
 */
abstract class ScriptFunctionalTestCase extends ScriptUnitTestCase {

  /**
   * Exit code for success.
   *
   * @var int
   */
  const EXIT_SUCCESS = 0;

  /**
   * Exit code for error.
   *
   * @var int
   */
  const EXIT_ERROR = 1;

  protected function setUp(): void {
    parent::setUp();
    // Allow script to run.
    putenv('SCRIPT_RUN_SKIP=0');
    // Log output into stdout.
    putenv('SCRIPT_QUIET=0');
  }

  /**
   * Run script with optional arguments.
   *
   * @param string|array $args
   *   Optional array of arguments to pass to the script.
   *
   * @return array
   *   Array with the following keys:
   *   - code: (int) Exit code.
   *   - output: (array) Output lines.
   */
  protected function runScript(string|array $args = []): array {
    $args = is_array($args) ? $args : [$args];

    $command = sprintf('php %s %s', static::$script, implode(' ', $args));

    $output = [];
    $result_code = 1;
    exec($command, $output, $result_code);

    return [
      'code' => $result_code,
      'output' => $output,
    ];
  }

}
