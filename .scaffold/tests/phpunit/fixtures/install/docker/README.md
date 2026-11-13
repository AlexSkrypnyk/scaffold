@@ -9,9 +9,6 @@
 
 [![GitHub Issues](https://img.shields.io/github/issues/yodashut/force-crystal.svg)](https://github.com/yodashut/force-crystal/issues)
 [![GitHub Pull Requests](https://img.shields.io/github/issues-pr/yodashut/force-crystal.svg)](https://github.com/yodashut/force-crystal/pulls)
-[![Test PHP](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml)
-[![Test Node.js](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml)
-[![Test Shell](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml)
 [![codecov](https://codecov.io/gh/yodashut/force-crystal/graph/badge.svg)](https://codecov.io/gh/yodashut/force-crystal)
 ![GitHub release (latest by date)](https://img.shields.io/github/v/release/yodashut/force-crystal)
 ![LICENSE](https://img.shields.io/github/license/yodashut/force-crystal)
@@ -30,56 +27,18 @@
 
 ## Installation
 
-Install the PHP package with Composer:
+Pull the Docker image from Docker Hub:
 
 ```bash
-composer require yodashut/force-crystal
+docker pull yodashut/force-crystal
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
 
-Run the PHP command that Composer installs:
+Run a container from the Docker image:
 
 ```bash
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
+docker run --rm yodashut/force-crystal
 ```
 
 ## Contribute
