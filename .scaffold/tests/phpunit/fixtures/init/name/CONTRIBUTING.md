@@ -17,7 +17,7 @@
 
 
     npm ci --prefix tests/bats
-    shellcheck force-crystal.sh tests/bats/*.bash tests/bats/*.bats
-    shfmt -i 2 -ci -s -d force-crystal.sh tests/bats/*.bash tests/bats/*.bats
+    shellcheck star-forge.sh tests/bats/*.bash tests/bats/*.bats
+    shfmt -i 2 -ci -s -d star-forge.sh tests/bats/*.bash tests/bats/*.bats
     ./tests/bats/node_modules/.bin/bats tests/bats
 
