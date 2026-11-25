@@ -12,93 +12,6 @@
 
 In asset names, `TAG` is the version tag. A `.sha256` file holds the checksum of an asset, and an `.intoto.jsonl` file holds its build attestation: a signed record of the workflow run that built it. A release of a private repository carries no `.intoto.jsonl` file, because GitHub offers attestations for private repositories only on GitHub Enterprise Cloud. [`SECURITY.md`](SECURITY.md) shows how to verify an asset with both files.
 
-### Release signing
-
-The release workflows sign every release asset, so anyone can confirm that a download comes from this project's maintainers. Each workflow writes the asset's SHA-256 checksum to a `.sha256` file, then signs that file with the project's GPG key as a `.sha256.asc` file. The public half of the key lives on [keys.openpgp.org](https://keys.openpgp.org) under the project's signing address, and verifiers fetch it from there:
-
-```mermaid
-sequenceDiagram
-    participant M as Maintainer
-    participant K as keys.openpgp.org
-    participant W as Release workflow
-    participant V as Verifier
-    M->>M: Create a key for the signing address
-    M->>K: Upload the public key
-    K-->>M: Email a confirmation link to the address
-    M->>K: Confirm the address
-    M->>W: Store the private key and the address as secrets
-    W->>W: Write the asset's .sha256 file
-    W->>K: Fetch the key confirmed for the address
-    W->>W: Stop unless it is the stored private key
-    W->>W: Sign the .sha256 file as .sha256.asc
-    W->>V: Publish the asset, .sha256 and .sha256.asc
-    V->>K: Fetch the key confirmed for the address
-    V->>V: Check the signature, then the checksum
-```
-
-keys.openpgp.org publishes an address on a key only after the address owner confirms it from that mailbox. A verifier who fetches the key by the address gets the key the maintainers confirmed. Someone who changes the repository's secrets can't replace that key without access to the mailbox.
-
-The release workflows stop until signing is set up. keys.openpgp.org links each address to 1 key, so give each project its own signing address. Create a dedicated mailbox, or use plus addressing where your mail provider supports it, such as `you+force-crystal@example.com`.
-
-To set up signing:
-
-1. Create a signing key for the address. `gpg` asks for a passphrase and prints the key's fingerprint:
-
-   ```bash
-   gpg --quick-generate-key "force-crystal releases <SIGNING_ADDRESS>" ed25519 sign 2y
-   ```
-
-2. Upload the public key to keys.openpgp.org:
-
-   ```bash
-   gpg --export KEY_FINGERPRINT | curl -T - https://keys.openpgp.org
-   ```
-
-3. Open the link that the upload prints, and request verification of the address. Confirm it from the email that keys.openpgp.org sends.
-4. Create the `release` environment:
-
-   ```bash
-   gh api -X PUT repos/yodashut/force-crystal/environments/release
-   ```
-
-5. Store the private key, the signing address and the passphrase. The last 2 commands prompt for their values:
-
-   ```bash
-   gpg --armor --export-secret-keys KEY_FINGERPRINT | gh secret set GPG_PRIVATE_KEY --env release --repo yodashut/force-crystal
-   gh secret set RELEASE_GPG_KEY_EMAIL --env release --repo yodashut/force-crystal
-   gh secret set GPG_PASSPHRASE --env release --repo yodashut/force-crystal
-   ```
-
-6. In [`SECURITY.md`](SECURITY.md), replace `SIGNING_ADDRESS` with the signing address, so verifiers fetch the key by an address that the secrets can't change.
-
-Replace `SIGNING_ADDRESS` with the project's signing address and `KEY_FINGERPRINT` with the fingerprint from step 1. Export only that key into `GPG_PRIVATE_KEY`, because the workflows stop on a secret that holds more than 1 key.
-
-The key expires after 2 years. Before then, extend it with `gpg --quick-set-expire KEY_FINGERPRINT 2y`, upload it again as in step 2 and store it again as in step 5.
-
-To have a reviewer approve each release before a workflow reads the key, add **Required reviewers** to the `release` environment under **Settings > Environments**. If you limit the environment's deployment branches, allow the version tags.
-
-### PHP release asset
-
-`Release PHP` builds `force-crystal.phar` and attaches it to the release. Its checksum and attestation go in `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
-
-### npm package
-
-`Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release. Its checksum and attestation go in `force-crystal-nodejs-TAG.sha256` and `force-crystal-nodejs-TAG.intoto.jsonl`. Then the workflow publishes the release.
-
-The workflow publishes through npm [trusted publishing](https://docs.npmjs.com/trusted-publishers), so you store no npm token in the repository. npm accepts the workflow only after the package exists on npm and names `release-nodejs.yml` as its trusted publisher. To release on GitHub only, set `"private": true` in `package.json` and skip this setup. The workflow then skips npm and still publishes the GitHub release.
-
-To set up trusted publishing before the first release:
-
-1. Check that `repository` in `package.json` points to this GitHub repository. npm compares it with the repository that runs the workflow.
-2. From your machine, publish the version that `package.json` holds. The workflow publishes every later version:
-
-   ```bash
-   npm publish --access public
-   ```
-
-3. On [npmjs.com](https://www.npmjs.com/), open the package's **Settings** and add a trusted publisher for **GitHub Actions**. Enter the repository's owner and name, and `release-nodejs.yml` as the workflow filename.
-4. Under **Allowed actions**, allow direct publishing with `npm publish`. The workflow runs `npm publish`, and a new trusted publisher allows only `npm stage publish` by default.
-
 ### Documentation site
 
 `Release docs` deploys the documentation site to GitHub Pages. The deploy fails until GitHub Pages accepts a deploy from a tag.
@@ -110,31 +23,15 @@
 
 ## Release a version
 
-A release of this project starts on your machine, with `npm version`. Follow 2 rules for every release:
+A release of this project starts on the repository's **Releases** page. Publishing a release creates its tag, and the tag starts the release workflows.
 
-- Release only by pushing the tag. `Release Node.js` stops on a published release, so clicking **Publish release** on the draft leaves the release without its assets.
-- Push 1 version tag at a time. `Release Node.js` publishes 1 tag at a time, and each newly waiting run cancels the run that waited before it.
+To release a version:
 
-Before the first release, set up [release signing](#release-signing). To release a version:
-
-1. Optional: On the repository's **Releases** page, open the draft release and edit its notes.
-2. On an up-to-date `main` with no uncommitted changes, set the version:
-
-   ```bash
-   npm version __VERSION__
-   ```
-
-   `npm version` sets the version in `package.json`, commits the change and tags the commit `__VERSION__`. The project's `.npmrc` sets the commit message to `Released __VERSION__.` and drops the `v` from the tag.
-
-3. Push the commit and the tag:
-
-   ```bash
-   git push origin main --follow-tags
-   ```
-
-4. On the **Actions** tab, open each release workflow's run for the tag. Confirm that every run passes and that everything in [What a release publishes](#what-a-release-publishes) is published. Re-run a canceled or failed run from the same tab.
-
-To release a pre-release, set a version with a suffix, such as `npm version __VERSION__`. `Release Node.js` publishes it under the `next` npm dist-tag and marks its GitHub release as a pre-release.
+1. On the **Releases** page, click **Edit** on the draft release. Without a draft, click **Draft a new release**.
+2. Set the tag to the new version, such as `__VERSION__`.
+3. Optional: Edit the release notes.
+4. Click **Publish release**. GitHub creates the tag.
+5. On the **Actions** tab, open each release workflow's run for the tag. Confirm that every run passes and that everything in [What a release publishes](#what-a-release-publishes) is published.
 
 ## Change the release process
 
