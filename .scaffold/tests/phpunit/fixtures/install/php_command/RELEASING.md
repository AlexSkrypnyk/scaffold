@@ -47,26 +47,10 @@
 
 ### PHP release asset
 
-`Release PHP` builds `force-crystal.phar` and attaches it to the release. Its checksum and attestation go in `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
+`Release PHP` builds `star-forge.phar` and attaches it to the release. Its checksum and attestation go in `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
 
-### npm package
+Then the workflow publishes the release.
 
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
@@ -78,31 +62,24 @@
 
 ## Release a version
 
-A release of this project starts on your machine, with `npm version`. Follow 2 rules for every release:
+A release of this project starts on your machine, with a version tag. Follow 2 rules for every release:
 
-- Release only by pushing the tag. `Release Node.js` stops on a published release, so clicking **Publish release** on the draft leaves the release without its assets.
-- Push 1 version tag at a time. `Release Node.js` publishes 1 tag at a time, and each newly waiting run cancels the run that waited before it.
+- Release only by pushing the tag. `Release PHP` stops on a published release, so clicking **Publish release** on the draft leaves the release without its assets.
+- Push 1 version tag at a time. `Release PHP` publishes 1 tag at a time, and each newly waiting run cancels the run that waited before it.
 
 To release a version:
 
 1. Optional: On the repository's **Releases** page, open the draft release and edit its notes.
-2. On an up-to-date `main` with no uncommitted changes, set the version:
+2. On an up-to-date `main`, tag the commit and push the tag:
 
    ```bash
-   npm version __VERSION__
+   git tag __VERSION__
+   git push origin __VERSION__
    ```
 
-   `npm version` sets the version in `package.json`, commits the change and tags the commit `__VERSION__`. The project's `.npmrc` sets the commit message to `Released __VERSION__.` and drops the `v` from the tag.
+3. On the **Actions** tab, open each release workflow's run for the tag. Confirm that every run passes and that everything in [What a release publishes](#what-a-release-publishes) is published. Re-run a canceled or failed run from the same tab.
 
-3. Push the commit and the tag:
-
-   ```bash
-   git push origin main --follow-tags
-   ```
-
-4. On the **Actions** tab, open each release workflow's run for the tag. Confirm that every run passes and that everything in [What a release publishes](#what-a-release-publishes) is published. Re-run a canceled or failed run from the same tab.
-
-To release a pre-release, set a version with a suffix, such as `npm version __VERSION__`. `Release Node.js` publishes it under the `next` npm dist-tag and marks its GitHub release as a pre-release.
+To release a pre-release, tag a version with a suffix, such as `__VERSION__`. `Release PHP` marks its GitHub release as a pre-release.
 
 ## Change the release process
 
