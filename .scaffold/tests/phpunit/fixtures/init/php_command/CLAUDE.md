@@ -19,7 +19,7 @@
 Multi-command CLI application structure:
 
 - **Location:** `src/Command/` directory
-- **Entry point:** `force-crystal` (wraps `src/app.php`)
+- **Entry point:** `star-forge` (wraps `src/app.php`)
 - **Use for:** Complex applications with multiple commands, shared logic, OOP
   architecture
 
@@ -75,12 +75,6 @@
 ```
 
 
-```bash
-# Shell script tests
-./tests/bats/node_modules/bats/bin/bats tests/bats/
-```
-
-
 ### Building
 
 
@@ -139,15 +133,6 @@
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
@@ -159,9 +144,6 @@
 
 - `.github/workflows/test-php.yml` - PHP testing
 - `.github/workflows/release-php.yml` - PHAR packaging and release
-
-
-- `.github/workflows/test-shell.yml` - Shell script testing
 
 
 - `.github/workflows/test-nodejs.yml` - NodeJS testing
