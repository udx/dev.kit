#!/usr/bin/env bash

# @description: Analyse repo structure and factors

dev_kit_cmd_repo() {
  local format="${1:-text}"
  local repo_dir="$(pwd)"
  local mode="learn"
  local repo_root=""
  local repo_name=""
  local gaps_json=""
  local context_yaml_path=""

  # Parse flags from remaining args (skip format which is first arg)
  if [ "$#" -ge 1 ]; then
    shift
  fi
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --check) mode="check" ;;
      --*)
        printf 'Unknown flag: %s\n' "$1" >&2
        printf 'Usage: dev.kit repo [--json] [--check]\n' >&2
        return 1
        ;;
      *)       repo_dir="$1" ;;
    esac
    shift
  done

  repo_root="$(dev_kit_repo_root "$repo_dir")"
  repo_dir="${repo_root:-$repo_dir}"
  repo_name="$(dev_kit_repo_name "$repo_dir")"
  context_yaml_path="$(dev_kit_context_yaml_path "$repo_dir")"

  # JSON mode: compute everything up front then emit template
  if [ "$format" = "json" ]; then
    gaps_json="$(dev_kit_scaffold_gaps_json "$repo_dir")"
    if [ "$mode" = "learn" ]; then
      dev_kit_context_yaml_write "$repo_dir" >/dev/null
    fi
    dev_kit_template_render "repo.json" \
      "command=repo" \
      "repo=$(dev_kit_json_escape "$repo_name")" \
      "path=$(dev_kit_json_escape "$repo_dir")" \
      "mode=$(dev_kit_json_escape "$mode")" \
      "archetype=$(dev_kit_json_escape "$(dev_kit_repo_primary_archetype "$repo_dir")")" \
      "profile=$(dev_kit_json_escape "$(dev_kit_repo_primary_profile "$repo_dir")")" \
      "markers=$(dev_kit_repo_markers_json "$repo_dir")" \
      "factors=$(dev_kit_repo_factor_summary_json "$repo_dir")" \
      "gaps=$gaps_json" \
      "actions=[]" \
      "context=$(dev_kit_json_escape "$context_yaml_path")"
    return 0
  fi

  # Text mode: print title immediately, then compute and display progressively.
  dev_kit_output_title "dev.kit repo"

  dev_kit_spinner_start "analyzing repo"
  local archetype
  archetype="$(dev_kit_repo_primary_archetype "$repo_dir")"
  dev_kit_spinner_stop ""

  dev_kit_output_summary "${repo_name} • ${archetype} • mode: ${mode}"

  dev_kit_output_section "factors"
  local factor status
  for factor in documentation architecture dependencies config verification runtime build_release_run; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    dev_kit_output_status_row "$factor" "$status"
  done

  # Gaps: factor statuses are now cached — this pass is fast
  gaps_json="$(dev_kit_scaffold_gaps_json "$repo_dir")"
  local gap_count
  gap_count="$(printf '%s\n' "$gaps_json" | grep -c '"factor"' 2>/dev/null || printf '0')"
  if [ "$gap_count" -gt 0 ]; then
    dev_kit_output_section "gaps"
    dev_kit_output_list_item "${gap_count} factor(s) missing or partial"
  else
    dev_kit_output_section "gaps"
    dev_kit_output_list_item "no gaps detected"
  fi

  # Write context.yaml after output — user already sees analysis above
  if [ "$mode" = "learn" ]; then
    dev_kit_spinner_start "writing context"
    dev_kit_context_yaml_write "$repo_dir" >/dev/null
    dev_kit_spinner_stop "context refreshed"
  fi

  dev_kit_output_section "context"
  dev_kit_output_list_item "$context_yaml_path"

  dev_kit_output_section "next"
  dev_kit_output_row "agent context" "dev.kit agent"
  dev_kit_output_row "session lessons" "dev.kit learn"
}
