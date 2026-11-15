@@ -8,8 +8,6 @@
 
 A version tag is 3 numbers with an optional suffix, such as `__VERSION__` or `__VERSION__`, with no `v`. The release workflows start on the version tag. They stop when the tag isn't a version or when the tagged commit isn't on `main`, so nothing gets published from that tag.
 
-The `Draft release notes` workflow keeps a draft release with notes for every pull request merged into `main`.
-
 Each release workflow of this project starts on the version tag:
 
 - `Release PHP` builds the PHAR and attaches it to the release, with `force-crystal-php-TAG.sha256` and `force-crystal-php-TAG.intoto.jsonl`.
