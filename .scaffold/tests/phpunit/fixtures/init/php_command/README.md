@@ -38,9 +38,6 @@
 
 
 
-Download the latest release from GitHub releases page.
-
-
 ## Usage
 
 
@@ -52,9 +49,6 @@
 
 
 
-    ./force-crystal.sh
-
-
 ### CLI options
 
 | Name        | Default value | Description                        |
@@ -76,13 +70,6 @@
     npm run lint
     npm run test
 
-
-
-    shellcheck force-crystal.sh tests/bats/*.bash tests/bats/*.bats
-    shfmt -i 2 -ci -s -d force-crystal.sh tests/bats/*.bash tests/bats/*.bats
-
-    npm ci --prefix tests/bats
-    ./tests/bats/node_modules/.bin/bats tests/bats
 
 
 ---
