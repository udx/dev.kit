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
      local intent="${3:-}"
      
      if [ -z "$skill_name" ]; then
        echo "Error: Skill name required. Usage: dev.kit skills run <skill-name> [intent]" >&2
        exit 1
      fi
      
      # Determine skill path
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
      
      # Step 1: Check for legacy scripts (Fallback)
      local script_file=""
      if [ -d "$skill_path/scripts" ]; then
        if [ -f "$skill_path/scripts/$intent" ]; then
          script_file="$skill_path/scripts/$intent"
        fi
      fi
      
      if [ -n "$script_file" ]; then
        [ ! -x "$script_file" ] && chmod +x "$script_file"
        export SKILL_PATH="$skill_path"
        export SKILL_NAME="$skill_name"
        shift 3 || true
        "$script_file" "$@"
        exit $?
      fi
      
      # Step 2: Dynamic Intent Normalization (The Modern Path)
      if command -v dev_kit_context_normalize >/dev/null 2>&1; then
        echo "--- dev.kit Intent Normalization ---"
        echo "Skill:  $skill_name"
        echo "Intent: $intent"
        
        # Resolve intent to a structured manifest
        local manifest
        manifest="$(dev_kit_context_normalize "$intent")"
        
        # Display the resolution for transparency
        if command -v jq >/dev/null 2>&1; then
          echo "Resolution:"
          
          # 1. Standard Commands/Workflows
          echo "$manifest" | jq -r '.mappings.explicit[]? | select(.type != "mesh-packages") | "  - Command: \(.name)"'
          echo "$manifest" | jq -r '.mappings.internal_workflows[]? | "  - Workflow: \(.name) (\(.path))"'
          
          # 2. NPM Packages with Health/Installation Hints
          local pkgs
          pkgs="$(echo "$manifest" | jq -r '.mappings.explicit[]? | select(.type == "mesh-packages") | .name')"
          for pkg in $pkgs; do
            if command -v dev_kit_npm_health >/dev/null 2>&1; then
              local bin
              bin="$(echo "$pkg" | sed 's/.*[\/]//')"
              if ! command -v "$bin" >/dev/null 2>&1; then
                 echo "  - Package: $pkg (Not installed)"
                 dev_kit_npm_install_hint "$pkg" "$bin"
              else
                 echo "  - Package: $pkg (Ready)"
              fi
            else
              echo "  - Package: $pkg"
            fi
          done
        fi
        echo "------------------------------------"
        
        # TODO: Implement automatic execution of the first high-priority mapping
        # For now, we've successfully mapped the intent to the deterministic engine.
        echo "Status: Intent Resolved (Normalization Layer)"
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
