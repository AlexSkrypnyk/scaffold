<?php

declare(strict_types=1);

namespace YourNamespace\App\Tests\Unit;

use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;
use YourNamespace\App\Example;

/**
 * Unit tests for the example library class.
 */
#[CoversClass(Example::class)]
final class ExampleUnitTest extends TestCase {

  #[DataProvider('dataProviderGreet')]
  public function testGreet(string $name, string $expected): void {
    $this->assertSame($expected, (new Example())->greet($name));
  }

  public static function dataProviderGreet(): \Iterator {
    yield ['World', 'Hello, World!'];
    yield ['Jane Doe', 'Hello, Jane Doe!'];
  }

  public function testGreetRejectsEmptyName(): void {
    $this->expectException(\InvalidArgumentException::class);
    $this->expectExceptionMessage('Name cannot be empty.');

    (new Example())->greet('');
  }

}
