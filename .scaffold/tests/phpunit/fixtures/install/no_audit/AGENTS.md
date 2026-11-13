@@ -224,13 +224,6 @@
 - `.github/workflows/release-nodejs.yml` - Runs on the tag that `npm version` creates: checks it matches `package.json`, publishes to npm with provenance, then attaches the script, its checksum and its provenance attestation to the release and publishes it
 
 
-## Security audit
-
-`.github/workflows/audit.yml` runs OpenSSF Scorecard, CodeQL and, on PHP
-projects, Semgrep. The results appear under **Security > Code scanning** in the
-GitHub repository.
-
-
 ## Documentation
 
 If using the documentation site (Docusaurus):
