@@ -10,8 +10,8 @@
 
 Report a vulnerability privately, so it stays hidden until a fix is out. Use either channel:
 
-- On the repository's **Security** tab, click **Report a vulnerability**. The form opens at https://github.com/yodashut/force-crystal/security/advisories/new.
-- Email force-crystal@yodashut.com.
+- On the repository's **Security** tab, click **Report a vulnerability**. The form opens at https://github.com/jeditemple/star-forge/security/advisories/new.
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
 
 3. Check the attestation with [GitHub CLI](https://cli.github.com/):
 
    ```bash
-   gh attestation verify ASSET --repo yodashut/force-crystal
+   gh attestation verify ASSET --repo jeditemple/star-forge
    ```
 
 Replace `TAG` with the release's tag and `ASSET` with the downloaded filename.
@@ -53,19 +53,19 @@
 
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
 
 3. Check the attestation with [GitHub CLI](https://cli.github.com/):
 
    ```bash
-   gh attestation verify nodejs-script --repo yodashut/force-crystal
+   gh attestation verify nodejs-script --repo jeditemple/star-forge
    ```
 
 Replace `TAG` with the release's tag. To check the npm package, run `npm audit signatures` in a project that installs it.
