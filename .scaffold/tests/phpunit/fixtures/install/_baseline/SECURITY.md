# Security policy

This page is for anyone who finds a security issue in this project or wants to check that a release came from it.

## Supported versions

Security fixes go into the latest release only. Before you report an issue, confirm that it affects the latest release or `main`.

## Report a vulnerability

Report a vulnerability privately, so it stays hidden until a fix is out. Use either channel:

- Open a [private security advisory](https://github.com/yodashut/force-crystal/security/advisories/new). The same form opens from **Report a vulnerability** on the repository's **Security** tab.
- Email force-crystal@yodashut.com.

Keep the details out of public issues, pull requests and discussions.

Include the following in your report:

- The affected version, or the commit on `main`
- What an attacker can do with the issue
- The steps to reproduce it, with a proof of concept when you have one
- Any fix or workaround you know of

## What happens after you report

We reply to every report within 14 days. When we confirm the issue, we agree a disclosure date with you and prepare the fix in a private fork.

We disclose the issue in a GitHub security advisory, published with the release that fixes it. The advisory credits you unless you ask to stay anonymous, and it carries a CVE identifier when the issue needs one.

## Verify a PHP release asset

Each release carries a SHA-256 checksum file and a build provenance attestation for the PHP asset, which shows that this repository's release workflow built it. To verify a downloaded asset:

1. From the release page, download the asset and `force-crystal-php-TAG.sha256`.
2. Check the checksum:

   ```bash
   sha256sum --check --ignore-missing force-crystal-php-TAG.sha256
   ```

   On macOS, run `shasum -a 256 --check --ignore-missing force-crystal-php-TAG.sha256` instead.

3. Check the attestation with [GitHub CLI](https://cli.github.com/):

   ```bash
   gh attestation verify ASSET --repo yodashut/force-crystal
   ```

Replace `TAG` with the release's tag and `ASSET` with the downloaded filename. A release of a private repository carries no attestation, so skip step 3 for it.

## Verify a Node.js release

Each release carries a SHA-256 checksum file and a build provenance attestation for `nodejs-script`. To verify a downloaded script:

1. From the release page, download `nodejs-script` and `force-crystal-nodejs-TAG.sha256`.
2. Check the checksum:

   ```bash
   sha256sum --check force-crystal-nodejs-TAG.sha256
   ```

   On macOS, run `shasum -a 256 --check force-crystal-nodejs-TAG.sha256` instead.

3. Check the attestation with [GitHub CLI](https://cli.github.com/):

   ```bash
   gh attestation verify nodejs-script --repo yodashut/force-crystal
   ```

Replace `TAG` with the release's tag. A release of a private repository carries no attestation, so skip step 3 for it. To check the npm package, run `npm audit signatures` in a project that installs it.

