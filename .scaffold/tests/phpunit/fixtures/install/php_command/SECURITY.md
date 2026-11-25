@@ -78,33 +78,3 @@
 
 Replace `TAG` with the release's tag and `ASSET` with the downloaded filename. A release of a private repository carries no attestation, so skip step 4 for it.
 
-## Verify a Node.js release
-
-Each release carries a SHA-256 checksum file, its signature and a build provenance attestation for `nodejs-script`. To verify a downloaded script:
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
-3. Download `force-crystal-nodejs-TAG.sha256.asc`. Check the signature against the key that keys.openpgp.org has confirmed for SIGNING_ADDRESS:
-
-   ```bash
-   curl -fsSL https://keys.openpgp.org/vks/v1/by-email/SIGNING_ADDRESS | gpg --dearmor > release-key.gpg
-   gpgv --keyring ./release-key.gpg force-crystal-nodejs-TAG.sha256.asc force-crystal-nodejs-TAG.sha256
-   ```
-
-   `gpgv` trusts only the key in `release-key.gpg`, so a signature by any other key fails.
-
-4. Check the attestation with [GitHub CLI](https://cli.github.com/):
-
-   ```bash
-   gh attestation verify nodejs-script --repo yodashut/force-crystal
-   ```
-
-Replace `TAG` with the release's tag. A release of a private repository carries no attestation, so skip step 4 for it. To check the npm package, run `npm audit signatures` in a project that installs it.
-
