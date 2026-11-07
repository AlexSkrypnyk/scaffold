@@ -28,8 +28,6 @@
 return RectorConfig::configure()
   ->withPaths([
     __DIR__ . '/**',
-    // Extensionless entry points, which the file extensions below don't match.
-    __DIR__ . '/bin/force-crystal',
   ])
   ->withPhpSets(php83: TRUE)
   ->withPreparedSets(
