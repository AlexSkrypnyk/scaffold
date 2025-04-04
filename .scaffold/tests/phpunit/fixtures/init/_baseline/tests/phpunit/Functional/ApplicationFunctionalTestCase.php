<?php

declare(strict_types=1);

namespace YodasHut\App\Tests\Functional;

use PHPUnit\Framework\TestCase;
use YodasHut\App\Tests\Traits\ArrayTrait;
use YodasHut\App\Tests\Traits\AssertTrait;
use YodasHut\App\Tests\Traits\MockTrait;

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
