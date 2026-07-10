'use strict';

/**
 * @file
 * Unit tests for nodejs-script.
 */

const { test } = require('node:test');
const assert = require('node:assert');
const { runMain } = require('./_helper');

const cases = [
  { args: 'help', expected: 'NodeJS CLI script template.' },
  { args: '--help', expected: 'NodeJS CLI script template.' },
  { args: '-h', expected: 'NodeJS CLI script template.' },
  { args: '-?', expected: 'NodeJS CLI script template.' },
  {
    args: '-help',
    expected: 'Would execute script business logic with argument -help.',
  },
  { args: '', error: 'Please provide a value of the first argument.' },
  {
    args: 'testarg1',
    expected: 'Would execute script business logic with argument testarg1.',
  },
  {
    args: ['testarg1', 'testarg2'],
    error: 'Please provide a value of the first argument.',
  },
];

for (const item of cases) {
  test(`main() with ${JSON.stringify(item.args)}`, () => {
    if (item.error) {
      assert.throws(() => runMain(item.args), { message: item.error });

      return;
    }

    const output = runMain(item.args);
    assert.ok(
      output.some((line) => line.includes(item.expected)),
      `Expected output to contain "${item.expected}".`,
    );
  });
}
