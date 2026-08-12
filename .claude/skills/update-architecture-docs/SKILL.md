---
name: update-architecture-docs
description: Generate or update the architecture documentation in docs/content/architecture/. Use on "update architecture docs", "generate architecture documentation", "regenerate architecture docs", or after any structural change to the codebase.
---

# Update architecture docs

`docs/content/architecture/README.md` is a narrative walkthrough of how this project works: what the main components are and how the primary data and control flows run through them, with diagrams embedded at the points in the story they support. It is a walkthrough, not an index.

All content is derived from the actual source code: sources, entry scripts, manifests, and CI workflows. Never derive content from wishes, plans, or design documents. If the documentation and the code disagree, the code wins.

## Task A: first generation

1. Analyze the codebase: entry points, sources, manifests, and workflows.
2. Identify the main components and the 1-3 primary data or control flows.
3. Write `docs/content/architecture/README.md` as a walkthrough with one component diagram for the overall structure and one sequence or flow diagram per primary flow, each embedded where the prose discusses it.
4. Give each diagram a comment naming the source files it was traced from.

## Task B: update after a structural change

1. Identify the components and flows the change affected.
2. Re-trace the affected diagrams from the current code.
3. Update the surrounding prose in the same pass so the visuals and the prose agree.

[//]: # (#;< AI_ARCH_DOCS_MERMAID)

## Diagram format: Mermaid

Diagrams are fenced code blocks with the `mermaid` language tag inside `docs/content/architecture/README.md`: `flowchart` or `graph` for structure, `sequenceDiagram` for flows. Put the traced-from annotation in a `%%` comment at the top of each block. No toolchain is needed: GitHub renders Mermaid natively and theme-aware.

[//]: # (#;> AI_ARCH_DOCS_MERMAID)
[//]: # (#;< AI_ARCH_DOCS_PLANTUML)

## Diagram format: PlantUML

Diagrams are `.puml` sources in `docs/content/architecture/`, rendered to committed light `.svg` files that `README.md` embeds as images. Put the traced-from annotation in a `'` comment at the top of each `.puml` file.

### Prerequisite

Before rendering, run `plantuml -version`. If PlantUML is not installed: stop before rendering, report to the user explicitly that the SVGs were not regenerated, and give install instructions (`brew install plantuml` on macOS, `apt-get install plantuml` on Debian/Ubuntu). Prose and `.puml` edits may still proceed.

### Rendering

Render with `plantuml -tsvg docs/content/architecture/*.puml`. Commit both the `.puml` sources and the generated `.svg` files.

[//]: # (#;> AI_ARCH_DOCS_PLANTUML)
