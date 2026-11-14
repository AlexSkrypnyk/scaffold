@@ -49,24 +49,3 @@
 
 Replace `TAG` with the release's tag and `ASSET` with the downloaded filename. A release of a private repository carries no attestation, so skip step 3 for it.
 
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
-3. Check the attestation with [GitHub CLI](https://cli.github.com/):
-
-   ```bash
-   gh attestation verify nodejs-script --repo yodashut/force-crystal
-   ```
-
-Replace `TAG` with the release's tag. A release of a private repository carries no attestation, so skip step 3 for it. To check the npm package, run `npm audit signatures` in a project that installs it.
-
