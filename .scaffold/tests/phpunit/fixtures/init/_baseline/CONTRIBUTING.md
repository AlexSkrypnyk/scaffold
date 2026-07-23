# Contributing

Thank you for considering a contribution to this project. This guide explains
how to set up a local environment and run the linting and tests.

## Installation


    composer install



    npm install



    npm ci --prefix tests/bats


## Linting


    composer lint



    npm run lint



    shellcheck force-crystal.sh tests/bats/*.bash tests/bats/*.bats
    shfmt -i 2 -ci -s -d force-crystal.sh tests/bats/*.bash tests/bats/*.bats


## Testing


    composer test



    npm run test



    ./tests/bats/node_modules/.bin/bats tests/bats

