@@ -14,25 +14,21 @@
 ## PHP Application Architecture
 
 
-### Symfony Console Application
+### Class Library
 
-Multi-command CLI application structure:
+This project ships classes only - there is no CLI entry point:
 
-- **Location:** `src/Command/` directory
-- **Entry point:** `force-crystal`
-- **Use for:** Complex applications with multiple commands, shared logic, OOP
-  architecture
+- **Location:** `src/` directory, autoloaded PSR-4
+- **Consumed by:** other projects, via `composer require`
+- **Use for:** packages such as test contexts, extensions, plugins and
+  interface implementations
 
-### Adding New Commands
+Add classes under `src/` and cover each one with a test in
+`tests/phpunit/Unit/`. The shipped `Example` class and its unit test are a
+placeholder pair to replace with the library's own code; keep at least one
+class, as the linters report an error when the project holds no PHP file.
 
-To add a Symfony Console command:
 
-1. Create class in `src/Command/YourCommand.php` extending
-   `Symfony\Component\Console\Command\Command`
-2. Register in `force-crystal`: `$application->add(new YourCommand());`
-3. Add functional test in `tests/phpunit/Functional/YourCommandTest.php`
-
-
 ### Namespace Structure
 
 - Source code: `YodasHut\App\`
@@ -137,12 +133,6 @@
 
 
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
@@ -211,7 +201,6 @@
 
 - `.github/workflows/test-php.yml` - PHP testing
 - `.github/workflows/release-php.yml` - GitHub release on a tag
-  - Builds the PHAR and attaches it to the release
 
 
 - `.github/workflows/test-shell.yml` - Shell script testing
