#!/usr/bin/env bash

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
      print_section "dev.kit | Available Engineering Skills"
      # List from provider-specific managed path
      if [ -d "$skills_dir" ]; then
        find "$skills_dir" -mindepth 1 -maxdepth 1 -name "dev-kit-*" -type d | while read -r skill; do
          local name
          name="$(basename "$skill")"
          local desc="(no description)"
          if [ -f "$skill/SKILL.md" ]; then
            # Extract first non-frontmatter line or first header
            desc="$(grep -v "^---" "$skill/SKILL.md" | grep -v "^$" | head -n 1 | sed 's/^# //')"
          fi
          echo "- [remote] $name"
          echo "  description: $desc"
          if [ -d "$skill/scripts" ]; then
             echo "  scripts:     $(ls "$skill/scripts" | tr '\n' ' ')"
          fi
          echo ""
        done
      fi
      
      # List from local repo skill-packs
      local local_packs="$REPO_DIR/src/ai/data/skill-packs"
      if [ -d "$local_packs" ]; then
        find "$local_packs" -mindepth 1 -maxdepth 1 -type d | while read -r skill; do
          local name
          name="$(basename "$skill")"
          echo "- [local]  $name"
          if [ -f "$skill/SKILL.md" ]; then
            echo "  description: $(grep -v "^---" "$skill/SKILL.md" | grep -v "^$" | head -n 1 | sed 's/^# //')"
          fi
          if [ -d "$skill/scripts" ]; then
             echo "  scripts:     $(ls "$skill/scripts" | tr '\n' ' ')"
          fi
          echo ""
        done
      fi
      ;;
    run|execute)
      local skill_name="${2:-}"
      local script_name="${3:-}"
      
      if [ -z "$skill_name" ]; then
        echo "Error: Skill name required. Usage: dev.kit skills run <skill-name> [script-name] [args]" >&2
        exit 1
      fi
      
      # Shift arguments to pass the rest to the script
      if [[ "$script_name" == *.sh ]] || [[ "$script_name" == *.py ]] || [[ "$script_name" == *.js ]]; then
         shift 3 || true
      else
         # If script_name doesn't look like a script, maybe it's actually an argument for the default script
         script_name=""
         shift 2 || true
      fi
      
      # Find skill path
      local skill_path=""
      if [ -d "$skills_dir/$skill_name" ]; then
        skill_path="$skills_dir/$skill_name"
      elif [ -d "$skills_dir/dev-kit-$skill_name" ]; then
        skill_path="$skills_dir/dev-kit-$skill_name"
      elif [ -d "$REPO_DIR/src/ai/data/skill-packs/$skill_name" ]; then
        skill_path="$REPO_DIR/src/ai/data/skill-packs/$skill_name"
      elif [ -d "$REPO_DIR/src/ai/data/skill-packs/dev-kit-$skill_name" ]; then
        skill_path="$REPO_DIR/src/ai/data/skill-packs/dev-kit-$skill_name"
      fi
      
      if [ -z "$skill_path" ]; then
        echo "Error: Skill '$skill_name' not found." >&2
        exit 1
      fi
      
      # Determine script
      local script_file=""
      if [ -n "$script_name" ] && [ -f "$skill_path/scripts/$script_name" ]; then
         script_file="$skill_path/scripts/$script_name"
      else
         # Try finding a "main" or the first executable script
         if [ -d "$skill_path/scripts" ]; then
            # Search for common entry points first
            for entry in "main.sh" "run.sh" "$(basename "$skill_path").sh"; do
              if [ -x "$skill_path/scripts/$entry" ]; then
                script_file="$skill_path/scripts/$entry"
                break
              fi
            done
            # Fallback to first executable if no standard entry point found
            if [ -z "$script_file" ]; then
              while IFS= read -r f; do
                if [ -x "$f" ]; then
                  script_file="$f"
                  break
                fi
              done < <(find "$skill_path/scripts" -maxdepth 1 -type f)
            fi
         fi
      fi
      
      if [ -z "$script_file" ] || [ ! -f "$script_file" ]; then
        echo "Error: No executable script found for skill '$skill_name'." >&2
        exit 1
      fi

      # Ensure executable
      [ ! -x "$script_file" ] && chmod +x "$script_file"
      
      # Prepare environment
      export SKILL_PATH="$skill_path"
      export SKILL_NAME="$skill_name"
      
      echo "--- dev.kit Skill Execution ---"
      echo "Skill:  $skill_name"
      echo "Script: $(basename "$script_file")"
      echo "Path:   $script_file"
      echo "-------------------------------"
      
      "$script_file" "$@"
      ;;
    info)
      local skill_name="${2:-}"
      [ -z "$skill_name" ] && { echo "Error: Skill name required."; exit 1; }
      
      local skill_path=""
      if [ -d "$skills_dir/$skill_name" ]; then
        skill_path="$skills_dir/$skill_name"
      elif [ -d "$skills_dir/dev-kit-$skill_name" ]; then
        skill_path="$skills_dir/dev-kit-$skill_name"
      elif [ -d "$REPO_DIR/src/ai/data/skill-packs/$skill_name" ]; then
        skill_path="$REPO_DIR/src/ai/data/skill-packs/$skill_name"
      fi
      
      if [ -z "$skill_path" ] || [ ! -f "$skill_path/SKILL.md" ]; then
        echo "Error: Skill info for '$skill_name' not found." >&2
        exit 1
      fi
      
      cat "$skill_path/SKILL.md"
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
