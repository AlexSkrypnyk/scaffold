<?php

declare(strict_types=1);

namespace YourNamespace\App\Tests\Traits;

use PHPUnit\Framework\MockObject\MockObject;

/**
 * Trait MockTrait.
 *
 * This trait provides a method to prepare class mock.
 *
 * @phpstan-ignore trait.unused
 */
trait MockTrait {

  /**
   * Helper to prepare class or trait mock.
   *
   * @param class-string $class
   *   Class or trait name to generate the mock.
   * @param array<string, scalar|\Closure> $methods
   *   Optional array of methods and values, keyed by method name. Array
   *   elements can be return values, callbacks created with
   *   $this->willReturnCallback(), or closures.
   * @param bool|array<mixed> $args
   *   Optional array of constructor arguments or FALSE to disable the original
   *   constructor. If omitted, an original constructor will be called.
   *
   * @return \PHPUnit\Framework\MockObject\MockObject
   *   Mocked class.
   *
   * @SuppressWarnings("PHPMD.CyclomaticComplexity")
   */
  protected function prepareMock(string $class, array $methods = [], array|bool $args = []): MockObject {
    $methods = array_filter($methods, fn($value, $key): bool => !is_numeric($key), ARRAY_FILTER_USE_BOTH);

    if (!class_exists($class)) {
      throw new \InvalidArgumentException(sprintf('Class %s does not exist', $class));
    }

    $builder = $this->getMockBuilder($class);

    if (is_array($args) && !empty($args)) {
      $builder->enableOriginalConstructor()->setConstructorArgs($args);
    }
    elseif ($args === FALSE) {
      $builder->disableOriginalConstructor();
    }

    $method_names = array_values(array_filter(array_keys($methods), fn($method): bool => !empty($method)));
    if (!empty($method_names)) {
      $builder->onlyMethods($method_names);
    }
    $mock = $builder->getMock();

    foreach ($methods as $method => $value) {
      if (empty($method)) {
        continue;
      }
      // Handle callback value differently based on its type.
      if (is_object($value) && str_contains($value::class, 'Callback')) {
        $mock->expects($this->any())->method($method)->willReturnCallback($value);
      }
      elseif (is_object($value) && str_contains($value::class, 'Closure')) {
        $mock->expects($this->any())->method($method)->willReturnCallback($value);
      }
      else {
        $mock->expects($this->any())->method($method)->willReturn($value);
      }
    }

    return $mock;
  }

}
