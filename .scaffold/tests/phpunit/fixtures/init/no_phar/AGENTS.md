@@ -137,15 +137,6 @@
 
 
 ```bash
-# Build PHAR executable into dist/ (installs Box first)
-composer build
-```
-
-Box compiles the same `bin/` launcher that Composer links into `vendor/bin`.
-The `dist/` directory is git-ignored; the PHAR ships only as a release asset.
-
-
-```bash
 # Clean and reinstall dependencies
 composer reset # removes vendor/, vendor-bin/, composer.lock
 composer install
@@ -213,8 +204,6 @@
 Key workflows:
 
 - `.github/workflows/test-php.yml` - PHP testing
-- `.github/workflows/release-php.yml` - Creates the release on a tag and attaches the asset
-  - Builds the PHAR to attach
 
 
 - `.github/workflows/test-shell.yml` - Shell script testing
