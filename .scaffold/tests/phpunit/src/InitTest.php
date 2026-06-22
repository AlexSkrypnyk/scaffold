<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests;

use AlexSkrypnyk\File\File;
use AlexSkrypnyk\Snapshot\Replacer\Replacer;
use Laravel\SerializableClosure\SerializableClosure;
use PHPUnit\Framework\Attributes\DataProvider;

/**
 * Class InitFunctionalTest.
 *
 * Functional tests for init.sh script.
 */
final class InitTest extends UnitTestCase {

  #[DataProvider('dataProviderInit')]
  public function testInit(
    array $answers = [],
    array $expected = [],
    ?SerializableClosure $before = NULL,
    ?SerializableClosure $after = NULL,
  ): void {
    self::$fixtures = static::locationsFixtureDir();

    if ($before instanceof SerializableClosure) {
      $before = self::cu($before);
      $before($this);
    }

    $answers = self::tuiEntries(array_replace(self::defaultAnswers(), $answers));

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', [], $answers);

    $this->assertProcessSuccessful();

    $expected = array_merge($expected, [
      'Summary',
      'Initialization complete.',
    ], $answers);

    $this->assertProcessOutputContainsOrNot($expected);

    $baseline = File::dir(self::$fixtures . '/../' . self::BASELINE_DIR);
    Replacer::versions()->replaceInDir(self::$sut);

    if (!is_string(self::$fixtures)) {
      throw new \RuntimeException('Fixtures directory is not set.');
    }
    $this->assertSnapshotMatchesBaseline(self::$sut, $baseline, self::$fixtures);

    if ($after instanceof SerializableClosure) {
      $after = self::cu($after);
      $after($this);
    }
  }

  /**
   * Non-interactive runs must produce the same result as interactive defaults.
   */
  #[DataProvider('dataProviderInitNonInteractive')]
  public function testInitNonInteractive(array $arguments, string $diffs_name): void {
    // Parity checks compare against the existing interactive fixtures, so a
    // divergence must surface as a failure to fix in code, never an update.
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', $arguments);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');
    $this->assertProcessOutputNotContains([
      'Please follow the prompts',
      'Proceed with project init',
    ]);

    Replacer::versions()->replaceInDir(self::$sut);

    $fixtures_init = self::$root . DIRECTORY_SEPARATOR . 'fixtures' . DIRECTORY_SEPARATOR . 'init';
    $baseline = File::dir($fixtures_init . DIRECTORY_SEPARATOR . self::BASELINE_DIR);
    $diffs = File::dir($fixtures_init . DIRECTORY_SEPARATOR . $diffs_name);

    $this->assertSnapshotMatchesBaseline(self::$sut, $baseline, $diffs);
  }

  /**
   * The script initialises a project when fetched and piped through curl.
   */
  public function testInitViaCurlWithArgs(): void {
    self::$fixtures = NULL;

    $url = 'file://' . self::$sut . DIRECTORY_SEPARATOR . 'init.sh';
    $script = sprintf(
      'set -o pipefail; curl -fsSL %s | bash -s -- --namespace=CurlNs --name=curl-proj --author=%s',
      escapeshellarg($url),
      escapeshellarg('Curl Author'),
    );

    $this->processRun('bash', ['-c', $script]);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');

    $composer_path = self::$sut . DIRECTORY_SEPARATOR . 'composer.json';
    $this->assertFileExists($composer_path);
    $composer = (string) file_get_contents($composer_path);
    $this->assertStringContainsString('CurlNs', $composer);
    $this->assertStringNotContainsString('YourNamespace', $composer);
  }

  /**
   * Piping through curl without options fails cleanly instead of hanging.
   */
  public function testInitViaCurlWithoutArgs(): void {
    self::$fixtures = NULL;

    $url = 'file://' . self::$sut . DIRECTORY_SEPARATOR . 'init.sh';
    $script = sprintf('set -o pipefail; curl -fsSL %s | bash -s --', escapeshellarg($url));

    $this->processRun('bash', ['-c', $script]);

    $this->assertProcessFailed();
    $this->assertProcessErrorOutputContains('No input available');

    // The aborted run must leave the project untouched.
    $composer_path = self::$sut . DIRECTORY_SEPARATOR . 'composer.json';
    $this->assertFileExists($composer_path);
    $composer = (string) file_get_contents($composer_path);
    $this->assertStringContainsString('YourNamespace', $composer);
  }

  /**
   * The initialised project keeps the updater skill pointing upstream.
   *
   * The bulk `scaffold` -> project rewrite in init.sh would otherwise
   * mangle the self-update skill URL, name, and trigger. They are
   * token-protected, so a regression here must fail loudly rather than
   * being silently re-baselined.
   */
  public function testInitPreservesUpdateSkillReferences(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', [
      '--namespace=AcmeApp',
      '--name=acme-app',
      '--author=Jane Doe',
    ]);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');

    $agents = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'AGENTS.md');
    $this->assertStringContainsString('https://raw.githubusercontent.com/AlexSkrypnyk/scaffold/main/.scaffold/skills/update-consumer-scaffold/SKILL.md', $agents);
    $this->assertStringContainsString('"update scaffold"', $agents);
    $this->assertStringNotContainsString('update-consumer-acme-app', $agents);

    $gitignore = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . '.gitignore');
    $this->assertStringContainsString('/.claude/skills/update-consumer-scaffold/', $gitignore);
  }

  public static function dataProviderInitNonInteractive(): \Iterator {
    $identity = ['--namespace=YodasHut', '--name=force-crystal', '--author=Luke Skywalker'];

    yield 'all defaults' => [
      $identity,
      self::BASELINE_DIR,
    ];
    yield 'no docs' => [
      array_merge($identity, ['--no-docs']),
      'no_docs',
    ];
  }

  public static function dataProviderInit(): \Iterator {
    yield self::BASELINE_DATASET => [
        [],
    ];
    yield 'name' => [
        [
          'namespace' => 'JediTemple',
          'project' => 'star-forge',
          'author' => 'Obi-Wan Kenobi',
        ],
    ];
    yield 'php command' => [
        [
          'use_php' => self::$tuiYes,
          'use_php_command' => self::$tuiYes,
          'php_command_name' => 'star-forge',
          'use_nodejs' => self::$tuiNo,
          'use_shell' => self::$tuiNo,
        ],
    ];
    yield 'php script' => [
        [
          'use_php' => self::$tuiYes,
          'use_php_command' => self::$tuiNo,
          'use_php_script' => self::$tuiYes,
          'use_nodejs' => self::$tuiNo,
          'use_shell' => self::$tuiNo,
        ],
    ];
    yield 'nodejs' => [
        [
          'use_php' => self::$tuiNo,
          'use_nodejs' => self::$tuiYes,
          'use_shell' => self::$tuiNo,
        ],
    ];
    yield 'shell' => [
        [
          'use_php' => self::$tuiNo,
          'use_nodejs' => self::$tuiNo,
          'use_shell' => self::$tuiYes,
        ],
    ];
    yield 'no languages' => [
        [
          'use_php' => self::$tuiNo,
          'use_php_command' => self::TUI_SKIP,
          'php_command_name' => self::TUI_SKIP,
          'use_php_command_build' => self::TUI_SKIP,
          'use_php_script' => self::TUI_SKIP,
          'use_nodejs' => self::$tuiNo,
          'use_shell' => self::$tuiNo,
        ],
    ];
    yield 'docker' => [
        [
          'use_php' => self::$tuiNo,
          'use_php_command' => self::TUI_SKIP,
          'php_command_name' => self::TUI_SKIP,
          'use_php_command_build' => self::TUI_SKIP,
          'use_php_script' => self::TUI_SKIP,
          'use_nodejs' => self::$tuiNo,
          'use_shell' => self::$tuiNo,
          'use_docker' => self::$tuiYes,
          'docker_image_name' => self::TUI_DEFAULT,
        ],
    ];
    yield 'no release drafter' => [
        [
          'use_release_drafter' => self::$tuiNo,
        ],
    ];
    yield 'no pr autoassign' => [
        [
          'use_pr_autoassign' => self::$tuiNo,
        ],
    ];
    yield 'no funding' => [
        [
          'use_funding' => self::$tuiNo,
        ],
    ];
    yield 'no pr template' => [
        [
          'use_pr_template' => self::$tuiNo,
        ],
    ];
    yield 'no renovate' => [
        [
          'use_renovate' => self::$tuiNo,
        ],
    ];
    yield 'no docs' => [
        [
          'use_docs' => self::$tuiNo,
        ],
    ];
  }

  protected static function defaultAnswers(): array {
    return [
      'namespace' => 'YodasHut',
      'project' => 'force-crystal',
      'author' => 'Luke Skywalker',
      'use_php' => self::TUI_DEFAULT,
      'use_php_command' => self::TUI_DEFAULT,
      'php_command_name' => self::TUI_DEFAULT,
      'use_php_command_build' => self::TUI_DEFAULT,
      'use_php_script' => self::TUI_DEFAULT,
      'use_nodejs' => self::TUI_DEFAULT,
      'use_shell' => self::TUI_DEFAULT,
      'use_docker' => self::TUI_DEFAULT,
      'docker_image_name' => self::TUI_SKIP,
      'use_release_drafter' => self::TUI_DEFAULT,
      'use_pr_autoassign' => self::TUI_DEFAULT,
      'use_funding' => self::TUI_DEFAULT,
      'use_pr_template' => self::TUI_DEFAULT,
      'use_renovate' => self::TUI_DEFAULT,
      'use_docs' => self::TUI_DEFAULT,
      'remove_self' => self::TUI_DEFAULT,
    ];
  }

}
