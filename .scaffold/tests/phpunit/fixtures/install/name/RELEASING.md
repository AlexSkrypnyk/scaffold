@@ -38,7 +38,7 @@
 
 keys.openpgp.org publishes an address on a key only after the address owner confirms it from that mailbox. A verifier who fetches the key by the address gets the key the maintainers confirmed. Someone who changes the repository's secrets can't replace that key without access to the mailbox.
 
-The release workflows stop until signing is set up. keys.openpgp.org links each address to 1 key, so give each project its own signing address. Create a dedicated mailbox, or use plus addressing where your mail provider supports it, such as `you+force-crystal@example.com`.
+The release workflows stop until signing is set up. keys.openpgp.org links each address to 1 key, so give each project its own signing address. Create a dedicated mailbox, or use plus addressing where your mail provider supports it, such as `you+star-forge@example.com`.
 
 To set up signing:
 
@@ -45,7 +45,7 @@
 1. Create a signing key for the address. `gpg` asks for a passphrase and prints the key's fingerprint:
 
    ```bash
-   gpg --quick-generate-key "force-crystal releases <SIGNING_ADDRESS>" ed25519 sign 2y
+   gpg --quick-generate-key "star-forge releases <SIGNING_ADDRESS>" ed25519 sign 2y
    ```
 
 2. Upload the public key to keys.openpgp.org:
@@ -58,15 +58,15 @@
 4. Create the `release` environment:
 
    ```bash
-   gh api -X PUT repos/yodashut/force-crystal/environments/release
+   gh api -X PUT repos/jeditemple/star-forge/environments/release
    ```
 
 5. Store the private key, the signing address and the passphrase. The last 2 commands prompt for their values:
 
    ```bash
-   gpg --armor --export-secret-keys KEY_FINGERPRINT | gh secret set GPG_PRIVATE_KEY --env release --repo yodashut/force-crystal
-   gh secret set RELEASE_GPG_KEY_EMAIL --env release --repo yodashut/force-crystal
-   gh secret set GPG_PASSPHRASE --env release --repo yodashut/force-crystal
+   gpg --armor --export-secret-keys KEY_FINGERPRINT | gh secret set GPG_PRIVATE_KEY --env release --repo jeditemple/star-forge
+   gh secret set RELEASE_GPG_KEY_EMAIL --env release --repo jeditemple/star-forge
+   gh secret set GPG_PASSPHRASE --env release --repo jeditemple/star-forge
    ```
 
 6. In [`SECURITY.md`](SECURITY.md), replace `SIGNING_ADDRESS` with the signing address, so verifiers fetch the key by an address that the secrets can't change.
@@ -79,11 +79,11 @@
 
 ### PHP release asset
 
-`Release PHP` builds `force-crystal.phar` and attaches it to the release. Its checksum and attestation go in `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
+`Release PHP` builds `star-forge.phar` and attaches it to the release. Its checksum and attestation go in `star-forge-php-TAG.sha256` and `star-forge-php-TAG.intoto.jsonl`.
 
 ### npm package
 
-`Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release. Its checksum and attestation go in `force-crystal-nodejs-TAG.sha256` and `force-crystal-nodejs-TAG.intoto.jsonl`. Then the workflow publishes the release.
+`Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release. Its checksum and attestation go in `star-forge-nodejs-TAG.sha256` and `star-forge-nodejs-TAG.intoto.jsonl`. Then the workflow publishes the release.
 
 The workflow publishes through npm [trusted publishing](https://docs.npmjs.com/trusted-publishers), so you store no npm token in the repository. npm accepts the workflow only after the package exists on npm and names `release-nodejs.yml` as its trusted publisher. To release on GitHub only, set `"private": true` in `package.json` and skip this setup. The workflow then skips npm and still publishes the GitHub release.
 
