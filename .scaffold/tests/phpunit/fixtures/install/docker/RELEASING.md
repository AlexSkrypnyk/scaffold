@@ -12,28 +12,18 @@
 
 In asset names, `TAG` is the version tag. A `.sha256` file holds the checksum of an asset, and an `.intoto.jsonl` file holds its build attestation: a signed record of the workflow run that built it. A release of a private repository carries no `.intoto.jsonl` file, because GitHub offers attestations for private repositories only on GitHub Enterprise Cloud. [`SECURITY.md`](SECURITY.md) shows how to verify an asset with both files.
 
-### PHP release asset
+### Docker image
 
-`Release PHP` builds `force-crystal.phar` and attaches it to the release. Its checksum and attestation go in `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
+`Release Docker` pushes the `yodashut/force-crystal` image to Docker Hub, tagged with the version and `latest`.
 
-### npm package
+To add the Docker Hub secrets that `Release Docker` signs in with:
 
-`Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release. Its checksum and attestation go in `force-crystal-nodejs-TAG.sha256` and `force-crystal-nodejs-TAG.intoto.jsonl`. Then the workflow publishes the release.
+1. In the repository, open **Settings > Secrets and variables > Actions**.
+2. On the **Secrets** tab, add a `DOCKER_USER` secret with your Docker Hub username.
+3. Add a `DOCKER_PASS` secret with a Docker Hub access token.
 
-The workflow publishes through npm [trusted publishing](https://docs.npmjs.com/trusted-publishers), so you store no npm token in the repository. npm accepts the workflow only after the package exists on npm and names `release-nodejs.yml` as its trusted publisher. To release on GitHub only, set `"private": true` in `package.json` and skip this setup. The workflow then skips npm and still publishes the GitHub release.
+To publish to another image name, set the `DOCKER_IMAGE` repository variable on the **Variables** tab of the same page.
 
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
@@ -45,31 +35,15 @@
 
 ## Release a version
 
-A release of this project starts on your machine, with `npm version`. Follow 2 rules for every release:
+A release of this project starts on the repository's **Releases** page. Publishing a release creates its tag, and the tag starts the release workflows.
 
-- Release only by pushing the tag. `Release Node.js` stops on a published release, so clicking **Publish release** on the draft leaves the release without its assets.
-- Push 1 version tag at a time. `Release Node.js` publishes 1 tag at a time, and each newly waiting run cancels the run that waited before it.
-
 To release a version:
 
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
 
