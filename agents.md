# QuranEngine

## Make commands

The Makefile exposes a few helpful commands:

1. Use `make build` to compile `QuranEngine-Package` (or override with `make build TARGET=NoorUI`).
2. Use `make test` for package tests, also honoring `TARGET` to point at another scheme/target.
3. Use `make build-example` to build the Example app.
4. Run `make format-lint` for SwiftFormat checks.

Keeping these commands green locally should keep the CI workflow green as well.
