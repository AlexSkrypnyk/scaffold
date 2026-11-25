@@ -28,83 +28,13 @@
 
 We disclose the issue in a GitHub security advisory, published with the release that fixes it. The advisory credits you unless you ask to stay anonymous, and it carries a CVE identifier when the issue needs one.
 
-## How releases are signed
+## Verify a Docker image
 
-Each release asset comes with a `.sha256` file that holds its SHA-256 checksum, and a `.sha256.asc` file that holds a GPG signature of that checksum file. The release workflow signs with the maintainers' key. The public half of that key is on [keys.openpgp.org](https://keys.openpgp.org), under the project's signing address SIGNING_ADDRESS:
+Each image published from a public repository carries a build provenance attestation. Check it with [GitHub CLI](https://cli.github.com/):
 
-```mermaid
-sequenceDiagram
-    participant M as Maintainers
-    participant K as keys.openpgp.org
-    participant W as Release workflow
-    participant V as You
-    M->>K: Upload the public key and confirm SIGNING_ADDRESS
-    W->>K: Fetch the key confirmed for SIGNING_ADDRESS
-    W->>W: Stop unless it is the signing key
-    W->>V: Publish the asset, .sha256 and .sha256.asc
-    V->>K: Fetch the key confirmed for SIGNING_ADDRESS
-    V->>V: Check the signature, then the checksum
+```bash
+gh attestation verify oci://acme/api-image:TAG --repo yodashut/force-crystal
 ```
 
-keys.openpgp.org publishes an address on a key only after the address owner confirms it from that mailbox. When you fetch the key by the address, you get the key the maintainers confirmed. A signature that checks against that key shows that the maintainers' release workflow signed the checksums, and a matching checksum shows that the asset is the one it signed.
-
-## Verify a PHP release asset
-
-Each release carries a SHA-256 checksum file, its signature and a build provenance attestation for the PHP asset. The attestation shows that this repository's release workflow built the asset. To verify a downloaded asset:
-
-1. From the release page, download the asset and `force-crystal-php-TAG.sha256`.
-2. Check the checksum:
-
-   ```bash
-   sha256sum --check --ignore-missing force-crystal-php-TAG.sha256
-   ```
-
-   On macOS, run `shasum -a 256 --check --ignore-missing force-crystal-php-TAG.sha256` instead.
-
-3. Download `force-crystal-php-TAG.sha256.asc`. Check the signature against the key that keys.openpgp.org has confirmed for SIGNING_ADDRESS:
-
-   ```bash
-   curl -fsSL https://keys.openpgp.org/vks/v1/by-email/SIGNING_ADDRESS | gpg --dearmor > release-key.gpg
-   gpgv --keyring ./release-key.gpg force-crystal-php-TAG.sha256.asc force-crystal-php-TAG.sha256
-   ```
-
-   `gpgv` trusts only the key in `release-key.gpg`, so a signature by any other key fails.
-
-4. Check the attestation with [GitHub CLI](https://cli.github.com/):
-
-   ```bash
-   gh attestation verify ASSET --repo yodashut/force-crystal
-   ```
-
-Replace `TAG` with the release's tag and `ASSET` with the downloaded filename. A release of a private repository carries no attestation, so skip step 4 for it.
-
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
+Replace `TAG` with the image tag. A name without a registry resolves to Docker Hub.
 
