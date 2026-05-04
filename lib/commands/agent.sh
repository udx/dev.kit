#!/usr/bin/env bash

# @description: Start an agent session with full repo context

dev_kit_cmd_agent() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"

  local repo_root repo_name context_yaml_path agents_md_path
  repo_root="$(dev_kit_repo_root "$repo_dir")"
  repo_dir="${repo_root:-$repo_dir}"
  repo_name="$(dev_kit_repo_name "$repo_dir")"
  context_yaml_path="$(dev_kit_context_yaml_path "$repo_dir")"
  agents_md_path="${repo_dir}/AGENTS.md"

  # Print title early so spinner output has context
  [ "$format" = "text" ] && dev_kit_output_title "dev.kit agent"

  # Auto-generate context if missing — no manual repo step required
  if [ ! -f "$context_yaml_path" ]; then
    dev_kit_spinner_start "generating repo context"
    dev_kit_context_yaml_write "$repo_dir" >/dev/null
    dev_kit_spinner_stop "context ready"
  fi

  # If generation still failed, report error
  if [ ! -f "$context_yaml_path" ]; then
    if [ "$format" = "json" ]; then
      printf '{ "error": "context generation failed", "path": "%s" }\n' \
        "$(dev_kit_json_escape "$context_yaml_path")"
    else
      dev_kit_output_section "error"
      dev_kit_output_list_item "Context generation failed — check repo at ${repo_dir}"
    fi
    return 1
  fi

  dev_kit_spinner_start "writing agents.md"
  dev_kit_agent_write_agents_md "$repo_dir" "$agents_md_path"

  local archetype
  archetype="$(dev_kit_repo_primary_archetype "$repo_dir")"
  dev_kit_spinner_stop ""

  if [ "$format" = "json" ]; then
    dev_kit_template_render "agent.json" \
      "command=agent" \
      "repo=$(dev_kit_json_escape "$repo_name")" \
      "path=$(dev_kit_json_escape "$repo_dir")" \
      "archetype=$(dev_kit_json_escape "$archetype")" \
      "agents_md=$(dev_kit_json_escape "$agents_md_path")" \
      "context=$(dev_kit_json_escape "$context_yaml_path")" \
      "priority_refs=$(dev_kit_repo_priority_refs_json "$repo_dir")" \
      "entrypoints=$(dev_kit_repo_entrypoints_json "$repo_dir")" \
      "workflow_contract=$(dev_kit_repo_workflow_json "$repo_dir")" \
      "dependencies=$(dev_kit_deps_json "$repo_dir")"
    return 0
  fi

  dev_kit_output_summary "${repo_name} • ${archetype}"

  # Key entrypoints — devs and agents see what commands are available
  local ep_json verify_cmd build_cmd run_cmd
  ep_json="$(dev_kit_repo_entrypoints_json "$repo_dir")"
  verify_cmd="$(printf '%s' "$ep_json" | jq -r '.verify // empty' 2>/dev/null)"
  build_cmd="$(printf '%s' "$ep_json" | jq -r '.build // empty' 2>/dev/null)"
  run_cmd="$(printf '%s' "$ep_json" | jq -r '.run // empty' 2>/dev/null)"
  if [ -n "$verify_cmd" ] || [ -n "$build_cmd" ] || [ -n "$run_cmd" ]; then
    dev_kit_output_section "commands"
    [ -n "$verify_cmd" ] && dev_kit_output_row "verify" "$verify_cmd"
    [ -n "$build_cmd" ]  && dev_kit_output_row "build"  "$build_cmd"
    [ -n "$run_cmd" ]    && dev_kit_output_row "run"    "$run_cmd"
  fi

  dev_kit_output_section "context"
  dev_kit_output_row "agents.md" "$agents_md_path"
  dev_kit_output_row "context.yaml" "$context_yaml_path"

  dev_kit_output_section "next"
  dev_kit_output_row "start" "read AGENTS.md"
  dev_kit_output_row "repo" "dev.kit repo"
  dev_kit_output_row "full" "dev.kit"
}

dev_kit_agent_context_multiline_block() {
  local context_yaml="$1"
  local section_name="$2"

  awk -v section_name="$section_name" '
    $0 == section_name ":" { in_section = 1; next }
    in_section && /^[a-zA-Z#]/ { exit }
    in_section { print }
  ' "$context_yaml"
}

dev_kit_agent_gap_lines() {
  local context_yaml="$1"

  awk '
    /^gaps:/ { in_gaps = 1; next }
    in_gaps && /^[^[:space:]]/ { exit }
    in_gaps && /^  - factor:/ {
      if (gap_factor != "") {
        print "  - " gap_factor " (" gap_status "): " gap_message
      }
      gap_factor = $0
      sub(/^  - factor:[[:space:]]*/, "", gap_factor)
      gap_status = ""
      gap_message = ""
      next
    }
    in_gaps && /^    status:/ {
      gap_status = $0
      sub(/^    status:[[:space:]]*/, "", gap_status)
      next
    }
    in_gaps && /^    message:/ {
      gap_message = $0
      sub(/^    message:[[:space:]]*/, "", gap_message)
      next
    }
    END {
      if (gap_factor != "") {
        print "  - " gap_factor " (" gap_status "): " gap_message
      }
    }
  ' "$context_yaml"
}

dev_kit_agent_workflow_lines() {
  local repo_dir="${1:-$(pwd)}"
  local step_line=""
  local step_label=""
  local step_command=""

  while IFS= read -r step_line; do
    [ -n "$step_line" ] || continue
    step_line="${step_line#*|}"
    step_label="${step_line%%|*}"
    step_command="${step_line#*|}"
    if [ -n "$step_command" ]; then
      printf '  - %s: %s\n' "$step_label" "$step_command"
    else
      printf '  - %s\n' "$step_label"
    fi
  done <<EOF
$(dev_kit_repo_workflow_steps "$repo_dir")
EOF
}

# Write AGENTS.md — the repo's execution contract for AI agents.
# All content is derived from context.yaml. Agents operate from this file,
# not from filesystem discovery.
dev_kit_agent_write_agents_md() {
  local repo_dir="$1"
  local agents_md_path="$2"
  local context_yaml="${repo_dir}/.rabbit/context.yaml"

  {
    printf '# AGENTS.md\n\n'
      printf '_Auto-generated by `dev.kit agent`. Source: `.rabbit/context.yaml`._\n\n'

    if [ ! -f "$context_yaml" ]; then
      printf 'Run `dev.kit repo` to generate context.\n'
    else
      # ── Repo layer — identity, commands, and source artifact ─────────────────
      local _name _arch
      _name="$(awk    '/^repo:/{f=1} f && /^  name:/     {sub(/.*name:[[:space:]]*/,""); print; exit}' "$context_yaml")"
      _arch="$(awk    '/^repo:/{f=1} f && /^  archetype:/{sub(/.*archetype:[[:space:]]*/,""); print; exit}' "$context_yaml")"
      printf '## Repo: %s\n\n' "${_name:-unknown}"
      [ -n "$_arch" ]    && printf -- '- archetype: %s\n' "$_arch"
      printf -- '- context: ./.rabbit/context.yaml\n'
      printf '\n'

      printf '## Operating contract\n\n'
      printf '1. Before each session, make sure `dev.kit` itself is up to date, then run `dev.kit`. Refresh focused layers with `dev.kit repo` or `dev.kit agent` after repo changes.\n'
      printf '2. Read `.rabbit/context.yaml` first. It is the machine contract for refs, commands, dependencies, manifests, and gaps.\n'
      printf '3. Read only the refs, manifests, dependency context, and explicitly referenced paths from `context.yaml`. Avoid broad filesystem scans.\n'
      printf '4. Prefer manifests and repo-declared commands over implementation guesses. Do not edit generated `.rabbit/context.yaml` directly.\n'
      printf '5. Fetch dynamic GitHub state with `gh` only when the current task needs issues, PRs, reviews, workflow runs, or alerts.\n\n'

      local _deps
      _deps="$(dev_kit_agent_context_multiline_block "$context_yaml" "dependencies")"
      if [ -n "$_deps" ]; then
        printf '### Dependency context\n\n'
        printf 'When a dependency entry points to another repo, treat that repo as its own context boundary. Prefer the dependency repo’s `.rabbit/context.yaml`; if it is missing in a local checkout, run `dev.kit repo` from that dependency repo before reading its implementation files.\n\n'
        printf 'For manifest backend traces, read the manifest first, then the traced backend path or docs listed under that manifest entry. Use live GitHub lookups only when local dependency context is unavailable or stale.\n\n'
      fi

      # ── gaps ─────────────────────────────────────────────────────────────────
      local _gaps
      _gaps="$(dev_kit_agent_gap_lines "$context_yaml")"
      if [ -n "$_gaps" ]; then
        printf '### Gap repair loop\n\n'
        printf 'For each gap, read its evidence in `context.yaml`, identify the repo-owned source asset that should declare the missing contract, patch that source asset, then rerun `dev.kit repo`. Repeat until the gap is resolved or clearly document why the repo intentionally cannot cover it.\n\n'
        printf 'Do not patch generated context to hide a gap. Fix docs, example env files, manifests, workflows, package scripts, Dockerfiles, or other primary repo assets so the next context refresh can detect the improvement.\n\n'
        printf '%s\n\n' "$_gaps"
      fi

      # ── Execution — workflow ─────────────────────────────────────────────────
      local _workflow
      _workflow="$(dev_kit_agent_workflow_lines "$repo_dir")"
      if [ -n "$_workflow" ]; then
        printf '## Workflow\n\n'
        printf 'Use these repo-derived steps as the default operating path. Adapt them to the current agent role instead of forcing a single development lifecycle onto every task.\n\n'
        printf '%s\n\n' "$_workflow"
      fi
    fi
  } > "$agents_md_path"
}
