# Contributing

Contributions to Scaffold are welcome.

Scaffold is a multi-stack project template. The `.scaffold/` directory holds the
template's own infrastructure and is removed from generated projects by
[`init.sh`](init.sh). The maintenance guide in
[`.scaffold/CLAUDE.md`](.scaffold/CLAUDE.md) documents the template
architecture, the `init.sh` token system, and the test and fixture workflow -
read it before changing template files.

## Local development

The example application is tested from the repository root:

```bash
composer install
composer lint
composer test
```

The `init.sh` script and the template files have a separate suite that must be
run for any change to them:

```bash
cd .scaffold/tests/phpunit
composer install
composer lint
composer test
```

After changing `init.sh` or any template file, regenerate the fixtures and
review the diff before committing:

```bash
cd .scaffold/tests/phpunit
composer update-snapshots
```
