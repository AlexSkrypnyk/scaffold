@@ -30,15 +30,15 @@
 3. Create the `release` environment:
 
    ```bash
-   gh api -X PUT repos/yodashut/force-crystal/environments/release
+   gh api -X PUT repos/jeditemple/star-forge/environments/release
    ```
 
 4. Store the private key, the confirmed address and, for a key that has one, the passphrase. The last 2 commands prompt for their values:
 
    ```bash
-   gpg --armor --export-secret-keys KEY_FINGERPRINT | gh secret set GPG_PRIVATE_KEY --env release --repo yodashut/force-crystal
-   gh secret set RELEASE_GPG_KEY_EMAIL --env release --repo yodashut/force-crystal
-   gh secret set GPG_PASSPHRASE --env release --repo yodashut/force-crystal
+   gpg --armor --export-secret-keys KEY_FINGERPRINT | gh secret set GPG_PRIVATE_KEY --env release --repo jeditemple/star-forge
+   gh secret set RELEASE_GPG_KEY_EMAIL --env release --repo jeditemple/star-forge
+   gh secret set GPG_PASSPHRASE --env release --repo jeditemple/star-forge
    ```
 
 Replace `KEY_FINGERPRINT` with your key's fingerprint. Export only that key into `GPG_PRIVATE_KEY`, because the workflows stop on a secret that holds more than 1 key.
@@ -47,11 +47,11 @@
 
 ### PHP release asset
 
-`Release PHP` builds `force-crystal.phar` and attaches it to the release. Its checksum and attestation go in `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
+`Release PHP` builds `star-forge.phar` and attaches it to the release. Its checksum and attestation go in `star-forge-php-TAG.sha256` and `star-forge-php-TAG.intoto.jsonl`.
 
 ### npm package
 
-`Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release. Its checksum and attestation go in `force-crystal-nodejs-TAG.sha256` and `force-crystal-nodejs-TAG.intoto.jsonl`. Then the workflow publishes the release.
+`Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release. Its checksum and attestation go in `star-forge-nodejs-TAG.sha256` and `star-forge-nodejs-TAG.intoto.jsonl`. Then the workflow publishes the release.
 
 The workflow publishes through npm [trusted publishing](https://docs.npmjs.com/trusted-publishers), so you store no npm token in the repository. npm accepts the workflow only after the package exists on npm and names `release-nodejs.yml` as its trusted publisher. To release on GitHub only, set `"private": true` in `package.json` and skip this setup. The workflow then skips npm and still publishes the GitHub release.
 
