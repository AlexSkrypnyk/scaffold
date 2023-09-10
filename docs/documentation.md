---
title: Documentation
layout: home
nav_order: 8
---

# Documentation

This documentation is built with [Just the Docs](https://just-the-docs.com/)
Jekyll template and hosted on [GitHub Pages](https://pages.github.com/).

You may re-use the configuration and structure of this documentation for your
own project.

The [configuration file](https://github.com/AlexSkrypnyk/scaffold/blob/main/docs/_config.yml)
allows to adjust the documentation to your needs.

## Publishing

Documentation is published to GitHub Pages using the [Deploy Docs to GitHub Pages](https://github.com/AlexSkrypnyk/scaffold/blob/main/.github/workflows/docs.yml) 
GitHub Action. 

This GitHub Action is designed to automatically build and publish documentation
to GitHub Pages. The workflow triggers on every `push` to the `main` branch,
specifically when changes are made in the `docs` directory. 

The Jekyll build command generates the static site.

The action uses concurrency controls to cancel any in-progress runs
if a new run is initiated, ensuring that only the latest changes are deployed.

The environment for this job is set to `github-pages`, and the URL for the
deployed page is dynamically generated.
