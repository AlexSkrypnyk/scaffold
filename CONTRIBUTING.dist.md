# Contributing

Thank you for considering a contribution to this project. This guide explains
how to set up a local environment and run the linting and tests.

## Installation

[//]: # (#;< PHP)

    composer install

[//]: # (#;> PHP)

[//]: # (#;< NODEJS)

    npm install

[//]: # (#;> NODEJS)

[//]: # (#;< SHELL)

    npm ci --prefix tests/bats

[//]: # (#;> SHELL)

## Linting

[//]: # (#;< PHP)

    composer lint

[//]: # (#;> PHP)

[//]: # (#;< NODEJS)

    npm run lint

[//]: # (#;> NODEJS)

[//]: # (#;< SHELL)

    shellcheck shell-command.sh tests/bats/*.bash tests/bats/*.bats
    shfmt -i 2 -ci -s -d shell-command.sh tests/bats/*.bash tests/bats/*.bats

[//]: # (#;> SHELL)

## Testing

[//]: # (#;< PHP)

    composer test

[//]: # (#;> PHP)

[//]: # (#;< NODEJS)

    npm run test

[//]: # (#;> NODEJS)

[//]: # (#;< SHELL)

    ./tests/bats/node_modules/.bin/bats tests/bats

[//]: # (#;> SHELL)
