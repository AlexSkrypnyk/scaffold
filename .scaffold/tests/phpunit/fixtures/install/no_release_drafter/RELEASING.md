@@ -8,8 +8,6 @@
 
 A version tag is 3 numbers with an optional suffix, such as `__VERSION__` or `__VERSION__`, with no `v`. A version tag starts the release workflows. Each workflow that publishes to the release or to a registry checks the tag before it builds anything. It stops when the tag doesn't match the version format or the tagged commit isn't on `main`.
 
-The `Draft release notes` workflow keeps a draft release, with notes for every pull request merged into `main`.
-
 In asset names, `TAG` is the version tag. A `.sha256` file holds the checksum of an asset, and an `.intoto.jsonl` file holds its build attestation: a signed record of the workflow run that built it. A release of a private repository carries no `.intoto.jsonl` file, because GitHub offers attestations for private repositories only on GitHub Enterprise Cloud. [`SECURITY.md`](SECURITY.md) shows how to verify an asset with both files.
 
 ### Signed checksums
