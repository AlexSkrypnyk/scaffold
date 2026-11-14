<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests;

use PHPUnit\Framework\Attributes\DataProvider;
use Symfony\Component\Finder\Finder;
use Symfony\Component\Yaml\Yaml;

/**
 * Checks the workflows that upload release assets.
 *
 * An immutable release takes no assets once published, so each such workflow
 * runs on a pushed tag only and attaches its assets to the draft. It also
 * attaches its attestation bundle, as Scorecard reads provenance from release
 * assets only.
 */
final class ReleaseWorkflowTest extends UnitTestCase {

  /**
   * @param list<string>|null $arguments
   *   Arguments for install.sh, or NULL to check the template itself.
   * @param list<string> $expected
   *   File names of the workflows expected to upload release assets.
   */
  #[DataProvider('dataProviderReleaseWorkflows')]
  public function testReleaseWorkflows(?array $arguments, array $expected): void {
    self::$fixtures = NULL;

    if ($arguments !== NULL) {
      $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', $arguments);
      $this->assertProcessSuccessful();
    }

    $finder = (new Finder())->files()->in(self::$sut . '/.github/workflows')->name(['*.yml', '*.yaml'])->sortByName();

    $uploading = [];
    $violations = [];

    foreach ($finder as $file) {
      $workflow = Yaml::parseFile($file->getPathname());
      $this->assertIsArray($workflow, $file->getFilename() . ' is not a YAML map.');

      if (!self::uploadsReleaseAssets($workflow)) {
        continue;
      }

      $uploading[] = $file->getFilename();
      $violations = array_merge($violations, self::releaseViolations($file->getFilename(), $workflow));
    }

    $this->assertSame($expected, $uploading);
    $this->assertSame([], $violations);
  }

  public static function dataProviderReleaseWorkflows(): \Iterator {
    yield 'template' => [NULL, ['release-nodejs.yml', 'release-php.yml', 'scaffold-release-installer.yml']];
    yield 'generated project' => [['--namespace=YodasHut', '--name=force-crystal', '--author=Luke Skywalker'], ['release-nodejs.yml', 'release-php.yml']];
  }

  /**
   * @param array<mixed> $workflow
   *   The parsed workflow.
   * @param list<string> $expected
   *   The expected violation messages.
   */
  #[DataProvider('dataProviderReleaseViolations')]
  public function testReleaseViolations(array $workflow, array $expected): void {
    $this->assertSame($expected, self::releaseViolations('release.yml', $workflow));
  }

  public static function dataProviderReleaseViolations(): \Iterator {
    $attest = ['id' => 'attest', 'uses' => 'actions/attest-build-provenance@0000000000000000000000000000000000000000'];
    $bundle = ['env' => ['BUNDLE_PATH' => '${{ steps.attest.outputs.bundle-path }}'], 'run' => 'cp "${BUNDLE_PATH}" ".release/name.intoto.jsonl"'];
    $upload = ['run' => 'gh release upload "${TAG}" .release/*'];
    $tags = ['push' => ['tags' => ['[0-9]+.[0-9]+.[0-9]+']]];

    yield 'tag push with bundle' => [['on' => $tags, 'jobs' => ['build' => ['steps' => [$attest, $bundle]], 'publish' => ['steps' => [$upload]]]], []];
    yield 'release event' => [['on' => ['release' => ['types' => ['published']]], 'jobs' => ['publish' => ['steps' => [$attest, $bundle, $upload]]]], ['release.yml runs on "release", not only on a pushed tag.', 'release.yml runs on a push without "tags".']];
    yield 'manual run' => [['on' => [...$tags, 'workflow_dispatch' => NULL], 'jobs' => ['publish' => ['steps' => [$attest, $bundle, $upload]]]], ['release.yml runs on "workflow_dispatch", not only on a pushed tag.']];
    yield 'branch push' => [['on' => ['push' => ['branches' => ['main']]], 'jobs' => ['publish' => ['steps' => [$attest, $bundle, $upload]]]], ['release.yml runs on a push without "tags".']];
    yield 'attestation without id' => [['on' => $tags, 'jobs' => ['publish' => ['steps' => [['uses' => $attest['uses']], $bundle, $upload]]]], ['release.yml attaches no ".intoto.jsonl" attestation bundle.']];
    yield 'no bundle' => [['on' => $tags, 'jobs' => ['publish' => ['steps' => [$attest, $upload]]]], ['release.yml attaches no ".intoto.jsonl" attestation bundle.']];
  }

  /**
   * @param array<mixed> $workflow
   *   The parsed workflow.
   */
  protected static function uploadsReleaseAssets(array $workflow): bool {
    foreach (self::steps($workflow) as $step) {
      if (is_string($step['run'] ?? NULL) && str_contains($step['run'], 'gh release upload')) {
        return TRUE;
      }
    }

    return FALSE;
  }

  /**
   * @param array<mixed> $workflow
   *   The parsed workflow.
   *
   * @return list<string>
   *   1 message per violation.
   */
  protected static function releaseViolations(string $name, array $workflow): array {
    $violations = [];

    $triggers = is_array($workflow['on'] ?? NULL) ? $workflow['on'] : [];

    foreach (array_keys($triggers) as $trigger) {
      if ($trigger !== 'push') {
        $violations[] = sprintf('%s runs on "%s", not only on a pushed tag.', $name, $trigger);
      }
    }

    $push = $triggers['push'] ?? NULL;

    if (!is_array($push) || !isset($push['tags']) || isset($push['branches'])) {
      $violations[] = sprintf('%s runs on a push without "tags".', $name);
    }

    $attest_ids = [];

    foreach (self::steps($workflow) as $step) {
      if (is_string($step['uses'] ?? NULL) && str_starts_with($step['uses'], 'actions/attest-build-provenance@') && is_string($step['id'] ?? NULL)) {
        $attest_ids[] = $step['id'];
      }
    }

    foreach (self::steps($workflow) as $step) {
      $env = is_array($step['env'] ?? NULL) ? $step['env'] : [];
      $run = is_string($step['run'] ?? NULL) ? $step['run'] : '';

      foreach ($attest_ids as $id) {
        if (in_array(sprintf('${{ steps.%s.outputs.bundle-path }}', $id), $env, TRUE) && str_contains($run, '.intoto.jsonl')) {
          return $violations;
        }
      }
    }

    $violations[] = sprintf('%s attaches no ".intoto.jsonl" attestation bundle.', $name);

    return $violations;
  }

  /**
   * @param array<mixed> $workflow
   *   The parsed workflow.
   *
   * @return list<array<mixed>>
   *   The steps of every job, in order.
   */
  protected static function steps(array $workflow): array {
    $steps = [];
    $jobs = is_array($workflow['jobs'] ?? NULL) ? $workflow['jobs'] : [];

    foreach ($jobs as $job) {
      if (!is_array($job) || !is_array($job['steps'] ?? NULL)) {
        continue;
      }

      foreach ($job['steps'] as $step) {
        if (is_array($step)) {
          $steps[] = $step;
        }
      }
    }

    return $steps;
  }

}
