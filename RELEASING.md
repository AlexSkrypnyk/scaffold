# Releasing

Follow this guide to release a new version of Scaffold. It's for maintainers with write access to the repository. The release workflows publish the installer that getscaffold.dev serves, the PHAR, the PHP script and the getscaffold.dev site. To change Scaffold itself, follow [`CONTRIBUTING.md`](CONTRIBUTING.md).

Generated projects get their own release guide from [`RELEASING.dist.md`](RELEASING.dist.md).

## Before you begin

Make sure you have the following:

- Write access to `AlexSkrypnyk/scaffold`
- A `main` with every change of the release merged and every required check passing
- The signing key stored in the `release` environment of the repository, as [Manage the signing key](#manage-the-signing-key) describes

## Release a version

A version tag is 3 numbers with an optional suffix, such as `1.2.3` or `1.2.3-rc.1`, with no `v`. The `Draft release notes` workflow, which runs Release Drafter, keeps a draft release with notes for the pull requests merged into `main`.

Publish a release only by pushing its tag. Never click **Publish release** on the draft. An immutable release accepts no assets after it's published, so `Release PHP` and `Release Scaffold installer` both fail on it, and the fix is a new version with a tag push.

To release a version:

1. Optional: On the **Releases** page, click **Edit** on the draft release and edit its notes.
2. On an up-to-date `main`, tag the commit and push the tag:

   ```bash
   git tag 1.2.3
   git push origin 1.2.3
   ```

3. On the **Actions** tab, open the `Release PHP`, `Release Scaffold installer` and `Release Scaffold docs` runs for the tag. Confirm that they pass.
4. Open the release. Confirm that it's published with the PHAR, the PHP script, `install.sh`, `SHA256SUMS`, `SHA256SUMS.asc` and `scaffold-installer-TAG.intoto.jsonl`.

Push 1 version tag at a time. The `Publish Scaffold release` job of `Release Scaffold installer` runs for 1 tag at a time, and GitHub keeps only the newest waiting run. Re-run each canceled `Publish Scaffold release` job from the **Actions** tab.

## What the tag starts

The tag starts 3 workflows:

- `Release PHP` attaches the PHAR and the PHP script to the draft release.
- `Release Scaffold installer` attaches the installer files and publishes the release.
- `Release Scaffold docs` deploys getscaffold.dev to GitHub Pages from the tag, in parallel with the other 2.

`scaffold-release-installer.yml` runs these steps:

1. Checks that the tag is a version on `main`, then stamps `SCAFFOLD_VERSION="dev"` in `install.sh` with the tag.
2. Pipes the stamped installer into `bash` in an empty directory, so it bootstraps and initializes the tag's template.
3. Writes `SHA256SUMS` and signs it as `SHA256SUMS.asc` with `GPG_PRIVATE_KEY`, and `GPG_PASSPHRASE` when the key has one. Both are secrets of the `release` environment.
4. Checks the signature against `install-key.asc` and its pinned fingerprint with `.scaffold/installer/verify-release.sh`.
5. Attests `install.sh` and `SHA256SUMS`, and saves the attestation bundle as `scaffold-installer-TAG.intoto.jsonl`.
6. Waits for the tag's `Release PHP` run, which attaches its assets to the draft release. Then it uploads the 4 installer files to the draft, publishes the release and verifies the uploaded copies.
7. For the latest release, checks that `releases/latest/download/install.sh`, getscaffold.dev/install.sh and getscaffold.dev/init.sh all serve the uploaded installer.

Steps 1-5 run in the `Build Scaffold installer` job, which reads the repository only. Steps 6-7 run in the `Publish Scaffold release` job, which writes the release. `TAG` in a filename is the version tag.

A re-run on a published release that already holds the same `install.sh` succeeds without uploading. The workflow rejects a tag whose installer has no `SCAFFOLD_VERSION="dev"` line.

## Manage the signing key

`install-key.asc` in the repository root is the public half of the `Scaffold Release Signing` key, fingerprint `86F0 77A2 E806 67D7 CF4A 3320 EDEA F2FC D434 756C`. It expires on 2028-11-08.

To give the workflow the signing key, create the `release` environment, then store the private key and its passphrase there:

```bash
gh api -X PUT repos/AlexSkrypnyk/scaffold/environments/release
gpg --armor --export-secret-keys 86F077A2E80667D7CF4A3320EDEAF2FCD434756C | gh secret set GPG_PRIVATE_KEY --env release --repo AlexSkrypnyk/scaffold
gh secret set GPG_PASSPHRASE --env release --repo AlexSkrypnyk/scaffold
```

To extend the key before it expires, run `gpg --quick-set-expire 86F077A2E80667D7CF4A3320EDEAF2FCD434756C 2y`, then export the public half again and commit it. The fingerprint stays the same:

```bash
gpg --armor --output install-key.asc --export 86F077A2E80667D7CF4A3320EDEAF2FCD434756C
```

To replace the key, commit a new `install-key.asc` and store the new private key in the `release` environment. Put the new fingerprint in `verify-release.sh` and in the "Verify the installer" section of `.scaffold/docs/content/README.mdx`. Add a note about the new key to the release notes.
