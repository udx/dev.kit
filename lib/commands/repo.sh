#!/usr/bin/env bash

# @description: Learn, improve, or scaffold a repo

dev_kit_cmd_repo() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"
  local mode="learn"
  local repo_root=""
  local repo_name=""
  local gaps_json=""
  local actions_json="[]"
  local manifest_path=""

  # Parse flags from remaining args (skip format and repo_dir already captured)
  if [ "$#" -ge 2 ]; then
    shift 2
  elif [ "$#" -ge 1 ]; then
    shift
  fi
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --scaffold) mode="scaffold" ;;
      --check)    mode="check"    ;;
      *)          repo_dir="$1"   ;;
    esac
    shift
  done

  repo_root="$(dev_kit_repo_root "$repo_dir")"
  repo_dir="${repo_root:-$repo_dir}"
  repo_name="$(dev_kit_repo_name "$repo_dir")"
  manifest_path="$(dev_kit_scaffold_manifest_path "$repo_dir")"

  gaps_json="$(dev_kit_scaffold_gaps_json "$repo_dir")"

  # learn/scaffold: write manifest and generate AGENTS.md
  if [ "$mode" = "learn" ] || [ "$mode" = "scaffold" ]; then
    mkdir -p "$(dirname "$manifest_path")"
    dev_kit_scaffold_manifest_write "$repo_dir" > "$manifest_path"
    dev_kit_agent_write_agents_md "$manifest_path" "${repo_dir}/AGENTS.md"
  fi

  # scaffold: apply missing dirs and files based on archetype + gap analysis
  if [ "$mode" = "scaffold" ]; then
    local archetype plan
    archetype="$(dev_kit_repo_primary_archetype "$repo_dir")"
    plan="$(dev_kit_scaffold_plan_dirs "$repo_dir" "$archetype")"
    actions_json="$(dev_kit_scaffold_apply "$repo_dir" "$plan")"
  fi

  if [ "$format" = "json" ]; then
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
      "actions=$actions_json" \
      "manifest=$(dev_kit_json_escape "$manifest_path")"
    return 0
  fi

  dev_kit_output_title "dev.kit repo"
  dev_kit_output_summary "${repo_name} • $(dev_kit_repo_primary_archetype "$repo_dir") • mode: ${mode}"

  dev_kit_output_section "factors"
  local factor status
  for factor in documentation architecture dependencies config verification runtime build_release_run; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    dev_kit_output_row "$factor" "$status"
  done

  local gap_count
  gap_count="$(printf '%s\n' "$gaps_json" | grep -c '"factor"' 2>/dev/null || printf '0')"
  if [ "$gap_count" -gt 0 ]; then
    dev_kit_output_section "gaps"
    dev_kit_output_list_item "${gap_count} factor(s) missing or partial — run dev.kit repo --scaffold to apply fixes"
  else
    dev_kit_output_section "gaps"
    dev_kit_output_list_item "no gaps detected"
  fi

  if [ "$mode" = "scaffold" ]; then
    dev_kit_output_section "scaffold"
    dev_kit_output_list_item "actions applied — see ${manifest_path}"
  fi

  dev_kit_output_section "manifest"
  dev_kit_output_list_item "$manifest_path"
}
