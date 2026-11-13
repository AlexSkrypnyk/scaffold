#!/usr/bin/env php
<?php

/**
 * @file
 * Generate the animated SVG and asciicast recordings of install.sh.
 *
 * Records 2 interactive `./install.sh` sessions against throwaway copies of
 * the current git tree: `install` declines to create a GitHub repository, and
 * `install-github` creates one. Each recording produces 2 artefacts:
 *
 * - `.scaffold/assets/<name>.svg` - an animated SVG embedded in the README
 *   (GitHub renders animated SVG but cannot run JavaScript).
 * - `.scaffold/docs/static/img/<name>.cast` - an asciicast played by the
 *   Docusaurus `AsciinemaPlayer` component (interactive playback).
 *
 * `install.sh` rewrites the tree in place and deletes itself, so each
 * recording runs in a disposable workspace exported with `git archive HEAD`.
 * The stand-ins in `record-bin/` replace `gh` and `git push`, so the GitHub
 * steps never reach GitHub.
 *
 * The recorded timing is discarded: the cast is rebuilt with 1 event per
 * answered prompt at a fixed interval, so regenerating an unchanged session
 * produces identical bytes.
 *
 * Dependencies: asciinema, expect, node, npm.
 *
 * Environment variables:
 * - SCRIPT_QUIET: Set to '1' to suppress progress messages.
 * - SCRIPT_RUN_SKIP: Set to '1' to define the helpers without running the
 *   generator. Used when unit-testing the pure helpers.
 *
 * Usage:
 * @code
 * php .scaffold/assets/update-assets.php
 * @endcode
 */

declare(strict_types=1);

define('TERMINAL_COLS', 80);
define('TERMINAL_ROWS', 24);

// Maximum idle time preserved between recorded events (seconds).
define('MAX_IDLE_TIME', 3);

// Rendered gap between one step and the next (seconds).
define('STEP_DELAY', 1);

// Written by the expect script before each answer, so the cast can be cut
// into steps where the session waited for input. An OSC sequence with no
// meaning to a terminal, and stripped before the cast is committed.
define('STEP_MARKER', "\033]scaffold-step\007");

// Pause appended after the last event so the SVG animation rests on the final
// frame before it loops (seconds).
define('END_PAUSE', 6);

// Recording identity values - shown in the recorded prompts and summary.
define('RECORD_NAMESPACE', 'MyNamespace');
define('RECORD_PROJECT', 'myproject');
define('RECORD_AUTHOR', 'Alex');

// GitHub login the stand-in 'gh' reports, shown as the default owner.
define('RECORD_LOGIN', 'my-org');

// Recordings to generate: file name => whether the session creates a GitHub
// repository.
define('RECORDINGS', [
  'install' => FALSE,
  'install-github' => TRUE,
]);

/**
 * Build the expect script that drives install.sh's interactive prompts.
 *
 * Types the three identity answers and accepts the default for every remaining
 * prompt, mirroring a "keep everything" run. With $create_repo, the session
 * also answers "y" to creating a GitHub repository; without it, the session
 * declines.
 *
 * Each answer is sent in 1 write after STEP_MARKER, so the session reaches the
 * terminal identically on every run. Expect writes out all output it has read
 * before the answer runs, so the marker lands where the session waited. A
 * prompt is matched up to its trailing ": ", so the marker never lands inside
 * a prompt that arrived in 2 reads.
 *
 * @param string $workspace_dir
 *   Directory holding the disposable copy of install.sh.
 * @param string $namespace
 *   Value typed at the "Namespace" prompt.
 * @param string $project
 *   Value typed at the "Project" prompt.
 * @param string $author
 *   Value typed at the "Author" prompt.
 * @param array<string, string> $env
 *   Environment variables set in the recorded shell.
 * @param bool $create_repo
 *   Whether to accept the "Create a GitHub repository" prompt.
 *
 * @return string
 *   The expect script contents.
 */
function buildInitExpectScript(string $workspace_dir, string $namespace, string $project, string $author, array $env = [], bool $create_repo = FALSE): string {
  $marker = STEP_MARKER;

  $env_lines = '';
  foreach ($env as $name => $value) {
    $env_lines .= sprintf("set env(%s) {%s}\n", $name, $value);
  }

  $github = $create_repo ? implode("\n", [
    'reply "Create a GitHub repository" "y"',
    'reply "GitHub owner"',
    'reply "GitHub repository"',
    'reply "Visibility"',
    'reply "Apply general settings"',
    'reply "Description"',
    'reply "Apply labels"',
    'reply "Delete labels not in the list"',
    'reply "Protect the default branch with a ruleset"',
    'reply "Wait for the first CI run and require its checks"',
  ]) : 'reply "Create a GitHub repository"';

  return <<<EXPECT
#!/usr/bin/env expect

set timeout 180
log_user 1

proc answer {{text ""}} {
    send_user "{$marker}"
    send -- "\$text\\r"
}

proc reply {label {text ""}} {
    expect "\$label*: " { answer \$text }
}

cd "{$workspace_dir}"

set env(PS1) {\$ }
{$env_lines}spawn bash --norc --noprofile

expect "\\$ " { answer "./install.sh" }
reply "Namespace (PascalCase)" "{$namespace}"
reply "Project" "{$project}"
reply "Author" "{$author}"
reply "Use PHP"
reply "Use CLI command app"
reply "CLI command name"
reply "Build PHAR"
reply "Use NodeJS"
reply "Use Shell"
reply "Shell command name"
reply "Use Docker"
reply "Use GitHub release drafter"
reply "Use GitHub PR author auto-assign"
reply "Use GitHub funding"
reply "Use GitHub PR template"
reply "Use Renovate"
reply "Use docs"
reply "Use GitHub Actions linting"
reply "Use security audit"
reply "Use scheduled builds"
reply "Use Windows in CI"
reply "Use AI agents"
reply "AI architecture docs"
reply "Remove this script"
{$github}
reply "Proceed with project init"
expect "\\$ " { answer "exit" }
expect eof

EXPECT;
}

/**
 * Neutralise the header and sanitise absolute paths in a cast.
 *
 * Rewrites the workspace and home directories to stable placeholders so the
 * committed cast never leaks a local path.
 *
 * @param string $content
 *   Raw asciicast content (newline-delimited JSON).
 * @param string $workspace_dir
 *   Absolute workspace path to replace with a placeholder.
 * @param string $home
 *   Absolute home directory path to replace with a placeholder.
 *
 * @return string
 *   The sanitised cast content, terminated with a newline.
 */
function sanitizeCast(string $content, string $workspace_dir, string $home): string {
  $lines = explode("\n", $content);
  if ($lines === []) {
    return $content;
  }

  // Neutralise the header metadata: the recorded `command` embeds the local
  // path to the expect script, and `timestamp`/`env` change every run and would
  // churn the committed cast on each regeneration.
  $header = json_decode($lines[0], TRUE);
  if (is_array($header)) {
    $header['command'] = './install.sh';
    unset($header['timestamp'], $header['env']);
    $lines[0] = (string) json_encode($header);
  }

  $result = implode("\n", array_filter($lines, static fn(string $line): bool => $line !== ''));
  $result = str_replace($workspace_dir, '/home/user/project', $result);
  if ($home !== '') {
    $result = str_replace($home, '/home/user', $result);
  }

  return rtrim($result, "\n") . "\n";
}

/**
 * Rewrite a v2 cast onto a canonical timeline.
 *
 * The recorded events follow how the terminal chunked its output and when
 * the scheduler delivered it, so 2 runs of an unchanged session differ in
 * both events and timestamps.
 *
 * The output is joined into 1 stream and cut at each STEP_MARKER, which the
 * expect script writes where the session waited for input. Each step becomes
 * 1 event, STEP_DELAY seconds after the previous one. Non-output events are
 * dropped.
 *
 * @param string $content
 *   Asciicast v2 content (newline-delimited JSON), the header first.
 *
 * @return string
 *   The canonical cast content, terminated with a newline.
 */
function canonicalizeCast(string $content): string {
  $lines = explode("\n", rtrim($content, "\n"));
  $header = array_shift($lines);
  $stream = '';

  foreach ($lines as $line) {
    $event = json_decode($line, TRUE);

    if (!is_array($event) || ($event[1] ?? NULL) !== 'o' || !is_string($event[2] ?? NULL)) {
      continue;
    }

    $stream .= $event[2];
  }

  $steps = array_values(array_filter(explode(STEP_MARKER, stripSpawnEcho($stream)), static fn(string $step): bool => $step !== ''));

  $canonical = [$header];
  foreach ($steps as $index => $step) {
    $canonical[] = json_encode([$index * STEP_DELAY, 'o', $step], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
  }

  return implode("\n", $canonical) . "\n";
}

/**
 * Remove the expect spawn echo from the head of a session's output.
 *
 * Expect prints the command it spawns, so a recording starts with a line
 * from the harness rather than the session. The echo ends at the first line
 * break.
 *
 * @param string $stream
 *   The session's output.
 *
 * @return string
 *   The output past the echo.
 */
function stripSpawnEcho(string $stream): string {
  if (!str_starts_with($stream, 'spawn ')) {
    return $stream;
  }

  $break = strpos($stream, "\n");

  return $break === FALSE ? $stream : substr($stream, $break + 1);
}

/**
 * Append a resting pause after the final event of a v2 cast.
 *
 * Adds a no-op output event `pause` seconds after the last recorded event so
 * the looping SVG animation holds on the final frame instead of snapping back.
 *
 * @param string $content
 *   Asciicast content with absolute (v2) timestamps.
 * @param int $pause
 *   Number of seconds to hold after the last event.
 *
 * @return string
 *   The cast content with the trailing pause event, terminated with a newline.
 */
function appendEndPause(string $content, int $pause): string {
  $lines = explode("\n", rtrim($content, "\n"));
  if (count($lines) < 2) {
    return $content;
  }

  $last_time = 0.0;
  foreach ($lines as $idx => $line) {
    if ($idx === 0 || $line === '') {
      continue;
    }
    $event = json_decode($line, TRUE);
    if (is_array($event) && isset($event[0]) && is_numeric($event[0])) {
      $last_time = (float) $event[0];
    }
  }

  $lines[] = (string) json_encode([round($last_time + $pause, 6), 'o', ' ']);

  return implode("\n", $lines) . "\n";
}

/**
 * Main functionality.
 */
function main(): void {
  $script_dir = dirname(__FILE__);
  $project_dir = dirname($script_dir, 2);
  $assets_dir = $script_dir;

  verbose('Scaffold - install.sh recording generator');
  verbose('======================================');

  checkDependencies();
  installSvgTerm($assets_dir);

  $tmp_dir = $project_dir . '/.artifacts/tmp';
  if (!is_dir($tmp_dir)) {
    mkdir($tmp_dir, 0755, TRUE);
  }

  foreach (RECORDINGS as $name => $create_repo) {
    recordInstall($name, $create_repo, $project_dir, $assets_dir, $tmp_dir);
  }

  verbose('Done.');
}

/**
 * Record 1 install.sh session and write its cast and SVG.
 *
 * @param string $name
 *   File name of the cast and the SVG, without the extension.
 * @param bool $create_repo
 *   Whether the session creates a GitHub repository.
 * @param string $project_dir
 *   Path to the repository root.
 * @param string $assets_dir
 *   Directory that receives the SVG and holds the stand-ins.
 * @param string $tmp_dir
 *   Path to the temporary directory.
 */
function recordInstall(string $name, bool $create_repo, string $project_dir, string $assets_dir, string $tmp_dir): void {
  $workspace_dir = createWorkspace($project_dir, $tmp_dir);
  verbose('Workspace: ' . $workspace_dir);

  $state_dir = $workspace_dir . '-state';
  mkdir($state_dir, 0755, TRUE);

  // A fixed git identity keeps the recorded session independent of the
  // maintainer's git config.
  $gitconfig = $state_dir . '/gitconfig';
  file_put_contents($gitconfig, "[user]\n\tname = " . RECORD_AUTHOR . "\n\temail = author@example.com\n");

  // A token in the maintainer's shell is replaced, and every 'gh' call goes to
  // the stand-in.
  $env = [
    'PATH' => $assets_dir . '/record-bin:' . getenv('PATH'),
    'SCAFFOLD_GITHUB_TOKEN' => 'recording-token',
    'SCAFFOLD_RECORD_LOGIN' => RECORD_LOGIN,
    'SCAFFOLD_RECORD_REPO' => RECORD_PROJECT,
    'SCAFFOLD_RECORD_STATE' => $state_dir,
    // The recorded shell runs in the workspace, so a relative path would break.
    'SCAFFOLD_RECORD_GIT' => (string) realpath(trim((string) shell_exec('command -v git'))),
    'GIT_CONFIG_GLOBAL' => $gitconfig,
    'GIT_CONFIG_NOSYSTEM' => '1',
  ];

  $expect_script = $tmp_dir . '/' . $name . '.exp';
  $cast_file = $tmp_dir . '/' . $name . '-raw.cast';
  $svg_input = $tmp_dir . '/' . $name . '-svg.cast';

  try {
    file_put_contents($expect_script, buildInitExpectScript($workspace_dir, RECORD_NAMESPACE, RECORD_PROJECT, RECORD_AUTHOR, $env, $create_repo));
    chmod($expect_script, 0755);

    verbose('Recording ' . $name . '...');
    recordSession($cast_file, $expect_script);

    $raw = (string) file_get_contents($cast_file);
    $home = (string) getenv('HOME');
    $clean = canonicalizeCast(sanitizeCast($raw, $workspace_dir, $home));

    $cast_dest = $project_dir . '/.scaffold/docs/static/img/' . $name . '.cast';
    file_put_contents($cast_dest, $clean);
    verbose('Cast written: ' . $cast_dest);

    file_put_contents($svg_input, appendEndPause($clean, END_PAUSE));

    $svg_file = $assets_dir . '/' . $name . '.svg';
    verbose('Rendering SVG...');
    renderSvg($svg_input, $svg_file, $assets_dir);
    verbose('SVG written: ' . $svg_file);
  }
  finally {
    removeDir($workspace_dir);
    removeDir($state_dir);
    removeFile($expect_script);
    removeFile($cast_file);
    removeFile($svg_input);
  }
}

/**
 * Ensure all external tools required for recording are available.
 */
function checkDependencies(): void {
  $deps = ['asciinema', 'expect', 'node', 'npm'];
  $missing = [];

  foreach ($deps as $dep) {
    $path = trim((string) shell_exec(sprintf('command -v %s 2>/dev/null', escapeshellarg($dep))));
    if ($path === '') {
      $missing[] = $dep;
    }
  }

  if ($missing !== []) {
    throw new \RuntimeException('Missing required dependencies: ' . implode(', ', $missing));
  }
}

/**
 * Install the svg-term renderer dependency on demand.
 *
 * @param string $assets_dir
 *   Directory containing svg-term-render.js and the on-demand node_modules.
 */
function installSvgTerm(string $assets_dir): void {
  if (is_dir($assets_dir . '/node_modules/svg-term')) {
    return;
  }

  verbose('Installing svg-term...');
  shell_exec(sprintf('npm install --prefix %s svg-term@1.3.1 2>&1', escapeshellarg($assets_dir)));

  if (!is_dir($assets_dir . '/node_modules/svg-term')) {
    throw new \RuntimeException('Failed to install svg-term.');
  }
}

/**
 * Export the current git tree into a disposable workspace directory.
 *
 * Uses `git stash create` so uncommitted changes to tracked files (e.g. an
 * in-progress install.sh) are recorded, falling back to HEAD when the tree is
 * clean. `git stash create` only builds stash commit objects - it never
 * touches the working tree or the stash list.
 *
 * @param string $project_dir
 *   Path to the repository root.
 * @param string $tmp_dir
 *   Path to the temporary directory that holds the workspace.
 *
 * @return string
 *   Path to the created workspace directory.
 */
function createWorkspace(string $project_dir, string $tmp_dir): string {
  $workspace_dir = $tmp_dir . '/install-record-' . bin2hex(random_bytes(6));
  mkdir($workspace_dir, 0755, TRUE);

  $stash = trim((string) shell_exec(sprintf('git -C %s stash create 2>/dev/null', escapeshellarg($project_dir))));
  $ref = $stash !== '' ? $stash : 'HEAD';

  $cmd = sprintf(
    'git -C %s archive %s | tar -x -C %s 2>&1',
    escapeshellarg($project_dir),
    escapeshellarg($ref),
    escapeshellarg($workspace_dir)
  );

  $output = [];
  exec($cmd, $output);

  if (!is_file($workspace_dir . '/install.sh')) {
    throw new \RuntimeException('Failed to export git archive: ' . implode("\n", $output));
  }

  return $workspace_dir;
}

/**
 * Record an install.sh session with asciinema driven by an expect script.
 *
 * @param string $cast_file
 *   Path to write the recorded cast.
 * @param string $expect_script
 *   Path to the expect automation script.
 */
function recordSession(string $cast_file, string $expect_script): void {
  $cmd = sprintf(
    'asciinema rec --headless --overwrite --window-size %dx%d --idle-time-limit %d --output-format asciicast-v2 --command %s %s 2>&1',
    TERMINAL_COLS,
    TERMINAL_ROWS,
    MAX_IDLE_TIME,
    escapeshellarg('expect ' . $expect_script),
    escapeshellarg($cast_file)
  );

  $output = [];
  exec($cmd, $output);

  if (!is_file($cast_file)) {
    throw new \RuntimeException('Failed to record session: ' . implode("\n", $output));
  }
}

/**
 * Render an asciicast to an animated SVG with the custom renderer.
 *
 * @param string $cast_file
 *   Path to the input cast.
 * @param string $svg_file
 *   Path to write the rendered SVG.
 * @param string $assets_dir
 *   Directory containing svg-term-render.js.
 */
function renderSvg(string $cast_file, string $svg_file, string $assets_dir): void {
  $cmd = sprintf(
    'node %s %s %s --line-height 1.1 2>&1',
    escapeshellarg($assets_dir . '/svg-term-render.js'),
    escapeshellarg($cast_file),
    escapeshellarg($svg_file)
  );

  $output = [];
  exec($cmd, $output);

  if (!is_file($svg_file) || filesize($svg_file) === 0) {
    throw new \RuntimeException('Failed to render SVG: ' . implode("\n", $output));
  }
}

/**
 * Recursively remove a directory.
 *
 * @param string $directory
 *   Path to the directory to remove.
 */
function removeDir(string $directory): void {
  if (!is_dir($directory)) {
    return;
  }

  shell_exec(sprintf('rm -rf %s 2>&1', escapeshellarg($directory)));
}

/**
 * Remove a file if it exists.
 *
 * @param string $file
 *   Path to the file to remove.
 */
function removeFile(string $file): void {
  if (is_file($file)) {
    unlink($file);
  }
}

/**
 * Print a progress message unless output is suppressed.
 *
 * @param string $message
 *   The message to print.
 */
function verbose(string $message): void {
  if (getenv('SCRIPT_QUIET') === '1') {
    return;
  }

  fwrite(STDOUT, $message . PHP_EOL);
}

if (getenv('SCRIPT_RUN_SKIP') !== '1' && PHP_SAPI === 'cli' && empty($_SERVER['REMOTE_ADDR'])) {
  ini_set('display_errors', '1');

  set_error_handler(static function (int $severity, string $message, string $file, int $line): bool {
    if ((error_reporting() & $severity) === 0) {
      return FALSE;
    }
    throw new \ErrorException($message, 0, $severity, $file, $line);
  });

  try {
    main();
  }
  catch (\Throwable $exception) {
    fwrite(STDERR, 'ERROR: ' . $exception->getMessage() . PHP_EOL);
    exit(1);
  }
}
