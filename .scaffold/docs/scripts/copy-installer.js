/**
 * @file
 * Copy the installer that the site serves at '/install.sh' and '/init.sh'.
 *
 * A release build (RELEASE_VERSION set) serves the stub that runs the
 * 'install.sh' attached to the latest GitHub release. Any other build, such
 * as a local server or the development site, serves the repository-root
 * 'install.sh' of the commit it was built from.
 */

const fs = require('node:fs');
const path = require('node:path');

const ROOT_DIR = path.resolve(__dirname, '..', '..', '..');

const STATIC_DIR = path.resolve(__dirname, '..', 'static');

const DEV_INSTALLER = path.join(ROOT_DIR, 'install.sh');

const RELEASE_INSTALLER = path.join(ROOT_DIR, '.scaffold', 'installer', 'install-latest.sh');

const TARGETS = ['install.sh', 'init.sh'];

const installerSource = (releaseVersion) => (releaseVersion ? RELEASE_INSTALLER : DEV_INSTALLER);

const copyInstaller = (releaseVersion, staticDir = STATIC_DIR) => {
  const source = installerSource(releaseVersion);

  for (const target of TARGETS) {
    fs.copyFileSync(source, path.join(staticDir, target));
  }

  return source;
};

module.exports = { DEV_INSTALLER, RELEASE_INSTALLER, STATIC_DIR, TARGETS, copyInstaller, installerSource };

/* istanbul ignore next */
if (require.main === module) {
  const source = copyInstaller(process.env.RELEASE_VERSION);
  console.log(`Copied ${path.relative(ROOT_DIR, source)} to ${TARGETS.join(' and ')}.`);
}
