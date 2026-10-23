@@ -19,7 +19,7 @@
 Multi-command CLI application structure:
 
 - **Location:** `src/Command/` directory
-- **Entry point:** `bin/force-crystal`
+- **Entry point:** `bin/star-forge`
 - **Use for:** Complex applications with multiple commands, shared logic, OOP
   architecture
 
@@ -29,14 +29,14 @@
 
 1. Create class in `src/Command/YourCommand.php` extending
    `Symfony\Component\Console\Command\Command`
-2. Register in `bin/force-crystal`: `$application->add(new YourCommand());`
+2. Register in `bin/star-forge`: `$application->add(new YourCommand());`
 3. Add functional test in `tests/phpunit/Functional/YourCommandTest.php`
 
 
 ### Namespace Structure
 
-- Source code: `YodasHut\App\`
-- Tests: `YodasHut\App\Tests\`
+- Source code: `JediTemple\App\`
+- Tests: `JediTemple\App\Tests\`
 - Autoloading: PSR-4 via Composer
 
 ## Commands
