# Contributing

Thank you for considering a contribution to this project. This guide covers
setting up a local environment and running the linting and tests.


    composer install
    composer lint
    composer test



    npm install
    npm run lint
    npm run test



    npm ci --prefix tests/bats
    shellcheck force-crystal.sh tests/bats/*.bash tests/bats/*.bats
    shfmt -i 2 -ci -s -d force-crystal.sh tests/bats/*.bash tests/bats/*.bats
    ./tests/bats/node_modules/.bin/bats tests/bats

