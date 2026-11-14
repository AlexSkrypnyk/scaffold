@@ -26,19 +26,6 @@
 
 To fix the ESLint and Prettier issues that the linters report, run `npm run lint-fix`. To write a coverage report to `.logs/`, run `npm run test-coverage`.
 
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
-
-To apply the formatting that shfmt reports, run the shfmt command with `-w` in place of `-d`.
-
 ## Documentation site
 
 Install the documentation site's dependencies, build the site, then run its Jest tests and spell check:
@@ -63,7 +50,6 @@
 
 - `Test PHP`
 - `Test Node.js`
-- `Test shell`
 - `Test Docs`
 - `Audit`, which scans the code with CodeQL
 
