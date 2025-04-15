<?php

declare(strict_types=1);

namespace YodasHut\App\Tests\Unit;

use AlexSkrypnyk\PhpunitHelpers\Traits\AssertArrayTrait;
use PHPUnit\Framework\TestCase;

/**
 * Class ScriptUnitTestCase.
 *
 * Base class to unit test scripts.
 */
abstract class ScriptUnitTestCase extends TestCase {

  use AssertArrayTrait;

  /**
   * Script to include.
   *
   * @var string
   */
  protected static $script = 'force-crystal';

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    // Prevent script from running.
    putenv('SCRIPT_RUN_SKIP=1');
    // Log output into internal buffer instead of stdout so we can assert it.
    putenv('SCRIPT_QUIET=1');

    if (!is_readable(static::$script)) {
      throw new \RuntimeException(\sprintf('Unable to include script file %s.', static::$script));
    }
    require_once static::$script;

    parent::setUp();
  }

  /**
   * Run main() with optional arguments.
   *
   * @param string|array<string> $args
   *   Optional array of arguments to pass to the script.
   *
   * @return array<string>
   *   Array of output lines.
   */
  protected function runMain(string|array $args = []): array {
    $args = is_array($args) ? $args : [$args];

    $function = new \ReflectionFunction('main');
    array_unshift($args, $function->getFileName());
    $args = array_filter($args);

    main($args, count($args));

    return verbose('');
  }

}
