@@ -6,42 +6,14 @@
 ## Installation
 
 
-    composer install
 
 
-
-    npm install
-
-
-
-    npm ci --prefix tests/bats
-
-
 ## Linting
 
 
-    composer lint
 
 
-
-    npm run lint
-
-
-
-    shellcheck force-crystal.sh tests/bats/*.bash tests/bats/*.bats
-    shfmt -i 2 -ci -s -d force-crystal.sh tests/bats/*.bash tests/bats/*.bats
-
-
 ## Testing
 
 
-    composer test
-
-
-
-    npm run test
-
-
-
-    ./tests/bats/node_modules/.bin/bats tests/bats
 
