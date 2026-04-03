#!/usr/bin/env bash

# @description: Evaluate the lessons-learned workflow for recent pull requests

dev_kit_cmd_learn() {
  local format="${1:-text}"
  shift || true
  local repo_dir="$(pwd)"
  local repo_root=""
  local workflow_id="$DEV_KIT_LEARNING_DEFAULT_WORKFLOW"
  local session_id=""
  local arg=""
  local observed_sources=""

  while [ "$#" -gt 0 ]; do
    arg="$1"
    case "$arg" in
      --workflow)
        shift
        [ "$#" -gt 0 ] || break
        workflow_id="$1"
        ;;
      *)
        repo_dir="$arg"
        ;;
    esac
    shift || true
  done

  repo_root="$(dev_kit_repo_root "$repo_dir")"
  repo_dir="${repo_root:-$repo_dir}"
  session_id="$(dev_kit_learning_discovered_session_id "$repo_dir")"
  observed_sources="[]"
  if [ -n "$session_id" ]; then
    observed_sources="$(dev_kit_learning_session_sources_json "$session_id")"
  fi

  if [ "$format" = "json" ]; then
    dev_kit_template_render "learn.json" \
      "command=learn" \
      "repo=$(dev_kit_json_escape "$repo_dir")" \
      "workflow_id=$(dev_kit_json_escape "$workflow_id")" \
      "workflow_name=$(dev_kit_json_escape "$(dev_kit_learning_workflow_name "$workflow_id")")" \
      "description=$(dev_kit_json_escape "$(dev_kit_learning_workflow_description "$workflow_id")")" \
      "sources=$(dev_kit_learning_workflow_sources "$workflow_id" | dev_kit_lines_to_json_array)" \
      "observed_sources=$observed_sources" \
      "destinations=$(dev_kit_learning_destinations_json "$workflow_id")" \
      "session=$(dev_kit_learning_session_summary_json "$session_id" "$repo_dir")" \
      "flow=$(dev_kit_learning_session_flow_json "$session_id")" \
      "shared_context=$(dev_kit_learning_session_shared_context_json "$session_id")" \
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
  if [ -n "$session_id" ]; then
    dev_kit_output_section "observed"
    dev_kit_output_list_from_lines <<EOF
$(dev_kit_learning_session_sources_text "$session_id")
EOF
    dev_kit_output_section "workflow"
    dev_kit_output_list_from_lines <<EOF
$(dev_kit_learning_session_flow_text "$session_id")
EOF
    dev_kit_output_section "learned"
    dev_kit_output_list_from_lines <<EOF
$(dev_kit_learning_session_lessons_text "$session_id")
EOF
    if [ "$(dev_kit_learning_session_issue_urls "$session_id" | dev_kit_lines_to_json_array)" != "[]" ]; then
      dev_kit_output_section "shared context"
      dev_kit_output_list_item "Use the GitHub issue as the cross-repo context root."
      dev_kit_output_list_from_lines <<EOF
$(dev_kit_learning_session_issue_urls "$session_id")
EOF
    fi
  fi
  dev_kit_output_section "send to"
  dev_kit_learning_destinations_text "$workflow_id"
  dev_kit_output_section "next"
  dev_kit_output_list_from_lines <<EOF
$(dev_kit_practice_message_list "context-driven-engineering" "strict-agent-boundary" | sed -n '1,2p')
EOF
  dev_kit_output_list_item "promote durable follow-up into docs, issues, wiki pages, or slack summaries only when the workflow contract is explicit"
}
