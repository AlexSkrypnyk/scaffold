@@ -48,36 +48,6 @@
 
 keys.openpgp.org publishes an address on a key only after the address owner confirms it from that mailbox. When you fetch the key by the address, you get the key the maintainers confirmed. A signature that checks against that key shows that the maintainers' release workflow signed the checksums, and a matching checksum shows that the asset is the one it signed.
 
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
 ## Verify a Node.js release
 
 Each release carries a SHA-256 checksum file, its signature and a build provenance attestation for `nodejs-script`. To verify a downloaded script:
