<?php

declare(strict_types=1);

namespace YodasHut\App\Tests\Functional;

use AlexSkrypnyk\PhpunitHelpers\Traits\ApplicationTrait;
use AlexSkrypnyk\PhpunitHelpers\Traits\AssertArrayTrait;
use PHPUnit\Framework\Attributes\CoversMethod;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\TestCase;
use YodasHut\App\Command\RollDiceCommand;

/**
 * Functional test for the RollDiceCommand class.
 */
#[CoversMethod(RollDiceCommand::class, 'execute')]
#[CoversMethod(RollDiceCommand::class, 'configure')]
#[CoversMethod(RollDiceCommand::class, 'parseInteger')]
#[CoversMethod(RollDiceCommand::class, 'rollDie')]
#[Group('command')]
final class RollDiceCommandTest extends TestCase {

  use ApplicationTrait;
  use AssertArrayTrait;

  /**
   * @param array<string, string> $input
   * @param list<int> $rolls
   * @param list<string> $expected_output
   */
  #[DataProvider('dataProviderExecute')]
  public function testExecute(array $input, array $rolls, array $expected_output, bool $expected_fail = FALSE): void {
    $builder = $this->getMockBuilder(RollDiceCommand::class);
    $builder->onlyMethods(['rollDie']);
    $mock = $builder->getMock();
    $mock->expects($this->exactly(count($rolls)))->method('rollDie')->willReturnOnConsecutiveCalls(...$rolls);

    $this->applicationInitFromCommand($mock);
    $output = $this->applicationRun($input, [], $expected_fail);

    foreach ($expected_output as $expected_output_string) {
      $this->assertStringContainsString($expected_output_string, $output);
    }
  }

  public static function dataProviderExecute(): \Iterator {
    yield 'defaults' => [[], [4], ['Rolled 1d6: 4', 'Total: 4']];
    yield 'custom sides' => [['--sides' => '20'], [17], ['Rolled 1d20: 17', 'Total: 17']];
    yield 'custom count' => [['--count' => '3'], [1, 6, 2], ['Rolled 3d6: 1, 6, 2', 'Total: 9']];
    yield 'custom sides and count' => [['--sides' => '2', '--count' => '2'], [2, 1], ['Rolled 2d2: 2, 1', 'Total: 3']];
    yield 'max count' => [['--count' => '100'], array_fill(0, 100, 1), ['Rolled 100d6: ', 'Total: 100']];
    yield 'sides below minimum' => [['--sides' => '1'], [], ['The "--sides" option must be an integer of at least 2.'], TRUE];
    yield 'sides zero' => [['--sides' => '0'], [], ['The "--sides" option must be an integer of at least 2.'], TRUE];
    yield 'sides negative' => [['--sides' => '-6'], [], ['The "--sides" option must be an integer of at least 2.'], TRUE];
    yield 'sides not a number' => [['--sides' => 'six'], [], ['The "--sides" option must be an integer of at least 2.'], TRUE];
    yield 'sides decimal' => [['--sides' => '6.5'], [], ['The "--sides" option must be an integer of at least 2.'], TRUE];
    yield 'sides empty' => [['--sides' => ''], [], ['The "--sides" option must be an integer of at least 2.'], TRUE];
    yield 'count zero' => [['--count' => '0'], [], ['The "--count" option must be an integer from 1 to 100.'], TRUE];
    yield 'count above maximum' => [['--count' => '101'], [], ['The "--count" option must be an integer from 1 to 100.'], TRUE];
    yield 'count not a number' => [['--count' => 'many'], [], ['The "--count" option must be an integer from 1 to 100.'], TRUE];
  }

  public function testExecuteRollsWithinRange(): void {
    $this->applicationInitFromCommand(RollDiceCommand::class);
    $output = $this->applicationRun(['--sides' => '2', '--count' => '100']);

    $this->assertMatchesRegularExpression('/^Rolled 100d2: [12](, [12]){99}$/m', $output);
    $this->assertMatchesRegularExpression('/^Total: (\d+)$/m', $output);

    preg_match('/^Total: (\d+)$/m', $output, $matches);
    $this->assertGreaterThanOrEqual(100, (int) $matches[1]);
    $this->assertLessThanOrEqual(200, (int) $matches[1]);
  }

}
