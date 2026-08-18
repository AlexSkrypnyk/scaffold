<?php

declare(strict_types=1);

namespace YodasHut\App;

/**
 * Example library class.
 *
 * Replace this class and its test with the library's own classes.
 */
class Example {

  /**
   * Greet a name.
   *
   * @param string $name
   *   Name to greet.
   *
   * @return string
   *   Greeting for the provided name.
   */
  public function greet(string $name): string {
    if ($name === '') {
      throw new \InvalidArgumentException('Name cannot be empty.');
    }

    return sprintf('Hello, %s!', $name);
  }

}
