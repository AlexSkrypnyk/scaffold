<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests;

use AlexSkrypnyk\File\File;
use Laravel\SerializableClosure\SerializableClosure;
use PHPUnit\Framework\Attributes\DataProvider;
use Symfony\Component\Finder\Finder;
use Symfony\Component\Process\ExecutableFinder;

/**
 * Class InitFunctionalTest.
 *
 * Functional tests for install.sh script.
 */
final class InstallTest extends UnitTestCase {

  #[DataProvider('dataProviderInstall')]
  public function testInstall(
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

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', [], $answers);

    $this->assertProcessSuccessful();

    $expected = array_merge($expected, [
      'Summary',
      'Initialization complete.',
    ], $answers);

    $this->assertProcessOutputContainsOrNot($expected);

    $baseline = File::dir(self::$fixtures . '/../' . self::BASELINE_DIR);
    File::getReplacer()->addVersionReplacements()->replaceInDir(self::$sut);

    if (!is_string(self::$fixtures)) {
      throw new \RuntimeException('Fixtures directory is not set.');
    }
    $this->assertSnapshotMatchesBaseline($baseline, self::$fixtures, self::$sut);

    if ($after instanceof SerializableClosure) {
      $after = self::cu($after);
      $after($this);
    }
  }

  public static function dataProviderInstall(): \Iterator {
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
        'use_nodejs_library' => self::TUI_SKIP,
        'use_shell' => self::$tuiNo,
        'shell_command_name' => self::TUI_SKIP,
      ],
    ];
    yield 'php script' => [
      [
        'use_php' => self::$tuiYes,
        'use_php_command' => self::$tuiNo,
        'php_command_name' => self::TUI_SKIP,
        'use_php_command_build' => self::TUI_SKIP,
        'use_php_script' => self::$tuiYes,
        'php_script_name' => self::TUI_DEFAULT,
        'use_nodejs' => self::$tuiNo,
        'use_nodejs_library' => self::TUI_SKIP,
        'use_shell' => self::$tuiNo,
        'shell_command_name' => self::TUI_SKIP,
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
    yield 'no phar' => [
      [
        'use_php_command_build' => self::$tuiNo,
      ],
    ];
    yield 'nodejs' => [
      [
        'use_php' => self::$tuiNo,
        'use_php_command' => self::TUI_SKIP,
        'php_command_name' => self::TUI_SKIP,
        'use_php_command_build' => self::TUI_SKIP,
        'use_nodejs' => self::$tuiYes,
        'use_shell' => self::$tuiNo,
        'shell_command_name' => self::TUI_SKIP,
      ],
    ];
    yield 'nodejs library' => [
      [
        'use_nodejs_library' => self::$tuiYes,
      ],
    ];
    yield 'shell' => [
      [
        'use_php' => self::$tuiNo,
        'use_php_command' => self::TUI_SKIP,
        'php_command_name' => self::TUI_SKIP,
        'use_php_command_build' => self::TUI_SKIP,
        'use_nodejs' => self::$tuiNo,
        'use_nodejs_library' => self::TUI_SKIP,
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
        'use_nodejs_library' => self::TUI_SKIP,
        'use_shell' => self::$tuiNo,
        'shell_command_name' => self::TUI_SKIP,
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
        'use_nodejs_library' => self::TUI_SKIP,
        'use_shell' => self::$tuiNo,
        'shell_command_name' => self::TUI_SKIP,
        'use_docker' => self::$tuiYes,
        'docker_image_name' => self::TUI_DEFAULT,
      ],
    ];
    yield 'docker custom image name' => [
      [
        'use_php' => self::$tuiNo,
        'use_php_command' => self::TUI_SKIP,
        'php_command_name' => self::TUI_SKIP,
        'use_php_command_build' => self::TUI_SKIP,
        'use_php_script' => self::TUI_SKIP,
        'use_nodejs' => self::$tuiNo,
        'use_nodejs_library' => self::TUI_SKIP,
        'use_shell' => self::$tuiNo,
        'shell_command_name' => self::TUI_SKIP,
        'use_docker' => self::$tuiYes,
        'docker_image_name' => 'acme/api-image',
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
    yield 'no audit' => [
      [
        'use_audit' => self::$tuiNo,
      ],
    ];
    yield 'no schedule' => [
      [
        'use_schedule' => self::$tuiNo,
      ],
    ];
    yield 'windows' => [
      [
        'use_windows' => self::$tuiYes,
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
  #[DataProvider('dataProviderInstallNonInteractive')]
  public function testInstallNonInteractive(array $arguments, string $diffs_name): void {
    // Parity checks compare against the existing interactive fixtures, so a
    // divergence must surface as a failure to fix in code, never an update.
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', $arguments);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');
    $this->assertProcessOutputNotContains([
      'Please follow the prompts',
      'Proceed with project init',
    ]);

    File::getReplacer()->addVersionReplacements()->replaceInDir(self::$sut);

    $fixtures_install = self::$root . DIRECTORY_SEPARATOR . 'fixtures' . DIRECTORY_SEPARATOR . 'install';
    $baseline = File::dir($fixtures_install . DIRECTORY_SEPARATOR . self::BASELINE_DIR);
    $diffs = File::dir($fixtures_install . DIRECTORY_SEPARATOR . $diffs_name);

    $this->assertSnapshotMatchesBaseline($baseline, $diffs, self::$sut);
  }

  public static function dataProviderInstallNonInteractive(): \Iterator {
    $identity = ['--namespace=YodasHut', '--name=force-crystal', '--author=Luke Skywalker'];

    yield 'all defaults' => [
      $identity,
      self::BASELINE_DIR,
    ];
    yield 'php library' => [
      array_merge($identity, ['--no-php-command', '--no-php-script']),
      'php_library',
    ];
    yield 'no phar' => [
      array_merge($identity, ['--no-phar']),
      'no_phar',
    ];
    yield 'no docs' => [
      array_merge($identity, ['--no-docs']),
      'no_docs',
    ];
    yield 'test actions' => [
      array_merge($identity, ['--test-actions']),
      'test_actions',
    ];
    yield 'no audit' => [
      array_merge($identity, ['--no-audit']),
      'no_audit',
    ];
    yield 'no schedule' => [
      array_merge($identity, ['--no-schedule']),
      'no_schedule',
    ];
    yield 'windows' => [
      array_merge($identity, ['--windows']),
      'windows',
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
  public function testInstallViaCurlWithArgs(): void {
    self::$fixtures = NULL;

    $url = 'file://' . self::$sut . DIRECTORY_SEPARATOR . 'install.sh';
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
  public function testInstallViaCurlWithoutArgs(): void {
    self::$fixtures = NULL;

    $url = 'file://' . self::$sut . DIRECTORY_SEPARATOR . 'install.sh';
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
   * With no template present, install.sh downloads and extracts the Scaffold
   * into the current directory, then initialises it. The archive is injected
   * via SCAFFOLD_ARCHIVE_URL so the test never reaches the network.
   */
  public function testInstallViaCurlBootstrapsIntoEmptyDir(): void {
    self::$fixtures = NULL;

    // GitHub archives nest everything under a top-level directory, so the
    // pristine SUT copy is archived under its own basename. install.sh strips
    // that component on extraction, as with a real GitHub tarball.
    $archive = self::$tmp . DIRECTORY_SEPARATOR . 'scaffold.tar.gz';
    $this->processRun('tar', ['-czf', $archive, '-C', dirname(self::$sut), basename(self::$sut)]);
    $this->assertProcessSuccessful();

    $target = File::mkdir(self::$tmp . DIRECTORY_SEPARATOR . 'bootstrap-target');

    $url = 'file://' . self::$sut . DIRECTORY_SEPARATOR . 'install.sh';
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
   * Bootstrapping an archive that ships 'init.sh' re-runs that script.
   *
   * Archives of older refs name the script 'init.sh', so the re-run must not
   * assume 'install.sh' is on disk after extraction.
   */
  public function testInstallViaCurlBootstrapsArchiveWithInitScript(): void {
    self::$fixtures = NULL;

    $piped = self::$tmp . DIRECTORY_SEPARATOR . 'install.sh';
    File::copy(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', $piped);
    File::copy(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', self::$sut . DIRECTORY_SEPARATOR . 'init.sh');
    File::remove(self::$sut . DIRECTORY_SEPARATOR . 'install.sh');

    $archive = self::$tmp . DIRECTORY_SEPARATOR . 'scaffold.tar.gz';
    $this->processRun('tar', ['-czf', $archive, '-C', dirname(self::$sut), basename(self::$sut)]);
    $this->assertProcessSuccessful();

    $target = File::mkdir(self::$tmp . DIRECTORY_SEPARATOR . 'init-script-target');

    $script = sprintf(
      'set -o pipefail; curl -fsSL %s | bash -s -- --namespace=CurlNs --name=curl-proj --author=%s',
      escapeshellarg('file://' . $piped),
      escapeshellarg('Curl Author'),
    );

    $this->processCwd = $target;
    $this->processRun('bash', ['-c', $script], [], ['SCAFFOLD_ARCHIVE_URL' => 'file://' . $archive]);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');
    $this->assertStringContainsString('CurlNs', (string) file_get_contents($target . DIRECTORY_SEPARATOR . 'composer.json'));
    $this->assertFileDoesNotExist($target . DIRECTORY_SEPARATOR . 'init.sh');
    $this->assertDirectoryDoesNotExist($target . DIRECTORY_SEPARATOR . '.scaffold');
  }

  /**
   * Bootstrapping refuses to run in a directory that already has files.
   *
   * The run must abort before anything is downloaded when the current
   * directory is not empty, so pre-existing files are never clobbered.
   */
  public function testInstallViaCurlBootstrapRefusesNonEmptyDir(): void {
    self::$fixtures = NULL;

    $archive = self::$tmp . DIRECTORY_SEPARATOR . 'scaffold.tar.gz';
    $this->processRun('tar', ['-czf', $archive, '-C', dirname(self::$sut), basename(self::$sut)]);
    $this->assertProcessSuccessful();

    $target = File::mkdir(self::$tmp . DIRECTORY_SEPARATOR . 'nonempty-target');
    File::dump($target . DIRECTORY_SEPARATOR . 'keep.txt', 'existing');

    $url = 'file://' . self::$sut . DIRECTORY_SEPARATOR . 'install.sh';
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
  public function testInstallViaCurlBootstrapsThenPromptsWithoutOptions(): void {
    self::$fixtures = NULL;

    $archive = self::$tmp . DIRECTORY_SEPARATOR . 'scaffold.tar.gz';
    $this->processRun('tar', ['-czf', $archive, '-C', dirname(self::$sut), basename(self::$sut)]);
    $this->assertProcessSuccessful();

    $target = File::mkdir(self::$tmp . DIRECTORY_SEPARATOR . 'prompt-target');

    $url = 'file://' . self::$sut . DIRECTORY_SEPARATOR . 'install.sh';
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
  public function testInstallViaCurlBootstrapCleansUpInvalidArchive(): void {
    self::$fixtures = NULL;

    // An archive that extracts to content but has no '.scaffold' directory.
    $fake = File::mkdir(self::$tmp . DIRECTORY_SEPARATOR . 'not-a-scaffold');
    File::dump($fake . DIRECTORY_SEPARATOR . 'hello.txt', 'hi');
    $archive = self::$tmp . DIRECTORY_SEPARATOR . 'not-scaffold.tar.gz';
    $this->processRun('tar', ['-czf', $archive, '-C', dirname($fake), basename($fake)]);
    $this->assertProcessSuccessful();

    $target = File::mkdir(self::$tmp . DIRECTORY_SEPARATOR . 'invalid-target');

    $url = 'file://' . self::$sut . DIRECTORY_SEPARATOR . 'install.sh';
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
   * The bulk `scaffold` -> project rewrite in install.sh would otherwise
   * mangle the self-update skill URL, name, and trigger. They are
   * token-protected, so a regression here must fail rather than be
   * silently re-baselined.
   */
  public function testInstallPreservesUpdateSkillReferences(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', [
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
   * The bulk `scaffold` -> project rewrite in install.sh would otherwise
   * mangle the README footer link text and domain into a project-named URL
   * that does not exist. The phrase is token-protected, so a regression must
   * fail rather than be silently re-baselined.
   */
  public function testInstallPreservesAttributionFooter(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', [
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
   * install.sh must not delete LICENSE: without it GitHub cannot detect the
   * project's license and the README badge renders "not identified", while
   * composer.json and package.json still declare GPL-3.0-or-later. A
   * regression here must fail rather than be silently re-baselined by
   * update-snapshots.
   */
  public function testInstallKeepsLicense(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', [
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
   * A class-only package has no command and no script, so install.sh must
   * generate neither - while keeping 'src' in the linting and test
   * configuration and dropping the 'composer.json' bin section, which
   * 'composer normalize' rejects once it is empty.
   */
  public function testInstallPhpLibraryShipsNoEntryPoint(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', [
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
    $this->assertDirectoryDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . 'bin');
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
   * Only a library stops Renovate from bumping its runtime constraints.
   *
   * @param list<string> $arguments
   *   Command-line arguments passed to install.sh.
   */
  #[DataProvider('dataProviderInstallRenovateRequireRule')]
  public function testInstallRenovateRequireRule(array $arguments, bool $expected, bool $npm_expected = FALSE): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', array_merge(['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe'], $arguments));

    $this->assertProcessSuccessful();

    $config = json_decode((string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'renovate.json'), TRUE, 512, JSON_THROW_ON_ERROR);
    $this->assertIsArray($config);
    $this->assertIsArray($config['packageRules']);

    $rule = [
      'matchManagers' => ['composer'],
      'matchFileNames' => ['composer.json'],
      'matchDepTypes' => ['require'],
      'enabled' => FALSE,
    ];
    $this->assertSame($expected, in_array($rule, $config['packageRules'], TRUE));

    $npm_rule = [
      'matchManagers' => ['npm'],
      'matchFileNames' => ['package.json'],
      'matchDepTypes' => ['dependencies'],
      'enabled' => FALSE,
    ];
    $this->assertSame($npm_expected, in_array($npm_rule, $config['packageRules'], TRUE));
  }

  public static function dataProviderInstallRenovateRequireRule(): \Iterator {
    yield 'php library' => [['--no-php-command', '--no-php-script'], TRUE];
    yield 'php library without nodejs' => [['--no-php-command', '--no-php-script', '--no-nodejs'], TRUE];
    yield 'php command' => [['--php-command', '--no-php-script'], FALSE];
    yield 'php command without phar' => [['--php-command', '--no-phar'], FALSE];
    yield 'php script' => [['--no-php-command', '--php-script'], FALSE];
    yield 'nodejs library' => [['--php-command', '--nodejs-library'], FALSE, TRUE];
    yield 'nodejs library without php' => [['--no-php', '--nodejs-library'], FALSE, TRUE];
    yield 'php and nodejs libraries' => [['--no-php-command', '--no-php-script', '--nodejs-library'], TRUE, TRUE];
  }

  /**
   * Runtime dependencies of the selected stacks get their own manual group.
   *
   * @param list<string> $arguments
   *   Command-line arguments passed to install.sh.
   * @param list<string> $expected
   *   Managers expected to have a runtime dependencies rule.
   */
  #[DataProvider('dataProviderInstallRenovateRuntimeRules')]
  public function testInstallRenovateRuntimeRules(array $arguments, array $expected): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', array_merge(['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe'], $arguments));

    $this->assertProcessSuccessful();

    $config = json_decode((string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'renovate.json'), TRUE, 512, JSON_THROW_ON_ERROR);
    $this->assertIsArray($config);
    $this->assertSame('7 days', $config['minimumReleaseAge'] ?? NULL);
    $this->assertSame('strict', $config['internalChecksFilter'] ?? NULL);
    $this->assertIsArray($config['packageRules']);

    $rules = [
      'composer' => ['matchManagers' => ['composer'], 'matchFileNames' => ['composer.json'], 'matchDepTypes' => ['require']],
      'npm' => ['matchManagers' => ['npm'], 'matchFileNames' => ['package.json'], 'matchDepTypes' => ['dependencies']],
    ];

    $catch_all = array_search(['matchPackageNames' => ['*'], 'groupName' => 'all dependencies', 'groupSlug' => 'all'], $config['packageRules'], TRUE);
    $this->assertIsInt($catch_all);

    $actual = [];
    foreach ($rules as $manager => $rule) {
      $rule += ['groupName' => 'runtime dependencies', 'groupSlug' => 'runtime', 'automerge' => FALSE];
      $position = array_search($rule, $config['packageRules'], TRUE);

      if ($position === FALSE) {
        continue;
      }

      // A later rule overrides the group set by an earlier one.
      $this->assertGreaterThan($catch_all, $position);
      $actual[] = $manager;
    }

    $this->assertSame($expected, $actual);

    foreach ($config['packageRules'] as $rule) {
      $this->assertIsArray($rule);
      $this->assertNotSame([], $rule['matchManagers'] ?? NULL, 'A rule with no managers must be removed.');
    }
  }

  public static function dataProviderInstallRenovateRuntimeRules(): \Iterator {
    yield 'php and nodejs' => [[], ['composer', 'npm']];
    yield 'php only' => [['--no-nodejs'], ['composer']];
    yield 'php library' => [['--no-php-command', '--no-php-script', '--no-nodejs'], ['composer']];
    yield 'nodejs only' => [['--no-php'], ['npm']];
    yield 'no languages' => [['--no-php', '--no-nodejs'], []];
  }

  /**
   * Lock file maintenance merges on its own, with each manager enforcing age.
   *
   * @param list<string> $arguments
   *   Command-line arguments passed to install.sh.
   */
  #[DataProvider('dataProviderInstallRenovateLockFileMaintenance')]
  public function testInstallRenovateLockFileMaintenance(array $arguments, bool $composer_rule): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', array_merge(['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe'], $arguments));

    $this->assertProcessSuccessful();

    $config = json_decode((string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'renovate.json'), TRUE, 512, JSON_THROW_ON_ERROR);
    $this->assertIsArray($config);
    $this->assertSame(['enabled' => TRUE, 'automerge' => TRUE], $config['lockFileMaintenance'] ?? NULL);
    $this->assertTrue($config['minimumReleaseAgePackageManagerSync'] ?? NULL);
    $this->assertSame('7 days', $config['minimumReleaseAge'] ?? NULL);
    $this->assertIsArray($config['packageRules']);

    $rule = ['matchManagers' => ['composer'], 'matchUpdateTypes' => ['lockFileMaintenance'], 'minimumReleaseAge' => NULL];
    $this->assertSame($composer_rule, in_array($rule, $config['packageRules'], TRUE));
  }

  public static function dataProviderInstallRenovateLockFileMaintenance(): \Iterator {
    yield 'php and nodejs' => [[], TRUE];
    yield 'php library' => [['--no-php-command', '--no-php-script'], TRUE];
    yield 'nodejs only' => [['--no-php'], FALSE];
    yield 'nodejs library' => [['--no-php', '--nodejs-library'], FALSE];
    yield 'no languages' => [['--no-php', '--no-nodejs'], FALSE];
  }

  /**
   * The class library initialises cleanly when Renovate is deselected.
   */
  public function testInstallPhpLibraryWithoutRenovate(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', ['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe', '--no-php-command', '--no-php-script', '--no-renovate']);

    $this->assertProcessSuccessful();
    $this->assertFileDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . 'renovate.json');
    $this->assertFileDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . 'renovate.json.tmp');
  }

  /**
   * Only a project that builds a PHAR keeps the Box build scaffolding.
   *
   * @param list<string> $arguments
   *   Command-line arguments passed to install.sh.
   */
  #[DataProvider('dataProviderInstallPharBuildScaffolding')]
  public function testInstallPharBuildScaffolding(array $arguments, bool $expected): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', array_merge(['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe'], $arguments));

    $this->assertProcessSuccessful();

    $composer = json_decode((string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'composer.json'), TRUE, 512, JSON_THROW_ON_ERROR);
    $this->assertIsArray($composer);
    $this->assertIsArray($composer['require-dev']);
    $this->assertIsArray($composer['config']);
    $this->assertIsArray($composer['config']['allow-plugins']);
    $this->assertIsArray($composer['scripts']);

    $this->assertSame($expected, array_key_exists('bamarni/composer-bin-plugin', $composer['require-dev']));
    $this->assertSame($expected, array_key_exists('bamarni/composer-bin-plugin', $composer['config']['allow-plugins']));
    $this->assertSame($expected, array_key_exists('build', $composer['scripts']));
    $this->assertSame($expected ? 'rm -Rf vendor vendor-bin composer.lock' : 'rm -Rf vendor composer.lock', $composer['scripts']['reset']);

    // Neighbouring keys survive the line-based removal.
    $this->assertArrayHasKey('phpunit/phpunit', $composer['require-dev']);
    $this->assertArrayHasKey('ergebnis/composer-normalize', $composer['config']['allow-plugins']);
    $this->assertArrayHasKey('lint', $composer['scripts']);

    $gitignore = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . '.gitignore');
    $this->assertSame($expected, str_contains($gitignore, '/vendor-bin'));
  }

  public static function dataProviderInstallPharBuildScaffolding(): \Iterator {
    yield 'php command' => [['--php-command', '--no-php-script'], TRUE];
    yield 'php command without phar' => [['--php-command', '--no-phar'], FALSE];
    yield 'php script' => [['--no-php-command', '--php-script'], FALSE];
    yield 'php library' => [['--no-php-command', '--no-php-script'], FALSE];
  }

  /**
   * Only an application commits its lock files, and they stay valid.
   *
   * @param list<string> $arguments
   *   Command-line arguments passed to install.sh.
   */
  #[DataProvider('dataProviderInstallLockFiles')]
  public function testInstallLockFiles(array $arguments, bool $composer_lock, bool $package_lock, bool $library, bool $nodejs_library = FALSE): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', array_merge(['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe'], $arguments));

    $this->assertProcessSuccessful();
    $this->assertProcessOutputNotContains('Composer could not refresh composer.lock');

    $this->assertSame($composer_lock, file_exists(self::$sut . DIRECTORY_SEPARATOR . 'composer.lock'));
    $this->assertSame($package_lock, file_exists(self::$sut . DIRECTORY_SEPARATOR . 'package-lock.json'));

    $gitignore = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . '.gitignore');
    $this->assertSame($library, preg_match('#^/composer\.lock$#m', $gitignore) === 1);
    $this->assertSame($nodejs_library, preg_match('#^/package-lock\.json$#m', $gitignore) === 1);
    $this->assertStringNotContainsString('# /composer.lock', $gitignore);
    $this->assertStringNotContainsString('# /package-lock.json', $gitignore);

    $workflow = self::$sut . DIRECTORY_SEPARATOR . '.github/workflows/test-nodejs.yml';

    if (file_exists($workflow)) {
      $install = $nodejs_library ? 'run: npm install --ignore-scripts' : 'run: npm ci --ignore-scripts';
      $this->assertStringContainsString($install, (string) file_get_contents($workflow));
    }

    $composer = [];

    if (file_exists(self::$sut . DIRECTORY_SEPARATOR . 'composer.json')) {
      $composer = json_decode((string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'composer.json'), TRUE, 512, JSON_THROW_ON_ERROR);
      $this->assertIsArray($composer);
      $this->assertIsArray($composer['config']);
      $this->assertIsArray($composer['require-dev']);
      $this->assertSame($library ? NULL : ['php' => '8.3'], $composer['config']['platform'] ?? NULL);
      $this->assertIsArray($composer['config']['policy']);
      $this->assertSame(['period' => '7 days'], $composer['config']['policy']['cooldown'] ?? NULL);
      $this->assertSame('>=2.11.0', $composer['require-dev']['composer'] ?? NULL);
      // Neighbouring keys survive the line-based removal.
      $this->assertArrayHasKey('discard-changes', $composer['config']);
      $this->assertArrayHasKey('policy', $composer['config']);
    }

    if ($composer_lock) {
      $lock = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'composer.lock');
      // Third-party author names match the replacement needles.
      $this->assertStringContainsString('"name": "Alex Skrypnyk"', $lock);
      $require_dev = is_array($composer['require-dev'] ?? NULL) ? $composer['require-dev'] : [];
      $this->assertSame(array_key_exists('bamarni/composer-bin-plugin', $require_dev), str_contains($lock, '"name": "bamarni/composer-bin-plugin"'));

      $this->processRun('composer', ['validate', '--no-check-publish', '--no-check-all', '--no-interaction']);
      $this->assertProcessSuccessful();
    }

    if ($package_lock) {
      $lock = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . 'package-lock.json');
      $this->assertStringContainsString('"name": "@acmeapp/acme-app"', $lock);
      $this->assertStringNotContainsString('yourproject', $lock);
    }
  }

  public static function dataProviderInstallLockFiles(): \Iterator {
    yield 'php command' => [['--php-command', '--no-php-script'], TRUE, TRUE, FALSE];
    yield 'php command without phar' => [['--php-command', '--no-phar'], TRUE, TRUE, FALSE];
    yield 'php script' => [['--no-php-command', '--php-script'], TRUE, TRUE, FALSE];
    yield 'php library' => [['--no-php-command', '--no-php-script'], FALSE, TRUE, TRUE];
    yield 'php library without nodejs' => [['--no-php-command', '--no-php-script', '--no-nodejs'], FALSE, FALSE, TRUE];
    yield 'nodejs only' => [['--no-php'], FALSE, TRUE, FALSE];
    yield 'nodejs library' => [['--no-php', '--nodejs-library'], FALSE, FALSE, FALSE, TRUE];
    yield 'php and nodejs libraries' => [['--no-php-command', '--no-php-script', '--nodejs-library'], FALSE, FALSE, TRUE, TRUE];
    yield 'php command with nodejs library' => [['--php-command', '--nodejs-library'], TRUE, FALSE, FALSE, TRUE];
    yield 'nodejs library flag without nodejs' => [['--no-php', '--no-nodejs', '--nodejs-library'], FALSE, FALSE, FALSE];
    yield 'no languages' => [['--no-php', '--no-nodejs'], FALSE, FALSE, FALSE];
  }

  /**
   * A lock file that Composer cannot refresh is removed instead of left stale.
   */
  public function testInstallRemovesComposerLockComposerCannotRefresh(): void {
    self::$fixtures = NULL;

    $bin = self::$tmp . DIRECTORY_SEPARATOR . 'bin';
    File::dump($bin . DIRECTORY_SEPARATOR . 'composer', "#!/usr/bin/env bash\nexit 1\n");
    chmod($bin . DIRECTORY_SEPARATOR . 'composer', 0755);

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', ['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe'], [], ['PATH' => $bin . PATH_SEPARATOR . getenv('PATH')]);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains("Warning: Composer could not refresh composer.lock, so it was removed. Run 'composer update' and commit composer.lock.");
    $this->assertFileDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . 'composer.lock');

    $gitignore = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . '.gitignore');
    $this->assertDoesNotMatchRegularExpression('#^/composer\.lock$#m', $gitignore);
  }

  /**
   * A project generated with Actions linting must pass the zizmor audit.
   *
   * Mirrors the audit the shipped "Test Actions" workflow runs, using the
   * generated suppression config, so consumer projects stay clean without a
   * manual check.
   */
  public function testInstallTestActionsPassesZizmor(): void {
    self::$fixtures = NULL;

    $zizmor = (new ExecutableFinder())->find('zizmor');

    if (!is_string($zizmor)) {
      $this->markTestSkipped('The "zizmor" binary is not available.');
    }

    $arguments = ['--namespace=YodasHut', '--name=force-crystal', '--author=Luke Skywalker', '--test-actions'];
    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', $arguments);
    $this->assertProcessSuccessful();

    $this->processRun($zizmor, ['--offline', '--config', 'zizmor.yml', '.github/workflows']);
    $this->assertProcessSuccessful();
  }

  /**
   * The audit analyzes only the languages the generated project holds.
   *
   * @param list<string> $arguments
   *   Command-line arguments passed to install.sh.
   * @param list<string> $present
   *   Strings that must be present in the audit workflow.
   * @param list<string> $absent
   *   Strings that must be absent from the audit workflow.
   */
  #[DataProvider('dataProviderInstallAuditLanguages')]
  public function testInstallAuditLanguages(array $arguments, array $present, array $absent): void {
    self::$fixtures = NULL;

    $arguments = array_merge(['--namespace=YodasHut', '--name=force-crystal', '--author=Luke Skywalker'], $arguments);
    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', $arguments);
    $this->assertProcessSuccessful();

    $workflow = File::read(self::$sut . '/.github/workflows/audit.yml');
    $this->assertStringNotContainsString('#;', $workflow);

    foreach ($present as $needle) {
      $this->assertStringContainsString($needle, $workflow);
    }

    foreach ($absent as $needle) {
      $this->assertStringNotContainsString($needle, $workflow);
    }
  }

  public static function dataProviderInstallAuditLanguages(): \Iterator {
    $jobs = ['name: Audit', 'name: Security'];
    yield 'all languages' => [[], [...$jobs, 'languages: actions,javascript-typescript', 'semgrep scan'], []];
    yield 'nodejs without docs' => [['--no-php', '--no-docs'], [...$jobs, 'languages: actions,javascript-typescript'], ['semgrep']];
    yield 'docs without nodejs' => [['--no-php', '--no-nodejs'], [...$jobs, 'languages: actions,javascript-typescript'], ['semgrep']];
    yield 'php without nodejs or docs' => [['--no-nodejs', '--no-docs'], [...$jobs, "languages: actions\n", 'semgrep scan'], ['javascript-typescript']];
    yield 'shell only' => [['--no-php', '--no-nodejs', '--no-docs'], [...$jobs, "languages: actions\n"], ['javascript-typescript', 'semgrep']];
  }

  public function testInstallWithoutAuditRemovesWorkflow(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', ['--namespace=YodasHut', '--name=force-crystal', '--author=Luke Skywalker', '--no-audit']);
    $this->assertProcessSuccessful();

    $this->assertFileDoesNotExist(self::$sut . '/.github/workflows/audit.yml');
    $this->assertStringNotContainsString('audit.yml', File::read(self::$sut . '/AGENTS.md'));
  }

  /**
   * The shared Claude settings ship and are trimmed to the selected features.
   *
   * @param list<string> $arguments
   *   Command-line arguments passed to install.sh.
   * @param list<string> $present
   *   Permission rules that must be present in the settings file.
   * @param list<string> $absent
   *   Permission rules that must be absent from the settings file.
   */
  #[DataProvider('dataProviderInstallClaudeSettings')]
  public function testInstallClaudeSettings(array $arguments, array $present, array $absent): void {
    self::$fixtures = NULL;

    $arguments = array_merge(['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe'], $arguments);
    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', $arguments);
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

  public static function dataProviderInstallClaudeSettings(): \Iterator {
    // Docker is off by default, so its rules are trimmed unless enabled.
    // Mermaid is the default diagram format, so the PlantUML rule is trimmed
    // unless that format is selected.
    // Commands that run repository scripts, install packages or start
    // containers are allowed only in their documented form, so the open-ended
    // wildcards are absent in every case.
    $wildcards = ['Bash(composer:*)', 'Bash(npm:*)', 'Bash(docker build:*)', 'Bash(docker run:*)'];
    $composer = ['Bash(composer install)', 'Bash(composer lint)', 'Bash(composer lint-fix)', 'Bash(composer test)', 'Bash(composer test-coverage)'];
    $npm_nodejs = ['Bash(npm run lint)', 'Bash(npm run lint-fix)', 'Bash(npm run test)', 'Bash(npm run test-coverage)'];
    $npm_docs = ['Bash(npm start)', 'Bash(npm run build)', 'Bash(npm run spellcheck)'];
    $docker = ['Bash(docker build -t acmeapp/acme-app .)', 'Bash(docker run --rm acmeapp/acme-app)', 'Bash(docker run --rm -i hadolint/hadolint:*)'];

    yield 'defaults' => [
      [],
      [...$composer, 'Bash(./vendor/bin/phpunit:*)', 'Bash(./tests/bats/node_modules/bats/bin/bats:*)', 'Bash(npm install)', ...$npm_nodejs, ...$npm_docs],
      [...$wildcards, ...$docker, 'Bash(plantuml:*)'],
    ];
    yield 'with docker' => [
      ['--docker'],
      $docker,
      [...$wildcards, 'Bash(docker build -t yournamespace/yourdockerimage .)'],
    ];
    yield 'ai arch docs plantuml' => [
      ['--ai-arch-docs=plantuml'],
      ['Bash(plantuml:*)'],
      $wildcards,
    ];
    yield 'no php' => [
      ['--no-php'],
      ['Bash(./tests/bats/node_modules/bats/bin/bats:*)', 'Bash(npm install)'],
      [...$wildcards, ...$composer, 'Bash(./vendor/bin/phpcs:*)', 'Bash(./vendor/bin/phpunit:*)'],
    ];
    yield 'docs npm rules survive without nodejs' => [
      ['--no-nodejs'],
      ['Bash(npm install)', ...$npm_docs],
      [...$wildcards, ...$npm_nodejs],
    ];
    yield 'nodejs npm rules survive without docs' => [
      ['--no-docs'],
      ['Bash(npm install)', ...$npm_nodejs],
      [...$wildcards, ...$npm_docs],
    ];
    yield 'npm trimmed without nodejs and docs' => [
      ['--no-nodejs', '--no-docs'],
      [],
      [...$wildcards, 'Bash(npm install)', ...$npm_nodejs, ...$npm_docs],
    ];
    yield 'no languages' => [
      ['--no-php', '--no-nodejs', '--no-shell', '--no-docs'],
      [],
      [...$wildcards, ...$composer, 'Bash(npm install)', 'Bash(./tests/bats/node_modules/bats/bin/bats:*)'],
    ];
  }

  /**
   * Disabling AI agents removes the Claude settings with the '.claude' dir.
   */
  public function testInstallClaudeSettingsRemovedWithoutAi(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', ['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe', '--no-ai']);
    $this->assertProcessSuccessful();

    $this->assertFileDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . '.claude' . DIRECTORY_SEPARATOR . 'settings.json');
    $this->assertDirectoryDoesNotExist(self::$sut . DIRECTORY_SEPARATOR . '.claude');
  }

  /**
   * Consumer-owned files under '.claude' survive an init run byte-for-byte.
   *
   * The update flow keeps the consumer's '.claude' across its wipe, then
   * extracts the template on top. install.sh then runs over a tree holding both
   * template-owned and consumer-owned files.
   *
   * A sweep that reaches the consumer-owned '.claude' tree rewrites the
   * fetched update skill to name the consumer's own repository. The next
   * update then pulls the wrong project.
   *
   * @param string $path
   *   Path of the consumer-owned file, relative to '.claude'.
   */
  #[DataProvider('dataProviderInstallPreservesConsumerClaudeFiles')]
  public function testInstallPreservesConsumerClaudeFiles(string $path): void {
    self::$fixtures = NULL;

    $claude_dir = self::$sut . DIRECTORY_SEPARATOR . '.claude';
    $file = $claude_dir . DIRECTORY_SEPARATOR . $path;
    $planted = self::consumerClaudeContent();
    File::dump($file, $planted);

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', [
      '--namespace=AcmeApp',
      '--name=acme-app',
      '--author=Jane Doe',
      '--php-command-name=acme-cli',
    ]);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');

    $this->assertSame($planted, (string) file_get_contents($file));
  }

  public static function dataProviderInstallPreservesConsumerClaudeFiles(): \Iterator {
    // The skill the consumer fetches on demand to run the next update.
    yield 'update skill' => ['skills/update-consumer-scaffold/SKILL.md'];
    // Personal Claude Code overrides, git-ignored and never template-owned.
    yield 'local settings' => ['settings.local.json'];
    // A skill and an agent the consumer wrote themselves.
    yield 'consumer skill' => ['skills/acme-deploy/SKILL.md'];
    yield 'consumer agent' => ['agents/acme-reviewer.md'];
  }

  /**
   * Every string install.sh sweeps for, in a consumer-owned file.
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
   *   Command-line arguments passed to install.sh.
   * @param string $present
   *   Heading of the diagram-format section that must survive.
   * @param string $absent
   *   Heading of the diagram-format section that must be removed.
   */
  #[DataProvider('dataProviderInstallProcessesShippedClaudeFiles')]
  public function testInstallProcessesShippedClaudeFiles(array $arguments, string $present, string $absent): void {
    self::$fixtures = NULL;

    $arguments = array_merge(['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe'], $arguments);
    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', $arguments);

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

  public static function dataProviderInstallProcessesShippedClaudeFiles(): \Iterator {
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
  public function testInstallKeepsOrdinaryScaffoldWord(): void {
    self::$fixtures = NULL;

    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', [
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

  /**
   * Initialization rewrites every file when the project path has spaces.
   *
   * The sweep helpers pass absolute paths to 'sed', so a space in the
   * project path must not split a file name into separate arguments.
   */
  public function testInstallInPathWithSpaces(): void {
    self::$fixtures = NULL;

    $target = self::$tmp . DIRECTORY_SEPARATOR . 'path with spaces';
    $this->processRun('cp', ['-R', self::$sut, $target]);
    $this->assertProcessSuccessful();

    $this->processCwd = $target;
    $this->processRun('bash', [
      './install.sh',
      '--namespace=AcmeApp',
      '--name=acme-app',
      '--author=Jane Doe',
    ]);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');

    $composer = (string) file_get_contents($target . DIRECTORY_SEPARATOR . 'composer.json');
    $this->assertStringContainsString('"name": "acmeapp/acme-app"', $composer);
    $this->assertStringNotContainsString('yournamespace', $composer);

    $readme = (string) file_get_contents($target . DIRECTORY_SEPARATOR . 'README.md');
    $this->assertStringNotContainsString('yourproject', $readme);
    $this->assertStringNotContainsString('#;', $readme);
  }

  /**
   * A custom Docker image name reaches only the Docker references.
   *
   * The default image name equals the Composer package name, so the default
   * fixtures cannot tell a scoped replacement from a project-wide one.
   *
   * @param list<string> $arguments
   *   Command-line arguments passed to install.sh.
   * @param array<string, list<string>> $present
   *   Strings that must be present, keyed by file path.
   * @param array<string, list<string>> $absent
   *   Strings that must be absent, keyed by file path.
   */
  #[DataProvider('dataProviderInstallDockerImageName')]
  public function testInstallDockerImageName(array $arguments, array $present, array $absent): void {
    self::$fixtures = NULL;

    $arguments = array_merge(['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe'], $arguments);
    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', $arguments);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');

    foreach ($present as $path => $needles) {
      $content = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . $path);
      foreach ($needles as $needle) {
        $this->assertStringContainsString($needle, $content, sprintf('Missing "%s" in "%s".', $needle, $path));
      }
    }

    foreach ($absent as $path => $needles) {
      $content = (string) file_get_contents(self::$sut . DIRECTORY_SEPARATOR . $path);
      foreach ($needles as $needle) {
        $this->assertStringNotContainsString($needle, $content, sprintf('Unexpected "%s" in "%s".', $needle, $path));
      }
    }

    $finder = (new Finder())->files()->in(self::$sut)->ignoreDotFiles(FALSE)->exclude(['.git', '.artifacts', 'vendor', 'node_modules']);
    foreach ($finder as $file) {
      $this->assertStringNotContainsString('yourdockerimage', $file->getContents(), sprintf('Unprocessed image placeholder in "%s".', $file->getRelativePathname()));
    }
  }

  public static function dataProviderInstallDockerImageName(): \Iterator {
    $package = [
      'composer.json' => ['"name": "acmeapp/acme-app"', '"homepage": "https://github.com/acmeapp/acme-app"'],
      'package.json' => ['"name": "@acmeapp/acme-app"', '"repository": "github:acmeapp/acme-app"'],
      'README.md' => ['https://github.com/acmeapp/acme-app/issues', 'https://img.shields.io/github/v/release/acmeapp/acme-app'],
    ];

    yield 'custom image name' => [
      ['--docker-image-name=acme/api-image'],
      [
        ...$package,
        'README.md' => [...$package['README.md'], 'docker pull acme/api-image', 'docker run --rm acme/api-image'],
        'Dockerfile' => ['org.opencontainers.image.source="https://github.com/acmeapp/acme-app"'],
        'CONTRIBUTING.md' => ['docker build -t acme/api-image .', 'docker run --rm acme/api-image'],
        'AGENTS.md' => ['docker build -t acme/api-image .', 'docker run --rm acme/api-image', 'it defaults to `acme/api-image`'],
        '.claude/settings.json' => ['Bash(docker build -t acme/api-image .)', 'Bash(docker run --rm acme/api-image)'],
        '.github/workflows/test-docker.yml' => ['tags: acme/api-image:test', 'docker run --rm acme/api-image:test', "vars.DOCKER_IMAGE || 'acme/api-image'"],
        '.github/workflows/release-docker.yml' => ["vars.DOCKER_IMAGE || 'acme/api-image'"],
      ],
      [
        'composer.json' => ['acme/api-image'],
        'package.json' => ['acme/api-image'],
        'README.md' => ['github.com/acme/api-image', 'composer require acme/api-image'],
        'Dockerfile' => ['acme/api-image'],
        'docs/docusaurus.config.js' => ['acme/api-image'],
      ],
    ];
    yield 'default image name' => [
      ['--docker'],
      [
        ...$package,
        'README.md' => [...$package['README.md'], 'docker pull acmeapp/acme-app'],
        '.github/workflows/test-docker.yml' => ['tags: acmeapp/acme-app:test'],
      ],
      [],
    ];
    yield 'no docker' => [
      ['--no-docker'],
      $package,
      [
        'README.md' => ['docker pull'],
        'AGENTS.md' => ['docker build'],
      ],
    ];
  }

  /**
   * The entrypoint BATS test ships only with both Docker and shell support.
   *
   * The Docker fixture scenarios decline every language, so they never hold
   * the shell test directory.
   *
   * @param list<string> $arguments
   *   Command-line arguments passed to install.sh.
   */
  #[DataProvider('dataProviderInstallEntrypointTest')]
  public function testInstallEntrypointTest(array $arguments, bool $expected): void {
    self::$fixtures = NULL;

    $arguments = array_merge(['--namespace=AcmeApp', '--name=acme-app', '--author=Jane Doe'], $arguments);
    $this->processRun(self::$sut . DIRECTORY_SEPARATOR . 'install.sh', $arguments);

    $this->assertProcessSuccessful();
    $this->assertProcessOutputContains('Initialization complete.');

    $test = self::$sut . DIRECTORY_SEPARATOR . 'tests' . DIRECTORY_SEPARATOR . 'bats' . DIRECTORY_SEPARATOR . 'entrypoint.bats';

    if (!$expected) {
      $this->assertFileDoesNotExist($test);

      return;
    }

    $this->assertFileExists(self::$sut . DIRECTORY_SEPARATOR . 'entrypoint.sh');
    $this->assertStringContainsString('"acme-app is running"', (string) file_get_contents($test));
  }

  public static function dataProviderInstallEntrypointTest(): \Iterator {
    yield 'docker and shell' => [['--docker', '--shell'], TRUE];
    yield 'docker without shell' => [['--docker', '--no-shell'], FALSE];
    yield 'shell without docker' => [['--no-docker', '--shell'], FALSE];
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
      // Asked only after the command app is declined.
      'use_php_script' => self::TUI_SKIP,
      'php_script_name' => self::TUI_SKIP,
      'use_nodejs' => self::TUI_DEFAULT,
      'use_nodejs_library' => self::TUI_DEFAULT,
      'use_shell' => self::TUI_DEFAULT,
      'shell_command_name' => self::TUI_DEFAULT,
      'use_docker' => self::TUI_DEFAULT,
      'docker_image_name' => self::TUI_SKIP,
      'use_release_drafter' => self::TUI_DEFAULT,
      'use_pr_autoassign' => self::TUI_DEFAULT,
      'use_funding' => self::TUI_DEFAULT,
      'use_pr_template' => self::TUI_DEFAULT,
      'use_renovate' => self::TUI_DEFAULT,
      'use_docs' => self::TUI_DEFAULT,
      'use_test_actions' => self::TUI_DEFAULT,
      'use_audit' => self::TUI_DEFAULT,
      'use_schedule' => self::TUI_DEFAULT,
      'use_windows' => self::TUI_DEFAULT,
      'use_ai' => self::TUI_DEFAULT,
      'use_ai_arch_docs' => self::TUI_DEFAULT,
      'remove_self' => self::TUI_DEFAULT,
    ];
  }

}
