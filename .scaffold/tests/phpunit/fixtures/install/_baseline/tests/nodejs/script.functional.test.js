'use strict';

/**
 * @file
 * Functional tests for nodejs-script.
 */

const { test } = require('node:test');
const assert = require('node:assert');
const { runScript } = require('./_helper');

const EXIT_SUCCESS = 0;
const EXIT_ERROR = 1;

const cases = [
  { args: 'help', code: EXIT_SUCCESS, expected: 'NodeJS CLI script template.' },
  {
    args: '--help',
    code: EXIT_SUCCESS,
    expected: 'NodeJS CLI script template.',
  },
  { args: '-h', code: EXIT_SUCCESS, expected: 'NodeJS CLI script template.' },
  { args: '-?', code: EXIT_SUCCESS, expected: 'NodeJS CLI script template.' },
  {
    args: '-help',
    code: EXIT_SUCCESS,
    expected: 'Would execute script business logic with argument -help.',
  },
  {
    args: '',
    code: EXIT_ERROR,
    expected: 'Please provide a value of the first argument.',
  },
  {
    args: 'testarg1',
    code: EXIT_SUCCESS,
    expected: 'Would execute script business logic with argument testarg1.',
  },
  {
    args: ['testarg1', 'testarg2'],
    code: EXIT_ERROR,
    expected: 'Please provide a value of the first argument.',
  },
];

for (const item of cases) {
  test(`nodejs-script with ${JSON.stringify(item.args)}`, () => {
    const result = runScript(item.args);
    assert.strictEqual(result.code, item.code);
    assert.ok(
      result.output.includes(item.expected),
      `Expected output to contain "${item.expected}".`,
    );
  });
}
