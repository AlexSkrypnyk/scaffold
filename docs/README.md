# Yourproject documentation

`docs` holds the source of this project's documentation site, which is built with [Docusaurus](https://docusaurus.io/). Follow this page to run the site locally and build it. Run every command from the `docs` directory.

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

Before you commit, run `npm test`. It runs the Jest tests and the CSpell spell check.
