@@ -2,14 +2,14 @@
 
 declare(strict_types=1);
 
-namespace YodasHut\App\Tests\Functional;
+namespace JediTemple\App\Tests\Functional;
 
 use PHPUnit\Framework\Attributes\CoversMethod;
 use PHPUnit\Framework\Attributes\DataProvider;
 use PHPUnit\Framework\Attributes\Group;
-use YodasHut\App\Command\JokeCommand;
-use YodasHut\App\Tests\Traits\ConsoleTrait;
-use YodasHut\App\Tests\Traits\MockTrait;
+use JediTemple\App\Command\JokeCommand;
+use JediTemple\App\Tests\Traits\ConsoleTrait;
+use JediTemple\App\Tests\Traits\MockTrait;
 
 /**
  * Class JokeCommandTest.
@@ -27,7 +27,7 @@
 
   #[DataProvider('dataProviderExecute')]
   public function testExecute(string $content, array $expected_output, bool $expected_fail = FALSE): void {
-    /** @var \YodasHut\App\Command\JokeCommand $mock */
+    /** @var \JediTemple\App\Command\JokeCommand $mock */
     // @phpstan-ignore varTag.nativeType
     $mock = $this->prepareMock(JokeCommand::class, [
       'getContent' => $content,
