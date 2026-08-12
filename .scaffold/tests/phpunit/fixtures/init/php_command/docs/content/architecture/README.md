@@ -10,19 +10,19 @@
 
 ### Console application
 
-The PHP stack is a Symfony Console application. The `force-crystal` entry script resolves the Composer autoloader, registers the commands from `src/Command/`, and hands control to the Symfony `Application`, with `joke` set as the default command.
+The PHP stack is a Symfony Console application. The `star-forge` entry script resolves the Composer autoloader, registers the commands from `src/Command/`, and hands control to the Symfony `Application`, with `joke` set as the default command.
 
 Commands live in the `YodasHut\App\Command` namespace, autoloaded PSR-4 from `src/`. `JokeCommand` accepts a `--topic` option, fetches a random joke from a public API, and prints the setup and punchline; any fetch or decode error is reported and returned as a command failure. `SayHelloCommand` is a minimal second command showing the multi-command structure.
 
 ```mermaid
-%% Traced from: force-crystal, src/Command/JokeCommand.php.
+%% Traced from: star-forge, src/Command/JokeCommand.php.
 sequenceDiagram
     participant User
-    participant Entry as force-crystal
+    participant Entry as star-forge
     participant App as Symfony Console Application
     participant Joke as JokeCommand
     participant API as official-joke-api.appspot.com
-    User->>Entry: ./force-crystal joke --topic=general
+    User->>Entry: ./star-forge joke --topic=general
     Entry->>App: run()
     App->>Joke: execute(input, output)
     Joke->>API: GET /jokes/{topic}/random
@@ -53,26 +53,6 @@
 
 The script is verified by the built-in Node test runner (`npm run test` over `tests/nodejs/`, with c8 coverage) and linted by ESLint and Prettier via `npm run lint`.
 
-
-
-## Shell script
-
-The shell stack is an interactive Bash script, `force-crystal.sh`. It collects a topic and a confirmation through `ask` and `ask_yesno` prompt helpers (each skipped when the value is already supplied as an argument or environment variable), fetches a random joke from a public API with `curl`, extracts the setup and punchline with `sed`, and prints them.
-
-`JOKE_URL_ENDPOINT` overrides the API endpoint, `SHOULD_PROCEED=y` bypasses the confirmation prompt, and `SCRIPT_DEBUG=1` enables trace output. The `main` invocation is guarded by a `BASH_SOURCE` check so BATS tests in `tests/bats/` can source the script and call its functions directly.
-
-```mermaid
-%% Traced from: force-crystal.sh.
-sequenceDiagram
-    participant User
-    participant Script as force-crystal.sh
-    participant API as official-joke-api.appspot.com
-    User->>Script: ./force-crystal.sh topic
-    Script->>User: prompts for topic and confirmation, skipped when supplied
-    Script->>API: curl GET /jokes/{topic}/random
-    API-->>Script: JSON response
-    Script-->>User: setup + punchline extracted with sed
-```
 
 
 ## Regenerating this document
