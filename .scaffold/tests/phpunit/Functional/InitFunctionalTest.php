<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests\Functional;

use AlexSkrypnyk\Scaffold\Tests\Traits\FixtureTrait;
use AlexSkrypnyk\Scaffold\Tests\Traits\ProcessTrait;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\TestCase;

/**
 * Class InitFunctionalTest.
 *
 * Functional tests for init.sh script.
 */
#[Group('functional')]
class InitFunctionalTest extends TestCase {

  use FixtureTrait;
  use ProcessTrait;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();
    $this->fixtureInit();
    $this->fixtureCopyRepository();
  }

  /**
   * {@inheritdoc}
   */
  protected function tearDown(): void {
    $this->fixtureCleanup();
    parent::tearDown();
  }

  /**
   * Assert that common files are present after initialization.
   */
  protected function assertCommonFilesPresent(): void {
    // Common files.
    $this->assertFixtureFileExists(".editorconfig");
    $this->assertFixtureFileExists(".gitattributes");
    $this->assertFixtureFileExists(".gitignore");
    $this->assertFixtureFileContains(".gitignore", "/.build");
    $this->assertFixtureFileNotContains(".gitignore", "/coverage");
    $this->assertFixtureFileExists("README.md");
    $this->assertFixtureFileNotExists("README.dist.md");
    $this->assertFixtureFileExists("logo.png");
    $this->assertFixtureFileNotExists("logo.tmp.png");

    $this->assertFixtureFileNotExists("LICENSE");
    $this->assertFixtureFileNotExists("SECURITY.md");
    $this->assertFixtureFileNotExists(".github/workflows/scaffold-test.yml");
    $this->assertFixtureFileNotExists(".github/workflows/scaffold-release-docs.yml");
    $this->assertFixtureDirectoryNotExists(".scaffold");

    // Assert that documentation was processed correctly.
    $this->assertFixtureFileNotContains("README.md", "Generic project scaffold template");
    $this->assertFixtureFileNotContains("README.md", "META");
    $this->assertFixtureFileContains("README.md", "_This repository was created using the [force-crystal](https://getforce-crystal.dev/) project template_");
    
    // Assert that README.md placeholder image URL and alt text were updated correctly
    $this->assertFixtureFileNotContains("README.md", "text=Yourproject");
    $this->assertFixtureFileContains("README.md", "text=force-crystal");
    $this->assertFixtureFileNotContains("README.md", "alt=\"Yourproject logo\"");
    $this->assertFixtureFileContains("README.md", "alt=\"force-crystal logo\"");

    // Assert that .gitattributes were processed correctly.
    $this->assertFixtureFileContains(".gitattributes", "/.editorconfig");
    $this->assertFixtureFileNotContains(".gitattributes", "# /.editorconfig");
    $this->assertFixtureFileContains(".gitattributes", "/.gitattributes");
    $this->assertFixtureFileNotContains(".gitattributes", "# /.gitattributes");
    $this->assertFixtureFileContains(".gitattributes", "/.github");
    $this->assertFixtureFileNotContains(".gitattributes", "# /.github");
    $this->assertFixtureFileContains(".gitattributes", "/.gitignore");
    $this->assertFixtureFileNotContains(".gitattributes", "# /.gitignore");
    $this->assertFixtureFileNotContains(".gitattributes", "# Uncomment the lines below in your project (or use init.sh script).");
  }

  /**
   * Assert that PHP files are present after initialization.
   */
  protected function assertPhpFilesPresent(): void {
    $this->assertFixtureFileContains("composer.json", '"name": "yodasHut/force-crystal"');
    $this->assertFixtureFileContains("composer.json", '"description": "Provides force-crystal functionality."');
    $this->assertFixtureFileContains("composer.json", '"name": "Jane Doe"');
    $this->assertFixtureFileContains("composer.json", '"homepage": "https://github.com/yodasHut/force-crystal"');
    $this->assertFixtureFileContains("composer.json", '"issues": "https://github.com/yodasHut/force-crystal/issues"');
    $this->assertFixtureFileContains("composer.json", '"source": "https://github.com/yodasHut/force-crystal"');

    $this->assertFixtureFileContains(".gitignore", "/vendor");
    $this->assertFixtureFileContains(".gitignore", "/composer.lock");

    $this->assertFixtureFileContains(".gitattributes", "/tests");
    $this->assertFixtureFileContains(".gitattributes", "/phpcs.xml");
    $this->assertFixtureFileContains(".gitattributes", "/phpmd.xml");
    $this->assertFixtureFileContains(".gitattributes", "/phpstan.neon");
    $this->assertFixtureFileContains(".gitattributes", "/phpunit.xml");

    $this->assertFixtureFileNotContains(".gitattributes", "# /tests");
    $this->assertFixtureFileNotContains(".gitattributes", "# /phpcs.xml");
    $this->assertFixtureFileNotContains(".gitattributes", "# /phpmd.xml");
    $this->assertFixtureFileNotContains(".gitattributes", "# /phpstan.neon");
    $this->assertFixtureFileNotContains(".gitattributes", "# /phpunit.xml");
    $this->assertFixtureFileNotContains(".gitattributes", "# /rector.php");

    $this->assertFixtureFileExists(".github/workflows/test-php.yml");
    $this->assertFixtureFileExists(".github/workflows/release-php.yml");

    $this->assertFixtureFileContains("README.md", "composer");

    $this->assertFixtureFileExists("phpcs.xml");
    $this->assertFixtureFileExists("phpmd.xml");
    $this->assertFixtureFileExists("phpstan.neon");
    $this->assertFixtureFileExists("phpunit.xml");
    $this->assertFixtureFileExists("rector.php");
  }

  /**
   * Assert that PHP command files are present.
   */
  protected function assertPhpCommandFilesPresent(): void {
    $this->assertFixtureFileExists("force-crystal");
    $this->assertFixtureDirectoryExists("src");

    $this->assertFixtureFileContains("phpcs.xml", "<file>src</file>");
    $this->assertFixtureFileContains("phpstan.neon", "- src");
    $this->assertFixtureFileContains("phpunit.xml", "<directory>src</directory>");
    $this->assertFixtureFileContains("composer.json", '"force-crystal"');
  }

  /**
   * Assert that PHP script files are present.
   */
  protected function assertPhpScriptFilesPresent(): void {
    $this->assertFixtureFileExists("force-crystal");
    $this->assertFixtureFileContains(".github/workflows/release-php.yml", "force-crystal");

    $this->assertFixtureFileContains("phpcs.xml", "force-crystal.php");
    $this->assertFixtureFileContains("phpstan.neon", "force-crystal");
    $this->assertFixtureFileContains("phpunit.xml", "force-crystal");

    $this->assertFixtureFileContains("composer.json", '"cp force-crystal force-crystal.php && phpcs; rm force-crystal.php",');
    $this->assertFixtureFileContains("composer.json", '"force-crystal"');
  }

  /**
   * Assert that NodeJS files are present.
   */
  protected function assertNodejsFilesPresent(): void {
    $this->assertFixtureFileContains("package.json", '"name": "@yodasHut/force-crystal"');
    $this->assertFixtureFileContains("package.json", '"description": "Provides force-crystal functionality."');
    $this->assertFixtureFileContains("package.json", '"name": "Jane Doe"');
    $this->assertFixtureFileContains("package.json", '"bugs": "https://github.com/yodasHut/force-crystal/issues"');
    $this->assertFixtureFileContains("package.json", '"repository": "github:yodasHut/force-crystal"');

    $this->assertFixtureFileContains(".gitignore", "/node_modules");
    $this->assertFixtureFileContains(".gitignore", "/package-lock.json");
    $this->assertFixtureFileContains(".gitignore", "/yarn.lock");

    $this->assertFixtureFileNotContains(".gitattributes", "# /.npmignore");
    $this->assertFixtureFileContains(".gitattributes", "/.npmignore");

    $this->assertFixtureFileExists(".github/workflows/test-nodejs.yml");
    $this->assertFixtureFileExists(".github/workflows/release-nodejs.yml");

    $this->assertFixtureFileContains("README.md", "npm install");
  }

  /**
   * Assert that Shell files are present.
   */
  protected function assertShellFilesPresent(): void {
    $this->assertFixtureFileExists("force-crystal.sh");
    $this->assertFixtureFileExists(".github/workflows/test-shell.yml");
    $this->assertFixtureFileContains("README.md", "force-crystal");
  }

  /**
   * Assert that docs files are present.
   */
  protected function assertDocsFilesPresent(): void {
    $this->assertFixtureFileExists("docs/.gitignore");
    $this->assertFixtureFileExists("docs/docusaurus.config.js");
    $this->assertFixtureFileExists("docs/package.json");
    $this->assertFixtureFileExists("docs/package-lock.json");
    $this->assertFixtureFileExists("docs/README.md");
    $this->assertFixtureFileExists("docs/content/README.mdx");

    $this->assertFixtureFileExists("docs/static/README.md");

    $this->assertFixtureFileExists(".github/workflows/test-docs.yml");
    $this->assertFixtureFileExists(".github/workflows/release-docs.yml");

    $this->assertFixtureFileContains(".gitattributes", "/docs");
    $this->assertFixtureFileNotContains(".gitattributes", "# /docs");
  }

  /**
   * Test init script with default values.
   */
  public function testInitDefaults(): void {
    // Log the fixture directory for debugging
    echo "Fixture directory: {$this->fixtureDir}" . PHP_EOL;
    
    // Run init.sh with default answers set to "Y".
    $process = $this->runProcess('./init.sh', [], [
      'YodasHut',
      'force-crystal',
      'Jane Doe',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Please follow the prompts to adjust your project configuration');
    $this->assertProcessOutputContains($process, 'Initialization complete.');

    // Verify SECURITY.md file was removed (fixed defect #1)
    if (file_exists($this->fixtureDir . DIRECTORY_SEPARATOR . 'SECURITY.md')) {
      echo "ERROR: SECURITY.md file exists but should be removed by init.sh" . PHP_EOL;
    } else {
      echo "FIXED: SECURITY.md file is correctly removed by init.sh" . PHP_EOL;
    }
    
    // Verify README.md placeholders were updated (fixed defect #2)
    if (file_exists($this->fixtureDir . DIRECTORY_SEPARATOR . 'README.md')) {
      $readme = file_get_contents($this->fixtureDir . DIRECTORY_SEPARATOR . 'README.md');
      echo "README.md first 10 lines:" . PHP_EOL;
      echo implode(PHP_EOL, array_slice(explode(PHP_EOL, $readme), 0, 10)) . PHP_EOL;
      
      if (strpos($readme, 'text=Yourproject') !== FALSE) {
        echo "ERROR: README.md still contains 'text=Yourproject'" . PHP_EOL;
      } else {
        echo "FIXED: README.md placeholder image URL is correctly updated" . PHP_EOL;
      }
      
      if (strpos($readme, 'alt="Yourproject logo"') !== FALSE) {
        echo "ERROR: README.md still contains 'alt=\"Yourproject logo\"'" . PHP_EOL;
      } else {
        echo "FIXED: README.md placeholder alt text is correctly updated" . PHP_EOL;
      }
    }

    // Verify all expected files are present.
    $this->assertCommonFilesPresent();
    $this->assertPhpFilesPresent();
    $this->assertPhpCommandFilesPresent();
    $this->assertNodejsFilesPresent();
    $this->assertShellFilesPresent();
    $this->assertDocsFilesPresent();
  }

  /**
   * Test init script with PHP Command but no build.
   */
  public function testInitPhpCommandNoBuild(): void {
    $process = $this->runProcess('./init.sh', [], [
      'YodasHut',
      'force-crystal',
      'Jane Doe',
      '',
      '',
      '',
      'n',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Please follow the prompts to adjust your project configuration');
    $this->assertProcessOutputContains($process, 'Initialization complete.');

    // Check that box.json is not created.
    $this->assertFixtureFileNotExists("box.json");
    $this->assertCommonFilesPresent();
    $this->assertPhpFilesPresent();
    $this->assertPhpCommandFilesPresent();

    // Verify no build artifacts are present.
    $this->assertFixtureFileNotContains(".github/workflows/release-php.yml", "Build PHAR");
    $this->assertFixtureFileNotContains(".github/workflows/release-php.yml", "Test PHAR");
    $this->assertFixtureFileNotContains(".github/workflows/release-php.yml", "force-crystal.phar");
  }

  /**
   * Test init script with PHP script instead of command.
   */
  public function testInitPhpScript(): void {
    $process = $this->runProcess('./init.sh', [], [
      'YodasHut',
      'force-crystal',
      'Jane Doe',
      '',
      'n',
      'y',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Please follow the prompts to adjust your project configuration');
    $this->assertProcessOutputContains($process, 'Initialization complete.');

    // Check that force-crystal exists but src directory doesn't.
    $this->assertFixtureFileExists("force-crystal");
    $this->assertFixtureDirectoryNotExists("src");

    // Check other files are as expected for PHP script.
    $this->assertCommonFilesPresent();
    $this->assertPhpFilesPresent();
    $this->assertPhpScriptFilesPresent();
  }

  /**
   * Test init script with neither PHP command nor script.
   */
  public function testInitNoPhpCommandOrScript(): void {
    $process = $this->runProcess('./init.sh', [], [
      'YodasHut',
      'force-crystal',
      'Jane Doe',
      '',
      'n',
      'n',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Please follow the prompts to adjust your project configuration');
    $this->assertProcessOutputContains($process, 'Initialization complete.');

    // Check neither force-crystal nor php-command exists.
    $this->assertFixtureFileNotExists("force-crystal");
    $this->assertFixtureFileNotExists("php-command");

    // Common files should still be present.
    $this->assertCommonFilesPresent();
    $this->assertPhpFilesPresent();
  }

  /**
   * Test init script without PHP.
   */
  public function testInitNoPhp(): void {
    $process = $this->runProcess('./init.sh', [], [
      'YodasHut',
      'force-crystal',
      'Jane Doe',
      'n',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Please follow the prompts to adjust your project configuration');
    $this->assertProcessOutputContains($process, 'Initialization complete.');

    // Check composer.json doesn't exist.
    $this->assertFixtureFileNotExists("composer.json");

    // Verify other PHP-related files don't exist.
    $this->assertFixtureFileNotExists("phpcs.xml");
    $this->assertFixtureFileNotExists("phpmd.xml");
    $this->assertFixtureFileNotExists("phpstan.neon");
    $this->assertFixtureFileNotExists("phpunit.xml");
    $this->assertFixtureFileNotExists("rector.php");
    $this->assertFixtureFileNotExists(".github/workflows/test-php.yml");
    $this->assertFixtureFileNotExists(".github/workflows/release-php.yml");

    // But common files should still exist.
    $this->assertCommonFilesPresent();
  }

  /**
   * Test init script without NodeJS.
   */
  public function testInitNoNodejs(): void {
    $process = $this->runProcess('./init.sh', [], [
      'YodasHut',
      'force-crystal',
      'Jane Doe',
      '',
      '',
      '',
      '',
      'n',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Please follow the prompts to adjust your project configuration');
    $this->assertProcessOutputContains($process, 'Initialization complete.');

    // Check package.json doesn't exist.
    $this->assertFixtureFileNotExists("package.json");

    // Verify other NodeJS files don't exist.
    $this->assertFixtureFileNotContains(".gitignore", "/node_modules");
    $this->assertFixtureFileNotContains(".gitignore", "/package-lock.json");
    $this->assertFixtureFileNotContains(".gitignore", "/yarn.lock");
    $this->assertFixtureFileNotContains(".gitattributes", "/.npmignore");
    $this->assertFixtureFileNotExists(".github/workflows/test-nodejs.yml");
    $this->assertFixtureFileNotExists(".github/workflows/release-nodejs.yml");
    $this->assertFixtureFileNotContains("README.md", "npm install");

    // But common and PHP files should exist.
    $this->assertCommonFilesPresent();
    $this->assertPhpFilesPresent();
  }

  /**
   * Test init script without Shell.
   */
  public function testInitNoShell(): void {
    $process = $this->runProcess('./init.sh', [], [
      'YodasHut',
      'force-crystal',
      'Jane Doe',
      '',
      '',
      '',
      '',
      '',
      'n',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Please follow the prompts to adjust your project configuration');
    $this->assertProcessOutputContains($process, 'Initialization complete.');

    // Check force-crystal.sh doesn't exist.
    $this->assertFixtureFileNotExists("force-crystal.sh");
    $this->assertFixtureFileNotExists(".github/workflows/test-shell.yml");

    // But common and PHP files should exist.
    $this->assertCommonFilesPresent();
    $this->assertPhpFilesPresent();
  }

  /**
   * Test init script without docs.
   */
  public function testInitNoDocs(): void {
    $process = $this->runProcess('./init.sh', [], [
      'YodasHut',
      'force-crystal',
      'Jane Doe',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'n',
      '',
      '',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Please follow the prompts to adjust your project configuration');
    $this->assertProcessOutputContains($process, 'Initialization complete.');

    // Check docs directory doesn't exist.
    $this->assertFixtureDirectoryNotExists("docs");
    $this->assertFixtureFileNotExists(".github/workflows/test-docs.yml");
    $this->assertFixtureFileNotExists(".github/workflows/release-docs.yml");
    $this->assertFixtureFileNotContains(".gitattributes", "/docs");

    // But common and PHP files should exist.
    $this->assertCommonFilesPresent();
    $this->assertPhpFilesPresent();
  }

  /**
   * Test init script with non-standard characters in project and namespace.
   */
  public function testInitWithNonStandardNames(): void {
    $process = $this->runProcess('./init.sh', [], [
      'Yodas-Hut',
      'Force Crystal',
      'Jane Doe',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Please follow the prompts to adjust your project configuration');
    $this->assertProcessOutputContains($process, 'Initialization complete.');

    // Check that namespace was converted correctly.
    $this->assertFixtureFileContains("composer.json", "YodasHut");

    // Check that project name was converted correctly.
    $this->assertFixtureFileContains("composer.json", "force-crystal");

    // All other files should be as expected.
    $this->assertCommonFilesPresent();
    $this->assertPhpFilesPresent();
    $this->assertPhpCommandFilesPresent();
    $this->assertNodejsFilesPresent();
    $this->assertShellFilesPresent();
    $this->assertDocsFilesPresent();
  }

  /**
   * Test init script with abort.
   */
  public function testInitAbort(): void {
    $process = $this->runProcess('./init.sh', [], [
      'YodasHut',
      'force-crystal',
      'Jane Doe',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'n',
    ]);

    $this->assertProcessFailed($process);
    $this->assertProcessOutputContains($process, 'Please follow the prompts to adjust your project configuration');
    $this->assertProcessOutputContains($process, 'Aborting.');
  }

  /**
   * Test init script with silent mode.
   */
  public function testInitSilentMode(): void {
    $process = $this->runProcess('./init.sh', ['YodasHut', 'force-crystal', 'Jane Doe']);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Initialization complete.');

    // Check basic files exist.
    $this->assertFixtureFileExists("README.md");
    $this->assertFixtureFileExists(".editorconfig");

    // All other files should be as expected.
    $this->assertCommonFilesPresent();
    $this->assertPhpFilesPresent();
    $this->assertPhpCommandFilesPresent();
    $this->assertNodejsFilesPresent();
    $this->assertShellFilesPresent();
    $this->assertDocsFilesPresent();
  }

  /**
   * Test init script with keep script option.
   */
  public function testInitKeepScript(): void {
    $process = $this->runProcess('./init.sh', [], [
      'YodasHut',
      'force-crystal',
      'Jane Doe',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'n',
      '',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Please follow the prompts to adjust your project configuration');
    $this->assertProcessOutputContains($process, 'Initialization complete.');

    // Verify init.sh was kept.
    $this->assertFixtureFileExists("init.sh");
  }

}
