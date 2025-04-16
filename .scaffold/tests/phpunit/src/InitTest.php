<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests;

use AlexSkrypnyk\File\File;
use Laravel\SerializableClosure\SerializableClosure;
use PHPUnit\Framework\Attributes\DataProvider;

/**
 * Class InitFunctionalTest.
 *
 * Functional tests for init.sh script.
 */
class InitTest extends UnitTestCase {

  #[DataProvider('dataProviderInit')]
  public function testInit(
    array $answers = [],
    array $expected = [],
    ?SerializableClosure $before = NULL,
    ?SerializableClosure $after = NULL,
  ): void {
    static::$fixtures = static::locationsFixtureDir();

    if ($before instanceof SerializableClosure) {
      $before = static::cu($before);
      $before($this);
    }

    $answers = static::tuiEntries(array_replace(static::defaultAnswers(), $answers));

    $this->processRun(static::$sut . DIRECTORY_SEPARATOR . 'init.sh', [], $answers);

    $this->assertProcessSuccessful();

    $expected = array_merge($expected, [
      'Summary',
      'Initialization complete.',
    ], $answers);

    $this->assertProcessOutputContainsOrNot($expected);

    $baseline = File::dir(static::$fixtures . '/../' . self::BASELINE_DIR);
    static::replaceVersions(static::$sut);
    $this->assertDirectoryEqualsPatchedBaseline(static::$sut, $baseline, static::$fixtures);

    if ($after instanceof SerializableClosure) {
      $after = static::cu($after);
      $after($this);
    }
  }

  public static function dataProviderInit(): array {
    return [
      static::BASELINE_DATASET => [
        [],
      ],
      'name' => [
        [
          'namespace' => 'JediTemple',
          'project' => 'star-forge',
          'author' => 'Obi-Wan Kenobi',
        ],
      ],
      'php command' => [
        [
          'use_php' => static::$tuiYes,
          'use_php_command' => static::$tuiYes,
          'php_command_name' => 'star-forge',
          'use_nodejs' => static::$tuiNo,
          'use_shell' => static::$tuiNo,
        ],
      ],
      'php script' => [
        [
          'use_php' => static::$tuiYes,
          'use_php_command' => static::$tuiNo,
          'use_php_script' => static::$tuiYes,
          'use_nodejs' => static::$tuiNo,
          'use_shell' => static::$tuiNo,
        ],
      ],
      'nodejs' => [
        [
          'use_php' => static::$tuiNo,
          'use_nodejs' => static::$tuiYes,
          'use_shell' => static::$tuiNo,
        ],
      ],
      'shell' => [
        [
          'use_php' => static::$tuiNo,
          'use_nodejs' => static::$tuiNo,
          'use_shell' => static::$tuiYes,
        ],
      ],
      'no languages' => [
        [
          'use_php' => static::$tuiNo,
          'use_php_command' => static::TUI_SKIP,
          'php_command_name' => static::TUI_SKIP,
          'use_php_command_build' => static::TUI_SKIP,
          'use_php_script' => static::TUI_SKIP,
          'use_nodejs' => static::$tuiNo,
          'use_shell' => static::$tuiNo,
        ],
      ],
      'no release drafter' => [
        [
          'use_release_drafter' => static::$tuiNo,
        ],
      ],
      'no pr autoassign' => [
        [
          'use_pr_autoassign' => static::$tuiNo,
        ],
      ],
      'no funding' => [
        [
          'use_funding' => static::$tuiNo,
        ],
      ],
      'no pr template' => [
        [
          'use_pr_template' => static::$tuiNo,
        ],
      ],
      'no renovate' => [
        [
          'use_renovate' => static::$tuiNo,
        ],
      ],
      'no docs' => [
        [
          'use_docs' => static::$tuiNo,
        ],
      ],
    ];
  }

  protected static function defaultAnswers(): array {
    return [
      'namespace' => 'YodasHut',
      'project' => 'force-crystal',
      'author' => 'Luke Skywalker',
      'use_php' => static::TUI_DEFAULT,
      'use_php_command' => static::TUI_DEFAULT,
      'php_command_name' => static::TUI_DEFAULT,
      'use_php_command_build' => static::TUI_DEFAULT,
      'use_php_script' => static::TUI_DEFAULT,
      'use_nodejs' => static::TUI_DEFAULT,
      'use_shell' => static::TUI_DEFAULT,
      'use_release_drafter' => static::TUI_DEFAULT,
      'use_pr_autoassign' => static::TUI_DEFAULT,
      'use_funding' => static::TUI_DEFAULT,
      'use_pr_template' => static::TUI_DEFAULT,
      'use_renovate' => static::TUI_DEFAULT,
      'use_docs' => static::TUI_DEFAULT,
      'remove_self' => static::TUI_DEFAULT,
    ];
  }

}
