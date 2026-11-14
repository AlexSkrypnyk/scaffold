# Security policy

This page is for anyone who finds a security issue in Scaffold or wants to check that an install script came from it.

## Supported versions

Security fixes go into the latest release only. Before you report an issue, confirm that it affects the latest release or `main`.

## Report a vulnerability

On the repository's **Security** tab, click **Report a vulnerability**. The form opens at https://github.com/AlexSkrypnyk/scaffold/security/advisories/new and keeps the report private until a fix is out. Keep the details out of public issues, pull requests and discussions.

Include the following in your report:

- The affected version, or the commit on `main`
- What an attacker can do with the issue
- The steps to reproduce it, with a proof of concept when you have one
- Any fix or workaround you know of

## What happens after you report

We reply to every report within 14 days. When we confirm the issue, we agree a disclosure date with you and prepare the fix in a private fork.

We disclose the issue in a GitHub security advisory, published with the release that fixes it. The advisory credits you unless you ask to stay anonymous, and it carries a CVE identifier when the issue needs one.

## Verify the install script

Each release carries `install.sh` with a signed `SHA256SUMS` file and a build provenance attestation. To check a downloaded script, follow [Verify the install script](https://getscaffold.dev/#verify-the-install-script).
