@@ -1,9 +1,9 @@
 #!/usr/bin/env bats
 #
-# Test force-crystal.sh functionality.
+# Test star-forge.sh functionality.
 #
 # Example usage:
-# ./.force-crystal/tests/node_modules/.bin/bats --no-tempdir-cleanup --formatter tap --filter-tags smoke tests/bats
+# ./.star-forge/tests/node_modules/.bin/bats --no-tempdir-cleanup --formatter tap --filter-tags smoke tests/bats
 #
 # shellcheck disable=SC2030,SC2031,SC2034
 
@@ -12,7 +12,7 @@
 export BATS_FIXTURE_EXPORT_CODEBASE_ENABLED=1
 
 # Script file for TUI testing.
-export SCRIPT_FILE="force-crystal.sh"
+export SCRIPT_FILE="star-forge.sh"
 
 # bats test_tags=smoke
 @test "Data can be fetched from the API with user input" {
