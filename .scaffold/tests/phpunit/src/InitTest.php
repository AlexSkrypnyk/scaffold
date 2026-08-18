<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests;

use AlexSkrypnyk\File\File;
use AlexSkrypnyk\Snapshot\Replacer\Replacer;
use Laravel\SerializableClosure\SerializableClosure;
use PHPUnit\Framework\Attributes\DataProvider;
use Symfony\Component\Finder\Finder;
use Symfony\Component\Process\ExecutableFinder;

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
    self::$fixtures = self::locationsFixtureDir();

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
    yield 'php library' => [
        [
          'use_php' => self::$tuiYes,
          'use_php_command' => self::$tuiNo,
          // Declining the command app skips its name and PHAR prompts, and
          // declining the script skips its name prompt.
          'php_command_name' => self::TUI_SKIP,
          'use_php_command_build' => self::TUI_SKIP,
          'use_php_script' => self::$tuiNo,
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
    yield 'test actions' => [
        [
          'use_test_actions' => self::$tuiYes,
        ],
    ];
    yield 'no schedule' => [
        [
          'use_schedule' => self::$tuiNo,
        ],
    ];
    yield 'no ai' => [
        [
          'use_ai' => self::$tuiNo,
          'use_ai_arch_docs' => self::TUI_SKIP,
        ],
    ];
    yield 'ai arch docs plantuml' => [
        [
          'use_ai_arch_docs' => 'plantuml',
        ],
    ];
    yield 'no ai arch docs' => [
        [
          'use_ai_arch_docs' => 'none',
        ],
    ];
    yield 'no docs no ai arch docs' => [
        [
          'use_docs' => self::$tuiNo,
          'use_ai_arch_docs' => 'none',
        ],
    ];
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

  public static function dataProviderInitNonInteractive(): \Iterator {
    $identity = ['--namespace=YodasHut', '--name=force-crystal', '--author=Luke Skywalker'];

    yield 'all defaults' => [
      $identity,
      self::BASELINE_DIR,
    ];
    yield 'php library' => [
      array_merge($identity, ['--no-php-command', '--no-php-script']),
      'php_library',
    ];
    yield 'no docs' => [
      array_merge($identity, ['--no-docs']),
      'no_docs',
    ];
    yield 'test actions' => [
      array_merge($identity, ['--test-actions']),
      'test_actions',
    ];
    yield 'no schedule' => [
      array_merge($identity, ['--no-schedule']),
      'no_schedule',
    ];
    yield 'no ai' => [
      array_merge($identity, ['--no-ai']),
      'no_ai',
    ];
    yield 'ai arch docs plantuml' => [
      array_merge($identity, ['--ai-arch-docs=plantuml']),
      'ai_arch_docs_plantuml',
    ];
    yield 'no ai arch docs' => [
      array_merge($identity, ['--no-ai-arch-docs']),
      'no_ai_arch_docs',
    ];
    yield 'no docs no ai arch docs' => [
      array_merge($identity, ['--no-docs', '--no-ai-arch-docs']),
      'no_docs_no_ai_arch_docs',
    ];
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
   * The script bootstraps the template when piped into an empty directory.
   *
   * With no template present, init.sh downloads and extracts the Scaffold into
   * the current directory, then initialises it. The archive is injected via
   * SCAFFOLD_ARCHIVE_URL so the test never reaches the network.
   */
  public function testInitViaCurlBootstrapsIntoEmptyDir(): void {
    self::$fixtures = NULL;

    // GitHub archives nest everything under a top-level directory, so the
    // pristine SUT copy is archived under its own basename. init.sh strips
    // that component on extraction, as with a real GitHub tarball.
    $archive = self::$tmp . DIRECTORY_SEPARATOR . 'scaffold.tar.gz';
    $this->processRun('tar', ['-czf', $archive, '-C', dirname(self::$sut), basename(self::$sut)]);
    $this->assertProcessSuccessful();

    $target = File::mkdir(self::$tmp . DIRECTORY_SEPARATOR . 'bootstrap-target');

    $url = 'file://' . self::$sut . DIRECTORY_SEPARATOR . 'init.sh';
    $script = sprintf(
      'set -o pipefail; curl -fsSL %s | bash -s -- --namespace=CurlNs --name=curl-proj --author=%s',
      escapeshellarg($url),
      escapeshellarg('Curl Author'),
    );

    $this->processCwd = $target;
    $this->processRun('bash', ['-c', $script], [], ['SCAFFOLD_ARCHIVE_URL' => 'file://' . $archive]);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Downloading Scaffold from');
    $this->assertProcessOutputContains('Initialization complete.');

    // The template was downloaded and initialised in the target directory.
    $composer_path = $target . DIRECTORY_SEPARATOR . 'composer.json';
    $this->assertFileExists($composer_path);
    $composer = (string) file_get_contents($composer_path);
    $this->assertStringContainsString('CurlNs', $composer);
    $this->assertStringNotContainsString('YourNamespace', $composer);

    // The downloaded archive and the template marker are cleaned up by init.
    $this->assertFileDoesNotExist($target . DIRECTORY_SEPARATOR . 'scaffold.tar.gz');
    $this->assertDirectoryDoesNotExist($target . DIRECTORY_SEPARATOR . '.scaffold');
  }

  /**
   * Bootstrapping refuses to run in a directory that already has files.
   *
   * The run must abort before anything is downloaded when the current
   * directory is not empty, so pre-existing files are never clobbered.
   */
  public function testInitViaCurlBootstrapRefusesNonEmptyDir(): void {
    self::$fixtures = NULL;

    $archive = self::$tmp . DIRECTORY_SEPARATOR . 'scaffold.tar.gz';
    $this->processRun('tar', ['-czf', $archive, '-C', dirname(self::$sut), basename(self::$sut)]);
    $this->assertProcessSuccessful();

    $target = File::mkdir(self::$tmp . DIRECTORY_SEPARATOR . 'nonempty-target');
    File::dump($target . DIRECTORY_SEPARATOR . 'keep.txt', 'existing');

    $url = 'file://' . self::$sut . DIRECTORY_SEPARATOR . 'init.sh';
    $script = sprintf(
      'set -o pipefail; curl -fsSL %s | bash -s -- --namespace=CurlNs --name=curl-proj --author=%s',
      escapeshellarg($url),
      escapeshellarg('Curl Author'),
    );

    $this->processCwd = $target;
    $this->processRun('bash', ['-c', $script], [], ['SCAFFOLD_ARCHIVE_URL' => 'file://' . $archive]);

    $this->assertProcessFailed();
    $this->assertProcessErrorOutputContains('current directory is not empty');

    // The stray file is untouched and no template was extracted.
    $this->assertFileExists($target . DIRECTORY_SEPARATOR . 'keep.txt');
    $this->assertDirectoryDoesNotExist($target . DIRECTORY_SEPARATOR . '.scaffold');
    $this->assertFileDoesNotExist($target . DIRECTORY_SEPARATOR . 'composer.json');
  }

  /**
   * Piping with no options bootstraps, then reaches interactive prompting.
   *
   * `curl ... | bash` with no options must download and extract the template
   * and then re-run to prompt the user. The test environment has no terminal,
   * so the prompt has nothing to read and the run aborts cleanly. The clean
   * abort proves the bootstrap completed and control reached the interactive
   * collector; a real user with a terminal answers the prompts instead.
   */
  public function testInitViaCurlBootstrapsThenPromptsWithoutOptions(): void {
    self::$fixtures = NULL;

    $archive = self::$tmp . DIRECTORY_SEPARATOR . 'scaffold.tar.gz';
    $this->processRun('tar', ['-czf', $archive, '-C', dirname(self::$sut), basename(self::$sut)]);
    $this->assertProcessSuccessful();

    $target = File::mkdir(self::$tmp . DIRECTORY_SEPARATOR . 'prompt-target');

    $url = 'file://' . self::$sut . DIRECTORY_SEPARATOR . 'init.sh';
    $script = sprintf('set -o pipefail; curl -fsSL %s | bash', escapeshellarg($url));

    $this->processCwd = $target;
    $this->processRun('bash', ['-c', $script], [], ['SCAFFOLD_ARCHIVE_URL' => 'file://' . $archive]);

    // No terminal to read prompts from, so the interactive run aborts cleanly.
    $this->assertProcessFailed();
    $this->assertProcessErrorOutputContains('No input available');

    // The template was still downloaded and extracted before prompting.
    $this->assertFileExists($target . DIRECTORY_SEPARATOR . 'composer.json');
    $this->assertDirectoryExists($target . DIRECTORY_SEPARATOR . 'src');
  }

  /**
   * An archive without a '.scaffold' leaves the target directory clean.
   *
   * The download is staged and validated before anything is promoted. An
   * archive that is not a Scaffold (or a partial extraction) must abort the
   * run without leaving debris that would trip the empty-directory guard on
   * a retry.
   */
  public function testInitViaCurlBootstrapCleansUpInvalidArchive(): void {
    self::$fixtures = NULL;

    // An archive that extracts to content but has no '.scaffold' directory.
    $fake = File::mkdir(self::$tmp . DIRECTORY_SEPARATOR . 'not-a-scaffold');
    File::dump($fake . DIRECTORY_SEPARATOR . 'hello.txt', 'hi');
    $archive = self::$tmp . DIRECTORY_SEPARATOR . 'not-scaffold.tar.gz';
    $this->processRun('tar', ['-czf', $archive, '-C', dirname($fake), basename($fake)]);
    $this->assertProcessSuccessful();

    $target = File::mkdir(self::$tmp . DIRECTORY_SEPARATOR . 'invalid-target');

    $url = 'file://' . self::$sut . DIRECTORY_SEPARATOR . 'init.sh';
    $script = sprintf(
      'set -o pipefail; curl -fsSL %s | bash -s -- --namespace=CurlNs --name=curl-proj --author=%s',
      escapeshellarg($url),
      escapeshellarg('Curl Author'),
    );

    $this->processCwd = $target;
    $this->processRun('bash', ['-c', $script], [], ['SCAFFOLD_ARCHIVE_URL' => 'file://' . $archive]);

    $this->assertProcessFailed();
    $this->assertProcessErrorOutputContains('not a Scaffold template');

    // No staging directory and no extracted debris remain in the target.
    $this->assertDirectoryDoesNotExist($target . DIRECTORY_SEPARATOR . '.scaffold-bootstrap');
    $this->assertFileDoesNotExist($target . DIRECTORY_SEPARATOR . 'hello.txt');
    $this->assertFileDoesNotExist($target . DIRECTORY_SEPARATOR . 'composer.json');
  }

  /**
   * The initialised project keeps the updater skill pointing upstream.
   *
   * The bulk `scaffold` -> project rewrite in init.sh would otherwise
   * mangle the self-update skill URL, name, and trigger. They are
   * token-protected, so a regression here must fail rather than be
   * silently re-baselined.
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

  /**
   * The initialised project keeps the Scaffold attribution footer intact.
   *
   * The bulk `scaffold` -> project rewrite in init.sh would otherwise
   * mangle the README footer link text and domain into a project-named URL
   * that does not exist. The phrase is token-protected, so a regression must
   * fail rather than be silently re-baselined.
   */
  public function testInitPreservesAttributionFooter(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', [
      '--namespace=AcmeApp',
      '--name=acme-app',
      '--author=Jane Doe',
    ]);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');

    $readme = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'README.md');
    $this->assertStringContainsString('_This repository was created using the [Scaffold](https://getscaffold.dev/) project template_', $readme);
    $this->assertStringNotContainsString('getacme-app.dev', $readme);
  }

  /**
   * The initialised project keeps a LICENSE matching its declared metadata.
   *
   * init.sh must not delete LICENSE: without it GitHub cannot detect the
   * project's license and the README badge renders "not identified", while
   * composer.json and package.json still declare GPL-3.0-or-later. A
   * regression here must fail rather than be silently re-baselined by
   * update-snapshots.
   */
  public function testInitKeepsLicense(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', [
      '--namespace=AcmeApp',
      '--name=acme-app',
      '--author=Jane Doe',
    ]);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');

    $license_path = self::$sut . DIRECTORY_SEPARATOR . 'LICENSE';
    $this->assertFileExists($license_path);
    $license = (string) file_get_contents($license_path);
    $this->assertStringContainsString('GNU GENERAL PUBLIC LICENSE', $license);
    $this->assertStringContainsString('Version 3', $license);

    $composer = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'composer.json');
    $this->assertStringContainsString('"license": "GPL-3.0-or-later"', $composer);

    $package = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'package.json');
    $this->assertStringContainsString('"license": "GPL-3.0-or-later"', $package);

    $bats_package = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'tests' . DIRECTORY_SEPARATOR . 'bats' . DIRECTORY_SEPARATOR . 'package.json');
    $this->assertStringContainsString('"license": "GPL-3.0-or-later"', $bats_package);
  }

  /**
   * Declining both PHP entry points leaves the tooling and no stubs.
   *
   * A class-only package has no command and no script, so init.sh must
   * generate neither - while keeping 'src' in the linting and test
   * configuration and dropping the 'composer.json' bin section, which
   * 'composer normalize' rejects once it is empty.
   */
  public function testInitPhpLibraryShipsNoEntryPoint(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', [
      '--namespace=AcmeApp',
      '--name=acme-app',
      '--author=Jane Doe',
      '--php',
      '--no-php-command',
      '--no-php-script',
    ]);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');

    $this->assertFileDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . 'acme-app');
    $this->assertFileDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . 'php-command');
    $this->assertFileDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . 'php-script');
    $this->assertFileDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . 'box.json');
    $this->assertDirectoryDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . 'src' . DIRECTORY_SEPARATOR . 'Command');

    // PHPCS and PHPStan both fail when pointed at a project with no PHP file,
    // so the mode ships one placeholder class and its test.
    $this->assertFileExists(self::$sut . DIRECTORY_SEPARATOR . 'src' . DIRECTORY_SEPARATOR . 'Example.php');
    $this->assertFileExists(self::$sut . DIRECTORY_SEPARATOR . 'tests' . DIRECTORY_SEPARATOR . 'phpunit' . DIRECTORY_SEPARATOR . 'Unit' . DIRECTORY_SEPARATOR . 'ExampleUnitTest.php');

    $composer = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'composer.json');
    $this->assertJson($composer);
    $this->assertStringNotContainsString('"bin"', $composer);
    $this->assertStringContainsString('"AcmeApp\\\\App\\\\": "src/"', $composer);

    $phpcs = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'phpcs.xml');
    $this->assertStringContainsString('<file>src</file>', $phpcs);
    $this->assertStringNotContainsString('<file>acme-app</file>', $phpcs);

    $phpstan = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'phpstan.neon');
    $this->assertStringContainsString('- src', $phpstan);
    $this->assertStringNotContainsString('- acme-app', $phpstan);

    $phpunit = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'phpunit.xml');
    $this->assertStringContainsString('<directory>src</directory>', $phpunit);
    $this->assertStringNotContainsString('<file>acme-app</file>', $phpunit);

    $readme = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'README.md');
    $this->assertStringNotContainsString('vendor/bin/acme-app', $readme);
    $this->assertStringContainsString('use AcmeApp\App\Example;', $readme);
    $this->assertStringContainsString("->greet('World')", $readme);
  }

  /**
   * A project generated with Actions linting must pass the zizmor audit.
   *
   * Mirrors the audit the shipped "Test Actions" workflow runs, using the
   * generated suppression config, so consumer projects stay clean without a
   * manual check.
   */
  public function testInitTestActionsPassesZizmor(): void {
    self::$fixtures = NULL;

    $zizmor = (new ExecutableFinder())->find('zizmor');

    if (!is_string($zizmor)) {
      $this->markTestSkipped('The "zizmor" binary is not available.');
    }

    $arguments = ['--namespace=YodasHut', '--name=force-crystal', '--author=Luke Skywalker', '--test-actions'];
    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', $arguments);
    $this->assertProcessSuccessful();

    $this->processRun($zizmor, ['--offline', '--config', 'zizmor.yml', '.github/workflows']);
    $this->assertProcessSuccessful();
  }

  /**
   * The shared Claude settings ship and are trimmed to the selected features.
   *
   * @param list<string> $arguments
   *   Command-line arguments passed to init.sh.
   * @param list<string> $present
   *   Permission rules that must be present in the settings file.
   * @param list<string> $absent
   *   Permission rules that must be absent from the settings file.
   */
  #[DataProvider('dataProviderInitClaudeSettings')]
  public function testInitClaudeSettings(array $arguments, array $present, array $absent): void {
    self::$fixtures = NULL;

    $arguments = array_merge(['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe'], $arguments);
    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', $arguments);
    $this->assertProcessSuccessful();

    $claude_dir = self::$sut . DIRECTORY_SEPARATOR . '.claude';
    $this->assertFileExists($claude_dir . DIRECTORY_SEPARATOR . 'settings.json');
    // Personal overrides must never leak into a generated project.
    $this->assertFileDoesNotExist($claude_dir . DIRECTORY_SEPARATOR . 'settings.local.json');

    $content = (string) file_get_contents($claude_dir . DIRECTORY_SEPARATOR . 'settings.json');
    // Decoding without errors proves the file is valid JSON (no dangling
    // comma) after trimming.
    $this->assertJson($content);

    foreach ($present as $rule) {
      $this->assertStringContainsString('"' . $rule . '"', $content);
    }
    foreach ($absent as $rule) {
      $this->assertStringNotContainsString('"' . $rule . '"', $content);
    }

    $gitignore = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . '.gitignore');
    $this->assertStringContainsString('!/.claude/', $gitignore);
    $this->assertStringContainsString('/.claude/settings.local.json', $gitignore);
    $this->assertStringContainsString('/.artifacts/', $gitignore);
  }

  public static function dataProviderInitClaudeSettings(): \Iterator {
    // Docker is off by default, so its rules are trimmed unless enabled.
    // Mermaid is the default diagram format, so the PlantUML rule is trimmed
    // unless that format is selected.
    yield 'defaults' => [
      [],
      ['Bash(composer:*)', 'Bash(./vendor/bin/phpunit:*)', 'Bash(./tests/bats/node_modules/bats/bin/bats:*)', 'Bash(npm:*)'],
      ['Bash(docker build:*)', 'Bash(docker run:*)', 'Bash(plantuml:*)'],
    ];
    yield 'with docker' => [
      ['--docker'],
      ['Bash(docker build:*)', 'Bash(docker run:*)'],
      [],
    ];
    yield 'ai arch docs plantuml' => [
      ['--ai-arch-docs=plantuml'],
      ['Bash(plantuml:*)'],
      [],
    ];
    yield 'no php' => [
      ['--no-php'],
      ['Bash(./tests/bats/node_modules/bats/bin/bats:*)', 'Bash(npm:*)'],
      ['Bash(composer:*)', 'Bash(./vendor/bin/phpcs:*)', 'Bash(./vendor/bin/phpunit:*)'],
    ];
    yield 'npm survives via docs without nodejs' => [
      ['--no-nodejs'],
      ['Bash(npm:*)'],
      [],
    ];
    yield 'npm trimmed without nodejs and docs' => [
      ['--no-nodejs', '--no-docs'],
      [],
      ['Bash(npm:*)'],
    ];
    yield 'no languages' => [
      ['--no-php', '--no-nodejs', '--no-shell', '--no-docs'],
      [],
      ['Bash(composer:*)', 'Bash(npm:*)', 'Bash(./tests/bats/node_modules/bats/bin/bats:*)'],
    ];
  }

  /**
   * Disabling AI agents removes the Claude settings with the '.claude' dir.
   */
  public function testInitClaudeSettingsRemovedWithoutAi(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', ['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe', '--no-ai']);
    $this->assertProcessSuccessful();

    $this->assertFileDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . '.claude' . DIRECTORY_SEPARATOR . 'settings.json');
    $this->assertDirectoryDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . '.claude');
  }

  /**
   * Consumer-owned files under '.claude' survive an init run byte-for-byte.
   *
   * The update flow keeps the consumer's '.claude' across its wipe, then
   * extracts the template on top. init.sh then runs over a tree holding both
   * template-owned and consumer-owned files.
   *
   * A sweep that reaches the consumer-owned '.claude' tree rewrites the
   * fetched update skill to name the consumer's own repository. The next
   * update then pulls the wrong project.
   *
   * @param string $path
   *   Path of the consumer-owned file, relative to '.claude'.
   */
  #[DataProvider('dataProviderInitPreservesConsumerClaudeFiles')]
  public function testInitPreservesConsumerClaudeFiles(string $path): void {
    self::$fixtures = NULL;

    $claude_dir = self::$sut . DIRECTORY_SEPARATOR . '.claude';
    $file = $claude_dir . DIRECTORY_SEPARATOR . $path;
    $planted = self::consumerClaudeContent();
    File::dump($file, $planted);

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', [
      '--namespace=AcmeApp',
      '--name=acme-app',
      '--author=Jane Doe',
      '--php-command-name=acme-cli',
    ]);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');

    $this->assertSame($planted, (string) file_get_contents($file));
  }

  public static function dataProviderInitPreservesConsumerClaudeFiles(): \Iterator {
    // The skill the consumer fetches on demand to run the next update.
    yield 'update skill' => ['skills/update-consumer-scaffold/SKILL.md'];
    // Personal Claude Code overrides, git-ignored and never template-owned.
    yield 'local settings' => ['settings.local.json'];
    // A skill and an agent the consumer wrote themselves.
    yield 'consumer skill' => ['skills/acme-deploy/SKILL.md'];
    yield 'consumer agent' => ['agents/acme-reviewer.md'];
  }

  /**
   * Every string init.sh sweeps for, in a consumer-owned file.
   *
   * Each line carries a needle from process_internal() or a token marker the
   * block and comment helpers act on. Any helper that reaches this file
   * changes it.
   */
  protected static function consumerClaudeContent(): string {
    return implode("\n", [
      '# Update Scaffold',
      '',
      'gh release list --repo AlexSkrypnyk/scaffold --limit 5',
      'The scaffold template lives at [getscaffold.dev](https://getscaffold.dev).',
      'This skill scaffolds new data-flow diagrams traced from src/.',
      'Run ./php-command, ./php-script and ./shell-command.sh.',
      'Namespace YourNamespace in yournamespace/yourproject, titled Yourproject.',
      'Authored by Your Name, maintained by Alex Skrypnyk.',
      'Generic project scaffold template',
      '',
      '#;< PHP',
      'A PHP-only note.',
      '#;> PHP',
      '#; A bare marker.',
      '',
    ]);
  }

  /**
   * Template-owned '.claude' files are processed by the sweep helpers.
   *
   * The shipped 'update-architecture-docs' skill carries the diagram-format
   * token blocks. The unselected format is removed, and no raw '#;' marker or
   * unsubstituted placeholder survives under '.claude'.
   *
   * @param list<string> $arguments
   *   Command-line arguments passed to init.sh.
   * @param string $present
   *   Heading of the diagram-format section that must survive.
   * @param string $absent
   *   Heading of the diagram-format section that must be removed.
   */
  #[DataProvider('dataProviderInitProcessesShippedClaudeFiles')]
  public function testInitProcessesShippedClaudeFiles(array $arguments, string $present, string $absent): void {
    self::$fixtures = NULL;

    $arguments = array_merge(['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe'], $arguments);
    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', $arguments);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');

    $skill = self::$sut . DIRECTORY_SEPARATOR . '.claude' . DIRECTORY_SEPARATOR . 'skills' . DIRECTORY_SEPARATOR . 'update-architecture-docs' . DIRECTORY_SEPARATOR . 'SKILL.md';
    $content = (string) file_get_contents($skill);
    $this->assertStringContainsString($present, $content);
    $this->assertStringNotContainsString($absent, $content);

    // The allowlist holds only while no other shipped '.claude' file needs a
    // substitution.
    $finder = (new Finder())->files()->in(self::$sut . DIRECTORY_SEPARATOR . '.claude')->ignoreDotFiles(FALSE);
    $placeholders = ['#;', 'YourNamespace', 'yournamespace', 'yourproject', 'Yourproject', 'Your Name'];

    foreach ($finder as $file) {
      foreach ($placeholders as $placeholder) {
        $this->assertStringNotContainsString($placeholder, $file->getContents(), sprintf('Unprocessed "%s" in shipped .claude file "%s".', $placeholder, $file->getRelativePathname()));
      }
    }
  }

  public static function dataProviderInitProcessesShippedClaudeFiles(): \Iterator {
    $mermaid = '## Diagram format: Mermaid';
    $plantuml = '## Diagram format: PlantUML';

    yield 'mermaid by default' => [[], $mermaid, $plantuml];
    yield 'plantuml when selected' => [['--ai-arch-docs=plantuml'], $plantuml, $mermaid];
  }

  /**
   * The word 'scaffold' survives outside the template's self-references.
   *
   * The rename targets the repository path, the updater skill references and
   * the attribution footer. A bare-word sweep reaches ordinary prose and
   * paths that merely contain the word, and rewrites those too.
   */
  public function testInitKeepsOrdinaryScaffoldWord(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'init.sh', [
      '--namespace=AcmeApp',
      '--name=acme-app',
      '--author=Jane Doe',
    ]);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');

    // A path into the bats binary, which has no relation to the project name.
    $bats = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'tests' . DIRECTORY_SEPARATOR . 'bats' . DIRECTORY_SEPARATOR . 'shell-command.bats');
    $this->assertStringContainsString('./tests/bats/node_modules/.bin/bats', $bats);
    $this->assertStringNotContainsString('acme-app/tests/node_modules', $bats);

    // Prose naming the template the project was generated from.
    $agents = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'AGENTS.md');
    $this->assertStringContainsString('created from the Scaffold template', $agents);
    $this->assertStringNotContainsString('created from the acme-app template', $agents);
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
      'use_test_actions' => self::TUI_DEFAULT,
      'use_schedule' => self::TUI_DEFAULT,
      'use_ai' => self::TUI_DEFAULT,
      'use_ai_arch_docs' => self::TUI_DEFAULT,
      'remove_self' => self::TUI_DEFAULT,
    ];
  }

}
