@@ -29,7 +29,7 @@
   ->withPaths([
     __DIR__ . '/**',
     // Extensionless entry points, which the file extensions below don't match.
-    __DIR__ . '/bin/force-crystal',
+    __DIR__ . '/force-crystal',
   ])
   ->withPhpSets(php83: TRUE)
   ->withPreparedSets(
