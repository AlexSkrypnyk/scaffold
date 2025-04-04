<?php

declare(strict_types=1);

namespace AlexSkrypnyk\Scaffold\Tests\Functional;

use AlexSkrypnyk\Scaffold\Tests\Traits\FixtureTrait;
use AlexSkrypnyk\Scaffold\Tests\Traits\ProcessTrait;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\TestCase;

/**
 * Class ShellCommandFunctionalTest.
 *
 * Functional tests for shell-command.sh script.
 */
#[Group('functional')]
class ShellCommandFunctionalTest extends TestCase {

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
   * Test the shell command with user input.
   */
  public function testShellCommandWithUserInput(): void {
    $process = $this->runProcess('./shell-command.sh', [], [
      'general',
      'y',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Follow the prompts');
    $this->assertProcessOutputContains($process, 'Fetching joke for topic: general');
    $this->assertProcessOutputContains($process, 'https://official-joke-api.appspot.com/jokes/general/random');
  }

  /**
   * Test the shell command with CLI arguments.
   */
  public function testShellCommandWithCliArguments(): void {
    $process = $this->runProcess('./shell-command.sh', ['programming'], [], 60, [
      'SHOULD_PROCEED' => 'y',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Follow the prompts');
    $this->assertProcessOutputContains($process, 'Fetching joke for topic: programming');
    $this->assertProcessOutputContains($process, 'https://official-joke-api.appspot.com/jokes/programming/random');
  }

  /**
   * Test the shell command with CLI arguments, aborting.
   */
  public function testShellCommandWithCliArgumentsAborting(): void {
    $process = $this->runProcess('./shell-command.sh', ['programming'], [], 60, [
      'SHOULD_PROCEED' => 'n',
    ]);

    $this->assertProcessSuccessful($process);
    $this->assertProcessOutputContains($process, 'Follow the prompts');
    $this->assertProcessOutputContains($process, 'Aborting.');
  }

}
