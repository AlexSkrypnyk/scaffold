@@ -23,7 +23,15 @@
 3. Update the surrounding prose in the same pass so the visuals and the prose agree.
 
 
-## Diagram format: Mermaid
+## Diagram format: PlantUML
 
-Diagrams are fenced code blocks with the `mermaid` language tag inside `docs/content/architecture/README.md`: `flowchart` or `graph` for structure, `sequenceDiagram` for flows. Put the traced-from annotation in a `%%` comment at the top of each block. No toolchain is needed: GitHub renders Mermaid natively and theme-aware.
+Diagrams are `.puml` sources in `docs/content/architecture/`, rendered to committed light `.svg` files that `README.md` embeds as images. Put the traced-from annotation in a `'` comment at the top of each `.puml` file.
+
+### Prerequisite
+
+Before rendering, run `plantuml -version`. If PlantUML is not installed: stop before rendering, report to the user explicitly that the SVGs were not regenerated, and give install instructions (`brew install plantuml` on macOS, `apt-get install plantuml` on Debian/Ubuntu). Prose and `.puml` edits may still proceed.
+
+### Rendering
+
+Render with `plantuml -tsvg docs/content/architecture/*.puml`. Commit both the `.puml` sources and the generated `.svg` files.
 
