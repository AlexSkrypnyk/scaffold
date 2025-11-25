@@ -14,25 +14,38 @@
 ## PHP Application Architecture
 
 
-### Symfony Console Application
+### Standalone Single-File Script
 
-Multi-command CLI application structure:
+Single-file CLI script structure:
 
-- **Location:** `src/Command/` directory
-- **Entry point:** `force-crystal` (wraps `src/app.php`)
-- **Use for:** Complex applications with multiple commands, shared logic, OOP
-  architecture
+- **Location:** `force-crystal` file (or custom name)
+- **Dependencies:** None - self-contained
+- **Use for:** Simple utilities, deployment scripts, one-off tasks
 
-### Adding New Commands
+### Environment Variables
 
-To add a Symfony Console command:
+- `SCRIPT_QUIET=1` - Suppress output (useful in tests)
+- `SCRIPT_RUN_SKIP=1` - Skip execution (useful when requiring file)
 
-1. Create class in `src/Command/YourCommand.php` extending
-   `Symfony\Component\Console\Command\Command`
-2. Register in `src/app.php`: `$application->add(new YourCommand());`
-3. Add functional test in `tests/phpunit/Functional/YourCommandTest.php`
+### Testing Standalone Scripts
 
+The script uses a testable pattern:
 
+- Business logic in `main()` function
+- Output via `verbose()` with internal buffer
+- Set `SCRIPT_QUIET=1` in tests, then assert on `verbose()` return value
+
+Example test:
+
+```php
+putenv('SCRIPT_QUIET=1');
+putenv('SCRIPT_RUN_SKIP=1');
+require 'force-crystal';
+$output = main(['force-crystal', 'arg1'], 2);
+$this->assertStringContainsString('expected', implode("\n", $output));
+```
+
+
 ### Namespace Structure
 
 - Source code: `YodasHut\App\`
@@ -76,22 +89,10 @@
 ```
 
 
-```bash
-# Shell script tests
-./tests/bats/node_modules/bats/bin/bats tests/bats/
-```
-
-
 ### Building
 
 
 ```bash
-# Build PHAR executable (installs Box first)
-composer build
-```
-
-
-```bash
 # Clean and reinstall dependencies
 composer reset # removes vendor/, vendor-bin/, composer.lock
 composer install
@@ -143,15 +144,6 @@
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
@@ -162,10 +154,6 @@
 Key workflows:
 
 - `.github/workflows/test-php.yml` - PHP testing
-- `.github/workflows/release-php.yml` - PHAR packaging and release
-
-
-- `.github/workflows/test-shell.yml` - Shell script testing
 
 
 - `.github/workflows/test-nodejs.yml` - NodeJS testing
