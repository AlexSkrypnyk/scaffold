<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests\Traits;

use Symfony\Component\Filesystem\Filesystem;
use Symfony\Component\Finder\Finder;

/**
 * Trait FixtureTrait.
 *
 * Helpers to work with fixture files and directories.
 */
trait FixtureTrait {

  /**
   * Fixture directory where tests are run.
   */
  protected string $fixtureDir;

  /**
   * Source directory where project files are located.
   */
  protected string $sourceDir;

  /**
   * Initialize fixture directory.
   *
   * @param string|null $name
   *   Optional fixture name.
   * @param string|null $root
   *   Optional root directory.
   * @param string|null $sourceDir
   *   Optional source directory.
   */
  protected function fixtureInit(?string $name = NULL, ?string $root = NULL, ?string $sourceDir = NULL): void {
    $name = $name ?? (new \ReflectionClass($this))->getShortName();
    $root = $root ?? sys_get_temp_dir();
    $this->fixtureDir = $root . DIRECTORY_SEPARATOR . uniqid('scaffold_test_' . $name . '_', TRUE);

    // Set the source directory to the parent of .scaffold directory.
    $this->sourceDir = $sourceDir ?? dirname(dirname(dirname(dirname(__DIR__))));

    // Create the fixture directory.
    $fs = new Filesystem();
    $fs->mkdir($this->fixtureDir);
  }

  /**
   * Copy source repository to the fixture directory.
   *
   * @param bool $excludeVendor
   *   Whether to exclude vendor directory. Defaults to TRUE.
   * @param bool $excludeTests
   *   Whether to exclude tests directories. Defaults to TRUE.
   * @param array $excludeDirs
   *   Additional directories to exclude.
   */
  protected function fixtureCopyRepository(bool $excludeVendor = TRUE, bool $excludeTests = TRUE, array $excludeDirs = []): void {
    $fs = new Filesystem();

    // Default exclusions.
    $exclusions = array_merge([
      '.git',
      '.github',
      '.idea',
      '.scaffold',
    ], $excludeDirs);

    if ($excludeVendor) {
      $exclusions[] = 'vendor';
      $exclusions[] = 'vendor-bin';
      $exclusions[] = 'node_modules';
    }

    if ($excludeTests) {
      $exclusions[] = 'tests';
      $exclusions[] = '.phpunit.cache';
      $exclusions[] = '.logs';
    }

    // Find all files to copy.
    $finder = new Finder();
    $finder->files()
      ->in($this->sourceDir)
      ->ignoreDotFiles(FALSE)
      ->ignoreVCS(FALSE);

    // Add exclusion patterns.
    foreach ($exclusions as $exclusion) {
      $finder->exclude($exclusion);
    }

    // Make the init.sh and shell-command.sh executable.
    if (file_exists($this->sourceDir . '/init.sh')) {
      $fs->chmod($this->sourceDir . '/init.sh', 0755);
    }
    if (file_exists($this->sourceDir . '/shell-command.sh')) {
      $fs->chmod($this->sourceDir . '/shell-command.sh', 0755);
    }

    // Copy all files.
    foreach ($finder as $file) {
      $relativePath = $file->getRelativePathname();
      $targetPath = $this->fixtureDir . DIRECTORY_SEPARATOR . $relativePath;

      $fs->mkdir(dirname($targetPath));
      $fs->copy($file->getRealPath(), $targetPath);

      // Make scripts executable in the target directory too.
      if (basename($relativePath) === 'init.sh' || basename($relativePath) === 'shell-command.sh') {
        $fs->chmod($targetPath, 0755);
      }
    }
  }

  /**
   * Clean up fixture directory.
   */
  protected function fixtureCleanup(): void {
    if (isset($this->fixtureDir) && is_dir($this->fixtureDir)) {
      (new Filesystem())->remove($this->fixtureDir);
    }
  }

  /**
   * Create a file in the fixture directory.
   *
   * @param string $path
   *   Relative path within the fixture directory.
   * @param string $content
   *   File content.
   *
   * @return string
   *   Full path to the created file.
   */
  protected function fixtureCreateFile(string $path, string $content): string {
    $fs = new Filesystem();
    $fullPath = $this->fixtureDir . DIRECTORY_SEPARATOR . $path;

    $fs->mkdir(dirname($fullPath));
    $fs->dumpFile($fullPath, $content);

    return $fullPath;
  }

}
