@@ -10,8 +10,6 @@
 [![GitHub Issues](https://img.shields.io/github/issues/yodashut/force-crystal.svg)](https://github.com/yodashut/force-crystal/issues)
 [![GitHub Pull Requests](https://img.shields.io/github/issues-pr/yodashut/force-crystal.svg)](https://github.com/yodashut/force-crystal/pulls)
 [![Test PHP](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml)
-[![Test Node.js](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml)
-[![Test Shell](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml)
 [![codecov](https://codecov.io/gh/yodashut/force-crystal/graph/badge.svg)](https://codecov.io/gh/yodashut/force-crystal)
 ![GitHub release (latest by date)](https://img.shields.io/github/v/release/yodashut/force-crystal)
 ![LICENSE](https://img.shields.io/github/license/yodashut/force-crystal)
@@ -40,30 +38,12 @@
 composer require yodashut/force-crystal
 ```
 
-Install the Node.js package with npm:
-
-```bash
-npm install --global @yodashut/force-crystal
-```
-
-Or download the Node.js script, `nodejs-script`, from the [latest release](https://github.com/yodashut/force-crystal/releases/latest) and make it executable:
-
-```bash
-chmod +x nodejs-script
-```
-
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
@@ -73,18 +53,6 @@
 | `arg1`      | None          | Description of the first argument. |
 | `--option1` | `default1`    | Option with a default value.       |
 | `--option2` | None          | Flag that takes no value.          |
-
-Run the Node.js script:
-
-```bash
-./nodejs-script value/of/argument
-```
-
-Run the shell script:
-
-```bash
-./force-crystal.sh
-```
 
 ## Contribute
 
