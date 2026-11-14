@@ -28,45 +28,13 @@
 
 We disclose the issue in a GitHub security advisory, published with the release that fixes it. The advisory credits you unless you ask to stay anonymous, and it carries a CVE identifier when the issue needs one.
 
-## Verify a PHP release asset
+## Verify a Docker image
 
-Each release carries a SHA-256 checksum file and a build provenance attestation for the PHP asset, which shows that this repository's release workflow built it. To verify a downloaded asset:
+Each image published from a public repository carries a build provenance attestation. Check it with [GitHub CLI](https://cli.github.com/):
 
-1. From the release page, download the asset and `force-crystal-php-TAG.sha256`.
-2. Check the checksum:
+```bash
+gh attestation verify oci://acme/api-image:TAG --repo yodashut/force-crystal
+```
 
-   ```bash
-   sha256sum --check --ignore-missing force-crystal-php-TAG.sha256
-   ```
-
-   On macOS, run `shasum -a 256 --check --ignore-missing force-crystal-php-TAG.sha256` instead.
-
-3. Check the attestation with [GitHub CLI](https://cli.github.com/):
-
-   ```bash
-   gh attestation verify ASSET --repo yodashut/force-crystal
-   ```
-
-Replace `TAG` with the release's tag and `ASSET` with the downloaded filename. A release of a private repository carries no attestation, so skip step 3 for it.
-
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
+Replace `TAG` with the image tag. A name without a registry resolves to Docker Hub.
 
