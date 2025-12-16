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
final class InitTest extends UnitTestCase {

  #[DataProvider('dataProviderInit')]
  public function testInit(
    array $answers = [],
    array $expected = [],
    ?SerializableClosure $before = NULL,
    ?SerializableClosure $after = NULL,
  ): void {
    self::$fixtures = static::locationsFixtureDir();

    if ($before instanceof SerializableClosure) {
      $before = self::cu($before);
      $before($this);
    }

    $answers = self::tuiEntries(array_replace(self::defaultAnswers(), $answers));

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', [], $answers);

    $this->assertProcessSuccessful();

    $expected = array_merge($expected, [
      'Summary',
      'Initialization complete.',
    ], $answers);

    $this->assertProcessOutputContainsOrNot($expected);

    $baseline = File::dir(self::$fixtures . '/../' . self::BASELINE_DIR);
    self::replaceVersions(self::$sut);

    if (!is_string(self::$fixtures)) {
      throw new \RuntimeException('Fixtures directory is not set.');
    }
    $this->assertDirectoryEqualsPatchedBaseline(self::$sut, $baseline, self::$fixtures);

    if ($after instanceof SerializableClosure) {
      $after = self::cu($after);
      $after($this);
    }
  }

  public static function dataProviderInit(): \Iterator {
    yield self::BASELINE_DATASET => [
        [],
    ];
    yield 'name' => [
        [
          'namespace' => 'JediTemple',
          'project' => 'star-forge',
          'author' => 'Obi-Wan Kenobi',
        ],
    ];
    yield 'php command' => [
        [
          'use_php' => self::$tuiYes,
          'use_php_command' => self::$tuiYes,
          'php_command_name' => 'star-forge',
          'use_nodejs' => self::$tuiNo,
          'use_shell' => self::$tuiNo,
        ],
    ];
    yield 'php script' => [
        [
          'use_php' => self::$tuiYes,
          'use_php_command' => self::$tuiNo,
          'use_php_script' => self::$tuiYes,
          'use_nodejs' => self::$tuiNo,
          'use_shell' => self::$tuiNo,
        ],
    ];
    yield 'nodejs' => [
        [
          'use_php' => self::$tuiNo,
          'use_nodejs' => self::$tuiYes,
          'use_shell' => self::$tuiNo,
        ],
    ];
    yield 'shell' => [
        [
          'use_php' => self::$tuiNo,
          'use_nodejs' => self::$tuiNo,
          'use_shell' => self::$tuiYes,
        ],
    ];
    yield 'no languages' => [
        [
          'use_php' => self::$tuiNo,
          'use_php_command' => self::TUI_SKIP,
          'php_command_name' => self::TUI_SKIP,
          'use_php_command_build' => self::TUI_SKIP,
          'use_php_script' => self::TUI_SKIP,
          'use_nodejs' => self::$tuiNo,
          'use_shell' => self::$tuiNo,
        ],
    ];
    yield 'no release drafter' => [
        [
          'use_release_drafter' => self::$tuiNo,
        ],
    ];
    yield 'no pr autoassign' => [
        [
          'use_pr_autoassign' => self::$tuiNo,
        ],
    ];
    yield 'no funding' => [
        [
          'use_funding' => self::$tuiNo,
        ],
    ];
    yield 'no pr template' => [
        [
          'use_pr_template' => self::$tuiNo,
        ],
    ];
    yield 'no renovate' => [
        [
          'use_renovate' => self::$tuiNo,
        ],
    ];
    yield 'no docs' => [
        [
          'use_docs' => self::$tuiNo,
        ],
    ];
  }

  protected static function defaultAnswers(): array {
    return [
      'namespace' => 'YodasHut',
      'project' => 'force-crystal',
      'author' => 'Luke Skywalker',
      'use_php' => self::TUI_DEFAULT,
      'use_php_command' => self::TUI_DEFAULT,
      'php_command_name' => self::TUI_DEFAULT,
      'use_php_command_build' => self::TUI_DEFAULT,
      'use_php_script' => self::TUI_DEFAULT,
      'use_nodejs' => self::TUI_DEFAULT,
      'use_shell' => self::TUI_DEFAULT,
      'use_release_drafter' => self::TUI_DEFAULT,
      'use_pr_autoassign' => self::TUI_DEFAULT,
      'use_funding' => self::TUI_DEFAULT,
      'use_pr_template' => self::TUI_DEFAULT,
      'use_renovate' => self::TUI_DEFAULT,
      'use_docs' => self::TUI_DEFAULT,
      'remove_self' => self::TUI_DEFAULT,
    ];
  }

}
