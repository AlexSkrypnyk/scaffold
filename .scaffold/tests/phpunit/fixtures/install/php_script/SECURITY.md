@@ -57,32 +57,3 @@
 
 Replace `TAG` with the release's tag and `ASSET` with the downloaded filename. A release of a private repository carries no attestation, so skip step 4 for it.
 
-## Verify a Node.js release
-
-Each release carries a SHA-256 checksum file and a build provenance attestation for `nodejs-script`. To verify a downloaded script:
-
-1. From the release page, download `nodejs-script` and `force-crystal-nodejs-TAG.sha256`.
-2. Check the checksum:
-
-   ```bash
-   sha256sum --check force-crystal-nodejs-TAG.sha256
-   ```
-
-   On macOS, run `shasum -a 256 --check force-crystal-nodejs-TAG.sha256` instead.
-
-3. When the release lists `force-crystal-nodejs-TAG.sha256.asc`, download it and check the signature of the checksum file. `gpg` fetches the signing key from keys.openpgp.org:
-
-   ```bash
-   gpg --keyserver hkps://keys.openpgp.org --auto-key-retrieve --verify force-crystal-nodejs-TAG.sha256.asc force-crystal-nodejs-TAG.sha256
-   ```
-
-   Confirm that `gpg` reports a good signature from a maintainer's address. keys.openpgp.org publishes an address on a key only after its owner confirms it. `gpg` also warns that the key isn't certified with a trusted signature, which is expected for a key you haven't marked as trusted.
-
-4. Check the attestation with [GitHub CLI](https://cli.github.com/):
-
-   ```bash
-   gh attestation verify nodejs-script --repo yodashut/force-crystal
-   ```
-
-Replace `TAG` with the release's tag. A release of a private repository carries no attestation, so skip step 4 for it. To check the npm package, run `npm audit signatures` in a project that installs it.
-
