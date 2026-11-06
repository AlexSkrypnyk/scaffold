@@ -9,7 +9,6 @@
 
 [![GitHub Issues](https://img.shields.io/github/issues/yodashut/force-crystal.svg)](https://github.com/yodashut/force-crystal/issues)
 [![GitHub Pull Requests](https://img.shields.io/github/issues-pr/yodashut/force-crystal.svg)](https://github.com/yodashut/force-crystal/pulls)
-[![Test PHP](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml)
 [![Test Node.js](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml)
 [![Test Shell](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml)
 [![codecov](https://codecov.io/gh/yodashut/force-crystal/graph/badge.svg)](https://codecov.io/gh/yodashut/force-crystal)
@@ -30,12 +29,6 @@
 
 ## Installation
 
-Install the PHP package with Composer:
-
-```bash
-composer require yodashut/force-crystal
-```
-
 Download the Node.js script, `nodejs-script`, from the [latest release](https://github.com/yodashut/force-crystal/releases/latest) and make it executable:
 
 ```bash
@@ -49,20 +42,6 @@
 ```
 
 ## Usage
-
-Run the PHP command that Composer installs:
-
-```bash
-vendor/bin/force-crystal
-```
-
-The command takes the following arguments and options:
-
-| Name        | Default value | Description                        |
-|-------------|---------------|------------------------------------|
-| `arg1`      | None          | Description of the first argument. |
-| `--option1` | `default1`    | Option with a default value.       |
-| `--option2` | None          | Flag that takes no value.          |
 
 Run the Node.js script with 1 argument:
 
