'use strict';

const js = require('@eslint/js');
const globals = require('globals');
const prettierConfig = require('eslint-config-prettier');

module.exports = [
  {
    ignores: [
      'docs/**',
      'node_modules/**',
      'vendor/**',
      '.build/**',
      '.logs/**',
    ],
  },
  {
    files: ['nodejs-script', 'tests/nodejs/**/*.js', 'eslint.config.js'],
    ...js.configs.recommended,
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'commonjs',
      globals: {
        ...globals.node,
      },
    },
  },
  prettierConfig,
];
