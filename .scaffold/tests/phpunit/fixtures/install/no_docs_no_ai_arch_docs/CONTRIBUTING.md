@@ -39,18 +39,6 @@
 
 To apply the formatting that shfmt reports, run the shfmt command with `-w` in place of `-d`.
 
-## Documentation site
-
-Install the documentation site's dependencies, build the site, then run its Jest tests and spell check:
-
-```bash
-npm --prefix docs install
-npm --prefix docs run build
-npm --prefix docs test
-```
-
-[`docs/README.md`](docs/README.md) shows how to preview the site locally.
-
 ## Submit a change
 
 Follow these rules for every pull request:
@@ -64,7 +52,6 @@
 - `Test PHP`
 - `Test Node.js`
 - `Test shell`
-- `Test Docs`
 - `Audit`, which scans the code with CodeQL
 
 To report a security issue, follow [`SECURITY.md`](SECURITY.md) instead of opening a pull request.
