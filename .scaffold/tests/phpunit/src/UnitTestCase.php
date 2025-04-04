<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests;

use AlexSkrypnyk\File\File;
use AlexSkrypnyk\File\Internal\Index;
use AlexSkrypnyk\File\Tests\Traits\DirectoryAssertionsTrait;
use AlexSkrypnyk\PhpunitHelpers\Traits\ProcessTrait;
use AlexSkrypnyk\PhpunitHelpers\Traits\SerializableClosureTrait;
use AlexSkrypnyk\PhpunitHelpers\Traits\TuiTrait;
use AlexSkrypnyk\PhpunitHelpers\UnitTestCase as UpstreamUnitTestCase;
use PHPUnit\Framework\TestStatus\Error;
use PHPUnit\Framework\TestStatus\Failure;

abstract class UnitTestCase extends UpstreamUnitTestCase {

  use DirectoryAssertionsTrait;
  use ProcessTrait;
  use SerializableClosureTrait;
  use TuiTrait;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();

    static::locationsCopy('../../../', static::$sut, [], [
      '*.png',
      '.idea',
      '.logs',
      '.phpunit.cache',
    ]);

    // Change the current working directory to the 'system under test'.
    chdir(static::$sut);
  }

  /**
   * {@inheritdoc}
   */
  protected function tearDown(): void {
    // Only run on failures related to the difference between directories.
    // Only update the fixtures for the 'baseline' tests.
    if (($this->status() instanceof Failure || $this->status() instanceof Error) && str_contains($this->status()->message(), 'Differences between directories') && (isset(self::$fixtures) && str_contains(self::$fixtures, DIRECTORY_SEPARATOR . 'init' . DIRECTORY_SEPARATOR) && getenv('UPDATE_FIXTURES'))) {
      $baseline = File::dir(static::$fixtures . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . self::BASELINE_DIR);
      if (str_contains(self::$fixtures, 'baseline')) {
        File::copyIfExists($baseline . DIRECTORY_SEPARATOR . Index::IGNORECONTENT, self::$sut . DIRECTORY_SEPARATOR . Index::IGNORECONTENT);
        File::copyIfExists($baseline . DIRECTORY_SEPARATOR . Index::IGNORECONTENT, self::$tmp . DIRECTORY_SEPARATOR . Index::IGNORECONTENT);
        File::rmdir($baseline);
        File::sync(self::$sut, $baseline);
        static::replaceVersions($baseline);
        File::copyIfExists(static::$tmp . DIRECTORY_SEPARATOR . Index::IGNORECONTENT, $baseline . DIRECTORY_SEPARATOR . Index::IGNORECONTENT);
      }
      File::copyIfExists(self::$fixtures . DIRECTORY_SEPARATOR . Index::IGNORECONTENT, self::$tmp . DIRECTORY_SEPARATOR . Index::IGNORECONTENT);
      File::rmdir(self::$fixtures);
      File::diff($baseline, self::$sut, self::$fixtures);
      File::copyIfExists(self::$tmp . DIRECTORY_SEPARATOR . Index::IGNORECONTENT, self::$fixtures . DIRECTORY_SEPARATOR . Index::IGNORECONTENT);
    }

    parent::tearDown();
  }

  /**
   * {@inheritdoc}
   */
  protected static function locationsFixturesDir(): string {
    return 'fixtures';
  }

  /**
   * Replace versions in the given directory.
   *
   * @param string $directory
   *   The directory to replace versions in.
   */
  protected static function replaceVersions(string $directory): void {
    $regexes = [
      // composer.json and package.json.
      '/":\s*"(?:\^|~|>=?|<=?)?\d+(?:\.\d+){0,2}(?:-[\w.-]+)?"/' => '": "__VERSION__"',
      // docker-compose.yml.
      '/([\w.-]+\/[\w.-]+:)(?:v)?\d+(?:\.\d+){0,2}(?:-[\w.-]+)?/' => '${1}__VERSION__',
      '/([\w.-]+\/[\w.-]+:)canary$/m' => '${1}__VERSION__',
      // GHAs.
      '/([\w.-]+\/[\w.-]+)@(?:v)?\d+(?:\.\d+){0,2}(?:-[\w.-]+)?/' => '${1}@__VERSION__',
    ];

    foreach ($regexes as $regex => $replace) {
      File::replaceContentInDir($directory, $regex, $replace);
    }
  }

}
