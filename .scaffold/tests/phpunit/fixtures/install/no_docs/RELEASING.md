@@ -14,7 +14,6 @@
 
 - `Release PHP` builds the PHAR and attaches it to the release, with `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
 - `Release Node.js` publishes the package to npm and attaches `nodejs-script` to the release, with `force-crystal-nodejs-TAG.sha256` and `force-crystal-nodejs-TAG.intoto.jsonl`. Then it publishes the release.
-- `Release docs` deploys the documentation site to GitHub Pages.
 
 `TAG` in a filename is the version tag. A release of a private repository carries no `.intoto.jsonl` file, because GitHub offers attestations for private repositories only on GitHub Enterprise Cloud. [`SECURITY.md`](SECURITY.md) shows how anyone can verify a downloaded asset with its checksum and attestation files.
 
@@ -38,13 +37,6 @@
 3. On [npmjs.com](https://www.npmjs.com/), open the package's **Settings** and add a trusted publisher for **GitHub Actions**. Enter the repository's owner and name, and `release-nodejs.yml` as the workflow filename.
 
 To release on GitHub only, set `"private": true` in `package.json`. The workflow then skips npm and still publishes the GitHub release.
-
-### GitHub Pages
-
-`Release docs` fails until the repository allows a tag to deploy to GitHub Pages. To allow it:
-
-1. In **Settings > Pages**, set **Source** to **GitHub Actions**.
-2. In **Settings > Environments > github-pages**, add a deployment rule with the **Tag** ref type and the `*` name pattern.
 
 ## Release a version
 
