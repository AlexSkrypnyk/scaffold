---
name: update-consumer-scaffold
description: Update a project created from the Scaffold template to the latest version of the Scaffold
user-invocable: true
---

# Update Scaffold

When this skill is triggered, follow the steps below to update the current
project's infrastructure to the latest version of the
[Scaffold](https://github.com/AlexSkrypnyk/scaffold) template
([getscaffold.dev](https://getscaffold.dev)).

The strategy is: download a fresh copy of the latest Scaffold, re-run its
`init.sh` with the answers this project was originally created with, then restore
the project's own code on top. This refreshes the template-managed
infrastructure (CI workflows, linting and test configuration, docs scaffolding,
Docker, etc.) without discarding the project's source code.

## Step 0: Ensure required permissions

This skill requires several Bash commands to run without prompts. Before doing
anything else, read `.claude/settings.local.json` (create it if it does not
exist) and ensure the following entries are present in `permissions.allow`. Add
only the missing ones:

```json
[
  "Bash(cat:*)",
  "Bash(composer:*)",
  "Bash(cp:*)",
  "Bash(curl:*)",
  "Bash(find:*)",
  "Bash(gh:*)",
  "Bash(git:*)",
  "Bash(grep:*)",
  "Bash(ls:*)",
  "Bash(mkdir:*)",
  "Bash(mv:*)",
  "Bash(npm:*)",
  "Bash(php:*)",
  "Bash(rm:*)",
  "Bash(sed:*)",
  "Bash(tar:*)",
  "Bash(./init.sh)"
]
```

If any entries were added, tell the user what was added and ask them to restart
the session. Permissions are loaded at startup, so changes made mid-session do
not take effect. **STOP here and do not continue** - the user must restart
Claude Code and re-invoke the skill for the new permissions to apply.

If all entries are already present, proceed to Step 1.

## Step 1: Detect the original init answers

Inspect the initialised project to reconstruct the answers it was created with.
These map directly to `init.sh` options (run `./init.sh --help` on a fresh
checkout for the full list).

**Identity:**

1. **Namespace** (PascalCase, e.g. `AcmeApp`): the PSR-4 prefix in
   `composer.json` `autoload.psr-4` - the segment before `\App\` (e.g.
   `"AcmeApp\\App\\"` -> `AcmeApp`). If there is no `composer.json`, derive it
   from the `package.json` scope (`@acmeapp/...`) or ask the user.
2. **Name** (kebab-case, e.g. `acme-app`): the part after `/` in the
   `composer.json` `name` field, or the `package.json` `name`, or the
   command/script/shell file name. If unclear, ask the user.
3. **Author**: `composer.json` `authors[0].name`, falling back to
   `git config user.name`. If unclear, ask the user.

**Features** (detect from file/directory presence):

| Option                      | Enabled when                                                |
|-----------------------------|-------------------------------------------------------------|
| `--php` / `--no-php`        | `composer.json` exists                                      |
| `--php-command`             | `src/` directory exists with command classes                |
| `--php-script`              | a single-file PHP bin exists and there is no `src/`         |
| `--phar` / `--no-phar`      | `box.json` exists                                           |
| `--nodejs` / `--no-nodejs`  | `package.json` exists                                       |
| `--shell` / `--no-shell`    | a `*.sh` command file and `tests/bats/` exist               |
| `--docker` / `--no-docker`  | `Dockerfile` exists                                         |
| `--release-drafter`         | `.github/workflows/draft-release-notes.yml` exists          |
| `--pr-autoassign`           | `.github/workflows/assign-author.yml` exists                |
| `--funding`                 | `.github/FUNDING.yml` exists                                |
| `--pr-template`             | `.github/PULL_REQUEST_TEMPLATE.md` exists                   |
| `--renovate`                | `renovate.json` exists                                      |
| `--docs`                    | `docs/` directory exists                                    |

**Custom names** (only when they differ from the project name):

- `--php-command-name=<file>` - the PHP CLI command file (the Symfony Console
  application entry point).
- `--php-script-name=<file>` - the single-file PHP script.
- `--shell-command-name=<file>` - the `*.sh` file name without the extension.
- `--docker-image-name=<image>` - read from the `Dockerfile`/CI, defaulting to
  `<namespace-lowercase>/<name>`.

Also detect the repository **default branch** (not the current checkout):

```bash
git symbolic-ref --short refs/remotes/origin/HEAD
```

Strip the `origin/` prefix from the result. If `origin/HEAD` is not set, fall
back to the branch CI runs on (see `.github/workflows/`), defaulting to `main`.

## Step 2: Get the latest Scaffold version and confirm

```bash
gh release list --repo AlexSkrypnyk/scaffold --limit 5
```

Pick the latest non-draft release. **Print the version and the full `init.sh`
command you assembled in Step 1, and confirm both with the user before making
any changes.** This is the single most important checkpoint - the rest of the
process is destructive to the working tree.

If the repository has no releases, fall back to the default-branch tarball in
Step 5 (`https://github.com/AlexSkrypnyk/scaffold/archive/refs/heads/main.tar.gz`)
and label the update with the short commit SHA instead of a version.

## Step 3: Prepare the feature branch

Ensure the working tree is clean and on the default branch, then branch off it.
This step is **mandatory** - never apply scaffold changes directly to the
default branch.

```bash
git switch <default_branch>
```

```bash
git pull
```

```bash
git switch -c feature/update-scaffold-<version>
```

## Step 4: Clean the project root

Delete everything in the project root **except** `.git/`, `.claude/` and
`.idea/`. The project's own code is recovered from git in Step 7.

**IMPORTANT:** This command MUST use a relative path (`.`) and be run from the
project root. Using an absolute path causes `-name '.'` to fail to match the
root directory, which results in the root directory itself (including `.git/`)
being deleted. Ensure the shell working directory is the project root before
running this command.

```bash
find . -maxdepth 1 ! -name '.' ! -name '.git' ! -name '.claude' ! -name '.idea' -exec rm -rf {} +
```

## Step 5: Download and extract the Scaffold

Download the release archive into the project root:

```bash
gh release download <version> --repo AlexSkrypnyk/scaffold --archive tar.gz --output scaffold.tar.gz
```

```bash
tar -xzf scaffold.tar.gz --strip-components=1
```

```bash
rm scaffold.tar.gz
```

(If the repository has no releases, download
`https://github.com/AlexSkrypnyk/scaffold/archive/refs/heads/main.tar.gz` with
`curl -fsSL ... -o scaffold.tar.gz` instead, then extract the same way.)

## Step 6: Run init.sh

Run `init.sh` from the project root, non-interactively, passing **every**
detected choice explicitly (identity plus each feature's on/off state and any
custom names). Passing options switches `init.sh` to non-interactive mode.

Example for a project that uses every default feature:

```bash
./init.sh --namespace=AcmeApp --name=acme-app --author="Jane Doe"
```

Example for a shell-only project with a custom command name and no docs:

```bash
./init.sh --namespace=AcmeApp --name=acme-app --author="Jane Doe" --no-php --no-nodejs --shell --shell-command-name=acme --no-docs
```

Build the command from the Step 1 detection. Do not pass `--keep`: the refreshed
`init.sh` should be removed exactly as it was on the initial setup.

## Step 7: Restore project-specific code from git

The extraction replaced everything, including the project's own code. Restore it
from the previous commit. Only restore paths that exist - skip any that error:

```bash
git checkout HEAD -- src tests README.md LICENSE
```

Add any other project-owned paths (the renamed command/script/shell files, CSS,
JS, config, etc.) to that command.

**Do not blindly restore `composer.json` or `package.json`.** They contain both
the project's dependencies and the template's refreshed infrastructure
(dev-dependencies, scripts). Treat them as a three-way merge: keep the project's
`require` / `autoload` entries, and take the template's updated dev-dependencies
and scripts. Review the diff with `git diff HEAD -- composer.json` and reconcile
by hand.

## Step 8: Review changes

Use `git status` and `git diff` to review everything. Pay attention to:

- **Branch references**: replace the scaffold default branch with the project's
  default branch in workflow files and the README where needed.
- **Removed files**: confirm that any files `git status` shows as deleted are
  genuinely retired by the new Scaffold version, not project files that should
  have been restored in Step 7.
- **New files**: review new template files and remove example stubs the project
  does not need (e.g. example commands or tests it never used).
- **README.md**: re-apply any structural changes from the template while keeping
  the project's own content.

## Step 9: Commit

Stage all changes and commit:

```bash
git add -A
```

```bash
git commit -m "Updated scaffold to <version>."
```

## Step 10: Build, lint, and test

Run the project's quality gates through its wrapper and fix everything they
report - both warnings and failures. Use the commands that apply to the
project's selected features:

```bash
composer install
```

```bash
composer lint
```

```bash
composer test
```

For NodeJS projects also run `npm install` and `npm run lint` / `npm test`; for
shell projects run the BATS suite
(`./tests/bats/node_modules/.bin/bats tests/bats`). Commit each fix as a
separate commit.

## Step 11: Open the PR

Push the branch and open a pull request summarising the update (use the
`/open-pr` skill if available).

## Important notes

- Always confirm the version and the assembled `init.sh` command with the user
  before starting (Step 2).
- Never overwrite project-specific code: `src/`, tests, the renamed
  command/script/shell files, and project documentation are restored from git in
  Step 7.
- `init.sh` deletes `.scaffold/`, `init.sh`, `LICENSE` and other
  template-only files - the same way it did on the initial setup. Restore the
  project's own `LICENSE` from git if it kept one.
- After the update, verify workflow branch references match the project's
  default branch.
- Prefer the project's wrapper commands (`composer ...`, `npm ...`) over calling
  the underlying tools directly.

## Command pattern rules

Run commands so they match the allowed permission prefixes and never trigger
approval prompts.

NEVER use compound or composite commands in a single Bash tool call. Every Bash
call must contain exactly ONE simple command. No exceptions.

**NEVER use:** `&&`, `||`, `;`, `|`, `<<<`, `$(...)`, heredocs.

**ALWAYS:**

- Use multiple separate Bash tool calls, one command per call.
- Use non-interactive flags or options for scripts that support them (e.g.
  `composer --no-interaction`, the `--namespace=`/`--name=`/`--author=` and
  feature options for `init.sh`).
- For git commits, use `git commit -m "Message here."`.
