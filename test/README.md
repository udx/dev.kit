# dev.kit tests

This directory holds test suites for dev.kit. Suites are JSON files under `test/suites/` and are executed by `dev.kit test`.

Quick start
- List suites: `dev.kit test --list`
- Mock run: `dev.kit test install --mock`
- Execute (requires force because suite uninstalls): `dev.kit test install --run --force`
- With purge: `DEV_KIT_TEST_PURGE=true dev.kit test install --run --force`

Environment variables
- `DEV_KIT_TEST_OUTPUT_DIR`: output directory for logs (default: `tmp/tests`)
- `DEV_KIT_TEST_LOG_FILE`: log path (default: `tmp/tests/dev-kit-test.log`)
- `DEV_KIT_TEST_SHELL`: shell type for install tests (default: `bash`)
- `DEV_KIT_TEST_PURGE`: set to `true` to pass `--purge` during uninstall
- `DEV_KIT_BIN`: path to dev.kit binary (default: `bin/dev-kit` in repo)
