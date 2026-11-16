# Releasing

Follow this guide to release a new version of this project. It's for maintainers with write access to the repository. It covers what a release publishes, the one-time setup and the steps to publish a version. To change the code, follow [`CONTRIBUTING.md`](CONTRIBUTING.md).

The process in this guide matches the release workflows the project started with. The maintainers own this project's release process, so change it to fit the project, as [Change the release process](#change-the-release-process) describes.

## What a release publishes

A version tag is 3 numbers with an optional suffix, such as `__VERSION__` or `__VERSION__`, with no `v`. A pushed tag starts the release workflows. Each workflow that publishes an asset checks the tag first. It stops when the tag isn't a version or the tagged commit isn't on `main`, so nothing gets published from that tag.

The `Draft release notes` workflow keeps a draft release with notes for every pull request merged into `main`.

Each release workflow of this project starts on the version tag:

- `Release PHP` builds the PHAR and attaches it to the release, with `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
- `Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release, with `force-crystal-nodejs-TAG.sha256` and `force-crystal-nodejs-TAG.intoto.jsonl`. Then it publishes the release.
- `Release docs` deploys the documentation site to GitHub Pages.

`TAG` in a filename is the version tag. [`SECURITY.md`](SECURITY.md) shows how anyone can verify a downloaded asset with its checksum and attestation files.

## Before your first release

Each release workflow needs settings that only the repository owner can add. Set them up before the first version tag.

### npm publishing

`Release Node.js` publishes to npm through [trusted publishing](https://docs.npmjs.com/trusted-publishers), so the repository stores no npm token. npm trusts the workflow from the package's settings, so the package has to exist on npm first.

To set up npm publishing:

1. Check that `repository` in `package.json` points to this GitHub repository. npm compares it with the repository that runs the workflow.
2. From your machine, publish the first version:

   ```bash
   npm publish --access public
   ```

3. On [npmjs.com](https://www.npmjs.com/), open the package's **Settings** and add a trusted publisher for **GitHub Actions**. Enter the repository's owner and name, and `release-nodejs.yml` as the workflow filename.

To release on GitHub only, set `"private": true` in `package.json`. The workflow then skips npm and still publishes the GitHub release.

### GitHub Pages

`Release docs` fails until the repository allows a tag to deploy to GitHub Pages. To allow it:

1. In **Settings > Pages**, set **Source** to **GitHub Actions**.
2. In **Settings > Environments > github-pages**, add a deployment rule with the **Tag** ref type and the `*` name pattern.

## Release a version

A release starts on your machine: `npm version` sets the version and creates the tag, and the tag push starts the release workflows. Release only by pushing a version tag. Never click **Publish release** on the draft release: a published release makes `Release Node.js` stop, so the release never gets its assets.

To release a version:

1. Optional: On the repository's **Releases** page, open the draft release and edit its notes.
2. On an up-to-date `main` with no uncommitted changes, set the version:

   ```bash
   npm version __VERSION__
   ```

   `npm version` sets the version in `package.json`, commits the change as `Released __VERSION__.` and tags the commit `__VERSION__`.

3. Push the commit and the tag:

   ```bash
   git push origin main --follow-tags
   ```

4. On the **Actions** tab, open each release workflow's run for the tag. Confirm that every run passes and that the release lists the assets from [What a release publishes](#what-a-release-publishes).

A version with a suffix, such as `__VERSION__`, goes to npm under the `next` dist-tag and becomes a GitHub pre-release. Push 1 version tag at a time. Release runs for different tags publish 1 at a time, and GitHub cancels every waiting run except the newest. Re-run each canceled run from the **Actions** tab.

## Change the release process

Every project releases differently. A release can start on your machine or on the **Releases** page, and its assets can come from your machine or from a GitHub Actions workflow. When the process changes, update this file in the same pull request as the workflow change. Keep these parts of the file current:

- Where a release starts, and the commands or buttons that start it
- What each workflow publishes, and where
- The secrets and settings each workflow needs
- The checks that confirm a release worked

The [Scaffold release documentation](https://getscaffold.dev/ci/release) explains each release workflow in depth.
