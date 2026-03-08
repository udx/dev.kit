#!/usr/bin/env bash

# @description: Discover and execute repository-bound skills.
# @intent: skills, list, run, discover, execute
# @objective: Provide a unified interface for discovering and executing both deterministic CLI commands and managed AI skills grounded in the repository.
# @usage: dev.kit skills list
# @usage: dev.kit skills run <name> [intent]
# @workflow: 1. Discover capabilities -> 2. Resolve intent -> 3. Normalize to deterministic command -> 4. Execute and report

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_cmd_skills() {
  local sub="${1:-list}"
  
  # Resolve skills directory based on active provider
  local provider
  provider="$(config_value_scoped ai.provider "gemini")"
  local skills_dir="$HOME/.$provider/skills"
  
  case "$sub" in
    list)
      print_section "dev.kit | Dynamic Capability Mesh"
      
      # 1. Deterministic Commands (Internal Logic)
      echo "Deterministic Commands (Internal Logic):"
      for file in "$REPO_DIR"/lib/commands/*.sh; do
        [ -f "$file" ] || continue
        local name; name="$(basename "${file%.sh}")"
        # Hide internal/utility commands from the main logic list
        case "$name" in agent|github|skills) continue ;; esac
        
        local desc; desc="$(grep "^# @description:" "$file" | cut -d: -f2- | sed 's/^ //' || echo "no description")"
        echo "- [command] $name: $desc"
      done
      
      # List from lib/modules/
      for file in "$REPO_DIR"/lib/modules/*.sh; do
        [ -f "$file" ] || continue
        local name; name="$(basename "${file%.sh}")"
        local desc; desc="$(grep "^# @description:" "$file" | cut -d: -f2- | sed 's/^ //' || echo "no description")"
        echo "- [module]  $name: $desc"
      done
      echo ""

      # 2. AI Skills (Dynamic Reasoning)
      echo "AI Skills (Dynamic Reasoning):"
      # List from provider-specific managed path
      if [ -d "$skills_dir" ]; then
        find "$skills_dir" -mindepth 1 -maxdepth 1 -name "dev-kit-*" -type d | while read -r skill; do
          local name; name="$(basename "$skill")"
          local desc="(no description)"
          if [ -f "$skill/SKILL.md" ]; then
            desc="$(grep -i "^description:" "$skill/SKILL.md" | head -n 1 | sed 's/^description: //I')"
          fi
          echo "- [skill]   $name: $desc"
        done
      fi
      
      # List from local repo workflows
      local local_workflows="$REPO_DIR/docs/workflows"
      if [ -d "$local_workflows" ]; then
        find "$local_workflows" -maxdepth 1 -name "*.md" | while read -r skill_file; do
          local filename; filename="$(basename "$skill_file")"
          [ "$filename" = "README.md" ] && continue
          [ "$filename" = "normalization.md" ] && continue
          [ "$filename" = "loops.md" ] && continue
          [ "$filename" = "mermaid-patterns.md" ] && continue

          local name="${filename%.md}"
          # Skip showing if already listed in managed
          [ -d "$skills_dir/dev-kit-$name" ] && continue
          
          local desc; desc="$(grep -i "^description:" "$skill_file" | head -n 1 | sed 's/^description: //I' || echo "Grounded workflow reasoning.")"
          echo "- [skill]   $name: $desc"
        done
      fi
      echo ""

      # 3. Virtual Capabilities
      echo "Virtual Capabilities (Environment):"
      if command -v gh >/dev/null 2>&1; then echo "- [virtual] github (via gh CLI)"; fi
      if command -v npm >/dev/null 2>&1; then echo "- [virtual] npm (via node runtime)"; fi
      if command -v docker >/dev/null 2>&1; then echo "- [virtual] docker (via docker CLI)"; fi
      if command -v gcloud >/dev/null 2>&1; then echo "- [virtual] google (via gcloud CLI)"; fi
      echo ""
      
      return 0
      ;;
    run|execute)
      local skill_name="${2:-}"
      local intent="${3:-}"
      
      if [ -z "$skill_name" ]; then
        echo "Error: Skill name required. Usage: dev.kit skills run <skill-name> [intent]" >&2
        exit 1
      fi
      
      # Determine skill path or file
      local skill_path=""
      local skill_file=""
      if [ -d "$skills_dir/$skill_name" ]; then
        skill_path="$skills_dir/$skill_name"
      elif [ -d "$skills_dir/dev-kit-$skill_name" ]; then
        skill_path="$skills_dir/dev-kit-$skill_name"
      elif [ -f "$REPO_DIR/docs/workflows/$skill_name.md" ]; then
        skill_file="$REPO_DIR/docs/workflows/$skill_name.md"
      elif [ -f "$REPO_DIR/docs/workflows/dev-kit-$skill_name.md" ]; then
        skill_file="$REPO_DIR/docs/workflows/dev-kit-$skill_name.md"
      fi
      
      # If skill path found, execute legacy script logic
      if [ -n "$skill_path" ]; then
        local script_exec=""
        if [ -d "$skill_path/scripts" ]; then
          if [ -f "$skill_path/scripts/$intent" ]; then
            script_exec="$skill_path/scripts/$intent"
          fi
        fi
        
        if [ -n "$script_exec" ]; then
          [ ! -x "$script_exec" ] && chmod +x "$script_exec"
          export SKILL_PATH="$skill_path"
          export SKILL_NAME="$skill_name"
          shift 3 || true
          "$script_exec" "$@"
          exit $?
        fi
      fi
      
      # Dynamic Intent Normalization (The Modern Path)
      if command -v dev_kit_context_normalize >/dev/null 2>&1; then
        echo "--- dev.kit Intent Normalization ---"
        echo "Input:  $skill_name $intent"
        
        # Resolve intent to a structured manifest
        local manifest
        manifest="$(dev_kit_context_normalize "$skill_name $intent")"
        
        # Display the resolution for transparency
        if command -v jq >/dev/null 2>&1; then
          echo "Resolution:"
          
          # 1. Standard Commands/Workflows
          echo "$manifest" | jq -r '.mappings.discovery[]? | "  - [Detected] \(.name) (\(.type))"'
          echo "$manifest" | jq -r '.mappings.internal_workflows[]? | "  - [Workflow] \(.name) (\(.path))"'
        fi
        echo "------------------------------------"
        echo "Status: Intent Resolved (Dynamic Discovery)"
        exit 0
      else
        echo "Error: Normalization mechanism not loaded." >&2
        exit 1
      fi
      ;;
    info)
      local skill_name="${2:-}"
      [ -z "$skill_name" ] && { echo "Error: Skill name required."; exit 1; }
      
      local skill_path=""
      local skill_file=""
      if [ -d "$skills_dir/$skill_name" ]; then
        skill_path="$skills_dir/$skill_name"
      elif [ -d "$skills_dir/dev-kit-$skill_name" ]; then
        skill_path="$skills_dir/dev-kit-$skill_name"
      elif [ -f "$REPO_DIR/docs/workflows/$skill_name.md" ]; then
        skill_file="$REPO_DIR/docs/workflows/$skill_name.md"
      elif [ -f "$REPO_DIR/docs/workflows/dev-kit-$skill_name.md" ]; then
        skill_file="$REPO_DIR/docs/workflows/dev-kit-$skill_name.md"
      fi
      
      if [ -n "$skill_path" ] && [ -f "$skill_path/SKILL.md" ]; then
        cat "$skill_path/SKILL.md"
      elif [ -n "$skill_file" ]; then
        cat "$skill_file"
      else
        echo "Error: Skill info for '$skill_name' not found." >&2
        exit 1
      fi
      ;;
    help|-h|--help)
      cat <<'SKILLS_HELP'
Usage: dev.kit skills <command>

Commands:
  list                 List all available skills and their scripts
  run <name> [script]  Execute a script from a skill
  info <name>          Display skill documentation (SKILL.md)

Examples:
  dev.kit skills run diagram-generator new_diagram.sh "A -> B"
  dev.kit skills execute git-sync
SKILLS_HELP
      ;;
    *)
      echo "Unknown skills command: $sub" >&2
      exit 1
      ;;
  esac
}
