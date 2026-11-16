@@ -14,11 +14,11 @@
 
 ### PHP release asset
 
-`Release PHP` builds `force-crystal.phar` and attaches it to the release. Its checksum and attestation go in `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
+`Release PHP` builds `star-forge.phar` and attaches it to the release. Its checksum and attestation go in `star-forge-php-TAG.sha256` and `star-forge-php-TAG.intoto.jsonl`.
 
 ### npm package
 
-`Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release. Its checksum and attestation go in `force-crystal-nodejs-TAG.sha256` and `force-crystal-nodejs-TAG.intoto.jsonl`. Then the workflow publishes the release.
+`Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release. Its checksum and attestation go in `star-forge-nodejs-TAG.sha256` and `star-forge-nodejs-TAG.intoto.jsonl`. Then the workflow publishes the release.
 
 The workflow publishes through npm [trusted publishing](https://docs.npmjs.com/trusted-publishers), so you store no npm token in the repository. npm accepts the workflow only after the package exists on npm and names `release-nodejs.yml` as its trusted publisher. To release on GitHub only, set `"private": true` in `package.json` and skip this setup. The workflow then skips npm and still publishes the GitHub release.
 
