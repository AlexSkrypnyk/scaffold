<?php

declare(strict_types=1);

namespace YodasHut\App\Tests\Functional;

use PHPUnit\Framework\Attributes\CoversMethod;
use PHPUnit\Framework\Attributes\Group;
use YodasHut\App\Command\SayHelloCommand;
use YodasHut\App\Tests\Traits\ConsoleTrait;

/**
 * Class SayHelloCommandTest.
 *
 * This is a unit test for the SayHelloCommand class.
 */
#[CoversMethod(SayHelloCommand::class, 'execute')]
#[CoversMethod(SayHelloCommand::class, 'configure')]
#[Group('command')]
class SayHelloCommandTest extends ApplicationFunctionalTestCase {

  use ConsoleTrait;

  public function testExecute(): void {
    $this->consoleInitApplicationTester(SayHelloCommand::class);

    $output = $this->consoleApplicationRun();
    $this->assertStringContainsString('Hello, Symfony console!', $output);
  }

}
