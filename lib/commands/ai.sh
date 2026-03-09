#!/bin/bash

# @description: Unified agent integration management (Sync, Skills, Status, Configuration).
# @intent: ai, agent, integration, skills, sync, status
# @objective: Manage the lifecycle of AI integrations by synchronizing skills, monitoring health, and configuring agent artifacts.
# @usage: dev.kit ai status
# @usage: dev.kit ai sync gemini
# @usage: dev.kit ai agent gemini --plan
# @workflow: 1. Monitor Integration Health -> 2. Synchronize Skills & Memories -> 3. Configure Agent Artifacts -> 4. Provide Advisory Insights

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_cmd_ai() {
  local sub="${1:-status}"
  
  case "$sub" in
    status)
      print_section "dev.kit | AI Integration Status"
      local provider; provider="$(config_value_scoped ai.provider "gemini")"
      local enabled; enabled="$(config_value_scoped ai.enabled "false")"
      
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
      [ -z "$provider" ] && provider="$(config_value_scoped ai.provider "gemini")"
      echo "Synchronizing AI skills and memories for: $provider"
      if command -v dev_kit_agent_apply_integration >/dev/null 2>&1; then
        dev_kit_agent_apply_integration "$provider" "apply"
      else
        echo "Error: Agent manager module not loaded." >&2
        exit 1
      fi
      ;;
    agent)
      shift
      local agent_sub="${1:-status}"
      case "$agent_sub" in
        status)
          echo "Integrations found in manifest:"
          jq -r '.integrations[].key' "$(dev_kit_agent_manifest)" | sed 's/^/- /'
          ;;
        disable)
          local key="${2:-}"
          if [ "$key" = "all" ]; then
            for k in $(jq -r '.integrations[].key' "$(dev_kit_agent_manifest)"); do dev_kit_agent_disable_integration "$k"; done
          else
            [ -z "$key" ] && { echo "Usage: dev.kit ai agent disable <key|all>" >&2; exit 1; }
            dev_kit_agent_disable_integration "$key"
          fi
          ;;
        skills)
          local key="${2:-}"
          [ -z "$key" ] && { echo "Usage: dev.kit ai agent skills <key>" >&2; exit 1; }
          local manifest="$(dev_kit_agent_manifest)"
          local target_dir="$(dev_kit_agent_expand_path "$(jq -r ".integrations[] | select(.key == \"$key\") | .target_dir" "$manifest")")"
          echo "Managed Skills for '$key' ($target_dir/skills):"
          [ -d "$target_dir/skills" ] && ls "$target_dir/skills" | sed 's/^/- /' || echo "(none)"
          ;;
        *)
          local key="$agent_sub"
          local mode="apply"
          [ "${2:-}" = "--plan" ] && mode="plan"
          if [ "$key" = "all" ]; then
            for k in $(jq -r '.integrations[].key' "$(dev_kit_agent_manifest)"); do dev_kit_agent_apply_integration "$k" "$mode"; done
          else
            dev_kit_agent_apply_integration "$key" "$mode"
          fi
          ;;
      esac
      ;;
    skills)
      print_section "dev.kit | Managed AI Skills"
      local local_packs="$REPO_DIR/docs/skills"
      if [ -d "$local_packs" ]; then
        find "$local_packs" -mindepth 1 -maxdepth 1 -type d | sort | while IFS= read -r skill; do
          local name; name="$(basename "$skill")"
          local desc; desc="$(grep -i "^description:" "$skill/SKILL.md" 2>/dev/null | head -n 1 | sed 's/^description: //I' || echo "no description")"
          echo "- [skill] $name"
          echo "  description: $desc"
          echo "  usage:       dev.kit skills run \"$name\" \"<intent>\""
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
        echo "- [command] dev.kit $key"
        echo "  description: $desc"
        echo ""
      done
      ;;
    advisory)
      local ops_dir="$REPO_DIR/docs/reference/operations"
      if [ -d "$ops_dir" ]; then
        echo "Engineering Advisory (Resolved Insights):"
        find "$ops_dir" -type f -name '*.md' | sort | while IFS= read -r file; do
           local title; title="$(head -n 1 "$file" | sed 's/^# //')"
           echo "- [insight] $title"
        done
      fi
      ;;
    help|-h|--help)
      cat <<'AI_HELP'
Usage: dev.kit ai <command>

Commands:
  status           Show AI provider and integration health
  sync [provider]  Synchronize AI skills, memories, and hooks
  agent <key>      Configure agent artifacts (use --plan to dry-run)
  skills           List managed AI skills
  commands         List CLI commands with metadata
  advisory         Fetch engineering guidance from local docs
AI_HELP
      ;;
    *) echo "Unknown ai command: $sub" >&2; exit 1 ;;
  esac
}
