@@ -45,10 +45,6 @@
 
 To have a reviewer approve each release before a workflow reads the key, add **Required reviewers** to the `release` environment under **Settings > Environments**. If you limit the environment's deployment branches, allow the version tags.
 
-### PHP release asset
-
-`Release PHP` builds `force-crystal.phar` and attaches it to the release. Its checksum and attestation go in `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
-
 ### npm package
 
 `Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release. Its checksum and attestation go in `force-crystal-nodejs-TAG.sha256` and `force-crystal-nodejs-TAG.intoto.jsonl`. Then the workflow publishes the release.
