<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests;

use PHPUnit\Framework\Attributes\DataProvider;
use Symfony\Component\Finder\Finder;
use Symfony\Component\Yaml\Yaml;

/**
 * Checks the workflows of the template and of a generated project.
 *
 * Every workflow grants no permissions at the top level, every job declares
 * its own, every action is pinned to a commit SHA, every checkout drops its
 * credentials, every dependency install skips the dependencies' scripts, and
 * a project that commits 'package-lock.json' installs with "npm ci".
 */
final class WorkflowPolicyTest extends UnitTestCase {

  /**
   * @param list<string>|null $arguments
   *   Arguments for install.sh, or NULL to check the template itself.
   */
  #[DataProvider('dataProviderWorkflowPolicy')]
  public function testWorkflowPolicy(?array $arguments): void {
    self::$fixtures = NULL;

    if ($arguments !== NULL) {
      $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', $arguments);
      $this->assertProcessSuccessful();
    }

    $finder = (new Finder())->files()->in(self::$sut . '/.github/workflows')->name(['*.yml', '*.yaml'])->sortByName();
    $this->assertGreaterThan(0, $finder->count());

    $violations = [];
    $npm_locked = file_exists(self::$sut . DIRECTORY_SEPARATOR . 'package-lock.json');

    foreach ($finder as $file) {
      $workflow = Yaml::parseFile($file->getPathname());
      $this->assertIsArray($workflow, $file->getFilename() . ' is not a YAML map.');

      $violations = array_merge($violations, self::workflowViolations($file->getFilename(), $workflow, $npm_locked));
    }

    $this->assertSame([], $violations);
  }

  public static function dataProviderWorkflowPolicy(): \Iterator {
    yield 'template' => [NULL];
    yield 'generated project with every workflow' => [['--namespace=YodasHut', '--name=force-crystal', '--author=Luke Skywalker', '--docker', '--test-actions']];
    yield 'generated Node.js project' => [['--namespace=YodasHut', '--name=force-crystal', '--author=Luke Skywalker', '--no-php', '--no-shell']];
    yield 'generated Node.js library' => [['--namespace=YodasHut', '--name=force-crystal', '--author=Luke Skywalker', '--no-php', '--no-shell', '--nodejs-library', '--test-actions']];
  }

  /**
   * @param list<string> $expected
   *   The expected violation messages.
   */
  #[DataProvider('dataProviderRunViolations')]
  public function testRunViolations(string $run, array $expected, bool $npm_locked = TRUE): void {
    $this->assertSame($expected, self::runViolations('step', $run, $npm_locked));
  }

  public static function dataProviderRunViolations(): \Iterator {
    yield 'npm with flag' => ['npm ci --ignore-scripts', []];
    yield 'npm without flag' => ['npm ci', ['step runs "npm ci" without "--ignore-scripts".']];
    yield 'npm with prefix' => ['npm --prefix=tests/bats ci', ['step runs "npm --prefix=tests/bats ci" without "--ignore-scripts".']];
    yield 'composer with flag' => ['composer install --no-scripts', []];
    yield 'composer without flag' => ['composer update', ['step runs "composer update" without "--no-scripts".']];
    yield 'unrelated command' => ['composer build', []];
    yield 'chained commands checked separately' => ['composer install --no-scripts && composer update', ['step runs "composer update" without "--no-scripts".']];
    yield 'npm install with flag' => ['npm install --ignore-scripts', ['step runs "npm install --ignore-scripts" instead of "npm ci".']];
    yield 'npm install alias' => ['npm i --ignore-scripts', ['step runs "npm i --ignore-scripts" instead of "npm ci".']];
    yield 'npm global install' => ['npm install --global --ignore-scripts zizmor', []];
    yield 'npm global install short flag' => ['npm i -g --ignore-scripts zizmor', []];
    yield 'npm install without a lock file' => ['npm install --ignore-scripts', [], FALSE];
    yield 'npm install without a lock file or flag' => ['npm install', ['step runs "npm install" without "--ignore-scripts".'], FALSE];
    yield 'commands on separate lines' => ["npm ci --ignore-scripts\nnpm install", ['step runs "npm install" without "--ignore-scripts".', 'step runs "npm install" instead of "npm ci".']];
    yield 'flag on a continued line' => ["composer install \\\n  --no-scripts", []];
    yield 'expression operators ignored' => ["composer install \${{ matrix.php == '8.5' && '--ignore-platform-reqs' || '' }} --no-scripts", []];
  }

  /**
   * @param array<mixed> $workflow
   *   The parsed workflow.
   *
   * @return list<string>
   *   1 message per violation.
   */
  protected static function workflowViolations(string $name, array $workflow, bool $npm_locked = TRUE): array {
    $violations = [];

    if (!array_key_exists('permissions', $workflow) || $workflow['permissions'] !== []) {
      $violations[] = sprintf('%s: top-level "permissions" is not {}.', $name);
    }

    $jobs = $workflow['jobs'] ?? [];

    if (!is_array($jobs) || $jobs === []) {
      return array_merge($violations, [sprintf('%s: no jobs.', $name)]);
    }

    foreach ($jobs as $job_id => $job) {
      if (!is_array($job)) {
        continue;
      }

      $location = sprintf('%s: job "%s"', $name, $job_id);

      if (!array_key_exists('permissions', $job)) {
        $violations[] = $location . ' declares no "permissions".';
      }

      if (isset($job['uses']) && is_string($job['uses'])) {
        $violations = array_merge($violations, self::usesViolations($location, $job['uses']));
      }

      $steps = is_array($job['steps'] ?? NULL) ? $job['steps'] : [];

      foreach ($steps as $index => $step) {
        if (!is_array($step)) {
          continue;
        }

        $step_location = sprintf('%s step "%s"', $location, is_string($step['name'] ?? NULL) ? $step['name'] : $index);

        if (isset($step['uses']) && is_string($step['uses'])) {
          $violations = array_merge($violations, self::usesViolations($step_location, $step['uses']));

          $with = is_array($step['with'] ?? NULL) ? $step['with'] : [];

          if (str_starts_with($step['uses'], 'actions/checkout@') && ($with['persist-credentials'] ?? NULL) !== FALSE) {
            $violations[] = $step_location . ' checks out without "persist-credentials: false".';
          }
        }

        if (isset($step['run']) && is_string($step['run'])) {
          $violations = array_merge($violations, self::runViolations($step_location, $step['run'], $npm_locked));
        }
      }
    }

    return $violations;
  }

  /**
   * @return list<string>
   *   1 message per violation.
   */
  protected static function usesViolations(string $location, string $uses): array {
    if (str_starts_with($uses, './') || str_starts_with($uses, 'docker://')) {
      return [];
    }

    if (preg_match('/^[^@\s]+@[0-9a-f]{40}$/', $uses) === 1) {
      return [];
    }

    return [sprintf('%s uses "%s", which is not pinned to a commit SHA.', $location, $uses)];
  }

  /**
   * @return list<string>
   *   1 message per violation.
   */
  protected static function runViolations(string $location, string $run, bool $npm_locked = TRUE): array {
    $violations = [];

    foreach (self::shellCommands($run) as $command) {
      $words = preg_split('/\s+/', $command) ?: [];

      if (in_array('npm', $words, TRUE) && array_intersect($words, ['install', 'i', 'ci', 'add']) !== [] && !in_array('--ignore-scripts', $words, TRUE)) {
        $violations[] = sprintf('%s runs "%s" without "--ignore-scripts".', $location, $command);
      }

      // A global install fetches a tool, not the project's locked dependencies,
      // and 'npm ci' refuses to run without a lock file.
      if ($npm_locked && in_array('npm', $words, TRUE) && array_intersect($words, ['install', 'i', 'add']) !== [] && array_intersect($words, ['-g', '--global']) === []) {
        $violations[] = sprintf('%s runs "%s" instead of "npm ci".', $location, $command);
      }

      if (in_array('composer', $words, TRUE) && array_intersect($words, ['install', 'update', 'require']) !== [] && !in_array('--no-scripts', $words, TRUE)) {
        $violations[] = sprintf('%s runs "%s" without "--no-scripts".', $location, $command);
      }
    }

    return $violations;
  }

  /**
   * Splits a "run" script into its separate shell commands.
   *
   * Expressions are blanked first, as their "&&" and "||" are not shell
   * operators, and continued lines are joined into 1 command.
   *
   * @return list<string>
   *   The trimmed, non-empty commands.
   */
  protected static function shellCommands(string $run): array {
    $script = (string) preg_replace('/\$\{\{.*?\}\}/s', 'EXPRESSION', $run);
    $script = (string) preg_replace('/\\\\\R/', ' ', $script);

    $commands = preg_split('/&&|\|\||[;|]|\R/', $script) ?: [];

    return array_values(array_filter(array_map(trim(...), $commands), static fn(string $command): bool => $command !== ''));
  }

}
