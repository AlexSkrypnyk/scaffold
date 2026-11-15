@@ -12,8 +12,7 @@
 
 Each release workflow of this project starts on the version tag:
 
-- `Release PHP` builds the PHAR and attaches it to the release, with `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
-- `Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release, with `force-crystal-nodejs-TAG.sha256` and `force-crystal-nodejs-TAG.intoto.jsonl`. Then it publishes the release.
+- `Release Docker` pushes the `acme/api-image` image to Docker Hub, tagged with the version and `latest`.
 - `Release docs` deploys the documentation site to GitHub Pages.
 
 `TAG` in a filename is the version tag. [`SECURITY.md`](SECURITY.md) shows how anyone can verify a downloaded asset with its checksum and attestation files.
@@ -22,23 +21,16 @@
 
 Each release workflow needs settings that only the repository owner can add. Set them up before the first version tag.
 
-### npm publishing
+### Docker Hub credentials
 
-`Release Node.js` publishes to npm through [trusted publishing](https://docs.npmjs.com/trusted-publishers), so the repository stores no npm token. npm trusts the workflow from the package's settings, so the package has to exist on npm first.
+`Release Docker` signs in to Docker Hub with 2 repository secrets. To add them:
 
-To set up npm publishing:
+1. In the repository, open **Settings > Secrets and variables > Actions**.
+2. On the **Secrets** tab, add a `DOCKER_USER` secret with your Docker Hub username.
+3. Add a `DOCKER_PASS` secret with a Docker Hub access token.
 
-1. Check that `repository` in `package.json` points to this GitHub repository. npm compares it with the repository that runs the workflow.
-2. From your machine, publish the first version:
+To publish to another image name, set the `DOCKER_IMAGE` repository variable on the **Variables** tab of the same page.
 
-   ```bash
-   npm publish --access public
-   ```
-
-3. On [npmjs.com](https://www.npmjs.com/), open the package's **Settings** and add a trusted publisher for **GitHub Actions**. Enter the repository's owner and name, and `release-nodejs.yml` as the workflow filename.
-
-To release on GitHub only, set `"private": true` in `package.json`. The workflow then skips npm and still publishes the GitHub release.
-
 ### GitHub Pages
 
 `Release docs` fails until the repository allows a tag to deploy to GitHub Pages. To allow it:
@@ -48,28 +40,13 @@
 
 ## Release a version
 
-A release starts on your machine: `npm version` sets the version and creates the tag, and the tag push starts the release workflows. Release only by pushing a version tag. Never click **Publish release** on the draft release: a published release makes `Release Node.js` stop, so the release never gets its assets.
+A release starts on the repository's **Releases** page: publishing a release creates its tag, and the tag starts the release workflows.
 
 To release a version:
 
-1. Optional: On the repository's **Releases** page, open the draft release and edit its notes.
-2. On an up-to-date `main` with no uncommitted changes, set the version:
-
-   ```bash
-   npm version __VERSION__
-   ```
-
-   `npm version` sets the version in `package.json`, commits the change as `Released __VERSION__.` and tags the commit `__VERSION__`.
-
-3. Push the commit and the tag:
-
-   ```bash
-   git push origin main --follow-tags
-   ```
-
-4. On the **Actions** tab, open each release workflow's run for the tag. Confirm that every run passes and that the release lists the assets from [What a release publishes](#what-a-release-publishes).
-
-A version with a suffix, such as `__VERSION__`, goes to npm under the `next` dist-tag and becomes a GitHub pre-release. Push 1 version tag at a time, because GitHub starts no workflow for a push that holds more than 3 tags.
+1. On the **Releases** page, click **Edit** on the draft release and edit its notes if they need it. Without a draft, click **Draft a new release** and enter a new version tag, such as `__VERSION__`.
+2. Click **Publish release**. GitHub creates the tag.
+3. On the **Actions** tab, open each release workflow's run for the tag. Confirm that every run passes and that the release lists the assets from [What a release publishes](#what-a-release-publishes).
 
 ## Change the release process
 
