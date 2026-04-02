#!/usr/bin/env bash

# @description: Evaluate the lessons-learned workflow for recent pull requests

dev_kit_cmd_learn() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"
  local repo_root=""
  local workflow_id="${3:-$DEV_KIT_LEARNING_DEFAULT_WORKFLOW}"

  repo_root="$(dev_kit_repo_root "$repo_dir")"
  repo_dir="${repo_root:-$repo_dir}"

  if [ "$format" = "json" ]; then
    dev_kit_template_render "learn.json" \
      "command=learn" \
      "repo=$(dev_kit_json_escape "$repo_dir")" \
      "workflow_id=$(dev_kit_json_escape "$workflow_id")" \
      "workflow_name=$(dev_kit_json_escape "$(dev_kit_learning_workflow_name "$workflow_id")")" \
      "description=$(dev_kit_json_escape "$(dev_kit_learning_workflow_description "$workflow_id")")" \
      "sources=$(dev_kit_learning_workflow_sources "$workflow_id" | dev_kit_lines_to_json_array)" \
      "destinations=$(dev_kit_learning_destinations_json "$workflow_id")" \
      "knowledge_base=$(dev_kit_knowledge_hierarchy_json)" \
      "knowledge_sources=$(dev_kit_knowledge_preferred_sources | dev_kit_lines_to_json_array)"
    return 0
  fi

  dev_kit_output_title "dev.kit learn"
  dev_kit_output_summary "$(dev_kit_learning_workflow_name "$workflow_id") • lightweight lessons from recent repo changes"
  dev_kit_output_section "summary"
  dev_kit_output_row "repo" "$repo_dir"
  dev_kit_output_row "behavior" "evaluation-only"
  dev_kit_output_row "workflow" "$(dev_kit_learning_workflow_description "$workflow_id")"
  dev_kit_output_section "read from"
  dev_kit_output_list_from_lines <<EOF
$(dev_kit_learning_workflow_sources "$workflow_id")
EOF
  dev_kit_output_section "send to"
  dev_kit_learning_destinations_text "$workflow_id"
  dev_kit_output_section "next"
  dev_kit_output_list_from_lines <<EOF
$(dev_kit_practice_message_list "context-driven-engineering" "strict-agent-boundary" | sed -n '1,2p')
EOF
  dev_kit_output_list_item "promote durable follow-up into docs, issues, wiki pages, or slack summaries only when the workflow contract is explicit"
}
