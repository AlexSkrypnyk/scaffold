# Releasing

Follow this guide to release a new version of Scaffold. It's for maintainers with write access to the repository. The release workflows publish the installer that getscaffold.dev serves, the PHAR, the PHP script and the getscaffold.dev site. To change Scaffold itself, follow [`CONTRIBUTING.md`](CONTRIBUTING.md).

Generated projects get their own release guide from [`RELEASING.dist.md`](RELEASING.dist.md).

## Before you begin

Make sure you have the following:

- Write access to `AlexSkrypnyk/scaffold`
- A `main` with every change of the release merged and every required check passing
- The signing key stored in `release`, the GitHub Actions environment that holds the signing secrets, as [Store the signing key](#store-the-signing-key) describes
- The `DOCKER_USER` and `DOCKER_PASS` repository secrets, which `Release Docker` signs in to Docker Hub with

## Release a version

You release a version by pushing its tag. Pushing the tag starts the release workflows, which attach the assets to the draft release and then publish it. The `Draft release notes` workflow runs Release Drafter to update that draft, with notes for the pull requests merged into `main`.

A version tag is 3 numbers with an optional suffix, such as `1.2.3` or `1.2.3-rc.1`, with no `v`. Follow 2 rules for every release:

- Release only by pushing the tag. With immutable releases turned on, GitHub accepts no new assets on a published release. Clicking **Publish release** on the draft then makes `Release PHP` and `Release Scaffold installer` fail, and the only fix is a new version.
- Push 1 version tag at a time. The `Publish Scaffold release` job of `Release Scaffold installer` handles 1 tag at a time, and each newly waiting run cancels the run that waited before it.

To release a version:

1. Optional: On the **Releases** page, click **Edit** on the draft release and edit its notes.
2. On an up-to-date `main`, tag the commit and push the tag:

   ```bash
   git tag 1.2.3
   git push origin 1.2.3
   ```

3. On the **Actions** tab, open the `Release PHP`, `Release Scaffold installer`, `Release Scaffold docs` and `Release Docker` runs for the tag. Confirm that all 4 pass.
4. Open the release. Confirm that it's published with these assets, where `TAG` is the version tag:
   - `php-command.phar` and `php-script`, with `scaffold-php-TAG.sha256` and `scaffold-php-TAG.intoto.jsonl`
   - `install.sh`, `SHA256SUMS`, `SHA256SUMS.asc` and `scaffold-installer-TAG.intoto.jsonl`

## Fix a failed release run

Re-run a canceled or failed job from the **Actions** tab. When the published release already holds the same `install.sh`, a re-run of `Publish Scaffold release` skips the upload and passes.

`Release Scaffold installer` rejects a tag whose `install.sh` has no `SCAFFOLD_VERSION="dev"` line.

## What the tag starts

Pushing the tag starts 4 workflows:

- `Release PHP` attaches the PHAR and the PHP script to the draft release.
- `Release Scaffold installer` attaches the installer files and publishes the release.
- `Release Scaffold docs` deploys getscaffold.dev to GitHub Pages from the tag.
- `Release Docker` builds the example Docker image and pushes it to Docker Hub. The optional `DOCKER_IMAGE` repository variable sets the image name, and the workflow falls back to `yournamespace/yourdockerimage` without it.

`Release Scaffold installer`, defined in `scaffold-release-installer.yml`, runs these steps:

1. Checks that the tag is a version on `main`. Then it replaces `dev` in the `SCAFFOLD_VERSION="dev"` line of `install.sh` with the tag.
2. Pipes the stamped installer into `bash` in an empty directory, so it bootstraps and initializes the tag's template.
3. Writes `SHA256SUMS` and signs it as `SHA256SUMS.asc` with `GPG_PRIVATE_KEY`, and with `GPG_PASSPHRASE` when the key has one. Both are secrets of the `release` environment.
4. Checks the signature against `install-key.asc` and its pinned fingerprint with `.scaffold/installer/verify-release.sh`.
5. Attests `install.sh` and `SHA256SUMS`, and saves the attestation bundle as `scaffold-installer-TAG.intoto.jsonl`.
6. Waits for the tag's `Release PHP` run. Then it uploads the 4 installer files to the draft, publishes the release and verifies the uploaded copies.
7. For the latest release, checks that `releases/latest/download/install.sh` and getscaffold.dev/install.sh both serve the uploaded installer.

Steps 1-5 run in the `Build Scaffold installer` job, which reads the repository only. Steps 6-7 run in the `Publish Scaffold release` job, which writes the release.

## Manage the signing key

`install-key.asc` in the repository root is the public half of the `Scaffold Release Signing` key, fingerprint `86F0 77A2 E806 67D7 CF4A 3320 EDEA F2FC D434 756C`. It expires on 2028-11-08. The workflow signs with the private half, which it reads from the `GPG_PRIVATE_KEY` secret.

### Store the signing key

To store the private key and its passphrase in the `release` environment:

1. Create the `release` environment:

   ```bash
   gh api -X PUT repos/AlexSkrypnyk/scaffold/environments/release
   ```

2. Store the private key as `GPG_PRIVATE_KEY`:

   ```bash
   gpg --armor --export-secret-keys 86F077A2E80667D7CF4A3320EDEAF2FCD434756C | gh secret set GPG_PRIVATE_KEY --env release --repo AlexSkrypnyk/scaffold
   ```

3. Store the passphrase as `GPG_PASSPHRASE`. The command prompts for its value:

   ```bash
   gh secret set GPG_PASSPHRASE --env release --repo AlexSkrypnyk/scaffold
   ```

### Extend the signing key

Extend the key before it expires. The fingerprint stays the same, so `verify-release.sh` needs no change.

To extend the key by 2 years:

1. Set the new expiry date:

   ```bash
   gpg --quick-set-expire 86F077A2E80667D7CF4A3320EDEAF2FCD434756C 2y
   ```

2. Export the public half, then commit `install-key.asc`:

   ```bash
   gpg --armor --output install-key.asc --export 86F077A2E80667D7CF4A3320EDEAF2FCD434756C
   ```

3. Store the extended private key again. `GPG_PRIVATE_KEY` still holds the copy with the old expiry date:

   ```bash
   gpg --armor --export-secret-keys 86F077A2E80667D7CF4A3320EDEAF2FCD434756C | gh secret set GPG_PRIVATE_KEY --env release --repo AlexSkrypnyk/scaffold
   ```

4. Update the expiry date in [Manage the signing key](#manage-the-signing-key).

### Replace the signing key

To replace the key with a new one:

1. Create the new key as a primary key that signs, with no signing subkey. `verify-release.sh` checks the fingerprint of the key that made the signature, so a signature from a subkey fails.
2. Commit the new key's public half as `install-key.asc`.
3. Store the new private key with the commands in [Store the signing key](#store-the-signing-key). Put the new key's fingerprint in place of `86F077A2E80667D7CF4A3320EDEAF2FCD434756C` before you run them.
4. Put the new fingerprint in `.scaffold/installer/verify-release.sh`, in the "Verify the installer" section of `.scaffold/docs/content/README.mdx` and in [Manage the signing key](#manage-the-signing-key).
5. Add a note about the new key to the release notes of the next version.
