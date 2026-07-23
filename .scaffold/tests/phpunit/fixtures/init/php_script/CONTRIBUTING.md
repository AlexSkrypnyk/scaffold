@@ -14,9 +14,6 @@
 
 
 
-    npm ci --prefix tests/bats
-
-
 ## Linting
 
 
@@ -28,10 +25,6 @@
 
 
 
-    shellcheck force-crystal.sh tests/bats/*.bash tests/bats/*.bats
-    shfmt -i 2 -ci -s -d force-crystal.sh tests/bats/*.bash tests/bats/*.bats
-
-
 ## Testing
 
 
@@ -41,7 +34,4 @@
 
     npm run test
 
-
-
-    ./tests/bats/node_modules/.bin/bats tests/bats
 
