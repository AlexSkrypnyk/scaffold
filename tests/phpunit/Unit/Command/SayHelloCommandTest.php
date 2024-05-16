<?php

declare(strict_types=1);

namespace YourNamespace\App\Tests\Unit\Command;

use PHPUnit\Framework\Attributes\CoversMethod;
use PHPUnit\Framework\Attributes\Group;
use YourNamespace\App\Command\SayHelloCommand;

/**
 * Class SayHelloCommandTest.
 *
 * This is a unit test for the SayHelloCommand class.
 */
#[CoversMethod(SayHelloCommand::class, 'execute')]
#[CoversMethod(SayHelloCommand::class, 'configure')]
#[Group('command')]
class SayHelloCommandTest extends CommandTestCase {

  public function testExecute(): void {
    $output = $this->runExecute(SayHelloCommand::class);
    $this->assertArrayContainsString('Hello, Symfony console!', $output);
  }

}
