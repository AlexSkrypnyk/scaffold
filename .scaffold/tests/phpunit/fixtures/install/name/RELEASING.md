@@ -12,8 +12,8 @@
 
 Each release workflow of this project starts on the version tag:
 
-- `Release PHP` builds the PHAR and attaches it to the release, with `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
-- `Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release, with `force-crystal-nodejs-TAG.sha256` and `force-crystal-nodejs-TAG.intoto.jsonl`. Then it publishes the release.
+- `Release PHP` builds the PHAR and attaches it to the release, with `star-forge-php-TAG.sha256` and `star-forge-php-TAG.intoto.jsonl`.
+- `Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release, with `star-forge-nodejs-TAG.sha256` and `star-forge-nodejs-TAG.intoto.jsonl`. Then it publishes the release.
 - `Release docs` deploys the documentation site to GitHub Pages.
 
 `TAG` in a filename is the version tag. A release of a private repository carries no `.intoto.jsonl` file, because GitHub offers attestations for private repositories only on GitHub Enterprise Cloud. [`SECURITY.md`](SECURITY.md) shows how anyone can verify a downloaded asset with its checksum and attestation files.
