@@ -235,15 +235,6 @@
 Documentation deploys automatically on releases via GitHub Actions.
 
 
-## Architecture Documentation
-
-Architecture documentation lives in `docs/content/architecture/`. It is generated and maintained by an AI agent via the `update-architecture-docs` skill in `.claude/skills/update-architecture-docs/SKILL.md`.
-
-After any structural change to the codebase, update it by invoking the skill (say "update architecture docs").
-
-The content is derived from the source code. If the documentation and the code disagree, the code wins.
-
-
 ## Updating from the template
 
 This project was generated from a template and can pull the template's latest
