@@ -10,18 +10,18 @@
 
 ### Console application
 
-The PHP stack is a Symfony Console application. The `bin/force-crystal` entry script resolves the Composer autoloader, registers the commands from `src/Command/`, and hands control to the Symfony `Application`, with `roll-dice` set as the default command.
+The PHP stack is a Symfony Console application. The `bin/star-forge` entry script resolves the Composer autoloader, registers the commands from `src/Command/`, and hands control to the Symfony `Application`, with `roll-dice` set as the default command.
 
-Commands live in the `YodasHut\App\Command` namespace, autoloaded PSR-4 from `src/`. `RollDiceCommand` accepts `--sides` (default 6, at least 2) and `--count` (default 1, from 1 to 100) options, rolls the dice with `random_int()` in `rollDie()`, and prints each roll and the total; an out-of-range or non-integer option is reported and returned as a command failure. `SayHelloCommand` is a minimal second command showing the multi-command structure.
+Commands live in the `JediTemple\App\Command` namespace, autoloaded PSR-4 from `src/`. `RollDiceCommand` accepts `--sides` (default 6, at least 2) and `--count` (default 1, from 1 to 100) options, rolls the dice with `random_int()` in `rollDie()`, and prints each roll and the total; an out-of-range or non-integer option is reported and returned as a command failure. `SayHelloCommand` is a minimal second command showing the multi-command structure.
 
 ```mermaid
-%% Traced from: bin/force-crystal, src/Command/RollDiceCommand.php.
+%% Traced from: bin/star-forge, src/Command/RollDiceCommand.php.
 sequenceDiagram
     participant User
-    participant Entry as bin/force-crystal
+    participant Entry as bin/star-forge
     participant App as Symfony Console Application
     participant Roll as RollDiceCommand
-    User->>Entry: ./bin/force-crystal roll-dice --sides=6 --count=2
+    User->>Entry: ./bin/star-forge roll-dice --sides=6 --count=2
     Entry->>App: run()
     App->>Roll: execute(input, output)
     Roll->>Roll: parseInteger() validates --sides and --count
@@ -56,16 +56,16 @@
 
 ## Shell script
 
-The shell stack is an interactive Bash script, `force-crystal.sh`. It collects the number of sides on a die and a confirmation through `ask` and `ask_yesno` prompt helpers (each skipped when the value is already supplied as an argument or environment variable), rejects a number of sides outside 2-100, rolls the die with Bash's `$RANDOM`, and prints the result.
+The shell stack is an interactive Bash script, `star-forge.sh`. It collects the number of sides on a die and a confirmation through `ask` and `ask_yesno` prompt helpers (each skipped when the value is already supplied as an argument or environment variable), rejects a number of sides outside 2-100, rolls the die with Bash's `$RANDOM`, and prints the result.
 
 `SHOULD_PROCEED=y` bypasses the confirmation prompt, and `SCRIPT_DEBUG=1` enables trace output. The `main` invocation is guarded by a `BASH_SOURCE` check so BATS tests in `tests/bats/` can source the script and call its functions directly.
 
 ```mermaid
-%% Traced from: force-crystal.sh.
+%% Traced from: star-forge.sh.
 sequenceDiagram
     participant User
-    participant Script as force-crystal.sh
-    User->>Script: ./force-crystal.sh sides
+    participant Script as star-forge.sh
+    User->>Script: ./star-forge.sh sides
     Script->>User: prompts for sides and confirmation, skipped when supplied
     Script->>Script: validates sides as a whole number from 2 to 100
     Script-->>User: rolled value from $RANDOM, or an error and exit 1
