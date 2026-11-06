@@ -2,18 +2,6 @@
 
 Thank you for considering a contribution to this project. Follow this guide to install the dependencies and run the same linters and tests that CI runs on your pull request. Run every command from the repository root.
 
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
-To fix the coding standard and Rector issues that the linters report, run `composer lint-fix`. To write a coverage report to `.logs/`, run `composer test-coverage`.
-
 ## Node.js
 
 Install the dependencies, then run the linters and the tests:
