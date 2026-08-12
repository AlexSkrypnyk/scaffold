@@ -5,36 +5,6 @@
 This document is generated and maintained by an AI agent via the `update-architecture-docs` skill in `.claude/skills/update-architecture-docs/SKILL.md`. The content is derived from the source code. If this documentation and the code disagree, the code wins.
 
 
-## PHP application
-
-
-### Console application
-
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
-
-
-PHP code is verified by PHPUnit tests in `tests/phpunit/` (unit tests with mocks in `Unit/`, integration tests against the real file system in `Functional/`) and by a three-layer quality stack: PHP_CodeSniffer, PHPStan, and Rector, wired as `composer lint` and `composer test`.
-
-
 
 ## NodeJS script
 
