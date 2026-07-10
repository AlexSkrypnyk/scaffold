#!/usr/bin/env php
<?php

/**
 * @file
 * Generate the animated SVG and asciicast recording of init.sh.
 *
 * Records an interactive `./init.sh` session against a throwaway copy of the
 * current git tree, then produces two artefacts from that single recording:
 *
 * - `.scaffold/assets/init.svg` - an animated SVG embedded in the README
 *   (GitHub renders animated SVG but cannot run JavaScript).
 * - `.scaffold/docs/static/img/init.cast` - an asciicast played by the
 *   Docusaurus `AsciinemaPlayer` component (interactive playback).
 *
 * `init.sh` rewrites the tree in place and deletes itself, so the recording
 * always runs in a disposable workspace exported with `git archive HEAD`.
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

// Terminal dimensions for the recording.
define('TERMINAL_COLS', 80);
define('TERMINAL_ROWS', 24);

// Delay before answering each prompt in the expect script (seconds).
define('PROMPT_DELAY', 1);

// Maximum idle time preserved between recorded events (seconds).
define('MAX_IDLE_TIME', 3);

// Pause appended after the last event so the SVG animation rests on the final
// frame before it loops (seconds).
define('END_PAUSE', 6);

// Recording identity values - shown in the recorded prompts and summary.
define('RECORD_NAMESPACE', 'MyNamespace');
define('RECORD_PROJECT', 'myproject');
define('RECORD_AUTHOR', 'Alex');

/**
 * Build the expect script that drives init.sh's interactive prompts.
 *
 * Types the three identity answers and accepts the default for every remaining
 * yes/no and name prompt, mirroring a "keep everything" run.
 *
 * @param string $workspace_dir
 *   Directory holding the disposable copy of init.sh.
 * @param string $namespace
 *   Value typed at the "Namespace" prompt.
 * @param string $project
 *   Value typed at the "Project" prompt.
 * @param string $author
 *   Value typed at the "Author" prompt.
 *
 * @return string
 *   The expect script contents.
 */
function buildInitExpectScript(string $workspace_dir, string $namespace, string $project, string $author): string {
  return <<<EXPECT
#!/usr/bin/env expect

set timeout 180
log_user 1

proc type_text {text} {
    set send_human {.1 .3 1 .05 2 .1 .2 0 .4 0 .6 0 .8 0 1}
    send -h -- \$text
}

proc accept_default {} {
    sleep 1
    send -- "\\r"
}

cd "{$workspace_dir}"

set env(PS1) {\$ }
spawn bash --norc --noprofile

expect "\\$ "
sleep 1
type_text "./init.sh"
accept_default

expect "Namespace (PascalCase):" {
    sleep 1
    type_text "{$namespace}"
    accept_default
}

expect "Project:" {
    sleep 1
    type_text "{$project}"
    accept_default
}

expect "Author:" {
    sleep 1
    type_text "{$author}"
    accept_default
}

expect "Use PHP" { accept_default }
expect "Use CLI command app" { accept_default }
expect "CLI command name" { accept_default }
expect "Build PHAR" { accept_default }
expect "Use NodeJS" { accept_default }
expect "Use Shell" { accept_default }
expect "Shell command name" { accept_default }
expect "Use Docker" { accept_default }
expect "Use GitHub release drafter" { accept_default }
expect "Use GitHub PR author auto-assign" { accept_default }
expect "Use GitHub funding" { accept_default }
expect "Use GitHub PR template" { accept_default }
expect "Use Renovate" { accept_default }
expect "Use docs" { accept_default }
expect "Use GitHub Actions linting" { accept_default }
expect "Use scheduled builds" { accept_default }
expect "Remove this script" { accept_default }
expect "Proceed with project init" { accept_default }

expect "\\$ "
send -- "exit\\r"
expect eof

EXPECT;
}

/**
 * Remove recording noise and sanitise absolute paths in a cast.
 *
 * Drops the `spawn` line echoed by expect and rewrites the workspace and home
 * directories to stable placeholders so the committed cast never leaks a local
 * path.
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
    $header['command'] = './init.sh';
    unset($header['timestamp'], $header['env']);
    $lines[0] = (string) json_encode($header);
  }

  $filtered = [$lines[0]];
  $count = count($lines);
  for ($i = 1; $i < $count; $i++) {
    if ($lines[$i] === '') {
      continue;
    }
    if (str_contains($lines[$i], 'spawn ')) {
      continue;
    }
    $filtered[] = $lines[$i];
  }

  $result = implode("\n", $filtered);
  $result = str_replace($workspace_dir, '/home/user/project', $result);
  if ($home !== '') {
    $result = str_replace($home, '/home/user', $result);
  }

  return rtrim($result, "\n") . "\n";
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

  verbose('Scaffold - init.sh recording generator');
  verbose('======================================');

  checkDependencies();
  installSvgTerm($assets_dir);

  $tmp_dir = $project_dir . '/.artifacts/tmp';
  if (!is_dir($tmp_dir)) {
    mkdir($tmp_dir, 0755, TRUE);
  }

  $workspace_dir = createWorkspace($project_dir, $tmp_dir);
  verbose('Workspace: ' . $workspace_dir);

  $expect_script = $tmp_dir . '/init.exp';
  file_put_contents($expect_script, buildInitExpectScript($workspace_dir, RECORD_NAMESPACE, RECORD_PROJECT, RECORD_AUTHOR));
  chmod($expect_script, 0755);

  $cast_file = $tmp_dir . '/init-raw.cast';
  verbose('Recording init.sh...');
  recordSession($cast_file, $expect_script);

  $raw = (string) file_get_contents($cast_file);
  $home = (string) getenv('HOME');
  $clean = sanitizeCast($raw, $workspace_dir, $home);

  $cast_dest = $project_dir . '/.scaffold/docs/static/img/init.cast';
  file_put_contents($cast_dest, $clean);
  verbose('Cast written: ' . $cast_dest);

  $svg_input = $tmp_dir . '/init-svg.cast';
  file_put_contents($svg_input, appendEndPause($clean, END_PAUSE));

  $svg_file = $assets_dir . '/init.svg';
  verbose('Rendering SVG...');
  renderSvg($svg_input, $svg_file, $assets_dir);
  verbose('SVG written: ' . $svg_file);

  removeDir($workspace_dir);
  cleanupFile($expect_script);
  cleanupFile($cast_file);
  cleanupFile($svg_input);

  verbose('Done.');
}

/**
 * Ensure all external tools required for recording are available.
 */
function checkDependencies(): void {
  $deps = ['asciinema', 'expect', 'node', 'npm'];
  $missing = [];

  foreach ($deps as $dep) {
    $path = trim((string) shell_exec('command -v ' . escapeshellarg($dep) . ' 2>/dev/null'));
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
 * in-progress init.sh) are recorded, falling back to HEAD when the tree is
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
  $workspace_dir = $tmp_dir . '/init-record-' . bin2hex(random_bytes(6));
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

  if (!is_file($workspace_dir . '/init.sh')) {
    throw new \RuntimeException('Failed to export git archive: ' . implode("\n", $output));
  }

  return $workspace_dir;
}

/**
 * Record an init.sh session with asciinema driven by an expect script.
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
function cleanupFile(string $file): void {
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

// Entrypoint.
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
