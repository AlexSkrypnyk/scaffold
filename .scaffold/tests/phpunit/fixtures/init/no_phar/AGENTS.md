@@ -137,12 +137,6 @@
 
 
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
@@ -210,8 +204,6 @@
 Key workflows:
 
 - `.github/workflows/test-php.yml` - PHP testing
-- `.github/workflows/release-php.yml` - Creates the release on a tag and attaches the asset
-  - Builds the PHAR to attach
 
 
 - `.github/workflows/test-shell.yml` - Shell script testing
