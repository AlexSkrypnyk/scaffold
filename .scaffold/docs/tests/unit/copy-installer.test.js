import fs from 'node:fs';
import path from 'node:path';
import { DEV_INSTALLER, STATIC_DIR, TARGETS, copyInstaller } from '../../scripts/copy-installer';

describe('copyInstaller', () => {
  let copy;
  let remove;

  beforeEach(() => {
    copy = jest.spyOn(fs, 'copyFileSync').mockImplementation(() => {});
    remove = jest.spyOn(fs, 'rmSync').mockImplementation(() => {});
  });

  afterEach(() => {
    copy.mockRestore();
    remove.mockRestore();
  });

  test.each([
    ['an unset version', undefined],
    ['an empty version', ''],
  ])('copies the development installer to every target with %s', (name, version) => {
    expect(copyInstaller(version, '/site/static')).toBe(DEV_INSTALLER);

    expect(copy.mock.calls).toEqual(TARGETS.map((target) => [DEV_INSTALLER, path.join('/site/static', target)]));
    expect(remove).not.toHaveBeenCalled();
  });

  test('removes every target in a release build', () => {
    expect(copyInstaller('1.5.0', '/site/static')).toBeNull();

    expect(remove.mock.calls).toEqual(TARGETS.map((target) => [path.join('/site/static', target), { force: true }]));
    expect(copy).not.toHaveBeenCalled();
  });

  test('copies into the static directory by default', () => {
    copyInstaller(undefined);

    expect(copy).toHaveBeenCalledWith(DEV_INSTALLER, path.join(STATIC_DIR, 'install.sh'));
  });
});

test('serves the installer as install.sh and init.sh', () => {
  expect(TARGETS).toEqual(['install.sh', 'init.sh']);
});

test('the development installer exists', () => {
  expect(fs.existsSync(DEV_INSTALLER)).toBe(true);
});
