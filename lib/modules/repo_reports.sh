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
    printf '\n    { "id": "%s", "factor": "%s", "status": "%s", "message": "%s" }' "$rule_id" "$factor" "$status" "$message"
    emitted=1
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF

  if [ "$emitted" -eq 1 ]; then
    printf '\n  '
  fi

  printf "]"
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
    printf '"%s"' "$guidance"
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
  printf '%s\n' "Use standard repo signals such as README, docs, manifests, workflows, deploy config, and tests as the primary contract; custom saved context is optional."

  if dev_kit_repo_has_archetype "$repo_dir" "workflow-repo"; then
    printf '%s\n' "Treat .github workflows as the primary runtime contract and preserve declared workflow_call inputs and outputs."
  fi

  if dev_kit_repo_has_saved_context "$repo_dir"; then
    printf '%s\n' "Saved repo-local context exists at $(dev_kit_repo_saved_context_summary_text "$repo_dir"); use it as supplemental repo-native guidance, not as a replacement for standard repo files."
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
