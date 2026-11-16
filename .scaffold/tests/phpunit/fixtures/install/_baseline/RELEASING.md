# Releasing

Follow this guide to release a new version of this project. It's for maintainers with write access to the repository. It covers what a release publishes, the setup each release workflow needs and the steps to publish a version. To change the code, follow [`CONTRIBUTING.md`](CONTRIBUTING.md).

To change how this project releases, follow [Change the release process](#change-the-release-process).

## What a release publishes

A version tag is 3 numbers with an optional suffix, such as `__VERSION__` or `__VERSION__`, with no `v`. A version tag starts the release workflows. Each workflow that publishes to the release or to a registry checks the tag before it builds anything. It stops when the tag doesn't match the version format or the tagged commit isn't on `main`.

The `Draft release notes` workflow keeps a draft release, with notes for every pull request merged into `main`.

In asset names, `TAG` is the version tag. A `.sha256` file holds the checksum of an asset, and an `.intoto.jsonl` file holds its build attestation: a signed record of the workflow run that built it. A release of a private repository carries no `.intoto.jsonl` file, because GitHub offers attestations for private repositories only on GitHub Enterprise Cloud. [`SECURITY.md`](SECURITY.md) shows how to verify an asset with both files.

### PHP release asset

`Release PHP` builds `force-crystal.phar` and attaches it to the release. Its checksum and attestation go in `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.

### npm package

`Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release. Its checksum and attestation go in `force-crystal-nodejs-TAG.sha256` and `force-crystal-nodejs-TAG.intoto.jsonl`. Then the workflow publishes the release.

The workflow publishes through npm [trusted publishing](https://docs.npmjs.com/trusted-publishers), so you store no npm token in the repository. npm accepts the workflow only after the package exists on npm and names `release-nodejs.yml` as its trusted publisher. To release on GitHub only, set `"private": true` in `package.json` and skip this setup. The workflow then skips npm and still publishes the GitHub release.

To set up trusted publishing before the first release:

1. Check that `repository` in `package.json` points to this GitHub repository. npm compares it with the repository that runs the workflow.
2. From your machine, publish the version that `package.json` holds. The workflow publishes every later version:

   ```bash
   npm publish --access public
   ```

3. On [npmjs.com](https://www.npmjs.com/), open the package's **Settings** and add a trusted publisher for **GitHub Actions**. Enter the repository's owner and name, and `release-nodejs.yml` as the workflow filename.

### Documentation site

`Release docs` deploys the documentation site to GitHub Pages. The deploy fails until GitHub Pages accepts a deploy from a tag.

To accept deploys from a tag:

1. In **Settings > Pages**, set **Source** to **GitHub Actions**.
2. In **Settings > Environments > github-pages**, add a deployment rule with the **Tag** ref type and the `*` name pattern.

## Release a version

A release of this project starts on your machine, with `npm version`. Follow 2 rules for every release:

- Release only by pushing the tag. `Release Node.js` stops on a published release, so clicking **Publish release** on the draft leaves the release without its assets.
- Push 1 version tag at a time. `Release Node.js` publishes 1 tag at a time, and each newly waiting run cancels the run that waited before it.

To release a version:

1. Optional: On the repository's **Releases** page, open the draft release and edit its notes.
2. On an up-to-date `main` with no uncommitted changes, set the version:

   ```bash
   npm version __VERSION__
   ```

   `npm version` sets the version in `package.json`, commits the change and tags the commit `__VERSION__`. The project's `.npmrc` sets the commit message to `Released __VERSION__.` and drops the `v` from the tag.

3. Push the commit and the tag:

   ```bash
   git push origin main --follow-tags
   ```

4. On the **Actions** tab, open each release workflow's run for the tag. Confirm that every run passes and that everything in [What a release publishes](#what-a-release-publishes) is published. Re-run a canceled or failed run from the same tab.

To release a pre-release, set a version with a suffix, such as `npm version __VERSION__`. `Release Node.js` publishes it under the `next` npm dist-tag and marks its GitHub release as a pre-release.

## Change the release process

The maintainers decide how this project releases. To change where a release starts or where its assets get built, change the release workflows in `.github/workflows`.

When the process changes, update this guide in the same pull request as the workflow change. Keep these parts of the guide current:

- Where a release starts, and the commands or buttons that start it
- What each workflow publishes, and where
- The secrets and settings each workflow needs
- The checks that confirm a release worked

The [Scaffold release documentation](https://getscaffold.dev/ci/release) explains each release workflow in depth.
