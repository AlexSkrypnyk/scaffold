[//]: # (#;< META)




| <h1 align="center"> <img src="docs/assets/logo.png" alt="Scaffold logo" width=400px/></h1> **Generic project scaffold template**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <div align="center"> [![Scaffold test](https://github.com/AlexSkrypnyk/scaffold/actions/workflows/scaffold-test.yml/badge.svg)](https://github.com/AlexSkrypnyk/scaffold/actions/workflows/scaffold-test.yml)  ![Scaffold LICENSE](https://img.shields.io/github/license/AlexSkrypnyk/scaffold?label=Scaffold+license)                                                                                                                                               ![GitHub Scaffold release (latest by date)](https://img.shields.io/github/v/release/AlexSkrypnyk/scaffold?label=Scaffold+release) </div>                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| <div align="center"> [Scaffold documentation](https://getscaffold.dev) </div>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| **Features**<br/><br/>- **PHP**<br>&nbsp;&nbsp;&nbsp;&nbsp;- `composer.json` config<br>&nbsp;&nbsp;&nbsp;&nbsp;- Symfony CLI command app scaffold with unit tests (with coverage) and traits<br>&nbsp;&nbsp;&nbsp;&nbsp;- Simple single-file script scaffold with unit tests (with coverage) and traits<br>&nbsp;&nbsp;&nbsp;&nbsp;- Code quality tools with configurations: PHP Code Sniffer, PHP Mess Detector, PHPStan<br>- **NodeJS**<br>&nbsp;&nbsp;&nbsp;&nbsp;- `package.json` config<br>- **CI**<br>&nbsp;&nbsp;&nbsp;&nbsp;- Lint, test and publish PHP as PHAR<br>&nbsp;&nbsp;&nbsp;&nbsp;- Build and test for NodeJS<br>&nbsp;&nbsp;&nbsp;&nbsp;- Release drafter<br>&nbsp;&nbsp;&nbsp;&nbsp;- Release asset packaging and upload<br>&nbsp;&nbsp;&nbsp;&nbsp;- PR auto-assign<br>&nbsp;&nbsp;&nbsp;&nbsp;- Funding<br>- **Utility files**<br>&nbsp;&nbsp;&nbsp;&nbsp;- Readme with badges<br>&nbsp;&nbsp;&nbsp;&nbsp;- `.editorconfig`, `.gitignore`, `.gitattributes`<br>&nbsp;&nbsp;&nbsp;&nbsp;- Init shell script to chose features |
| **How to use this scaffold repository**<br/><br/>1. Click on **Use this template** > **Create a new repository**<br>2. Checkout locally <br>3. Run `./init.sh` to replace `yournamespace`, `yourproject`, `Your Name` strings with your own and choose the features. <br/>  ![init](https://github.com/AlexSkrypnyk/scaffold/assets/378794/43962d9f-eae7-4b54-bec8-2e3139ed722c)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| This table will be removed after running `./init.sh`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | The contents below will be a part of your repository.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |

<br>

[//]: # (#;> META)


<p align="center">
  <a href="" rel="noopener">
 <img width=200px height=200px src="https://i.imgur.com/6wj0hh6.jpg" alt="Project logo"></a>
</p>

<h1 align="center">yourproject</h1>

<div align="center">

  [![GitHub Issues](https://img.shields.io/github/issues/AlexSkrypnyk/scaffold.svg)](https://github.com/AlexSkrypnyk/scaffold/issues)
  [![GitHub Pull Requests](https://img.shields.io/github/issues-pr/AlexSkrypnyk/scaffold.svg)](https://github.com/AlexSkrypnyk/scaffold/pulls)
  [![Test](https://github.com/AlexSkrypnyk/scaffold/actions/workflows/test.yml/badge.svg)](https://github.com/AlexSkrypnyk/scaffold/actions/workflows/test.yml)
  ![Coverage](https://github.com/AlexSkrypnyk/scaffold/blob/_xml_coverage_reports/data/main/badge.svg)
  ![GitHub release (latest by date)](https://img.shields.io/github/v/release/AlexSkrypnyk/scaffold)
  ![LICENSE](https://img.shields.io/github/license/AlexSkrypnyk/scaffold)

</div>

---

<p align="center"> Few lines describing your project.
    <br> 
</p>

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
