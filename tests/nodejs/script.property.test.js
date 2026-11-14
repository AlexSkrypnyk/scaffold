'use strict';

/**
 * @file
 * Property-based tests for nodejs-script argument handling.
 */

const { test } = require('node:test');
const assert = require('node:assert');
const fc = require('fast-check');
const { runMain } = require('./_helper');

const HELP_FLAGS = ['help', '--help', '-h', '-?'];
const HELP_TITLE = 'NodeJS CLI script template.';

// runMain() drops empty arguments, so every generated argument is non-empty.
const argument = fc
  .string({ minLength: 1 })
  .filter((value) => !HELP_FLAGS.includes(value));

test('main() reports any single non-help argument as given', () => {
  fc.assert(
    fc.property(argument, (value) => {
      const output = runMain([value]);

      assert.deepStrictEqual(output, [
        `Would execute script business logic with argument ${value}.`,
        '',
      ]);
    }),
  );
});

test('main() prints help when any argument is a help flag', () => {
  fc.assert(
    fc.property(
      fc.array(argument, { maxLength: 4 }),
      fc.constantFrom(...HELP_FLAGS),
      fc.nat(),
      (values, flag, position) => {
        const args = [...values];
        args.splice(position % (args.length + 1), 0, flag);

        const output = runMain(args);

        assert.strictEqual(output.length, 2);
        assert.ok(output[0].startsWith(HELP_TITLE));
      },
    ),
  );
});

test('main() rejects 2 or more non-help arguments', () => {
  fc.assert(
    fc.property(
      fc.array(argument, { minLength: 2, maxLength: 5 }),
      (values) => {
        assert.throws(() => runMain(values), {
          message: 'Please provide a value of the first argument.',
        });
      },
    ),
  );
});
