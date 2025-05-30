@@ -1,6 +1,6 @@
 <p align="center">
   <a href="" rel="noopener">
-  <img width=200px height=200px src="https://placehold.jp/000000/ffffff/200x200.png?text=force-crystal&css=%7B%22border-radius%22%3A%22%20100px%22%7D" alt="force-crystal logo"></a>
+  <img width=200px height=200px src="https://placehold.jp/000000/ffffff/200x200.png?text=star-forge&css=%7B%22border-radius%22%3A%22%20100px%22%7D" alt="star-forge logo"></a>
 </p>
 
 <h1 align="center">Few lines describing your project</h1>
@@ -7,14 +7,14 @@
 
 <div align="center">
 
-[![GitHub Issues](https://img.shields.io/github/issues/yodashut/force-crystal.svg)](https://github.com/yodashut/force-crystal/issues)
-[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/yodashut/force-crystal.svg)](https://github.com/yodashut/force-crystal/pulls)
-[![Test PHP](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-php.yml)
-[![Test Node.js](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-nodejs.yml)
-[![Test Shell](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml/badge.svg)](https://github.com/yodashut/force-crystal/actions/workflows/test-shell.yml)
-[![codecov](https://codecov.io/gh/yodashut/force-crystal/graph/badge.svg?token=7WEB1IXBYT)](https://codecov.io/gh/yodashut/force-crystal)
-![GitHub release (latest by date)](https://img.shields.io/github/v/release/yodashut/force-crystal)
-![LICENSE](https://img.shields.io/github/license/yodashut/force-crystal)
+[![GitHub Issues](https://img.shields.io/github/issues/jeditemple/star-forge.svg)](https://github.com/jeditemple/star-forge/issues)
+[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/jeditemple/star-forge.svg)](https://github.com/jeditemple/star-forge/pulls)
+[![Test PHP](https://github.com/jeditemple/star-forge/actions/workflows/test-php.yml/badge.svg)](https://github.com/jeditemple/star-forge/actions/workflows/test-php.yml)
+[![Test Node.js](https://github.com/jeditemple/star-forge/actions/workflows/test-nodejs.yml/badge.svg)](https://github.com/jeditemple/star-forge/actions/workflows/test-nodejs.yml)
+[![Test Shell](https://github.com/jeditemple/star-forge/actions/workflows/test-shell.yml/badge.svg)](https://github.com/jeditemple/star-forge/actions/workflows/test-shell.yml)
+[![codecov](https://codecov.io/gh/jeditemple/star-forge/graph/badge.svg?token=7WEB1IXBYT)](https://codecov.io/gh/jeditemple/star-forge)
+![GitHub release (latest by date)](https://img.shields.io/github/v/release/jeditemple/star-forge)
+![LICENSE](https://img.shields.io/github/license/jeditemple/star-forge)
 ![Renovate](https://img.shields.io/badge/renovate-enabled-green?logo=renovatebot)
 
 </div>
@@ -30,11 +30,11 @@
 ## Installation
 
 
-    composer require yodashut/force-crystal
+    composer require jeditemple/star-forge
 
 
 
-    npm install @yodashut/force-crystal
+    npm install @jeditemple/star-forge
 
 
 
@@ -44,15 +44,15 @@
 ## Usage
 
 
-    vendor/bin/force-crystal
+    vendor/bin/star-forge
 
 
 
-    node_modules/.bin/force-crystal
+    node_modules/.bin/star-forge
 
 
 
-    ./force-crystal.sh
+    ./star-forge.sh
 
 
 
@@ -80,8 +80,8 @@
 
 
 
-    shellcheck force-crystal.sh tests/bats/*.bash tests/bats/*.bats
-    shfmt -i 2 -ci -s -d force-crystal.sh tests/bats/*.bash tests/bats/*.bats
+    shellcheck star-forge.sh tests/bats/*.bash tests/bats/*.bats
+    shfmt -i 2 -ci -s -d star-forge.sh tests/bats/*.bash tests/bats/*.bats
 
     npm ci --prefix tests/bats
     ./tests/bats/node_modules/.bin/bats tests/bats
@@ -88,4 +88,4 @@
 
 
 ---
-_This repository was created using the [force-crystal](https://getforce-crystal.dev/) project template_
+_This repository was created using the [star-forge](https://getstar-forge.dev/) project template_
