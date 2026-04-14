#!/usr/bin/env bash

# @description: Learn, improve, or scaffold a repo

dev_kit_cmd_repo() {
  local format="${1:-text}"
  local repo_dir="$(pwd)"
  local mode="learn"
  local repo_root=""
  local repo_name=""
  local gaps_json=""
  local actions_json="[]"
  local context_yaml_path=""

  # Parse flags from remaining args (skip format which is first arg)
  if [ "$#" -ge 1 ]; then
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
  context_yaml_path="$(dev_kit_context_yaml_path "$repo_dir")"

  # JSON mode: compute everything up front then emit template
  if [ "$format" = "json" ]; then
    gaps_json="$(dev_kit_scaffold_gaps_json "$repo_dir")"
    if [ "$mode" = "learn" ] || [ "$mode" = "scaffold" ]; then
      dev_kit_context_yaml_write "$repo_dir" >/dev/null
    fi
    if [ "$mode" = "scaffold" ]; then
      local archetype plan
      archetype="$(dev_kit_repo_primary_archetype "$repo_dir")"
      plan="$(dev_kit_scaffold_plan "$repo_dir" "$archetype")"
      actions_json="$(dev_kit_scaffold_apply "$repo_dir" "$plan")"
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
      "actions=$actions_json" \
      "context=$(dev_kit_json_escape "$context_yaml_path")"
    return 0
  fi

  # Text mode: print title immediately, then compute and display progressively.
  dev_kit_output_title "dev.kit repo"

  # Archetype detection + scaffold plan — show spinner during analysis
  dev_kit_spinner_start "analyzing repo"
  local archetype scaffold_plan
  archetype="$(dev_kit_repo_primary_archetype "$repo_dir")"
  scaffold_plan="$(dev_kit_scaffold_plan "$repo_dir" "$archetype")"
  dev_kit_spinner_stop ""

  # scaffold mode: apply the plan now (before output so result shows correctly)
  if [ "$mode" = "scaffold" ]; then
    actions_json="$(dev_kit_scaffold_apply "$repo_dir" "$scaffold_plan")"
  fi

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
    dev_kit_output_list_item "${gap_count} factor(s) missing or partial — run dev.kit repo --scaffold to apply fixes"
  else
    dev_kit_output_section "gaps"
    dev_kit_output_list_item "no gaps detected"
  fi

  if [ "$mode" = "scaffold" ]; then
    dev_kit_output_section "scaffold"
    local _action _rel _status
    while IFS='|' read -r _action _rel_path; do
      [ -n "$_action" ] || continue
      _status="$(printf '%s' "$actions_json" | grep -q "\"path\": \"${_rel_path}\".*\"status\": \"ok\"" 2>/dev/null && printf 'ok' || printf 'done')"
      dev_kit_output_list_item "${_action}: ${_rel_path}"
    done <<EOF
$scaffold_plan
EOF
    [ -z "$scaffold_plan" ] && dev_kit_output_list_item "no actions needed"
  elif [ -n "$scaffold_plan" ]; then
    dev_kit_output_section "scaffold preview"
    while IFS='|' read -r action rel_path; do
      [ -n "$action" ] || continue
      dev_kit_output_list_item "would ${action}: ${rel_path}"
    done <<EOF
$scaffold_plan
EOF
  fi

  # Write context.yaml after output — user already sees analysis above
  if [ "$mode" = "learn" ] || [ "$mode" = "scaffold" ]; then
    dev_kit_spinner_start "writing context"
    dev_kit_context_yaml_write "$repo_dir" >/dev/null
    dev_kit_spinner_stop "context refreshed"
  fi

  dev_kit_output_section "context"
  dev_kit_output_list_item "$context_yaml_path"

  dev_kit_output_section "next"
  dev_kit_output_row "agent context" "dev.kit agent"
  dev_kit_output_row "session lessons" "dev.kit learn"
  if [ "$gap_count" -gt 0 ] && [ "$mode" != "scaffold" ]; then
    dev_kit_output_row "apply fixes" "dev.kit repo --scaffold"
  fi
}
