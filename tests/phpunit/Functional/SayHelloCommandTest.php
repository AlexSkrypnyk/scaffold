<?php

declare(strict_types=1);

namespace YourNamespace\App\Tests\Functional;

use AlexSkrypnyk\PhpunitHelpers\Traits\ApplicationTrait;
use PHPUnit\Framework\Attributes\CoversMethod;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\TestCase;
use YourNamespace\App\Command\SayHelloCommand;

/**
 * Class SayHelloCommandTest.
 *
 * This is a unit test for the SayHelloCommand class.
 */
#[CoversMethod(SayHelloCommand::class, 'execute')]
#[CoversMethod(SayHelloCommand::class, 'configure')]
#[Group('command')]
class SayHelloCommandTest extends TestCase {

  use ApplicationTrait;

  public function testExecute(): void {
    $this->applicationInitFromCommand(SayHelloCommand::class);

    $output = $this->applicationRun();
    $this->assertStringContainsString('Hello, Symfony console!', $output);
  }

}
