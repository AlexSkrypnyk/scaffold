# Playground

The scripts in this directory run `install.sh` against real GitHub repositories, for manual checks before a release. CI doesn't run them, and `install.sh` deletes `.scaffold/`, so they never reach a generated project.

## Before you begin

- Install [GitHub CLI](https://cli.github.com) so `gh` is on your `PATH`.
- Set `SCAFFOLD_GITHUB_TOKEN` to a token that can manage the test repository. The token permissions are on the [GitHub repository setup](https://getscaffold.dev/github) page.
- Optional: set `PLAYGROUND_GITHUB_OWNER` to run against an account other than `AlexSkrypnyk`.

Each script exits with code 1 when `gh` or the token is missing, because a run that skips the GitHub step checks nothing.

## Scripts

The directory holds these scripts:

| Script | What it does |
|---|---|
| `update.sh` | Runs `./install.sh github` against `<owner>/scaffold-test-install`. Every run reuses that repository, so repeat runs show whether each section is safe to run again. Create it by hand before the first run. |
| `_helper.sh` | Holds the shared helpers: the repository root, the prerequisite check, the work directory and the summary. |

Every script follows 3 rules:

- It takes `install.sh` from the current `HEAD`, so commit your changes before a run.
- It works in a new `.artifacts/playground/<script>-<timestamp>/` directory and keeps that directory for inspection or a manual re-run.
- It passes any extra arguments to `install.sh`.

To print the changes `update.sh` would make without applying them, run the following command:

```bash
.scaffold/tests/playground/update.sh --dry-run
```

## Clean up

To delete the work directories, run `rm -Rf .artifacts/playground`. The test repository stays on GitHub for the next run.
