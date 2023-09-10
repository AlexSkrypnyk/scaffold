---
title: Renovate
layout: default
parent: CI
nav_order: 4
---

# Renovate

[Renovate Bot](https://www.mend.io/renovate/) is an automated tool designed to
keep software dependencies up to date within a project. It works by scanning
your project files for dependencies, then it checks for newer versions of those
dependencies. When it finds updates, Renovate Bot can automatically generate
pull
requests with the necessary changes for updating to the newer versions.
This helps to maintain your project with the latest, most secure versions of
libraries and packages, thereby reducing potential security risks and improving
overall code quality.

The bot is extremely configurable, allowing you to set schedules for when
updates should be checked, limit the number of open pull requests, group
dependencies for multi-package updates, and much more.

This template provides
a [`renovate.json`](https://github.com/AlexSkrypnyk/scaffold/blob/main/renovate.json)
configuration file with some sensible defaults to get you started.

It uses the base configuration provided by Renovate Bot, inheriting a set of
default settings aimed at providing an optimal balance between stability and
staying up-to-date. No additional or custom configurations are specified, making
it a minimal setup. It also validates the configuration against the official
Renovate schema.

For more information on how to configure Renovate Bot, see the [Renovate Docs](https://docs.renovatebot.com/).
