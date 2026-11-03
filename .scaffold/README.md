# Template infrastructure

This directory holds the tools, tests and documentation for the Scaffold template itself. It's for Scaffold maintainers. `init.sh` deletes the whole directory when it initializes a project, so generated projects don't include it.

The directory holds the following:

- [`CLAUDE.md`](CLAUDE.md): the maintenance guide for the template architecture, the `init.sh` token system and the test and fixture workflow
- [`assets`](assets): the `update-assets.php` terminal recorder and the `init.svg` walkthrough it generates
- [`docs`](docs): the source of the Docusaurus site published at getscaffold.dev
- [`skills`](skills): the `update-consumer-scaffold` skill, which AI agents download from this template's GitHub repository to update a generated project
- [`tests`](tests): the PHPUnit fixture tests and the BATS unit tests, which both cover `init.sh`
