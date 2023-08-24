# Scaffold

[//]: # (#;< META)

| **Generic project scaffold template**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Features**<br/><br/>- **PHP**<br>&nbsp;&nbsp;- `composer.json` config<br>&nbsp;&nbsp;- Symfony CLI command app scaffold with unit tests<br>&nbsp;&nbsp;- Simple single-file script scaffold with unit tests<br>&nbsp;&nbsp;- Code quality tools with configurations: PHP Code Sniffer, PHP Mess Detector, PHP Stan<br>- **NodeJS**<br>&nbsp;&nbsp;- `package.json` config<br>- **CI**<br>&nbsp;&nbsp;- Build and test for PHP<br>&nbsp;&nbsp;- Build and test for NodeJS<br>&nbsp;&nbsp;- Release drafter<br>&nbsp;&nbsp;- Release asset packaging and upload<br>&nbsp;&nbsp;- PR auto-assign<br>&nbsp;&nbsp;- Funding<br>- **Utility files**<br>&nbsp;&nbsp;- Readme with badges<br>&nbsp;&nbsp;- `.editorconfig`, `.gitignore`, `.gitattributes`<br>&nbsp;&nbsp;- Init shell script to chose features |
| **How to use this scaffold repository**<br/><br/>1. Click on **Use this template** > **Create a new repository**<br>2. Checkout locally <br>3. Run `./init.sh` to replace `yournamespace`, `yourproject`, `Your Name` strings with your own and choose the features.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| This table will be removed after running `./init.sh`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| [![Scaffold test](https://github.com/AlexSkrypnyk/scaffold/actions/workflows/scaffold-test.yml/badge.svg)](https://github.com/AlexSkrypnyk/scaffold/actions/workflows/scaffold-test.yml)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| The contents below will be a part of your repository.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |

<br>

[//]: # (#;> META)

[![Test](https://github.com/AlexSkrypnyk/scaffold/actions/workflows/test.yml/badge.svg)](https://github.com/AlexSkrypnyk/scaffold/actions/workflows/test.yml)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/AlexSkrypnyk/scaffold)
![LICENSE](https://img.shields.io/github/license/AlexSkrypnyk/scaffold)

## Features

- Your first feature as a list item
- Your second feature as a list item
- Your third feature as a list item

## Installation

[//]: # (#;< PHP)

    composer require yournamespace/yourproject

[//]: # (#;> PHP)

[//]: # (#;< NODEJS)

    npm install @yournamespace/yourproject

[//]: # (#;> NODEJS)

## Usage

[//]: # (#;< PHP)

    vendor/bin/yourproject

[//]: # (#;> PHP)

[//]: # (#;< NODEJS)

    node_modules/.bin/yourproject

[//]: # (#;> NODEJS)

## Maintenance

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
