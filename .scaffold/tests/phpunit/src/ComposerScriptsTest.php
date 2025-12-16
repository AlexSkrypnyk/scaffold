<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests;

final class ComposerScriptsTest extends UnitTestCase {

  public function testComposerLint(): void {
    $this->assertDirectoryDoesNotExist(self::$sut . '/vendor');
    $this->assertFileDoesNotExist(self::$sut . '/composer.lock');

    $this->processRun('composer', ['install']);
    $this->assertProcessSuccessful();
    $this->assertDirectoryExists(self::$sut . '/vendor');
    $this->assertFileExists(self::$sut . '/composer.lock');

    $this->processRun('composer', ['lint']);
    $this->assertProcessSuccessful();

    $this->processRun('composer', ['reset']);
    $this->assertProcessSuccessful();
    $this->assertDirectoryDoesNotExist(self::$sut . '/vendor');
    $this->assertFileDoesNotExist(self::$sut . '/composer.lock');
  }

  public function testComposerTestNoCoverage(): void {
    $this->assertDirectoryDoesNotExist(self::$sut . '/vendor');
    $this->assertFileDoesNotExist(self::$sut . '/composer.lock');

    $this->processRun('php', ['-i']);
    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('pcov');

    $this->processRun('composer', ['install']);
    $this->assertProcessSuccessful();

    $this->assertDirectoryDoesNotExist(self::$sut . '/.logs');

    $this->processRun('composer', ['test']);
    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('OK');
    $this->assertFileExists(self::$sut . '/.logs/junit.xml');
    $this->assertDirectoryDoesNotExist(self::$sut . '/.logs/.coverage-html');
  }

  public function testComposerTestCoverage(): void {
    $this->assertDirectoryDoesNotExist(self::$sut . '/vendor');
    $this->assertFileDoesNotExist(self::$sut . '/composer.lock');

    $this->processRun('php', ['-i']);
    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('pcov');

    $this->processRun('composer', ['install']);
    $this->assertProcessSuccessful();

    $this->assertDirectoryDoesNotExist(self::$sut . '/.logs');

    $this->processRun('composer', ['test-coverage']);
    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('OK');
    $this->assertFileExists(self::$sut . '/.logs/junit.xml');
    $this->assertDirectoryExists(self::$sut . '/.logs/.coverage-html');
  }

}
