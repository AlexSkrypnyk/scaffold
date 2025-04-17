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
    if (empty(static::$fixtures)) {
      throw new \RuntimeException('Fixtures directory is not set.');
    }

    $is_failure = $this->status() instanceof Failure || $this->status() instanceof Error;
    $has_message = str_contains($this->status()->message(), 'Differences between directories') || str_contains($this->status()->message(), 'Failed to apply patch');
    $fixture_exists = str_contains(static::$fixtures, DIRECTORY_SEPARATOR . 'init' . DIRECTORY_SEPARATOR);
    $update_requested = getenv('UPDATE_FIXTURES');

    if ($is_failure && $has_message && $fixture_exists && $update_requested) {
      $baseline = File::dir(static::$fixtures . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . static::BASELINE_DIR);

      $ic_baseline = $baseline . DIRECTORY_SEPARATOR . Index::IGNORECONTENT;
      $ic_sut = static::$sut . DIRECTORY_SEPARATOR . Index::IGNORECONTENT;
      $ic_tmp = static::$tmp . DIRECTORY_SEPARATOR . Index::IGNORECONTENT;
      $ic_fixtures = static::$fixtures . DIRECTORY_SEPARATOR . Index::IGNORECONTENT;

      if (str_contains(static::$fixtures, DIRECTORY_SEPARATOR . static::BASELINE_DIR . DIRECTORY_SEPARATOR)) {
        File::copyIfExists($ic_baseline, $ic_sut);
        File::copyIfExists($ic_baseline, $ic_tmp);
        File::rmdir($baseline);
        File::sync(static::$sut, $baseline);
        static::replaceVersions($baseline);
        File::copyIfExists($ic_tmp, $ic_baseline);
      }
      else {
        File::copyIfExists($ic_fixtures, $ic_tmp);
        File::rmdir(static::$fixtures);
        File::diff($baseline, static::$sut, static::$fixtures);
        File::copyIfExists($ic_tmp, $ic_fixtures);
      }
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
