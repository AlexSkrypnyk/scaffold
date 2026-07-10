@@ -6,7 +6,7 @@
 
 ## Project Overview
 
-This project was created from the force-crystal template and provides a foundation
+This project was created from the star-forge template and provides a foundation
 for Shell scripts, PHP CLI applications, and/or NodeJS projects with integrated
 testing, code quality tools, and CI/CD workflows.
 
@@ -19,7 +19,7 @@
 Multi-command CLI application structure:
 
 - **Location:** `src/Command/` directory
-- **Entry point:** `force-crystal`
+- **Entry point:** `star-forge`
 - **Use for:** Complex applications with multiple commands, shared logic, OOP
   architecture
 
@@ -29,14 +29,14 @@
 
 1. Create class in `src/Command/YourCommand.php` extending
    `Symfony\Component\Console\Command\Command`
-2. Register in `force-crystal`: `$application->add(new YourCommand());`
+2. Register in `star-forge`: `$application->add(new YourCommand());`
 3. Add functional test in `tests/phpunit/Functional/YourCommandTest.php`
 
 
 ### Namespace Structure
 
-- Source code: `YodasHut\App\`
-- Tests: `YodasHut\App\Tests\`
+- Source code: `JediTemple\App\`
+- Tests: `JediTemple\App\Tests\`
 - Autoloading: PSR-4 via Composer
 
 ## Commands
