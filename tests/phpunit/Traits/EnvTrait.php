<?php

declare(strict_types=1);

namespace YourNamespace\App\Tests\Traits;

/**
 * Trait EnvTrait.
 *
 * Trait for managing environment variables.
 *
 * @phpstan-ignore trait.unused
 */
trait EnvTrait {

  /**
   * The environment variables that were set.
   *
   * @var array
   */
  protected static $env = [];

  /**
   * Set an environment variable.
   *
   * @param string $name
   *   The name of the environment variable.
   * @param string $value
   *   The value of the environment variable.
   */
  public static function envSet(string $name, string $value): void {
    static::$env[$name] = $value;
    putenv($name . '=' . $value);
  }

  /**
   * Set multiple environment variables.
   *
   * @param array $vars
   *   An array of environment variables to set.
   */
  public static function envSetMultiple(array $vars): void {
    foreach ($vars as $name => $value) {
      static::envSet($name, $value);
    }
  }

  /**
   * Unset an environment variable.
   *
   * @param string $name
   *   The name of the environment variable.
   */
  public static function envUnset(string $name): void {
    unset(static::$env[$name]);
    putenv($name);
  }

  /**
   * Unset an environment variable by prefix.
   *
   * @param string $prefix
   *   The prefix of the environment variable.
   */
  public static function envUnsetPrefix(string $prefix): void {
    foreach (array_keys(static::$env) as $name) {
      if (str_starts_with($name, $prefix)) {
        static::envUnset($name);
      }
    }

    foreach (array_keys(getenv()) as $name) {
      if (str_starts_with($name, $prefix)) {
        static::envUnset($name);
      }
    }
  }

  /**
   * Get an environment variable.
   *
   * @param string $name
   *   The name of the environment variable.
   */
  public static function envGet(string $name): mixed {
    return getenv($name);
  }

  /**
   * Check if an environment variable is set.
   *
   * @param string $name
   *   The name of the environment variable.
   */
  public static function envIsSet(string $name): bool {
    return getenv($name) !== FALSE;
  }

  /**
   * Check if an environment variable is not set.
   */
  public static function envIsUnset(string $name): bool {
    return getenv($name) === FALSE;
  }

  /**
   * Reset environment variables.
   */
  public static function envReset(): void {
    foreach (array_keys(static::$env) as $name) {
      static::envUnset($name);
    }
    static::$env = [];
  }

  /**
   * Set environment variables from input.
   *
   * @param array $input
   *   The input array.
   * @param string $prefix
   *   The prefix to look for.
   * @param bool $remove
   *   Whether to remove the input variables.
   */
  public static function envFromInput(array &$input, string $prefix = '', bool $remove = TRUE): void {
    foreach ($input as $name => $value) {
      if (str_starts_with($name, $prefix)) {
        static::envSet($name, $value);
        if ($remove) {
          unset($input[$name]);
        }
      }
    }
  }

}
