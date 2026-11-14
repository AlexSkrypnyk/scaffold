@@ -19,7 +19,7 @@
 Multi-command CLI application structure:
 
 - **Location:** `src/Command/` directory
-- **Entry point:** `bin/force-crystal`
+- **Entry point:** `bin/star-forge`
 - **Use for:** Complex applications with multiple commands, shared logic, OOP
   architecture
 
@@ -29,7 +29,7 @@
 
 1. Create class in `src/Command/YourCommand.php` extending
    `Symfony\Component\Console\Command\Command`
-2. Register in `bin/force-crystal`: `$application->add(new YourCommand());`
+2. Register in `bin/star-forge`: `$application->add(new YourCommand());`
 3. Add functional test in `tests/phpunit/Functional/YourCommandTest.php`
 
 
@@ -75,64 +75,6 @@
 ```
 
 
-## NodeJS Application Architecture
-
-### Standalone Single-File Script
-
-Single-file CLI script structure:
-
-- **Location:** `nodejs-script` file (or custom name)
-- **Dependencies:** None - self-contained
-- **Use for:** Simple utilities, deployment scripts, one-off tasks
-
-### Environment Variables
-
-- `SCRIPT_QUIET=1` - Suppress output (useful in tests)
-- `SCRIPT_RUN_SKIP=1` - Skip execution (useful when requiring file)
-
-### Testing Standalone Scripts
-
-The script uses a testable pattern:
-
-- Business logic in `main()` function
-- Output via `verbose()` with internal buffer
-- Set `SCRIPT_QUIET=1` in tests, then assert on `verbose()` return value
-
-Example test:
-
-```js
-const assert = require('node:assert');
-
-process.env.SCRIPT_QUIET = '1';
-process.env.SCRIPT_RUN_SKIP = '1';
-const { main, verbose } = require('./nodejs-script');
-main(['nodejs-script', 'arg1'], 2);
-assert.ok(verbose('').some((line) => line.includes('expected')));
-```
-
-### Commands
-
-```bash
-# Run all linters (ESLint, Prettier)
-npm run lint
-
-# Auto-fix code style issues
-npm run lint-fix
-
-# Run all tests
-npm run test
-
-# Run tests with coverage (reports in .logs/)
-npm run test-coverage
-```
-
-
-```bash
-# Shell script tests
-./tests/bats/node_modules/bats/bin/bats tests/bats/
-```
-
-
 ### Building
 
 
@@ -194,15 +136,6 @@
 - Data providers: `#[DataProvider('providerMethodName')]`
 
 
-### Shell Script Testing with BATS
-
-Shell script tests use BATS:
-
-- Tests in `tests/bats/` with `.bats` extension
-- Helper functions in `tests/bats/_helper.bash`
-- Coverage exclusions: `# LCOV_EXCL_START` / `# LCOV_EXCL_END`
-
-
 ## CI/CD
 
 GitHub Actions workflows test across:
@@ -215,13 +148,6 @@
 - `.github/workflows/test-php.yml` - PHP testing
 - `.github/workflows/release-php.yml` - Runs on the tag that publishing the draft release creates: checks it, then attaches the asset, its checksum and its provenance attestation to the release
   - Builds the PHAR to attach
-
-
-- `.github/workflows/test-shell.yml` - Shell script testing
-
-
-- `.github/workflows/test-nodejs.yml` - NodeJS testing
-- `.github/workflows/release-nodejs.yml` - Runs on the tag that `npm version` creates: checks it matches `package.json`, publishes to npm with provenance, then attaches the script, its checksum and its provenance attestation to the release and publishes it
 
 
 ## Security audit
