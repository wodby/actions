# `setup-wodby-cli`

Installs the [Wodby CLI](https://github.com/wodby/wodby-cli), exports
`WODBY_API_KEY` and `WODBY_API_BASE_URL` for later workflow steps, and optionally runs `wodby ci init`.

This action is intended for GitHub-hosted Linux runners, which match the VM-based pattern already used by the CircleCI examples in [
`wodby/wodby-ci`](https://github.com/wodby/wodby-ci).

## Inputs

| Name                | Required | Default | Description                                                                                                             |
|---------------------|----------|---------|-------------------------------------------------------------------------------------------------------------------------|
| `api-key`           | yes      |         | Wodby API key. The action exports it as `WODBY_API_KEY` for subsequent steps.                                           |
| `app-service-id`    | no       | `""`    | When provided, the action runs `wodby ci init <app-service-id>`.                                                        |
| `cli-version`       | no       | `""`    | Exact CLI version to install, for example `2.8.0`. When omitted, the action installs the latest Wodby 2 release.        |
| `verbose`           | no       | `false` | When `true`, exports `WODBY_VERBOSE=true`.                                                                              |
| `working-directory` | no       | `.`     | Directory from which `wodby ci init` is executed.                                                                       |
| `cache`             | no       | `auto`  | Restores caches detected from lockfiles. Use `none` or a comma-separated list of `npm`, `composer`, `bundler`, and `uv` to override. |

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
      - uses: actions/checkout@v6

      - uses: wodby/actions/setup-wodby-cli@v1
        with:
          api-key: ${{ secrets.WODBY_API_KEY }}
          app-service-id: your-app-service-id

      - name: Install dependencies
        run: wodby ci run -- composer install -n

      - name: Build images
        run: wodby ci build

      - name: Release images
        run: wodby ci release

      - name: Deploy
        run: wodby ci deploy
```

## Notes

- `app-service-id` is optional. If you omit it, the action only installs the CLI and exports environment variables.
- With the default `cache: auto`, the action restores npm, Composer, Bundler, and uv caches when it finds
  `package-lock.json`, `composer.lock`, `Gemfile.lock`, or `uv.lock`. `wodby ci run` automatically mounts the matching
  cache for supported images.
- Set `cache: none` to disable dependency caching, or set an explicit list such as `cache: npm,composer` when lockfiles
  are generated later in the job.
- The action derives the REST API base URL from `api-host` and exports it as `WODBY_API_BASE_URL`.
- The action downloads the runner-specific CLI archive directly from GitHub Releases. GitHub's latest release tracks Wodby 2.
- If you want reproducible installs, set `cli-version` explicitly.
- The action does not run `build`, `release`, or
  `deploy` for you. Those remain explicit workflow steps because they are project-specific.
- `wodby ci init` requires Docker access later in the workflow, so use an Ubuntu runner for the actual build pipeline.
