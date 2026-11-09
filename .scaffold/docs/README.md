# Scaffold documentation

`.scaffold/docs` holds the source of getscaffold.dev, the site that documents the Scaffold template. The site is built with [Docusaurus](https://docusaurus.io/). Follow this page to run the site locally and build it. Run every command from the `.scaffold/docs` directory of the repository.

## Install the dependencies

To install the dependencies, run the following command:

```bash
$ npm install
```

## Start a local server

To start a local development server and open the site in a browser, run the following command:

```bash
$ npm start
```

Most changes appear in the browser without a server restart.

## Build the site

To generate the static site into the `build` directory, run the following command:

```bash
$ npm run build
```

Any static hosting service can serve the `build` directory.

`npm start` and `npm run build` first run `scripts/copy-installer.js`, which writes the installer that the site serves to `static/install.sh` and `static/init.sh`. Both are git-ignored copies. The source of the copies depends on the build:

| Build | Source | What `/install.sh` runs |
|---|---|---|
| `RELEASE_VERSION` set, as in the release workflow | `.scaffold/installer/install-latest.sh` | The `install.sh` attached to the latest GitHub release |
| `RELEASE_VERSION` unset, such as a local server or the development site | The repository-root `install.sh` | The installer of the built commit |

Before you commit, run `npm test`. It runs the Jest tests and the CSpell spell check. CI runs the same command after it builds the site.
