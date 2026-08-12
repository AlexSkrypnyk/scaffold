@@ -1,11 +1,11 @@
 ---
 name: update-architecture-docs
-description: Generate or update the architecture documentation in docs/content/architecture/. Use on "update architecture docs", "generate architecture documentation", "regenerate architecture docs", or after any structural change to the codebase.
+description: Generate or update the architecture documentation in docs/architecture/. Use on "update architecture docs", "generate architecture documentation", "regenerate architecture docs", or after any structural change to the codebase.
 ---
 
 # Update architecture docs
 
-`docs/content/architecture/README.md` is a narrative walkthrough of how this project works: what the main components are and how the primary data and control flows run through them, with diagrams embedded at the points in the story they support. It is a walkthrough, not an index.
+`docs/architecture/README.md` is a narrative walkthrough of how this project works: what the main components are and how the primary data and control flows run through them, with diagrams embedded at the points in the story they support. It is a walkthrough, not an index.
 
 All content is derived from the actual source code: sources, entry scripts, manifests, and CI workflows. Never derive content from wishes, plans, or design documents. If the documentation and the code disagree, the code wins.
 
@@ -13,7 +13,7 @@
 
 1. Analyze the codebase: entry points, sources, manifests, and workflows.
 2. Identify the main components and the 1-3 primary data or control flows.
-3. Write `docs/content/architecture/README.md` as a walkthrough with one component diagram for the overall structure and one sequence or flow diagram per primary flow, each embedded where the prose discusses it.
+3. Write `docs/architecture/README.md` as a walkthrough with one component diagram for the overall structure and one sequence or flow diagram per primary flow, each embedded where the prose discusses it.
 4. Give each diagram a comment naming the source files it was traced from.
 
 ## Task B: update after a structural change
@@ -25,5 +25,5 @@
 
 ## Diagram format: Mermaid
 
-Diagrams are fenced code blocks with the `mermaid` language tag inside `docs/content/architecture/README.md`: `flowchart` or `graph` for structure, `sequenceDiagram` for flows. Put the traced-from annotation in a `%%` comment at the top of each block. No toolchain is needed: GitHub renders Mermaid natively and theme-aware.
+Diagrams are fenced code blocks with the `mermaid` language tag inside `docs/architecture/README.md`: `flowchart` or `graph` for structure, `sequenceDiagram` for flows. Put the traced-from annotation in a `%%` comment at the top of each block. No toolchain is needed: GitHub renders Mermaid natively and theme-aware.
 
