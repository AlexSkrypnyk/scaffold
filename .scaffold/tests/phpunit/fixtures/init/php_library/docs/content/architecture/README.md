@@ -8,28 +8,9 @@
 ## PHP application
 
 
-### Console application
+### Class library
 
-The PHP stack is a Symfony Console application. The `force-crystal` entry script resolves the Composer autoloader, registers the commands from `src/Command/`, and hands control to the Symfony `Application`, with `joke` set as the default command.
-
-Commands live in the `YodasHut\App\Command` namespace, autoloaded PSR-4 from `src/`. `JokeCommand` accepts a `--topic` option, fetches a random joke from a public API, and prints the setup and punchline; any fetch or decode error is reported and returned as a command failure. `SayHelloCommand` is a minimal second command showing the multi-command structure.
-
-```mermaid
-%% Traced from: force-crystal, src/Command/JokeCommand.php.
-sequenceDiagram
-    participant User
-    participant Entry as force-crystal
-    participant App as Symfony Console Application
-    participant Joke as JokeCommand
-    participant API as official-joke-api.appspot.com
-    User->>Entry: ./force-crystal joke --topic=general
-    Entry->>App: run()
-    App->>Joke: execute(input, output)
-    Joke->>API: GET /jokes/{topic}/random
-    API-->>Joke: JSON with setup and punchline
-    Joke-->>App: SUCCESS, or FAILURE on fetch or decode error
-    App-->>User: setup + punchline
-```
+The PHP stack has no entry point: it is a class library consumed by other projects through Composer. Classes live in `src/` and are autoloaded PSR-4 under the `YodasHut\App` namespace, starting from the `Example` placeholder and its unit test. The flows through them are documented here as the library grows.
 
 
 PHP code is verified by PHPUnit tests in `tests/phpunit/` (unit tests with mocks in `Unit/`, integration tests against the real file system in `Functional/`) and by a three-layer quality stack: PHP_CodeSniffer, PHPStan, and Rector, wired as `composer lint` and `composer test`.
