@@ -8,27 +8,21 @@
 ## PHP application
 
 
-### Console application
+### Single-file script
 
-The PHP stack is a Symfony Console application. The `force-crystal` entry script resolves the Composer autoloader, registers the commands from `src/Command/`, and hands control to the Symfony `Application`, with `joke` set as the default command.
+The PHP stack is a self-contained single-file CLI script, `force-crystal`, with no dependencies on external packages. All business logic lives in a `main()` function, output goes through a `verbose()` function that records every message into an internal buffer, and the script validates that exactly one argument is provided before running.
 
-Commands live in the `YodasHut\App\Command` namespace, autoloaded PSR-4 from `src/`. `JokeCommand` accepts a `--topic` option, fetches a random joke from a public API, and prints the setup and punchline; any fetch or decode error is reported and returned as a command failure. `SayHelloCommand` is a minimal second command showing the multi-command structure.
+Two environment variables make the script testable: `SCRIPT_QUIET=1` suppresses printed output while the buffer keeps recording, and `SCRIPT_RUN_SKIP=1` skips execution so tests can require the file and call `main()` directly, asserting on the buffer contents.
 
 ```mermaid
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
+%% Traced from: force-crystal.
+flowchart TB
+    start([./force-crystal argument]) --> help{help flag passed}
+    help -- yes --> printhelp[print_help writes usage through the verbose buffer]
+    help -- no --> argc{exactly one argument}
+    argc -- no --> err[exception asking for the first argument]
+    argc -- yes --> logic[main business logic]
+    logic --> out[verbose messages, silenced by SCRIPT_QUIET]
 ```
 
 
@@ -53,26 +47,6 @@
 
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
