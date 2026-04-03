#!/usr/bin/env bash

dev_kit_repo_findings_json() {
  local repo_dir="$1"
  local emitted=0
  local factor=""
  local status=""
  local rule_id=""
  local message=""

  printf "["
  while IFS= read -r factor; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    rule_id="$(dev_kit_repo_factor_rule_id "$factor" "$status" || true)"
    [ -n "$rule_id" ] || continue
    message="$(dev_kit_rule_message "$rule_id")"
    if [ "$emitted" -eq 1 ]; then
      printf ","
    fi
    printf '\n    { "id": "%s", "factor": "%s", "status": "%s", "message": "%s" }' \
      "$(dev_kit_json_escape "$rule_id")" \
      "$(dev_kit_json_escape "$factor")" \
      "$(dev_kit_json_escape "$status")" \
      "$(dev_kit_json_escape "$message")"
    emitted=1
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF

  if [ "$emitted" -eq 1 ]; then
    printf '\n  '
  fi

  printf "]"
}

dev_kit_repo_findings_text() {
  local repo_dir="$1"
  local factor=""
  local status=""
  local rule_id=""

  while IFS= read -r factor; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    rule_id="$(dev_kit_repo_factor_rule_id "$factor" "$status" || true)"
    [ -n "$rule_id" ] || continue
    printf '%s\n' "$(dev_kit_rule_message "$rule_id")"
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF
}

dev_kit_repo_advices() {
  local repo_dir="$1"
  local factor=""
  local status=""
  local rule_id=""

  while IFS= read -r factor; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    rule_id="$(dev_kit_repo_factor_rule_id "$factor" "$status" || true)"
    [ -n "$rule_id" ] || continue
    printf 'advice: %s\n' "$(dev_kit_rule_message "$rule_id")"
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF
}

dev_kit_repo_factor_summary_json() {
  local repo_dir="$1"
  local factor=""
  local status=""
  local first=1

  printf "{"
  while IFS= read -r factor; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    if [ "$first" -eq 0 ]; then
      printf ","
    fi
    printf '\n    "%s": {' "$factor"
    printf '\n      "status": "%s",' "$status"
    printf '\n      "evidence": '
    dev_kit_repo_factor_evidence_json "$repo_dir" "$factor"
    if dev_kit_repo_factor_entrypoint "$repo_dir" "$factor" >/dev/null 2>&1; then
      printf ',\n      "entrypoint": "%s"\n    }' "$(dev_kit_repo_factor_entrypoint "$repo_dir" "$factor")"
    else
      printf '\n    }'
    fi
    first=0
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF
  printf '\n  }'
}

dev_kit_repo_agent_guidance_json() {
  local repo_dir="$1"
  local first=1
  local guidance=""

  printf "["
  while IFS= read -r guidance; do
    [ -n "$guidance" ] || continue
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '"%s"' "$(dev_kit_json_escape "$guidance")"
    first=0
  done <<EOF
$(dev_kit_repo_agent_guidance_text "$repo_dir")
EOF
  printf "]"
}

dev_kit_repo_agent_guidance_text() {
  local repo_dir="$1"
  local factor=""
  local status=""
  local entrypoint=""

  printf '%s\n' "Treat this repository as a $(dev_kit_repo_primary_archetype "$repo_dir") and preserve its existing workflow contract."
  dev_kit_practice_message_list "standard-repo-first" "repo-centric" | sed -n '1,2p'

  if dev_kit_repo_has_archetype "$repo_dir" "workflow-repo"; then
    printf '%s\n' "Treat .github workflows as the primary runtime contract and preserve declared workflow_call inputs and outputs."
  fi

  while IFS= read -r factor; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    case "$factor:$status" in
      architecture:present)
        printf '%s\n' "Respect the repository's existing architectural boundaries instead of collapsing commands, domain logic, templates, and config into one layer."
        ;;
      architecture:partial)
        printf '%s\n' "Some structural boundaries exist, but the repository architecture is only partially normalized."
        ;;
      verification:present)
        entrypoint="$(dev_kit_repo_factor_entrypoint "$repo_dir" "verification" || true)"
        printf '%s\n' "Use ${entrypoint} as the canonical verification step before and after changes."
        ;;
      verification:partial)
        printf '%s\n' "Verification assets exist, but the canonical test entrypoint is not normalized yet."
        ;;
      config:present)
        printf '%s\n' "Treat configuration as external to code and preserve the documented config contract."
        ;;
      config:partial)
        printf '%s\n' "Config signals exist, but the environment contract is incomplete or only partially documented."
        ;;
      runtime:present)
        entrypoint="$(dev_kit_repo_factor_entrypoint "$repo_dir" "runtime" || true)"
        printf '%s\n' "Use ${entrypoint:-the documented runtime entrypoint} to reproduce runtime behavior instead of inventing ad hoc commands."
        ;;
      build_release_run:present)
        printf '%s\n' "Keep build and runtime steps separated; use the discovered build and run entrypoints instead of editing in place."
        ;;
      documentation:missing)
        printf '%s\n' "Expect more agent ambiguity until a repository README defines purpose and workflow."
        ;;
      *)
        ;;
    esac
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF
}

dev_kit_repo_agent_contract_text() {
  local repo_dir="$1"

  printf '%s\n' "Use dev.kit JSON output as the machine contract: dev.kit explore --json, dev.kit action --json, dev.kit learn --json."
  dev_kit_practice_message_list "standard-repo-first" "strict-agent-boundary" | sed -n '1,2p'

  if [ -f "$repo_dir/AGENTS.md" ]; then
    printf '%s\n' "AGENTS.md exists; treat it as a local agent override after repo-native refs, not as the primary repo contract."
  else
    printf '%s\n' "AGENTS.md is optional. If a local provider-agnostic agent note is needed, keep it small and never let it replace repo-native sources."
  fi

  printf '%s\n' "Do not create parallel agent-only state when repo files such as TODO.md, refs.md, README, docs, and workflows already carry the same context."
}

dev_kit_repo_agent_contract_json() {
  dev_kit_repo_agent_contract_text "$1" | dev_kit_lines_to_json_array
}
