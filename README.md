# Wodby GitHub Actions

Reusable GitHub Actions for Wodby workflows.

## Available actions

- [`setup-wodby-cli`](./setup-wodby-cli/README.md): installs `wodby`, exports `WODBY_API_KEY`, and can run `wodby ci init`.

## Versioning

Use the major version alias, such as `wodby/actions/setup-wodby-cli@v1`, to receive the latest compatible minor and patch updates. Pin a complete version such as `@v1.1.0` when the workflow must remain on an immutable release.

Stable `vMAJOR.MINOR.PATCH` releases automatically update the corresponding `vMAJOR` and `vMAJOR.MINOR` aliases after the action tests pass. Breaking changes are released under a new major version.
