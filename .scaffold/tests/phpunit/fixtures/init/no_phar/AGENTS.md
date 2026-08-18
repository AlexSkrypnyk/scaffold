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
@@ -211,7 +205,6 @@
 
 - `.github/workflows/test-php.yml` - PHP testing
 - `.github/workflows/release-php.yml` - GitHub release on a tag
-  - Builds the PHAR and attaches it to the release
 
 
 - `.github/workflows/test-shell.yml` - Shell script testing
