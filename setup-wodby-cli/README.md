# `setup-wodby-cli`

Installs the [Wodby CLI](https://github.com/wodby/wodby-cli), exports
`WODBY_API_KEY` for later workflow steps, and optionally runs `wodby ci init`.

This action is intended for GitHub-hosted Linux runners, which match the VM-based pattern already used by the CircleCI examples in [
`wodby/wodby-ci`](https://github.com/wodby/wodby-ci).

## Inputs

| Name                | Required | Default | Description                                                                                                             |
|---------------------|----------|---------|-------------------------------------------------------------------------------------------------------------------------|
| `api-key`           | yes      |         | Wodby API key. The action exports it as `WODBY_API_KEY` for subsequent steps.                                           |
| `app-service-id`    | no       | `""`    | When provided, the action runs `wodby ci init <app-service-id>`.                                                        |
| `cli-version`       | no       | `""`    | Exact CLI version to install, for example `2.2.0`. When omitted, the action resolves the default version automatically. |
| `verbose`           | no       | `false` | When `true`, exports `WODBY_VERBOSE=true`.                                                                              |
| `working-directory` | no       | `.`     | Directory from which `wodby ci init` is executed.                                                                       |

## Usage

Run `actions/checkout` before this action so `wodby ci init` can inspect the repository and later
`wodby ci build` can use the current workspace.

```yaml
name: Wodby Deploy

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/cache@v4
        with:
          path: ~/.composer
          key: composer-${{ hashFiles('composer.lock') }}
          restore-keys: |
            composer-

      - uses: wodby/actions/setup-wodby-cli@v1
        with:
          api-key: ${{ secrets.WODBY_API_KEY }}
          app-service-id: your-app-service-id

      - name: Install dependencies
        run: wodby ci run -v "$HOME/.composer:/home/wodby/.composer" -- composer install -n

      - name: Build images
        run: wodby ci build

      - name: Release images
        run: wodby ci release

      - name: Deploy
        run: wodby ci deploy
```

## Notes

- `app-service-id` is optional. If you omit it, the action only installs the CLI and exports environment variables.
- By default the action asks Wodby backend which CLI version should be installed, then downloads the matching GitHub release asset directly.
- If you want reproducible builds without backend dependency, set `cli-version` explicitly.
- The action does not run `build`, `release`, or
  `deploy` for you. Those remain explicit workflow steps because they are project-specific.
- `wodby ci init` requires Docker access later in the workflow, so use an Ubuntu runner for the actual build pipeline.
