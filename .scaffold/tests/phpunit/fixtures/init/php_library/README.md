@@ -50,19 +50,13 @@
 
 ## Usage
 
-Run the command that Composer installs:
+Call the library's classes from your code:
 
-```bash
-vendor/bin/force-crystal
+```php
+use YodasHut\App\Example;
+
+echo (new Example())->greet('World');
 ```
-
-The command takes the following arguments and options:
-
-| Name        | Default value | Description                        |
-|-------------|---------------|------------------------------------|
-| `arg1`      | None          | Description of the first argument. |
-| `--option1` | `default1`    | Option with a default value.       |
-| `--option2` | None          | Option without a value.            |
 
 Run the script with 1 argument:
 
