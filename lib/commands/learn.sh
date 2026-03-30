#!/usr/bin/env bash

# @description: Evaluate the lessons-learned workflow for recent pull requests

dev_kit_cmd_learn() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"
  local workflow_id="${3:-$DEV_KIT_LEARNING_DEFAULT_WORKFLOW}"

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
      "knowledge_sources=$(dev_kit_knowledge_preferred_sources | dev_kit_lines_to_json_array)" \
      "tooling_refs=$(dev_kit_tooling_repos_json)" \
      "operating_surface=$(dev_kit_knowledge_operating_surface_json)" \
      "responsibility_split=$(dev_kit_knowledge_responsibility_split_json)"
    return 0
  fi

  dev_kit_output_title "dev.kit learn"
  dev_kit_output_section "workflow"
  dev_kit_output_row "repo" "$repo_dir"
  dev_kit_output_row "workflow" "$(dev_kit_learning_workflow_name "$workflow_id")"
  dev_kit_output_row "description" "$(dev_kit_learning_workflow_description "$workflow_id")"
  dev_kit_output_row "mode" "evaluation-only"
  dev_kit_output_section "sources"
  dev_kit_output_list_from_lines <<EOF
$(dev_kit_learning_workflow_sources "$workflow_id")
EOF
  dev_kit_output_section "destinations"
  dev_kit_learning_destinations_text "$workflow_id"
  dev_kit_output_section "knowledgebase"
  dev_kit_output_row "local repos" "$(dev_kit_knowledge_local_repos_root)"
  dev_kit_output_row "remote org" "$(dev_kit_knowledge_remote_org_root)"
  dev_kit_output_row "preferred sources" "$(dev_kit_knowledge_preferred_sources_text)"
  dev_kit_output_row "dependency orgs" "$(dev_kit_tooling_dependency_orgs | dev_kit_lines_to_csv)"
  dev_kit_output_section "tooling repos"
  dev_kit_tooling_repos_text
  dev_kit_output_section "responsibility split"
  dev_kit_output_row "repo mechanisms" "$(dev_kit_knowledge_repo_mechanisms | dev_kit_lines_to_csv)"
  dev_kit_output_row "agent tasks" "$(dev_kit_knowledge_agent_tasks | dev_kit_lines_to_csv)"
  dev_kit_output_section "next"
  dev_kit_output_list_item "keep lessons lightweight and grounded in recent pull requests, docs, and saved repo context"
  dev_kit_output_list_item "promote durable follow-up into docs, issues, wiki pages, or slack summaries only when the workflow contract is explicit"
}
