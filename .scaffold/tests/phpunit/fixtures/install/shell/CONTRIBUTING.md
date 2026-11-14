@@ -2,30 +2,6 @@
 
 Thank you for considering a contribution to this project. Follow this guide to install the dependencies and run the same linters and tests that CI runs on your pull request. Run the section for each stack your change touches, from the repository root.
 
-## PHP
-
-Install the dependencies, then run the linters and the tests:
-
-```bash
-composer install
-composer lint
-composer test
-```
-
-To fix the PHP_CodeSniffer and Rector issues that the linters report, run `composer lint-fix`. To write a coverage report to `.logs/`, enable the PCOV or Xdebug extension and run `composer test-coverage`. Xdebug also needs `XDEBUG_MODE=coverage`.
-
-## Node.js
-
-Install the dependencies, then run the linters and the tests:
-
-```bash
-npm ci
-npm run lint
-npm run test
-```
-
-To fix the ESLint and Prettier issues that the linters report, run `npm run lint-fix`. To write a coverage report to `.logs/`, run `npm run test-coverage`.
-
 ## Shell
 
 The linters need [ShellCheck](https://www.shellcheck.net/) and [shfmt](https://github.com/mvdan/sh) on your `PATH`. Install the BATS test dependencies, then run the linters and the tests:
@@ -61,8 +37,6 @@
 
 The checks come from these workflows:
 
-- `Test PHP`
-- `Test Node.js`
 - `Test shell`
 - `Test Docs`
 - `Audit`, which scans the code with CodeQL
