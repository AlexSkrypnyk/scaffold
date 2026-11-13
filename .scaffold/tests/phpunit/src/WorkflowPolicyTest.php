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
 * credentials, and every dependency install skips the dependencies' scripts.
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

    foreach ($finder as $file) {
      $workflow = Yaml::parseFile($file->getPathname());
      $this->assertIsArray($workflow, $file->getFilename() . ' is not a YAML map.');

      $violations = array_merge($violations, self::workflowViolations($file->getFilename(), $workflow));
    }

    $this->assertSame([], $violations);
  }

  public static function dataProviderWorkflowPolicy(): \Iterator {
    yield 'template' => [NULL];
    yield 'generated project with every workflow' => [['--namespace=YodasHut', '--name=force-crystal', '--author=Luke Skywalker', '--docker', '--test-actions']];
  }

  /**
   * @param array<mixed> $workflow
   *   The parsed workflow.
   *
   * @return list<string>
   *   1 message per violation.
   */
  protected static function workflowViolations(string $name, array $workflow): array {
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
          $violations = array_merge($violations, self::runViolations($step_location, $step['run']));
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
  protected static function runViolations(string $location, string $run): array {
    $violations = [];

    foreach (preg_split('/\R/', $run) ?: [] as $line) {
      $words = preg_split('/\s+/', trim($line)) ?: [];

      if (in_array('npm', $words, TRUE) && array_intersect($words, ['install', 'i', 'ci', 'add']) !== [] && !in_array('--ignore-scripts', $words, TRUE)) {
        $violations[] = sprintf('%s runs "%s" without "--ignore-scripts".', $location, trim($line));
      }

      if (in_array('composer', $words, TRUE) && array_intersect($words, ['install', 'update', 'require']) !== [] && !in_array('--no-scripts', $words, TRUE)) {
        $violations[] = sprintf('%s runs "%s" without "--no-scripts".', $location, trim($line));
      }
    }

    return $violations;
  }

}
