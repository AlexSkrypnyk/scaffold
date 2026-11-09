@@ -5,35 +5,6 @@
 This document is generated and maintained by an AI agent via the `update-architecture-docs` skill in `.claude/skills/update-architecture-docs/SKILL.md`. The content is derived from the source code. If this documentation and the code disagree, the code wins.
 
 
-## PHP application
-
-
-### Console application
-
-The PHP stack is a Symfony Console application. The `bin/force-crystal` entry script resolves the Composer autoloader, registers the commands from `src/Command/`, and hands control to the Symfony `Application`, with `roll-dice` set as the default command.
-
-Commands live in the `YodasHut\App\Command` namespace, autoloaded PSR-4 from `src/`. `RollDiceCommand` accepts `--sides` (default 6, at least 2) and `--count` (default 1, from 1 to 100) options, rolls the dice with `random_int()` in `rollDie()`, and prints each roll and the total; an out-of-range or non-integer option is reported and returned as a command failure. `SayHelloCommand` is a minimal second command showing the multi-command structure.
-
-```mermaid
-%% Traced from: bin/force-crystal, src/Command/RollDiceCommand.php.
-sequenceDiagram
-    participant User
-    participant Entry as bin/force-crystal
-    participant App as Symfony Console Application
-    participant Roll as RollDiceCommand
-    User->>Entry: ./bin/force-crystal roll-dice --sides=6 --count=2
-    Entry->>App: run()
-    App->>Roll: execute(input, output)
-    Roll->>Roll: parseInteger() validates --sides and --count
-    Roll->>Roll: rollDie() once per die
-    Roll-->>App: SUCCESS, or FAILURE on invalid option
-    App-->>User: each roll + total
-```
-
-
-PHP code is verified by PHPUnit tests in `tests/phpunit/` (unit tests with mocks in `Unit/`, integration tests against the real file system in `Functional/`) and by a three-layer quality stack: PHP_CodeSniffer, PHPStan, and Rector, wired as `composer lint` and `composer test`.
-
-
 
 ## NodeJS script
 
