@@ -10,8 +10,8 @@
 
 Report a vulnerability privately, so it stays hidden until a fix is out. Use either channel:
 
-- Open a [private security advisory](https://github.com/yodashut/force-crystal/security/advisories/new). The same form opens from **Report a vulnerability** on the repository's **Security** tab.
-- Email force-crystal@yodashut.com.
+- Open a [private security advisory](https://github.com/jeditemple/star-forge/security/advisories/new). The same form opens from **Report a vulnerability** on the repository's **Security** tab.
+- Email star-forge@jeditemple.com.
 
 Keep the details out of public issues, pull requests and discussions.
 
@@ -52,20 +52,20 @@
 
 Each release carries a SHA-256 checksum file, its signature and a build provenance attestation for the PHP asset. The attestation shows that this repository's release workflow built the asset. To verify a downloaded asset:
 
-1. From the release page, download the asset and `force-crystal-php-TAG.sha256`.
+1. From the release page, download the asset and `star-forge-php-TAG.sha256`.
 2. Check the checksum:
 
    ```bash
-   sha256sum --check --ignore-missing force-crystal-php-TAG.sha256
+   sha256sum --check --ignore-missing star-forge-php-TAG.sha256
    ```
 
-   On macOS, run `shasum -a 256 --check --ignore-missing force-crystal-php-TAG.sha256` instead.
+   On macOS, run `shasum -a 256 --check --ignore-missing star-forge-php-TAG.sha256` instead.
 
-3. Download `force-crystal-php-TAG.sha256.asc`. Check the signature against the key that keys.openpgp.org has confirmed for SIGNING_ADDRESS:
+3. Download `star-forge-php-TAG.sha256.asc`. Check the signature against the key that keys.openpgp.org has confirmed for SIGNING_ADDRESS:
 
    ```bash
    curl -fsSL https://keys.openpgp.org/vks/v1/by-email/SIGNING_ADDRESS | gpg --dearmor > release-key.gpg
-   gpgv --keyring ./release-key.gpg force-crystal-php-TAG.sha256.asc force-crystal-php-TAG.sha256
+   gpgv --keyring ./release-key.gpg star-forge-php-TAG.sha256.asc star-forge-php-TAG.sha256
    ```
 
    `gpgv` trusts only the key in `release-key.gpg`, so a signature by any other key fails.
@@ -73,7 +73,7 @@
 4. Check the attestation with [GitHub CLI](https://cli.github.com/):
 
    ```bash
-   gh attestation verify ASSET --repo yodashut/force-crystal
+   gh attestation verify ASSET --repo jeditemple/star-forge
    ```
 
 Replace `TAG` with the release's tag and `ASSET` with the downloaded filename. A release of a private repository carries no attestation, so skip step 4 for it.
@@ -82,20 +82,20 @@
 
 Each release carries a SHA-256 checksum file, its signature and a build provenance attestation for `nodejs-script`. To verify a downloaded script:
 
-1. From the release page, download `nodejs-script` and `force-crystal-nodejs-TAG.sha256`.
+1. From the release page, download `nodejs-script` and `star-forge-nodejs-TAG.sha256`.
 2. Check the checksum:
 
    ```bash
-   sha256sum --check force-crystal-nodejs-TAG.sha256
+   sha256sum --check star-forge-nodejs-TAG.sha256
    ```
 
-   On macOS, run `shasum -a 256 --check force-crystal-nodejs-TAG.sha256` instead.
+   On macOS, run `shasum -a 256 --check star-forge-nodejs-TAG.sha256` instead.
 
-3. Download `force-crystal-nodejs-TAG.sha256.asc`. Check the signature against the key that keys.openpgp.org has confirmed for SIGNING_ADDRESS:
+3. Download `star-forge-nodejs-TAG.sha256.asc`. Check the signature against the key that keys.openpgp.org has confirmed for SIGNING_ADDRESS:
 
    ```bash
    curl -fsSL https://keys.openpgp.org/vks/v1/by-email/SIGNING_ADDRESS | gpg --dearmor > release-key.gpg
-   gpgv --keyring ./release-key.gpg force-crystal-nodejs-TAG.sha256.asc force-crystal-nodejs-TAG.sha256
+   gpgv --keyring ./release-key.gpg star-forge-nodejs-TAG.sha256.asc star-forge-nodejs-TAG.sha256
    ```
 
    `gpgv` trusts only the key in `release-key.gpg`, so a signature by any other key fails.
@@ -103,7 +103,7 @@
 4. Check the attestation with [GitHub CLI](https://cli.github.com/):
 
    ```bash
-   gh attestation verify nodejs-script --repo yodashut/force-crystal
+   gh attestation verify nodejs-script --repo jeditemple/star-forge
    ```
 
 Replace `TAG` with the release's tag. A release of a private repository carries no attestation, so skip step 4 for it. To check the npm package, run `npm audit signatures` in a project that installs it.
