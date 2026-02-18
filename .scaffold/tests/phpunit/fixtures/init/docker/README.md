@@ -30,61 +30,17 @@
 ## Installation
 
 
-    composer require yodashut/force-crystal
 
 
-
-    npm install @yodashut/force-crystal
-
-
-
-Download the latest release from GitHub releases page.
-
-
 ## Usage
 
 
-    vendor/bin/force-crystal
 
 
 
-    node_modules/.bin/force-crystal
-
-
-
-    ./force-crystal.sh
-
-
-
-### CLI options
-
-| Name        | Default value | Description                        |
-|-------------|---------------|------------------------------------|
-| `arg1`      |               | Description of the first argument. |
-| `--option1` | `default1`    | Option with a default value.       |
-| `--option2` | None          | Option wihtout a value.            |
-
-
 ## Maintenance
 
 
-    composer install
-    composer lint
-    composer test
-
-
-
-    npm install
-    npm run lint
-    npm run test
-
-
-
-    shellcheck force-crystal.sh tests/bats/*.bash tests/bats/*.bats
-    shfmt -i 2 -ci -s -d force-crystal.sh tests/bats/*.bash tests/bats/*.bats
-
-    npm ci --prefix tests/bats
-    ./tests/bats/node_modules/.bin/bats tests/bats
 
 
 ---
