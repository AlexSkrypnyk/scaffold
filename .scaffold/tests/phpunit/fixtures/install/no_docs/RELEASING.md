@@ -34,15 +34,6 @@
 3. On [npmjs.com](https://www.npmjs.com/), open the package's **Settings** and add a trusted publisher for **GitHub Actions**. Enter the repository's owner and name, and `release-nodejs.yml` as the workflow filename.
 4. Under **Allowed actions**, allow direct publishing with `npm publish`. The workflow runs `npm publish`, and a new trusted publisher allows only `npm stage publish` by default.
 
-### Documentation site
-
-`Release docs` deploys the documentation site to GitHub Pages. The deploy fails until GitHub Pages accepts a deploy from a tag.
-
-To accept deploys from a tag:
-
-1. In **Settings > Pages**, set **Source** to **GitHub Actions**.
-2. In **Settings > Environments > github-pages**, add a deployment rule with the **Tag** ref type and the `*` name pattern.
-
 ## Release a version
 
 A release of this project starts on your machine, with `npm version`. Follow 2 rules for every release:
