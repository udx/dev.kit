#!/usr/bin/env bash

# @description: Start an agent session with full repo context

dev_kit_cmd_agent() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"

  local repo_root repo_name manifest_path agents_md_path
  repo_root="$(dev_kit_repo_root "$repo_dir")"
  repo_dir="${repo_root:-$repo_dir}"
  repo_name="$(dev_kit_repo_name "$repo_dir")"
  manifest_path="$(dev_kit_scaffold_manifest_path "$repo_dir")"
  agents_md_path="${repo_dir}/AGENTS.md"

  if [ ! -f "$manifest_path" ]; then
    if [ "$format" = "json" ]; then
      printf '{ "error": "manifest not found", "hint": "run dev.kit repo first", "path": "%s" }\n' \
        "$(dev_kit_json_escape "$manifest_path")"
    else
      dev_kit_output_title "dev.kit agent"
      dev_kit_output_section "error"
      dev_kit_output_list_item "Manifest not found — run dev.kit repo first."
    fi
    return 1
  fi

  # Generate AGENTS.md only if dev.kit repo hasn't already done it
  if [ ! -f "$agents_md_path" ]; then
    dev_kit_agent_write_agents_md "$manifest_path" "$agents_md_path"
  fi

  local archetype profile
  archetype="$(jq -r '.archetype // empty' "$manifest_path" 2>/dev/null)"
  profile="$(jq -r '.profile   // empty' "$manifest_path" 2>/dev/null)"

  if [ "$format" = "json" ]; then
    dev_kit_template_render "agent.json" \
      "command=agent" \
      "repo=$(dev_kit_json_escape "$repo_name")" \
      "path=$(dev_kit_json_escape "$repo_dir")" \
      "archetype=$(dev_kit_json_escape "$archetype")" \
      "profile=$(dev_kit_json_escape "$profile")" \
      "agents_md=$(dev_kit_json_escape "$agents_md_path")" \
      "manifest=$(dev_kit_json_escape "$manifest_path")" \
      "priority_refs=$(jq -c '.priority_refs    // []' "$manifest_path" 2>/dev/null)" \
      "entrypoints=$(jq -c '.entrypoints        // {}' "$manifest_path" 2>/dev/null)" \
      "workflow_contract=$(jq -c '.workflow_contract // []' "$manifest_path" 2>/dev/null)" \
      "factors=$(jq -c '.factors              // {}' "$manifest_path" 2>/dev/null)" \
      "task="
    return 0
  fi

  dev_kit_output_title "dev.kit agent"
  dev_kit_output_summary "${repo_name} • ${archetype}"
  dev_kit_output_section "context"
  dev_kit_output_list_item "manifest:  ${manifest_path}"
  dev_kit_output_list_item "agents.md: ${agents_md_path}"
}

# Write AGENTS.md from manifest — called by dev.kit repo (and agent as fallback)
dev_kit_agent_write_agents_md() {
  local manifest_path="$1"
  local agents_md_path="$2"

  {
    printf '# AGENTS.md\n\n'
    printf '> Run `dev.kit repo` to refresh.\n\n'

    # Repo name + plain-English description
    local _repo _desc
    _repo="$(jq -r '.repo // "unknown"' "$manifest_path" 2>/dev/null)"
    _desc="$(jq -r '.archetype_description // empty' "$manifest_path" 2>/dev/null)"
    printf '## %s\n\n' "$_repo"
    [ -n "$_desc" ] && printf '%s\n\n' "$_desc"

    # Start here — exclude tool-specific files that would be self-referential here
    printf '## Start here\n\n'
    jq -r '.priority_refs[]? | "- \(.)"' "$manifest_path" 2>/dev/null \
      | awk '!/^- \.\/(AGENTS|CLAUDE)\.md$/' \
      | head -6
    printf '\n'

    # Commands — only present entries
    local _verify _build _run
    _verify="$(jq -r '.entrypoints.verify // empty' "$manifest_path" 2>/dev/null)"
    _build="$(jq -r '.entrypoints.build  // empty' "$manifest_path" 2>/dev/null)"
    _run="$(jq -r '.entrypoints.run    // empty' "$manifest_path" 2>/dev/null)"
    if [ -n "$_verify" ] || [ -n "$_build" ] || [ -n "$_run" ]; then
      printf '## Commands\n\n'
      [ -n "$_verify" ] && printf -- '- **verify**: `%s`\n' "$_verify"
      [ -n "$_build"  ] && printf -- '- **build**: `%s`\n'  "$_build"
      [ -n "$_run"    ] && printf -- '- **run**: `%s`\n'    "$_run"
      printf '\n'
    fi

    # Gaps — factors with missing or partial status
    local _gaps
    _gaps="$(jq -r '
      .factors | to_entries[] |
      select(.value.status == "missing" or .value.status == "partial") |
      "- **\(.key)** (\(.value.status))" +
        if .value.message then " — \(.value.message)" else "" end
    ' "$manifest_path" 2>/dev/null)"
    if [ -n "$_gaps" ]; then
      printf '## Gaps\n\n'
      printf '%s\n\n' "$_gaps"
    fi

    # Workflow steps from contract
    local _workflow
    _workflow="$(jq -r '
      .workflow_contract[]? |
      if .refs then
        "- \(.label): \(.refs | map(select(test("/(AGENTS|CLAUDE)\\.md$") | not)) | join(", "))"
      elif .command then
        "- \(.label): `\(.command)`"
      else
        "- \(.label)"
      end
    ' "$manifest_path" 2>/dev/null)"
    if [ -n "$_workflow" ]; then
      printf '## Workflow\n\n'
      printf '%s\n\n' "$_workflow"
    fi
  } > "$agents_md_path"
}
