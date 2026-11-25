@@ -10,8 +10,8 @@
 
 Report a vulnerability privately, so it stays hidden until a fix is out. Use either channel:
 
-- Open a [private security advisory](https://github.com/yodashut/force-crystal/security/advisories/new). The same form opens from **Report a vulnerability** on the repository's **Security** tab.
-- Email force-crystal@yodashut.com.
+- Open a [private security advisory](https://github.com/jeditemple/star-forge/security/advisories/new). The same form opens from **Report a vulnerability** on the repository's **Security** tab.
+- Email star-forge@jeditemple.com.
 
 Keep the details out of public issues, pull requests and discussions.
 
@@ -32,19 +32,19 @@
 
 Each release carries a SHA-256 checksum file and a build provenance attestation for the PHP asset, which shows that this repository's release workflow built it. To verify a downloaded asset:
 
-1. From the release page, download the asset and `force-crystal-php-TAG.sha256`.
+1. From the release page, download the asset and `star-forge-php-TAG.sha256`.
 2. Check the checksum:
 
    ```bash
-   sha256sum --check --ignore-missing force-crystal-php-TAG.sha256
+   sha256sum --check --ignore-missing star-forge-php-TAG.sha256
    ```
 
-   On macOS, run `shasum -a 256 --check --ignore-missing force-crystal-php-TAG.sha256` instead.
+   On macOS, run `shasum -a 256 --check --ignore-missing star-forge-php-TAG.sha256` instead.
 
-3. When the release lists `force-crystal-php-TAG.sha256.asc`, download it and check the signature of the checksum file. `gpg` fetches the signing key from keys.openpgp.org:
+3. When the release lists `star-forge-php-TAG.sha256.asc`, download it and check the signature of the checksum file. `gpg` fetches the signing key from keys.openpgp.org:
 
    ```bash
-   gpg --keyserver hkps://keys.openpgp.org --auto-key-retrieve --verify force-crystal-php-TAG.sha256.asc force-crystal-php-TAG.sha256
+   gpg --keyserver hkps://keys.openpgp.org --auto-key-retrieve --verify star-forge-php-TAG.sha256.asc star-forge-php-TAG.sha256
    ```
 
    Confirm that `gpg` reports a good signature from a maintainer's address. keys.openpgp.org publishes an address on a key only after its owner confirms it. `gpg` also warns that the key isn't certified with a trusted signature, which is expected for a key you haven't marked as trusted.
@@ -52,7 +52,7 @@
 4. Check the attestation with [GitHub CLI](https://cli.github.com/):
 
    ```bash
-   gh attestation verify ASSET --repo yodashut/force-crystal
+   gh attestation verify ASSET --repo jeditemple/star-forge
    ```
 
 Replace `TAG` with the release's tag and `ASSET` with the downloaded filename. A release of a private repository carries no attestation, so skip step 4 for it.
@@ -61,19 +61,19 @@
 
 Each release carries a SHA-256 checksum file and a build provenance attestation for `nodejs-script`. To verify a downloaded script:
 
-1. From the release page, download `nodejs-script` and `force-crystal-nodejs-TAG.sha256`.
+1. From the release page, download `nodejs-script` and `star-forge-nodejs-TAG.sha256`.
 2. Check the checksum:
 
    ```bash
-   sha256sum --check force-crystal-nodejs-TAG.sha256
+   sha256sum --check star-forge-nodejs-TAG.sha256
    ```
 
-   On macOS, run `shasum -a 256 --check force-crystal-nodejs-TAG.sha256` instead.
+   On macOS, run `shasum -a 256 --check star-forge-nodejs-TAG.sha256` instead.
 
-3. When the release lists `force-crystal-nodejs-TAG.sha256.asc`, download it and check the signature of the checksum file. `gpg` fetches the signing key from keys.openpgp.org:
+3. When the release lists `star-forge-nodejs-TAG.sha256.asc`, download it and check the signature of the checksum file. `gpg` fetches the signing key from keys.openpgp.org:
 
    ```bash
-   gpg --keyserver hkps://keys.openpgp.org --auto-key-retrieve --verify force-crystal-nodejs-TAG.sha256.asc force-crystal-nodejs-TAG.sha256
+   gpg --keyserver hkps://keys.openpgp.org --auto-key-retrieve --verify star-forge-nodejs-TAG.sha256.asc star-forge-nodejs-TAG.sha256
    ```
 
    Confirm that `gpg` reports a good signature from a maintainer's address. keys.openpgp.org publishes an address on a key only after its owner confirms it. `gpg` also warns that the key isn't certified with a trusted signature, which is expected for a key you haven't marked as trusted.
@@ -81,7 +81,7 @@
 4. Check the attestation with [GitHub CLI](https://cli.github.com/):
 
    ```bash
-   gh attestation verify nodejs-script --repo yodashut/force-crystal
+   gh attestation verify nodejs-script --repo jeditemple/star-forge
    ```
 
 Replace `TAG` with the release's tag. A release of a private repository carries no attestation, so skip step 4 for it. To check the npm package, run `npm audit signatures` in a project that installs it.
