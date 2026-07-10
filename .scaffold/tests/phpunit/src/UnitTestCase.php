<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests;

use AlexSkrypnyk\File\File;
use AlexSkrypnyk\PhpunitHelpers\Traits\ProcessTrait;
use AlexSkrypnyk\PhpunitHelpers\Traits\SerializableClosureTrait;
use AlexSkrypnyk\PhpunitHelpers\Traits\TuiTrait;
use AlexSkrypnyk\PhpunitHelpers\UnitTestCase as UpstreamUnitTestCase;
use AlexSkrypnyk\Snapshot\Testing\SnapshotTrait;

abstract class UnitTestCase extends UpstreamUnitTestCase {

  use ProcessTrait;
  use SerializableClosureTrait;
  use SnapshotTrait;
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
      '.claude',
    ]);

    // The template ships a shared '.claude/settings.json'; personal overrides
    // in '.claude/settings.local.json' are git-ignored and must never leak into
    // a generated project, so copy only the shared file (the bulk copy above
    // skips the whole '.claude' directory to keep local overrides out).
    File::copyIfExists(static::locationsRealpath('../../../') . '/.claude/settings.json', static::$sut . '/.claude/settings.json');

    // Change the current working directory to the 'system under test'.
    chdir(static::$sut);
  }

  /**
   * {@inheritdoc}
   */
  protected function tearDown(): void {
    if (!empty(static::$fixtures)) {
      $this->snapshotUpdateOnFailure(static::$fixtures, static::$sut, static::$tmp);
    }

    parent::tearDown();
  }

  /**
   * {@inheritdoc}
   */
  protected static function locationsFixturesDir(): string {
    return 'fixtures';
  }

}
