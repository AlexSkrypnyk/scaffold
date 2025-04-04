<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests\Traits;

use Symfony\Component\Process\Process;

/**
 * Trait ProcessTrait.
 *
 * Helpers to run and test shell processes.
 */
trait ProcessTrait {

  /**
   * Run a process in the fixture directory.
   *
   * @param string $command
   *   The command to run.
   * @param array $arguments
   *   Command arguments.
   * @param array $inputs
   *   Array of inputs for interactive processes.
   * @param int $timeout
   *   Process timeout in seconds.
   * @param array $env
   *   Additional environment variables.
   *
   * @return \Symfony\Component\Process\Process
   *   The completed process.
   */
  protected function runProcess(
    string $command,
    array $arguments = [],
    array $inputs = [],
    int $timeout = 60,
    array $env = [],
  ): Process {
    // Combine command and arguments.
    $commandLine = array_merge([$command], $arguments);

    // Create process with working directory set to fixture dir.
    $process = new Process(
      $commandLine,
      $this->fixtureDir,
      array_merge(['SHELL_INTERACTIVE' => '0'], $env),
      NULL,
      $timeout
    );

    // Run process with input if provided.
    if (!empty($inputs)) {
      $process->setInput(implode(PHP_EOL, $inputs));
    }

    $process->run();

    return $process;
  }

  /**
   * Asserts that process was successful.
   *
   * @param \Symfony\Component\Process\Process $process
   *   Process to check.
   */
  protected function assertProcessSuccessful(Process $process): void {
    $this->assertTrue($process->isSuccessful(), sprintf(
      "Process failed with exit code %d: %s%sOutput:%s%s",
      $process->getExitCode(),
      $process->getErrorOutput(),
      PHP_EOL,
      PHP_EOL,
      $process->getOutput()
    ));
  }

  /**
   * Asserts that process was not successful.
   *
   * @param \Symfony\Component\Process\Process $process
   *   Process to check.
   */
  protected function assertProcessFailed(Process $process): void {
    $this->assertFalse($process->isSuccessful(), sprintf(
      "Process succeeded when failure was expected.%sOutput:%s%s",
      PHP_EOL,
      PHP_EOL,
      $process->getOutput()
    ));
  }

  /**
   * Asserts that process output contains string.
   *
   * @param \Symfony\Component\Process\Process $process
   *   Process to check.
   * @param string $expected
   *   Expected string.
   */
  protected function assertProcessOutputContains(Process $process, string $expected): void {
    $output = $process->getOutput();

    $this->assertStringContainsString($expected, $output, sprintf(
      "Process output does not contain '%s'.%sOutput:%s%s",
      $expected,
      PHP_EOL,
      PHP_EOL,
      $output
    ));
  }

  /**
   * Asserts that process error output contains string.
   *
   * @param \Symfony\Component\Process\Process $process
   *   Process to check.
   * @param string $expected
   *   Expected string.
   */
  protected function assertProcessErrorOutputContains(Process $process, string $expected): void {
    $output = $process->getErrorOutput();

    $this->assertStringContainsString($expected, $output, sprintf(
      "Process error output does not contain '%s'.%sError output:%s%s",
      $expected,
      PHP_EOL,
      PHP_EOL,
      $output
    ));
  }

  /**
   * Asserts that a file exists in the fixture directory.
   *
   * @param string $path
   *   Relative path to the file.
   */
  protected function assertFixtureFileExists(string $path): void {
    $fullPath = $this->fixtureDir . DIRECTORY_SEPARATOR . $path;

    $this->assertFileExists($fullPath, sprintf("File '%s' does not exist.", $path));
  }

  /**
   * Asserts that a file does not exist in the fixture directory.
   *
   * @param string $path
   *   Relative path to the file.
   */
  protected function assertFixtureFileNotExists(string $path): void {
    $fullPath = $this->fixtureDir . DIRECTORY_SEPARATOR . $path;

    $this->assertFileDoesNotExist($fullPath, sprintf("File '%s' exists but should not.", $path));
  }

  /**
   * Asserts that a directory exists in the fixture directory.
   *
   * @param string $path
   *   Relative path to the directory.
   */
  protected function assertFixtureDirectoryExists(string $path): void {
    $fullPath = $this->fixtureDir . DIRECTORY_SEPARATOR . $path;

    $this->assertDirectoryExists($fullPath, sprintf("Directory '%s' does not exist.", $path));
  }

  /**
   * Asserts that a directory does not exist in the fixture directory.
   *
   * @param string $path
   *   Relative path to the directory.
   */
  protected function assertFixtureDirectoryNotExists(string $path): void {
    $fullPath = $this->fixtureDir . DIRECTORY_SEPARATOR . $path;

    $this->assertDirectoryDoesNotExist($fullPath, sprintf("Directory '%s' exists but should not.", $path));
  }

  /**
   * Asserts that a file contains a string.
   *
   * @param string $path
   *   Relative path to the file.
   * @param string $expected
   *   Expected string.
   */
  protected function assertFixtureFileContains(string $path, string $expected): void {
    $fullPath = $this->fixtureDir . DIRECTORY_SEPARATOR . $path;

    $this->assertFileExists($fullPath, sprintf("File '%s' does not exist.", $path));

    $content = file_get_contents($fullPath);
    if ($content === FALSE) {
      $this->fail(sprintf("Failed to read file '%s'.", $path));
    }

    $this->assertStringContainsString($expected, $content, sprintf(
      "File '%s' does not contain '%s'.",
      $path,
      $expected
    ));
  }

  /**
   * Asserts that a file does not contain a string.
   *
   * @param string $path
   *   Relative path to the file.
   * @param string $expected
   *   Expected string.
   */
  protected function assertFixtureFileNotContains(string $path, string $expected): void {
    $fullPath = $this->fixtureDir . DIRECTORY_SEPARATOR . $path;

    $this->assertFileExists($fullPath, sprintf("File '%s' does not exist.", $path));

    $content = file_get_contents($fullPath);
    if ($content === FALSE) {
      $this->fail(sprintf("Failed to read file '%s'.", $path));
    }

    $this->assertStringNotContainsString($expected, $content, sprintf(
      "File '%s' contains '%s' but should not.",
      $path,
      $expected
    ));
  }

}
