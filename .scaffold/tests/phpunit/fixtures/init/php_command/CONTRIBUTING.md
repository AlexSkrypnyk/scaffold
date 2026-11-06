@@ -26,14 +26,3 @@
 
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
