# Releasing

Follow this guide to release a new version of this project. It's for maintainers with write access to the repository. It covers what a release publishes, the setup each release workflow needs and the steps to publish a version. To change the code, follow [`CONTRIBUTING.md`](CONTRIBUTING.md).

To change how this project releases, follow [Change the release process](#change-the-release-process).

## What a release publishes

A version tag is 3 numbers with an optional suffix, such as `1.2.3` or `1.2.3-rc.1`, with no `v`. A version tag starts the release workflows. Each workflow that publishes to the release or to a registry checks the tag before it builds anything. It stops when the tag doesn't match the version format or the tagged commit isn't on `main`.

[//]: # (#;< RELEASEDRAFTER)
The `Draft release notes` workflow keeps a draft release, with notes for every pull request merged into `main`.

[//]: # (#;> RELEASEDRAFTER)
In asset names, `TAG` is the version tag. A `.sha256` file holds the checksum of an asset, and an `.intoto.jsonl` file holds its build attestation: a signed record of the workflow run that built it. A release of a private repository carries no `.intoto.jsonl` file, because GitHub offers attestations for private repositories only on GitHub Enterprise Cloud. [`SECURITY.md`](SECURITY.md) shows how to verify an asset with both files.

[//]: # (#;< RELEASE_SIGNING)
### Signed checksums

The release workflows sign each `.sha256` file with a GPG key and attach the signature as a `.sha256.asc` file. Signing starts after you store the key in the `release` environment. Until then, the workflows skip it and print a notice.

Before it signs, a workflow fetches the key that [keys.openpgp.org](https://keys.openpgp.org) has confirmed for your release address. The release stops when that key isn't the signing key. keys.openpgp.org publishes an address only after its owner confirms it, so a swapped key can't pass this check without access to that mailbox.

To turn on signing:

1. Upload the public half of your signing key to keys.openpgp.org:

   ```bash
   gpg --export KEY_FINGERPRINT | curl -T - https://keys.openpgp.org
   ```

2. Open the link that the upload prints, and request verification of your release address. Confirm the address from the email that keys.openpgp.org sends.
3. Create the `release` environment:

   ```bash
   gh api -X PUT repos/yournamespace/yourproject/environments/release
   ```

4. Store the private key, the confirmed address and, for a key that has one, the passphrase. The last 2 commands prompt for their values:

   ```bash
   gpg --armor --export-secret-keys KEY_FINGERPRINT | gh secret set GPG_PRIVATE_KEY --env release --repo yournamespace/yourproject
   gh secret set RELEASE_GPG_KEY_EMAIL --env release --repo yournamespace/yourproject
   gh secret set GPG_PASSPHRASE --env release --repo yournamespace/yourproject
   ```

Replace `KEY_FINGERPRINT` with your key's fingerprint. Export only that key into `GPG_PRIVATE_KEY`, because the workflows stop on a secret that holds more than 1 key.

To have a reviewer approve each release before a workflow reads the key, add **Required reviewers** to the `release` environment under **Settings > Environments**. If you limit the environment's deployment branches, allow the version tags.

[//]: # (#;> RELEASE_SIGNING)
[//]: # (#;< PHP_RELEASE)
### PHP release asset

[//]: # (#;> PHP_RELEASE)
[//]: # (#;< PHP_PHAR)
`Release PHP` builds `php-command.phar` and attaches it to the release. Its checksum and attestation go in `yourproject-php-TAG.sha256` and `yourproject-php-TAG.intoto.jsonl`.

[//]: # (#;> PHP_PHAR)
[//]: # (#;< PHP_SCRIPT)
`Release PHP` attaches `php-script` to the release. Its checksum and attestation go in `yourproject-php-TAG.sha256` and `yourproject-php-TAG.intoto.jsonl`.

[//]: # (#;> PHP_SCRIPT)
[//]: # (#;< PHP_RELEASE)
[//]: # (#;< !NODEJS)
Then the workflow publishes the release.

[//]: # (#;> !NODEJS)
[//]: # (#;> PHP_RELEASE)
[//]: # (#;< NODEJS)
### npm package

`Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release. Its checksum and attestation go in `yourproject-nodejs-TAG.sha256` and `yourproject-nodejs-TAG.intoto.jsonl`. Then the workflow publishes the release.

The workflow publishes through npm [trusted publishing](https://docs.npmjs.com/trusted-publishers), so you store no npm token in the repository. npm accepts the workflow only after the package exists on npm and names `release-nodejs.yml` as its trusted publisher. To release on GitHub only, set `"private": true` in `package.json` and skip this setup. The workflow then skips npm and still publishes the GitHub release.

To set up trusted publishing before the first release:

1. Check that `repository` in `package.json` points to this GitHub repository. npm compares it with the repository that runs the workflow.
2. From your machine, publish the version that `package.json` holds. The workflow publishes every later version:

   ```bash
   npm publish --access public
   ```

3. On [npmjs.com](https://www.npmjs.com/), open the package's **Settings** and add a trusted publisher for **GitHub Actions**. Enter the repository's owner and name, and `release-nodejs.yml` as the workflow filename.
4. Under **Allowed actions**, allow direct publishing with `npm publish`. The workflow runs `npm publish`, and a new trusted publisher allows only `npm stage publish` by default.

[//]: # (#;> NODEJS)
[//]: # (#;< DOCKER)
### Docker image

`Release Docker` pushes the `yournamespace/yourdockerimage` image to Docker Hub, tagged with the version and `latest`.

To add the Docker Hub secrets that `Release Docker` signs in with:

1. In the repository, open **Settings > Secrets and variables > Actions**.
2. On the **Secrets** tab, add a `DOCKER_USER` secret with your Docker Hub username.
3. Add a `DOCKER_PASS` secret with a Docker Hub access token.

To publish to another image name, set the `DOCKER_IMAGE` repository variable on the **Variables** tab of the same page.

[//]: # (#;> DOCKER)
[//]: # (#;< DOCS)
### Documentation site

`Release docs` deploys the documentation site to GitHub Pages. The deploy fails until GitHub Pages accepts a deploy from a tag.

To accept deploys from a tag:

1. In **Settings > Pages**, set **Source** to **GitHub Actions**.
2. In **Settings > Environments > github-pages**, add a deployment rule with the **Tag** ref type and the `*` name pattern.

[//]: # (#;> DOCS)
## Release a version

[//]: # (#;< NODEJS)
A release of this project starts on your machine, with `npm version`. Follow 2 rules for every release:

- Release only by pushing the tag. `Release Node.js` stops on a published release, so clicking **Publish release** on the draft leaves the release without its assets.
- Push 1 version tag at a time. `Release Node.js` publishes 1 tag at a time, and each newly waiting run cancels the run that waited before it.

To release a version:

1. Optional: On the repository's **Releases** page, open the draft release and edit its notes.
2. On an up-to-date `main` with no uncommitted changes, set the version:

   ```bash
   npm version 1.2.3
   ```

   `npm version` sets the version in `package.json`, commits the change and tags the commit `1.2.3`. The project's `.npmrc` sets the commit message to `Released 1.2.3.` and drops the `v` from the tag.

3. Push the commit and the tag:

   ```bash
   git push origin main --follow-tags
   ```

4. On the **Actions** tab, open each release workflow's run for the tag. Confirm that every run passes and that everything in [What a release publishes](#what-a-release-publishes) is published. Re-run a canceled or failed run from the same tab.

To release a pre-release, set a version with a suffix, such as `npm version 1.2.3-rc.1`. `Release Node.js` publishes it under the `next` npm dist-tag and marks its GitHub release as a pre-release.

[//]: # (#;> NODEJS)
[//]: # (#;< !NODEJS)
[//]: # (#;< PHP_RELEASE)
A release of this project starts on your machine, with a version tag. Follow 2 rules for every release:

- Release only by pushing the tag. `Release PHP` stops on a published release, so clicking **Publish release** on the draft leaves the release without its assets.
- Push 1 version tag at a time. `Release PHP` publishes 1 tag at a time, and each newly waiting run cancels the run that waited before it.

To release a version:

1. Optional: On the repository's **Releases** page, open the draft release and edit its notes.
2. On an up-to-date `main`, tag the commit and push the tag:

   ```bash
   git tag 1.2.3
   git push origin 1.2.3
   ```

3. On the **Actions** tab, open each release workflow's run for the tag. Confirm that every run passes and that everything in [What a release publishes](#what-a-release-publishes) is published. Re-run a canceled or failed run from the same tab.

To release a pre-release, tag a version with a suffix, such as `1.2.3-rc.1`. `Release PHP` marks its GitHub release as a pre-release.

[//]: # (#;> PHP_RELEASE)
[//]: # (#;< !PHP_RELEASE)
A release of this project starts on the repository's **Releases** page. Publishing a release creates its tag, and the tag starts the release workflows.

To release a version:

1. On the **Releases** page, click **Edit** on the draft release. Without a draft, click **Draft a new release**.
2. Set the tag to the new version, such as `1.2.3`.
3. Optional: Edit the release notes.
4. Click **Publish release**. GitHub creates the tag.
5. On the **Actions** tab, open each release workflow's run for the tag. Confirm that every run passes and that everything in [What a release publishes](#what-a-release-publishes) is published.

[//]: # (#;> !PHP_RELEASE)
[//]: # (#;> !NODEJS)
## Change the release process

The maintainers decide how this project releases. To change where a release starts or where its assets get built, change the release workflows in `.github/workflows`.

When the process changes, update this guide in the same pull request as the workflow change. Keep these parts of the guide current:

- Where a release starts, and the commands or buttons that start it
- What each workflow publishes, and where
- The secrets and settings each workflow needs
- The checks that confirm a release worked

The [Scaffold release documentation](https://getscaffold.dev/ci/release) explains each release workflow in depth.
