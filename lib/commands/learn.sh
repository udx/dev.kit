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
      "operating_surface=$(dev_kit_knowledge_operating_surface_json)" \
      "responsibility_split=$(dev_kit_knowledge_responsibility_split_json)"
    return 0
  fi

  echo "dev.kit learn"
  echo "repo: $repo_dir"
  echo "workflow: $(dev_kit_learning_workflow_name "$workflow_id")"
  echo "description: $(dev_kit_learning_workflow_description "$workflow_id")"
  echo "mode: evaluation-only"
  echo
  echo "sources:"
  while IFS= read -r source; do
    [ -n "$source" ] || continue
    printf '  - %s\n' "$source"
  done <<EOF
$(dev_kit_learning_workflow_sources "$workflow_id")
EOF
  echo
  echo "destinations:"
  dev_kit_learning_destinations_text "$workflow_id"
  echo
  echo "knowledgebase:"
  echo "  - local repos: $(dev_kit_knowledge_local_repos_root)"
  echo "  - remote org: $(dev_kit_knowledge_remote_org_root)"
  echo "  - preferred sources: $(dev_kit_knowledge_preferred_sources_text)"
  echo
  echo "responsibility split:"
  echo "  - repo mechanisms: $(dev_kit_knowledge_repo_mechanisms | dev_kit_lines_to_csv)"
  echo "  - agent tasks: $(dev_kit_knowledge_agent_tasks | dev_kit_lines_to_csv)"
  echo
  echo "next:"
  echo "  - keep lessons lightweight and grounded in recent pull requests, docs, and saved repo context"
  echo "  - promote durable follow-up into docs, issues, wiki pages, or slack summaries only when the workflow contract is explicit"
}
