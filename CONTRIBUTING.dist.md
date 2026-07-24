# Contributing

Thank you for considering a contribution to this project. This guide covers
setting up a local environment and running the linting and tests.

[//]: # (#;< PHP)

    composer install
    composer lint
    composer test

[//]: # (#;> PHP)

[//]: # (#;< NODEJS)

    npm install
    npm run lint
    npm run test

[//]: # (#;> NODEJS)

[//]: # (#;< SHELL)

    npm ci --prefix tests/bats
    shellcheck shell-command.sh tests/bats/*.bash tests/bats/*.bats
    shfmt -i 2 -ci -s -d shell-command.sh tests/bats/*.bash tests/bats/*.bats
    ./tests/bats/node_modules/.bin/bats tests/bats

[//]: # (#;> SHELL)
