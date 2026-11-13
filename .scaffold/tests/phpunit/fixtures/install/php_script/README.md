@@ -11,7 +11,6 @@
 [![GitHub Pull Requests](https://img.shields.io/github/issues-pr/yodashut/force-crystal.svg)](https://github.com/yodashut/force-crystal/pulls)
 [![Test PHP](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml)
 [![Test Node.js](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml)
-[![Test Shell](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml)
 [![codecov](https://codecov.io/gh/yodashut/force-crystal/graph/badge.svg)](https://codecov.io/gh/yodashut/force-crystal)
 ![GitHub release (latest by date)](https://img.shields.io/github/v/release/yodashut/force-crystal)
 ![LICENSE](https://img.shields.io/github/license/yodashut/force-crystal)
@@ -48,38 +47,18 @@
 chmod +x nodejs-script
 ```
 
-Copy the shell script, `force-crystal.sh`, from this repository and make it executable:
-
-```bash
-chmod +x force-crystal.sh
-```
-
 ## Usage
 
-Run the PHP command that Composer installs:
+Run the PHP script that Composer installs:
 
 ```bash
 vendor/bin/force-crystal
 ```
 
-The command takes the following arguments and options:
-
-| Name        | Default value | Description                        |
-|-------------|---------------|------------------------------------|
-| `arg1`      | None          | Description of the first argument. |
-| `--option1` | `default1`    | Option with a default value.       |
-| `--option2` | None          | Flag that takes no value.          |
-
 Run the Node.js script:
 
 ```bash
 ./nodejs-script value/of/argument
-```
-
-Run the shell script:
-
-```bash
-./force-crystal.sh
 ```
 
 ## Contribute
