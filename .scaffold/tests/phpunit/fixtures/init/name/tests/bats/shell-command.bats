@@ -1,6 +1,6 @@
 #!/usr/bin/env bats
 #
-# Test force-crystal.sh functionality.
+# Test star-forge.sh functionality.
 #
 # Example usage:
 # ./tests/bats/node_modules/.bin/bats --no-tempdir-cleanup --formatter tap --filter-tags smoke tests/bats
@@ -12,7 +12,7 @@
 export BATS_HELPERS_FIXTURE_EXPORT_CODEBASE_ENABLED=1
 
 # Script file for TUI testing.
-export SCRIPT_FILE="force-crystal.sh"
+export SCRIPT_FILE="star-forge.sh"
 
 # bats test_tags=smoke
 @test "Data can be fetched from the API with user input" {
