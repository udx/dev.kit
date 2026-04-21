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

  local archetype profile
  archetype="$(dev_kit_repo_primary_archetype "$repo_dir")"
  profile="$(dev_kit_repo_primary_profile "$repo_dir")"
  dev_kit_spinner_stop ""

  if [ "$format" = "json" ]; then
    dev_kit_template_render "agent.json" \
      "command=agent" \
      "repo=$(dev_kit_json_escape "$repo_name")" \
      "path=$(dev_kit_json_escape "$repo_dir")" \
      "archetype=$(dev_kit_json_escape "$archetype")" \
      "profile=$(dev_kit_json_escape "$profile")" \
      "agents_md=$(dev_kit_json_escape "$agents_md_path")" \
      "context=$(dev_kit_json_escape "$context_yaml_path")" \
      "priority_refs=$(dev_kit_repo_priority_refs_json "$repo_dir")" \
      "entrypoints=$(dev_kit_repo_entrypoints_json "$repo_dir")" \
      "workflow_contract=$(dev_kit_repo_workflow_json "$repo_dir")" \
      "dependencies=$(dev_kit_deps_json "$repo_dir")"
    return 0
  fi

  dev_kit_output_summary "${repo_name} • ${archetype} • profile ${profile}"

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

  dev_kit_output_section "ready"
  dev_kit_output_list_item "Context synced. Start your session following AGENTS.md workflow."
  dev_kit_output_list_item "Run dev.kit → dev.kit repo → dev.kit agent at each new interaction or after repo updates to resync."
}

dev_kit_agent_context_list() {
  local context_yaml="$1"
  local section_name="$2"

  awk -v section_name="$section_name" '
    $0 == section_name ":" { in_section = 1; next }
    in_section && /^[a-zA-Z#]/ { exit }
    in_section && /^  - / {
      gsub(/^  - "/, "  - ")
      sub(/"$/, "")
      gsub(/\\"/, "\"")
      gsub(/\\\\/, "\\")
      print
    }
  ' "$context_yaml"
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

dev_kit_agent_github_section() {
  local context_yaml="$1"
  local section_name="$2"

  awk -v section_name="$section_name" '
    $0 == "  " section_name ":" { in_section = 1; next }
    in_section && /^    - / {
      sub(/^    - "?/, "  - ")
      sub(/"$/, "")
      gsub(/\\"/, "\"")
      gsub(/\\\\/, "\\")
      print
      next
    }
    in_section && /^[^ ]|^  [a-z]/ { exit }
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

dev_kit_agent_principle_lines() {
  cat <<'EOF'
  - Start from `.rabbit/context.yaml`, then read only the highest-priority repo refs it points to.
  - Prefer repo-declared commands, manifests, workflows, and tests over ad hoc exploration.
  - Treat current GitHub state as useful live context when available, not as a mandatory workflow for every task.
  - Keep generated guidance lightweight. Do not duplicate repo context already serialized in `.rabbit/context.yaml`.
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
      printf '_Auto-generated by `dev.kit agent`. Sources: `.rabbit/context.yaml`, GitHub history, lesson artifacts._\n\n'

    if [ ! -f "$context_yaml" ]; then
      printf 'Run `dev.kit repo` to generate context.\n'
    else
      # ── Contract — deterministic execution rules ─────────────────────────────
      printf '## Contract\n\n'
      printf 'This repository is a deterministic execution contract. Agents MUST interpret declared context — no scanning, no guesswork, no invention.\n\n'

      printf '### Rules\n\n'
      printf '1. **Do NOT scan the filesystem.** No `find`, `ls -R`, `glob`, or recursive directory walks. All paths you need are listed below.\n'
      printf '2. **Context boundaries are strict.** Read only files in Priority refs and Config manifests. If a file is not listed, do not read it unless a listed file explicitly references it.\n'
      printf '3. **Manifests before code.** When you need to understand behavior, read the YAML manifest that defines it — not the code that implements it. Manifests are the interface.\n'
      printf '4. **Context over memory.** Operate from repo-declared context. Do not carry assumptions from prior sessions or rely on prompt history when the contract is on disk.\n'
      printf '5. **Prefer workflow verification, not automatic local enforcement.** Detect the repo verify command from `context.yaml`, prefer GitHub workflow executions when the repo already has CI coverage, and use local verification to reproduce failures, debug quickly, or cover workflow gaps.\n'
      printf '6. **Follow the Workflow below.** Do not invent ad hoc steps or skip phases. The workflow is the execution sequence.\n'
      printf '7. **Reuse over invention.** Check existing org patterns, configs, and workflows before creating new ones.\n'
      printf '8. **Prefer live GitHub experience over generic defaults.** After loading the repo contract, use current issues, pull requests, review state, and commit history as the primary dynamic source. Fall back to workflow and practice catalogs when GitHub signal is missing, thin, or irrelevant.\n'
      printf '9. **Remember this context.** If your agent supports persistent memory, save that this repo uses `dev.kit` for context management. Start every session — or after merges, config changes, or workflow updates — by running: `dev.kit` → `dev.kit repo` → `dev.kit agent`. Each command guides to the next required step. This resyncs repo context, environment state, and the execution contract before any work begins.\n\n'

      # ── Repo layer — identity, commands, and source artifact ─────────────────
      local _name _arch _profile
      _name="$(awk    '/^repo:/{f=1} f && /^  name:/     {sub(/.*name:[[:space:]]*/,""); print; exit}' "$context_yaml")"
      _arch="$(awk    '/^repo:/{f=1} f && /^  archetype:/{sub(/.*archetype:[[:space:]]*/,""); print; exit}' "$context_yaml")"
      _profile="$(awk '/^repo:/{f=1} f && /^  profile:/  {sub(/.*profile:[[:space:]]*/,""); print; exit}' "$context_yaml")"
      printf '## Repo: %s\n\n' "${_name:-unknown}"
      [ -n "$_arch" ]    && printf -- '- archetype: %s\n' "$_arch"
      [ -n "$_profile" ] && printf -- '- profile: %s\n' "$_profile"
      printf -- '- context: ./.rabbit/context.yaml\n'
      printf '\n'

      # ── commands ─────────────────────────────────────────────────────────────
      local _cmds
      _cmds="$(dev_kit_agent_context_multiline_block "$context_yaml" "commands")"
      if [ -n "$_cmds" ]; then
        printf '### Commands\n\n```\n%s\n```\n\n' "$_cmds"
      fi

      printf '## Use context.yaml\n\n'
      printf 'All refs, config manifests, command surfaces, dependencies, and gaps live in `.rabbit/context.yaml`.\n\n'
      printf 'Do not duplicate that inventory here. Read `context.yaml` first, then use this file for operating rules, workflow, and dynamic guidance.\n\n'

      # ── GitHub context ─────────────────────────────────────────────────────
      # Items in context.yaml are 4-space indented under github subsections.
      # Strip 4 leading spaces when emitting into markdown.
      local _gh_repo _gh_section
      _gh_repo="$(awk '/^github:/{f=1} f && /^  repo:/{sub(/.*repo:[[:space:]]*/,""); print; exit}' "$context_yaml")"
      if [ -n "$_gh_repo" ]; then
        printf '### GitHub context\n\n'
        printf 'Development signals from [%s](https://github.com/%s). Treat this as the primary dynamic source for current repo experience.\n\n' "$_gh_repo" "$_gh_repo"

        _gh_section="$(dev_kit_agent_github_section "$context_yaml" "open_issues")"
        [ -n "$_gh_section" ] && printf '**Open issues:**\n\n%s\n\n' "$_gh_section"

        _gh_section="$(dev_kit_agent_github_section "$context_yaml" "open_prs")"
        [ -n "$_gh_section" ] && printf '**Open PRs:**\n\n%s\n\n' "$_gh_section"

        _gh_section="$(dev_kit_agent_github_section "$context_yaml" "recent_prs")"
        [ -n "$_gh_section" ] && printf '**Recent PRs:**\n\n%s\n\n' "$_gh_section"

        _gh_section="$(dev_kit_agent_github_section "$context_yaml" "security_alerts")"
        [ -n "$_gh_section" ] && printf '**Security alerts:**\n\n%s\n\n' "$_gh_section"
      fi

      # ── gaps ─────────────────────────────────────────────────────────────────
      local _gaps
      _gaps="$(dev_kit_agent_context_list "$context_yaml" "gaps")"
      if [ -n "$_gaps" ]; then
        printf '### Gaps\n\n'
        printf 'Incomplete factors. Address within the workflow, not as separate tasks.\n\n'
        printf '%s\n\n' "$_gaps"
      fi

      # ── Versioned workflow artifacts ─────────────────────────────────────────
      local _lessons
      _lessons="$(dev_kit_agent_context_list "$context_yaml" "lessons")"
      printf '## Versioned workflow artifacts\n\n'
      printf '`.rabbit/` contains generated context downstream of repo signals. These are versioned artifacts, not primary sources.\n\n'
      printf '  - `.rabbit/context.yaml` — generated execution contract (source of truth for this file)\n'
      if [ -n "$_lessons" ]; then
        printf '\nPrior session lessons — read before starting work:\n\n'
        printf '%s\n' "$_lessons"
      fi
      printf '\n'

      # ── Execution — workflow ─────────────────────────────────────────────────
      local _workflow
      _workflow="$(dev_kit_agent_workflow_lines "$repo_dir")"
      if [ -n "$_workflow" ]; then
        printf '## Workflow\n\n'
        printf 'Use these repo-derived steps as the default operating path. Adapt them to the current agent role instead of forcing a single development lifecycle onto every task.\n\n'
        printf '%s\n\n' "$_workflow"
      fi

      # ── Learned workflow rules (from agent session lessons) ────────────────
      local _learned_rules _learned_templates
      _learned_rules="$(dev_kit_learning_lesson_rules "$repo_dir")"
      _learned_templates="$(dev_kit_learning_lesson_templates "$repo_dir")"
      if [ -n "$_learned_rules" ] || [ -n "$_learned_templates" ]; then
        printf '### Learned from prior sessions\n\n'
        printf 'Patterns detected from agent sessions on this repo. Follow these in addition to the workflow above.\n\n'
        if [ -n "$_learned_rules" ]; then
          while IFS= read -r _rule; do
            [ -n "$_rule" ] || continue
            printf -- '- %s\n' "$_rule"
          done <<EOF
$_learned_rules
EOF
          printf '\n'
        fi
        if [ -n "$_learned_templates" ]; then
          printf '**Reusable templates:**\n\n'
          while IFS= read -r _tmpl; do
            [ -n "$_tmpl" ] || continue
            printf -- '- %s\n' "$_tmpl"
          done <<EOF
$_learned_templates
EOF
          printf '\n'
        fi
      fi

      # ── Dynamic PR guide (from repo GitHub history) ──────────────────────────
      local _pr_bodies _pr_headings _pr_example
      _pr_bodies="$(dev_kit_learning_github_recent_pr_bodies "$repo_dir" 2>/dev/null || true)"
      if [ -n "$_pr_bodies" ]; then
        _pr_headings="$(dev_kit_learning_github_pr_heading_pattern "$_pr_bodies")"
        _pr_example="$(dev_kit_learning_github_best_pr_example "$_pr_bodies")"

        if [ -n "$_pr_headings" ] || [ -n "$_pr_example" ]; then
          printf '## PR description guide\n\n'
          printf '_Detected from recent merged PRs in this repo. Follow this structure when creating PRs._\n\n'

          if [ -n "$_pr_headings" ]; then
            printf '**Common sections** (appear in multiple PRs):\n\n'
            while IFS= read -r _h; do
              [ -n "$_h" ] || continue
              printf -- '- %s\n' "$_h"
            done <<EOF
$_pr_headings
EOF
            printf '\n'
          fi

          if [ -n "$_pr_example" ]; then
            local _pr_title _pr_body
            _pr_title="$(printf '%s' "$_pr_example" | head -1)"
            _pr_body="$(printf '%s' "$_pr_example" | tail -n +2)"
            if [ -n "$_pr_body" ]; then
              printf '**Best example** (PR %s):\n\n' "$_pr_title"
              printf '```markdown\n%s\n```\n\n' "$_pr_body"
            fi
          fi
        fi
      fi

      # ── Dynamic issue update guide (from repo GitHub history) ────────────────
      local _issue_comments _issue_patterns _issue_example
      _issue_comments="$(dev_kit_learning_github_recent_issue_comments "$repo_dir" 2>/dev/null || true)"
      if [ -n "$_issue_comments" ]; then
        _issue_patterns="$(dev_kit_learning_github_issue_update_detect "$_issue_comments")"
        _issue_example="$(dev_kit_learning_github_best_issue_comment "$_issue_comments")"

        if [ -n "$_issue_patterns" ] || [ -n "$_issue_example" ]; then
          printf '## Issue update guide\n\n'
          printf '_Detected from recent issue comments by the authenticated user. Follow this style when posting updates._\n\n'

          if [ -n "$_issue_patterns" ]; then
            printf '**Detected patterns:**\n\n'
            while IFS= read -r _p; do
              [ -n "$_p" ] || continue
              printf -- '- %s\n' "$_p"
            done <<EOF
$_issue_patterns
EOF
            printf '\n'
          fi

          if [ -n "$_issue_example" ]; then
            printf '**Example update:**\n\n'
            printf '```markdown\n%s\n```\n\n' "$_issue_example"
          fi
        fi
      fi

      # ── Principles — engineering practices ───────────────────────────────────
      local _practices
      _practices="$(dev_kit_agent_principle_lines)"
      if [ -n "$_practices" ]; then
        printf '## Engineering practices\n\n%s\n\n' "$_practices"
      fi
    fi
  } > "$agents_md_path"
}
