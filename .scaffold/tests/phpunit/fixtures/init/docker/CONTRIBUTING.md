@@ -2,38 +2,15 @@
 
 Thank you for considering a contribution to this project. Follow this guide to install the dependencies and run the same linters and tests that CI runs on your pull request. Run every command from the repository root.
 
-## PHP
+## Docker
 
-Install the dependencies, then run the linters and the tests:
+Lint the `Dockerfile` with Hadolint, then build the image and run a container from it:
 
 ```bash
-composer install
-composer lint
-composer test
+docker run --rm -i hadolint/hadolint < Dockerfile
+docker build -t yodashut/force-crystal .
+docker run --rm yodashut/force-crystal
 ```
 
-To fix the coding standard and Rector issues that the linters report, run `composer lint-fix`. To write a coverage report to `.logs/`, run `composer test-coverage`.
-
-## Node.js
-
-Install the dependencies, then run the linters and the tests:
-
-```bash
-npm install
-npm run lint
-npm run test
-```
-
-To fix the ESLint and Prettier issues that the linters report, run `npm run lint-fix`. To write a coverage report to `.logs/`, run `npm run test-coverage`.
-
-## Shell
-
-The linters need [ShellCheck](https://www.shellcheck.net/) and [shfmt](https://github.com/mvdan/sh) on your `PATH`. Install the BATS test dependencies, then run the linters and the tests:
-
-```bash
-npm ci --prefix tests/bats
-shellcheck force-crystal.sh tests/bats/*.bash tests/bats/*.bats
-shfmt -i 2 -ci -s -d force-crystal.sh tests/bats/*.bash tests/bats/*.bats
-./tests/bats/node_modules/.bin/bats tests/bats
-```
+The container prints `force-crystal is running`.
 
