import fs from 'node:fs';
import path from 'node:path';
import { DEV_INSTALLER, RELEASE_INSTALLER, STATIC_DIR, TARGETS, copyInstaller, installerSource } from '../../scripts/copy-installer';

describe('installerSource', () => {
  test.each([
    ['an unset version', undefined, DEV_INSTALLER],
    ['an empty version', '', DEV_INSTALLER],
    ['a release version', '1.5.0', RELEASE_INSTALLER],
  ])('picks the installer for %s', (name, version, expected) => {
    expect(installerSource(version)).toBe(expected);
  });
});

describe('copyInstaller', () => {
  let copy;

  beforeEach(() => {
    copy = jest.spyOn(fs, 'copyFileSync').mockImplementation(() => {});
  });

  afterEach(() => {
    copy.mockRestore();
  });

  test.each([
    ['the development installer', undefined, DEV_INSTALLER],
    ['the release stub', '1.5.0', RELEASE_INSTALLER],
  ])('copies %s to every target', (name, version, expected) => {
    expect(copyInstaller(version, '/site/static')).toBe(expected);

    expect(copy.mock.calls).toEqual(TARGETS.map((target) => [expected, path.join('/site/static', target)]));
  });

  test('copies into the static directory by default', () => {
    copyInstaller('1.5.0');

    expect(copy).toHaveBeenCalledWith(RELEASE_INSTALLER, path.join(STATIC_DIR, 'install.sh'));
  });
});

test('serves the installer as install.sh and init.sh', () => {
  expect(TARGETS).toEqual(['install.sh', 'init.sh']);
});

test.each([DEV_INSTALLER, RELEASE_INSTALLER])('the installer %p exists', (file) => {
  expect(fs.existsSync(file)).toBe(true);
});

test('the release stub runs the installer of the latest release', () => {
  expect(fs.readFileSync(RELEASE_INSTALLER, 'utf8')).toContain('https://github.com/AlexSkrypnyk/scaffold/releases/latest/download/install.sh');
});
