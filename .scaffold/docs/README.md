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

`npm start` and `npm run build` first copy `install.sh` from the repository root to `static/install.sh`, a git-ignored copy. The built site includes that copy, so the one-line `curl` installer fetches it from getscaffold.dev/install.sh. The copy step also writes `static/init.sh`, so getscaffold.dev/init.sh serves the same script.

Before you commit, run `npm test`. It runs the Jest tests and the CSpell spell check. CI runs the same command after it builds the site.
