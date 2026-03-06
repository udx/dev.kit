#!/usr/bin/env bash

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_cmd_skills() {
  local sub="${1:-list}"
  local skills_dir="$HOME/.gemini/skills"
  
  case "$sub" in
    list)
      print_section "dev.kit | Available Engineering Skills"
      # List from native gemini path
      if [ -d "$skills_dir" ]; then
        find "$skills_dir" -mindepth 1 -maxdepth 1 -name "dev-kit-*" -type d | while read -r skill; do
          local name
          name="$(basename "$skill")"
          local desc="(no description)"
          if [ -f "$skill/SKILL.md" ]; then
            desc="$(grep -m 1 "^" "$skill/SKILL.md" | sed 's/^# //')"
          fi
          echo "- [remote] $name"
          echo "  description: $desc"
          if [ -d "$skill/scripts" ]; then
             echo "  scripts:     $(ls "$skill/scripts" | tr '\n' ' ')"
          fi
          echo ""
        done
      fi
      
      # List from local repo
      local local_packs="$REPO_DIR/src/ai/data/skill-packs"
      if [ -d "$local_packs" ]; then
        find "$local_packs" -mindepth 1 -maxdepth 1 -type d | while read -r skill; do
          local name
          name="$(basename "$skill")"
          echo "- [local]  $name"
          if [ -f "$skill/SKILL.md" ]; then
            echo "  description: $(grep -m 1 "^" "$skill/SKILL.md" | sed 's/^# //')"
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
      shift 3 || shift 2 || true
      
      if [ -z "$skill_name" ]; then
        echo "Error: Skill name required. Usage: dev.kit skills run <skill-name> [script-name] [args]" >&2
        exit 1
      fi
      
      # Find skill path
      local skill_path=""
      if [ -d "$skills_dir/$skill_name" ]; then
        skill_path="$skills_dir/$skill_name"
      elif [ -d "$skills_dir/dev-kit-$skill_name" ]; then
        skill_path="$skills_dir/dev-kit-$skill_name"
      elif [ -d "$REPO_DIR/src/ai/data/skill-packs/$skill_name" ]; then
        skill_path="$REPO_DIR/src/ai/data/skill-packs/$skill_name"
      fi
      
      if [ -z "$skill_path" ]; then
        echo "Error: Skill '$skill_name' not found." >&2
        exit 1
      fi
      
      # Determine script
      local script_file=""
      if [ -z "$script_name" ] || [ ! -f "$skill_path/scripts/$script_name" ]; then
         # Try finding a "main" or the only script
         if [ -d "$skill_path/scripts" ]; then
            script_file="$(find "$skill_path/scripts" -maxdepth 1 -type f -perm +111 | head -n 1)"
         fi
      else
         script_file="$skill_path/scripts/$script_name"
      fi
      
      if [ -z "$script_file" ] || [ ! -f "$script_file" ]; then
        echo "Error: No executable script found for skill '$skill_name'." >&2
        exit 1
      fi
      
      echo "Executing skill: $skill_name ($(basename "$script_file"))"
      "$script_file" "$@"
      ;;
    info)
      local skill_name="${2:-}"
      [ -z "$skill_name" ] && { echo "Error: Skill name required."; exit 1; }
      # (Similar path finding logic...)
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
