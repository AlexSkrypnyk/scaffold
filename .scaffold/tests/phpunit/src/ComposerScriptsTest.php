<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests;

class ComposerScriptsTest extends UnitTestCase {

  public function testComposerLint(): void {
    $this->assertDirectoryDoesNotExist(static::$sut . '/vendor');
    $this->assertFileDoesNotExist(static::$sut . '/composer.lock');

    $this->processRun('composer', ['install']);
    $this->assertProcessSuccessful();
    $this->assertDirectoryExists(static::$sut . '/vendor');
    $this->assertFileExists(static::$sut . '/composer.lock');

    $this->processRun('composer', ['lint']);
    $this->assertProcessSuccessful();

    $this->processRun('composer', ['reset']);
    $this->assertProcessSuccessful();
    $this->assertDirectoryDoesNotExist(static::$sut . '/vendor');
    $this->assertFileDoesNotExist(static::$sut . '/composer.lock');
  }

  public function testComposerTestNoCoverage(): void {
    $this->assertDirectoryDoesNotExist(static::$sut . '/vendor');
    $this->assertFileDoesNotExist(static::$sut . '/composer.lock');

    $this->processRun('php', ['-i']);
    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('pcov');

    $this->processRun('composer', ['install']);
    $this->assertProcessSuccessful();

    $this->assertDirectoryDoesNotExist(static::$sut . '/.logs');

    $this->processRun('composer', ['test']);
    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('OK');
    $this->assertFileExists(static::$sut . '/.logs/junit.xml');
    $this->assertDirectoryDoesNotExist(static::$sut . '/.logs/.coverage-html');
  }

  public function testComposerTestCoverage(): void {
    $this->assertDirectoryDoesNotExist(static::$sut . '/vendor');
    $this->assertFileDoesNotExist(static::$sut . '/composer.lock');

    $this->processRun('php', ['-i']);
    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('pcov');

    $this->processRun('composer', ['install']);
    $this->assertProcessSuccessful();

    $this->assertDirectoryDoesNotExist(static::$sut . '/.logs');

    $this->processRun('composer', ['test-coverage']);
    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('OK');
    $this->assertFileExists(static::$sut . '/.logs/junit.xml');
    $this->assertDirectoryExists(static::$sut . '/.logs/.coverage-html');
  }

}
