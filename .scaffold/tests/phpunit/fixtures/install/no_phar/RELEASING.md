@@ -12,7 +12,6 @@
 
 Each release workflow of this project starts on the version tag:
 
-- `Release PHP` builds the PHAR and attaches it to the release, with `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
 - `Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release, with `force-crystal-nodejs-TAG.sha256` and `force-crystal-nodejs-TAG.intoto.jsonl`. Then it publishes the release.
 - `Release docs` deploys the documentation site to GitHub Pages.
 
