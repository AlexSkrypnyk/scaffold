/**
 * @file
 * Copy the development installer that the site serves at '/install.sh' and
 * '/init.sh'.
 *
 * A build without RELEASE_VERSION, such as a local server or the development
 * site, serves the repository-root 'install.sh' of the commit it was built
 * from. A release build serves no installer: getscaffold.dev redirects both
 * paths to the 'install.sh' attached to the latest GitHub release.
 */

const fs = require('node:fs');
const path = require('node:path');

const ROOT_DIR = path.resolve(__dirname, '..', '..', '..');

const STATIC_DIR = path.resolve(__dirname, '..', 'static');

const DEV_INSTALLER = path.join(ROOT_DIR, 'install.sh');

const TARGETS = ['install.sh', 'init.sh'];

// Removes the targets in a release build, so a copy left by an earlier
// development build never ships behind the redirect.
const copyInstaller = (releaseVersion, staticDir = STATIC_DIR) => {
  for (const target of TARGETS) {
    const destination = path.join(staticDir, target);

    if (releaseVersion) {
      fs.rmSync(destination, { force: true });
    }
    else {
      fs.copyFileSync(DEV_INSTALLER, destination);
    }
  }

  return releaseVersion ? null : DEV_INSTALLER;
};

module.exports = { DEV_INSTALLER, STATIC_DIR, TARGETS, copyInstaller };

/* istanbul ignore next */
if (require.main === module) {
  const source = copyInstaller(process.env.RELEASE_VERSION);
  console.log(source ? `Copied ${path.relative(ROOT_DIR, source)} to ${TARGETS.join(' and ')}.` : `Release build: removed ${TARGETS.join(' and ')}.`);
}
