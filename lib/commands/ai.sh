#!/bin/bash

# @description: Unified agent integration management (Sync, Skills, Status).
# @intent: ai, agent, integration, skills, sync, status
# @objective: Manage the lifecycle of AI integrations by synchronizing skills, monitoring health, and providing engineering advisory insights.
# @usage: dev.kit ai status
# @usage: dev.kit ai sync gemini
# @workflow: 1. Monitor Integration Health -> 2. Synchronize Skills & Memories -> 3. Ground Agent in Engineering Loop -> 4. Provide Advisory Insights

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
      provider="$(config_value_scoped ai.provider "gemini")"
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
      ;;
    sync)
      local provider="${2:-}"
      if [ -z "$provider" ]; then
        provider="$(config_value_scoped ai.provider "gemini")"
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
      local local_packs="$REPO_DIR/docs/skills"
      if [ -d "$local_packs" ]; then
        find "$local_packs" -mindepth 1 -maxdepth 1 -type d | sort | while IFS= read -r skill; do
          local name desc usage
          name="$(basename "$skill")"
          desc="$(grep -i "^description:" "$skill/SKILL.md" 2>/dev/null | head -n 1 | sed 's/^description: //I' || echo "no description")"
          usage="dev.kit skills run \"$name\" \"<intent>\""
          
          echo "- [skill] $name"
          echo "  description: $desc"
          echo "  usage:       $usage"
          echo ""
        done
      fi
      ;;
    commands)
      print_section "dev.kit | CLI Commands Metadata"
      for file in "$REPO_DIR"/lib/commands/*.sh; do
        [ -f "$file" ] || continue
        local key; key="$(basename "${file%.sh}")"
        local desc; desc="$(grep "^# @description:" "$file" | cut -d: -f2- | sed 's/^ //' || echo "no description")"
        local objective; objective="$(grep "^# @objective:" "$file" | cut -d: -f2- | sed 's/^ //' || echo "")"
        local workflow; workflow="$(grep "^# @workflow:" "$file" | cut -d: -f2- | sed 's/^ //' || echo "")"
        local intents; intents="$(grep "^# @intent:" "$file" | cut -d: -f2- | sed 's/^ //' || echo "none")"
        
        echo "- [command] dev.kit $key"
        echo "  description: $desc"
        [ -n "$objective" ] && echo "  objective:   $objective"
        [ -n "$workflow" ] && echo "  workflow:    $workflow"
        echo "  intents:     $intents"
        echo ""
      done
      ;;
    workflows)
      print_section "dev.kit | Engineering Loops (Workflows)"
      local workflow_file="$REPO_DIR/docs/ai/workflows.md"
      if [ -f "$workflow_file" ]; then
        # Parse markdown headers as workflow names
        grep "^## " "$workflow_file" | sed 's/^## //' | while IFS= read -r name; do
          echo "- [loop] $name"
          # Simple extraction of description/steps if needed
          echo ""
        done
      else
        echo "No centralized workflow documentation found."
      fi
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
