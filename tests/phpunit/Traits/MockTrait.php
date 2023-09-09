<?php

namespace YourNamespace\App\Tests\Traits;

/**
 * Trait MockTrait.
 *
 * This trait provides a method to prepare class mock.
 */
trait MockTrait {

  /**
   * Prepare class mock.
   *
   * @param string $class
   *   Class name to generate the mock.
   * @param array $methodsMap
   *   Optional array of methods and values, keyed by method name.
   * @param array $args
   *   Optional array of constructor arguments. If omitted, a constructor will
   *   not be called.
   *
   * @return object
   *   Mocked class.
   */
  protected function prepareMock($class, array $methodsMap = [], array $args = []) {
    $methods = array_keys($methodsMap);

    $reflectionClass = new \ReflectionClass($class);

    if ($reflectionClass->isAbstract()) {
      $mock = $this->getMockForAbstractClass(
        $class, $args, '', !empty($args), TRUE, TRUE, $methods
      );
    }
    else {
      $mock = $this->getMockBuilder($class);
      if (!empty($args)) {
        $mock = $mock->enableOriginalConstructor()
          ->setConstructorArgs($args);
      }
      else {
        $mock = $mock->disableOriginalConstructor();
      }
      $mock = $mock->onlyMethods($methods)
        ->getMock();
    }

    foreach ($methodsMap as $method => $value) {
      // Handle callback values differently.
      if (is_object($value) && !str_contains(get_class($value), 'Callback') && !str_contains(get_class($value), 'Closure')) {
        $mock->expects($this->any())
          ->method($method)
          ->will($value);
      }
      elseif (is_callable($value)) {
        $mock->expects($this->any())
          ->method($method)
          ->willReturnCallback($value);
      }
      else {
        $mock->expects($this->any())
          ->method($method)
          ->willReturn($value);
      }
    }

    return $mock;
  }

}
