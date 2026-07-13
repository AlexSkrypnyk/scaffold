'use strict';

/**
 * @file
 * Shared helpers for the nodejs-script tests.
 */

const path = require('node:path');
const { spawnSync } = require('node:child_process');

/**
 * Absolute path to the script under test.
 *
 * @type {string}
 */
const SCRIPT = path.join(__dirname, '..', '..', 'nodejs-script');

/**
 * Restore an environment variable to a previous value.
 *
 * @param {string} name
 *   Environment variable name.
 * @param {string|undefined} value
 *   Value to restore, or undefined to unset it.
 */
function restoreEnv(name, value) {
  if (value === undefined) {
    delete process.env[name];
  } else {
    process.env[name] = value;
  }
}

/**
 * Run main() in-process with optional arguments and return the verbose buffer.
 *
 * The script is required rather than executed, so main() can be invoked
 * directly and its buffered output asserted without spawning a process. A fresh
 * copy is loaded on every call so the internal buffer does not accumulate output
 * across invocations, and the environment is restored afterwards.
 *
 * @param {string|string[]} args
 *   Optional arguments to pass to the script.
 *
 * @return {string[]}
 *   Array of output messages.
 */
function runMain(args = []) {
  const previousRunSkip = process.env.SCRIPT_RUN_SKIP;
  const previousQuiet = process.env.SCRIPT_QUIET;

  try {
    // Prevent the script from running on require and log output into the
    // internal buffer instead of stdout so it can be asserted.
    process.env.SCRIPT_RUN_SKIP = '1';
    process.env.SCRIPT_QUIET = '1';

    delete require.cache[require.resolve(SCRIPT)];
    const script = require(SCRIPT);

    args = Array.isArray(args) ? args : [args];
    const argv = [SCRIPT, ...args].filter(Boolean);
    script.main(argv, argv.length);

    return script.verbose('');
  } finally {
    restoreEnv('SCRIPT_RUN_SKIP', previousRunSkip);
    restoreEnv('SCRIPT_QUIET', previousQuiet);
  }
}

/**
 * Run the script as a separate process with optional arguments.
 *
 * @param {string|string[]} args
 *   Optional arguments to pass to the script.
 *
 * @return {{code: number, output: string}}
 *   The exit code and the captured stdout.
 */
function runScript(args = []) {
  args = Array.isArray(args) ? args : [args];

  const result = spawnSync('node', [SCRIPT, ...args.filter(Boolean)], {
    encoding: 'utf8',
    env: { ...process.env, SCRIPT_RUN_SKIP: '0', SCRIPT_QUIET: '0' },
  });

  return { code: result.status, output: result.stdout };
}

module.exports = { SCRIPT, runMain, runScript };
