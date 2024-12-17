<?php

declare(strict_types=1);

namespace YourNamespace\App\Tests\Functional;

use PHPUnit\Framework\TestCase;
use YourNamespace\App\Tests\Traits\ArrayTrait;
use YourNamespace\App\Tests\Traits\AssertTrait;
use YourNamespace\App\Tests\Traits\MockTrait;

/**
 * Class ApplicationFunctionalTestCase.
 *
 * Base class to unit test scripts.
 */
abstract class ApplicationFunctionalTestCase extends TestCase {

  use ArrayTrait;
  use AssertTrait;
  use MockTrait;

}
