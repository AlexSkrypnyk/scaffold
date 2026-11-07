@@ -11,7 +11,6 @@
 [![GitHub Pull Requests](https://img.shields.io/github/issues-pr/yodashut/force-crystal.svg)](https://github.com/yodashut/force-crystal/pulls)
 [![Test PHP](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml)
 [![Test Node.js](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml)
-[![Test Shell](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml)
 [![codecov](https://codecov.io/gh/yodashut/force-crystal/graph/badge.svg)](https://codecov.io/gh/yodashut/force-crystal)
 ![GitHub release (latest by date)](https://img.shields.io/github/v/release/yodashut/force-crystal)
 ![LICENSE](https://img.shields.io/github/license/yodashut/force-crystal)
@@ -42,18 +41,12 @@
 chmod +x nodejs-script
 ```
 
-Copy the shell script, `force-crystal.sh`, from this repository and make it executable:
-
-```bash
-chmod +x force-crystal.sh
-```
-
 ## Usage
 
 Run the PHP command that Composer installs:
 
 ```bash
-vendor/bin/force-crystal
+vendor/bin/star-forge
 ```
 
 The command takes the following arguments and options:
@@ -68,12 +61,6 @@
 
 ```bash
 ./nodejs-script value/of/argument
-```
-
-Run the shell script and answer its prompts:
-
-```bash
-./force-crystal.sh
 ```
 
 ## Contribute
