#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
. "$REPO_DIR/tests/helpers/assert.sh"

OUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dev-kit-promptfoo-test.XXXXXX")"
trap 'rm -rf "$OUT_DIR"' EXIT

bash -n "$REPO_DIR/bin/scripts/promptfoo-dev-kit.sh"
pass "promptfoo helper has valid shell syntax"

prepare_output="$(bash "$REPO_DIR/bin/scripts/promptfoo-dev-kit.sh" prepare --repo "$REPO_DIR" --out-dir "$OUT_DIR")"
assert_contains "$prepare_output" "Prepared Promptfoo config:" "promptfoo prepare reports config path"
assert_file_exists "$OUT_DIR/promptfooconfig.yaml" "promptfoo prepare writes config"

config_text="$(sed -n '1,260p' "$OUT_DIR/promptfooconfig.yaml")"
assert_contains "$config_text" "file://tests/promptfoo/prompts/baseline.txt" "promptfoo config includes baseline prompt"
assert_contains "$config_text" "file://tests/promptfoo/prompts/with-dev-kit.txt" "promptfoo config includes dev.kit prompt"
assert_contains "$config_text" "\"command\": \"explore\"" "promptfoo config embeds explore json"
assert_contains "$config_text" "\"command\": \"action\"" "promptfoo config embeds action json"

eval_output="$(bash "$REPO_DIR/bin/scripts/promptfoo-dev-kit.sh" eval --repo "$REPO_DIR" --out-dir "$OUT_DIR")"
assert_contains "$eval_output" "Promptfoo results:" "promptfoo eval reports result path"
assert_file_exists "$OUT_DIR/results.json" "promptfoo eval writes results json"

results_text="$(cat "$OUT_DIR/results.json")"
assert_contains "$results_text" "\"description\": \"current-repo-start-here\"" "promptfoo results include the current repo scenario"
assert_contains "$results_text" "with-dev-kit.txt" "promptfoo results include the dev.kit-enriched prompt"
assert_contains "$results_text" "baseline.txt" "promptfoo results include the baseline prompt"
