---
title: "Laravel 10.x + Livewire 3.x Pre-Commit Linting and Formatting"
date: 2024-01-16T01:08:02+03:00
draft: false
author: "Timothy Karani"
authorTwitter: "c3n7_luc"
tags: ["laravel"]
keywords: ["laravel"]
description: "Setup a Livewire project with linting and formatting pre-commit hooks"
---

## Introduction

When creating Laravel+Livewire projects, especially for teams, pre-commit hooks come in handy by ensuring everyone on the team follows the same formatting standards and adheres to some level of code quality. In this blog-post we will use:

- [_husky_](https://github.com/typicode/husky): Sets up pre-commit hooks
- [_prettier_](https://github.com/prettier/prettier): To format `*.css`, `*.js` and `*.blade` files.
- [_@shufo/prettier-plugin-blade_](https://github.com/shufo/prettier-plugin-blade): A prettier plugin for formatting `*blade` files
- [_laravel/pint_](https://github.com/laravel/pint): to format PHP files like classes, traits, etc.
- [larastan](https://github.com/larastan/larastan): does PHP static analysis.

## Installation

Assuming you are creating a project from scratch, let us begin the set-up.

1. Create a new project, I will name mine `livewire-precommits-demo`:
   ```shell
   $ composer create-project laravel/laravel livewire-precommits-demo
   ```
2. Open the project, initialize git and make the first commit:
   ```shell
   $ cd livewire-precommits-demo
   $ git init
   $ git add -A
   $ git commit -m "First of many"
   ```
3. Install `husky`, `prettier`, and `@shufo/prettier-plugin-blade` as dev dependencies:
   ```shell
   $ npm i -D husky prettier @shufo/prettier-plugin-blade
   ```
4. Add Laravel Pint:
   ```shell
   $ composer require laravel/pint --dev
   ```
   To test it out in action:
   ```shell
   $ ./vendor/bin/pint
   ```
5. Install Larastan:
   ```shell
   $ composer require larastan/larastan:^2.0 --dev
   ```
6. Create a `phpstan.neon` file in the root of the project with this:

   ```yaml
   includes:
     - vendor/larastan/larastan/extension.neon

   parameters:
     paths:
       - app/

     # Level 9 is the highest level
     level: 5
   #    ignoreErrors:
   #        - '#PHPDoc tag @var#'
   #
   #    excludePaths:
   #        - ./*/*/FileToBeExcluded.php
   #
   #    checkMissingIterableValueType: false
   ```

   To test if it works:

   ```shell
   $ ./vendor/bin/phpstan analyse
   ```

7. We have installed everything we need, now we can create a commit to track these changes:
   ```shell
   $ git add -A && git commit -m "Added linting and formatting packages"
   ```

## Set Up Pre-Commit Hook

We have all the packages needed for static analysis and code formatting so now let us create a pre-commit hook that runs them before every commit:

1. First we should install husky's Git hooks
   ```shell
   $ npx husky install
   ```
2. Create a file under the `.husky` directory called `pre-commit`, in full (`.husky/pre-commit`), and add the following content:

   ```shell
   #!/usr/bin/env sh
   . "$(dirname -- "$0")/_/husky.sh"

   # Format resources
   # https://stackoverflow.com/a/6879568
   # https://stackoverflow.com/a/1587952
   ./node_modules/.bin/prettier --ignore-unknown --write $(git diff --name-only --diff-filter=ACMR HEAD -- '*.blade.php')
   ./node_modules/.bin/prettier resources/**/*.js  resources/**/*.css --write

   # Format php classes
   ./vendor/bin/pint && git add -A

   # Do static analysis
   ./vendor/bin/phpstan analyse --memory-limit=2G
   ```

   Let us break down this command: `/node_modules/.bin/prettier --ignore-unknown --write $(git diff --name-only --diff-filter=ACMR HEAD -- '*.blade.php')`

   - `--ignore-unknown` prevents the command from returning a non-zero result if no match is found in our filter
   - `--write` tells prettier to write the formatting changes to the respective files
   - `--diff-filter=ACMR HEAD` matches files that have either been [**A**dded, **C**opied, **M**odified, or **R**enamed](https://stackoverflow.com/a/6879568). `HEAD` adds to this filter by matching files that have gone through either of the aforementioned changes, whether they have been stagged for commit or not. If this is not the desired behaviour [this resource should come in handy](https://stackoverflow.com/a/1587952)

3. Make the `.husky/pre-commit` executable:
   ```shell
   $ chmod +x .husky/pre-commit
   ```
   Now when we do a commit, the pre-commit hook should run
4. Commit our changes:
   ```shell
   $ git add -A
   $ git commit -m "Added pre-commit hook"
   ```
   Congratulations! Now linting and static analysis is done before every commit. There's one more thing we can do to help new team members install the pre-commit hook:
5. Update `package.json` and the following script. It runs right after one runs `npm install`:
   ```json
   {
     "scripts": {
       ...
       "prepare": "husky install && git add .husky/pre-commit"
     }
   }
   ```
   Now an `npm install` should trigger the installation of the pre-commit hooks, or one can just run `npm run prepare`.

## Resources

- [Filter git diff by type of change](https://stackoverflow.com/a/6879568)
- [How do I show the changes which have been staged?](https://stackoverflow.com/a/1587952)
