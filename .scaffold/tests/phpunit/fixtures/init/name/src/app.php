@@ -8,11 +8,11 @@
 declare(strict_types=1);
 
 use Symfony\Component\Console\Application;
-use YodasHut\App\Command\JokeCommand;
-use YodasHut\App\Command\SayHelloCommand;
+use JediTemple\App\Command\JokeCommand;
+use JediTemple\App\Command\SayHelloCommand;
 
 // @codeCoverageIgnoreStart
-$application = new Application('YourProject', '@force-crystal-version@');
+$application = new Application('YourProject', '@star-forge-version@');
 
 $command = new JokeCommand();
 $application->add($command);
