<?php

namespace YourNamespace\App\Tests\Unit\Command;

use YourNamespace\App\Command\SayHelloCommand;

/**
 * Class SayHelloCommandTest.
 *
 * This is a unit test for the SayHelloCommand class.
 *
 * @coversDefaultClass \YourNamespace\App\Command\SayHelloCommand
 */
class SayHelloCommandTest extends CommandTestCase {

  /**
   * Test the execute method.
   *
   * @covers ::execute
   * @covers ::configure
   * @group command
   */
  public function testExecute(): void {
    $output = $this->runExecute(SayHelloCommand::class);
    $this->assertArrayContainsString('Hello, Symfony console!', $output);
  }

}
