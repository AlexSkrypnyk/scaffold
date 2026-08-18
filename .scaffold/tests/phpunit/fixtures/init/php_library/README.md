@@ -45,7 +45,8 @@
 ## Usage
 
 
-    vendor/bin/force-crystal
+    use YodasHut\App\YourClass;
+    $result = (new YourClass())->run();
 
 
 
@@ -55,15 +56,6 @@
 
     ./force-crystal.sh
 
-
-
-### CLI options
-
-| Name        | Default value | Description                        |
-|-------------|---------------|------------------------------------|
-| `arg1`      |               | Description of the first argument. |
-| `--option1` | `default1`    | Option with a default value.       |
-| `--option2` | None          | Option without a value.            |
 
 
 ## Contributing
