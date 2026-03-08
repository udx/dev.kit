#!/usr/bin/env bash

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_cmd_ai() {
  local sub="${1:-status}"
  local data_dir="$REPO_DIR/src/ai/data"
  
  case "$sub" in
    status)
      print_section "dev.kit | AI Integration Status"
      local provider
      provider="$(config_value_scoped ai.provider "codex")"
      local enabled
      enabled="$(config_value_scoped ai.enabled "false")"
      
      print_check "Provider" "[ok]" "$provider"
      print_check "Enabled" "$([ "$enabled" = "true" ] && echo "[ok]" || echo "[warn]")" "$enabled"
      
      echo ""
      echo "Active Integrations:"
      if [ -d "$HOME/.gemini" ]; then
        print_check "Gemini" "[ok]" "path: ~/.gemini"
      else
        print_check "Gemini" "[warn]" "missing (run: dev.kit ai sync)"
      fi
      if [ -d "$HOME/.codex" ]; then
        print_check "Codex" "[ok]" "path: ~/.codex"
      else
        print_check "Codex" "[warn]" "missing (run: dev.kit ai sync)"
      fi
      ;;
    sync)
      local provider="${2:-}"
      if [ -z "$provider" ]; then
        provider="$(config_value_scoped ai.provider "codex")"
      fi
      echo "Synchronizing AI skills and memories for: $provider"
      if command -v dev_kit_agent_apply_integration >/dev/null 2>&1; then
        dev_kit_agent_apply_integration "$provider" "apply"
      else
        echo "Error: Synchronization logic not loaded correctly." >&2
        exit 1
      fi
      ;;
    skills)
      print_section "dev.kit | Managed AI Skills"
      local skill_file=""
      while IFS= read -r skill_file; do
        [ -z "$skill_file" ] && continue
        local name desc usage keywords workflow
        name="$(jq -r '.name' "$skill_file" || echo "unknown")"
        desc="$(jq -r '.description' "$skill_file" || echo "no description")"
        
        local pack_dir
        pack_dir="$(jq -r '.pack_dir // empty' "$skill_file" || echo "")"
        [ -z "$pack_dir" ] && pack_dir="skill-packs/$name"
        
        local skill_md="$data_dir/$pack_dir/SKILL.md"
        usage="dev.kit skills run \"<intent for $name>\""
        if [ -f "$skill_md" ]; then
           local example
           # Grep more lines and allow failure
           example="$(grep -A 10 "## CLI Usage Example" "$skill_md" 2>/dev/null | grep "dev.kit" | head -n 1 | sed 's/^[[:space:]]*//' || true)"
           [ -n "$example" ] && usage="$example"
        fi
        
        keywords="$(jq -r '.keywords | join(", ") // "none"' "$skill_file" 2>/dev/null || echo "none")"
        workflow="$(jq -r '.sections[] | select(.title == "Typical Workflow") | .bullets | join("; ") // "none"' "$skill_file" 2>/dev/null || echo "none")"
        
        echo "- [skill] $name"
        echo "  description: $desc"
        echo "  usage:       $usage"
        echo "  keywords:    $keywords"
        echo "  workflow:    $workflow"
        echo ""
      done < <(find "$data_dir/skills" -type f -name '*.json' | sort)
      ;;
    commands)
      print_section "dev.kit | CLI Commands Metadata"
      local cmd_data="$data_dir/commands.json"
      if [ ! -f "$cmd_data" ]; then
        echo "Error: Command metadata not found: $cmd_data" >&2
        exit 1
      fi
      
      jq -c '.commands[]' "$cmd_data" | while IFS= read -r cmd; do
        local key desc keywords w_plan w_norm w_proc
        key="$(echo "$cmd" | jq -r '.key' || echo "unknown")"
        desc="$(echo "$cmd" | jq -r '.description' || echo "no description")"
        keywords="$(echo "$cmd" | jq -r '.keywords | join(", ")' 2>/dev/null || echo "none")"
        w_plan="$(echo "$cmd" | jq -r '.workflow.plan' 2>/dev/null || echo "none")"
        w_norm="$(echo "$cmd" | jq -r '.workflow.normalize' 2>/dev/null || echo "none")"
        w_proc="$(echo "$cmd" | jq -r '.workflow.process' 2>/dev/null || echo "none")"
        
        echo "- [command] dev.kit $key"
        echo "  description: $desc"
        echo "  keywords:    $keywords"
        echo "  workflow:    Plan: $w_plan; Normalize: $w_norm; Process: $w_proc"
        echo ""
      done
      ;;
    workflows)
      print_section "dev.kit | Engineering Loops (Workflows)"
      local workflow_data="$data_dir/workflows.json"
      if [ ! -f "$workflow_data" ]; then
        echo "Error: Workflow data not found: $workflow_data" >&2
        exit 1
      fi
      
      jq -c '.workflows[]' "$workflow_data" | while IFS= read -r wf; do
        local name desc steps
        name="$(echo "$wf" | jq -r '.name')"
        desc="$(echo "$wf" | jq -r '.description')"
        steps="$(echo "$wf" | jq -r '.steps | join("\n    - ")')"
        
        echo "- [loop] $name"
        echo "  description: $desc"
        echo "  steps:"
        echo "    - $steps"
        echo ""
      done
      ;;
    advisory)
      local ops_dir="$REPO_DIR/docs/reference/operations"
      if [ -d "$ops_dir" ]; then
        echo "Engineering Advisory (Resolved Insights):"
        local file=""
        while IFS= read -r file; do
           [ -z "$file" ] && continue
           local title
           title="$(head -n 1 "$file" | sed 's/^# //')"
           local highlights
           highlights="$(grep -m 2 "^- " "$file" | head -n 2 | sed 's/^- /  - /' || true)"
           echo "- [insight] $title"
           if [ -n "$highlights" ]; then
              echo "$highlights"
           fi
        done < <(find "$ops_dir" -type f -name '*.md' | sort)
      else
        echo "Engineering Advisory: (no local guidance artifacts found)"
      fi
      ;;
    help|-h|--help)
      cat <<'AI_HELP'
Usage: dev.kit ai <command>

Commands:
  status     Show AI provider and integration health
  sync       Synchronize AI skills, memories, and hooks
  skills     List managed AI skills with usage and workflow
  commands   List CLI commands with waterfall metadata
  workflows  List standardized engineering loops (loops)
  advisory   Fetch engineering guidance from local docs
AI_HELP
      ;;
    *)
      echo "Unknown ai command: $sub" >&2
      exit 1
      ;;
  esac
}
