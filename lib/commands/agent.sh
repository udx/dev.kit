#!/bin/bash

# @description: Direct agent integration management (advanced).
# @intent: agent, llm, provider, model, configure
# @objective: Orchestrate the rendering and deployment of AI provider artifacts (Gemini) using dynamic normalization from documentation and scripts.
# @usage: dev.kit agent gemini --plan
# @usage: dev.kit agent all
# @workflow: 1. Parse Manifest -> 2. Render Templates from Docs/Lib -> 3. Synchronize Skills -> 4. Backup & Deploy Artifacts

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_agent_manifest() {
  echo "$REPO_DIR/src/ai/integrations/manifest.json"
}

dev_kit_agent_expand_path() {
  local val="$1"
  val="${val//\{\{HOME\}\}/$HOME}"
  val="${val//\{\{DEV_KIT_HOME\}\}/$DEV_KIT_HOME}"
  val="${val//\{\{DEV_KIT_STATE\}\}/$DEV_KIT_STATE}"
  echo "$val"
}

dev_kit_agent_render_artifact() {
  local type="$1"
  local src_tmpl="$2"
  local dst_path="$3"
  local base_rendered="$4"
  
  case "$type" in
    template)
      # Dynamic gathering from Docs & Lib
      local agent_skills=""
      local available_tools=""
      local memories=""
      
      # Gather Workflows from docs/workflows/
      for skill_file in "$REPO_DIR"/docs/workflows/*.md; do
        [ -f "$skill_file" ] || continue
        local filename; filename="$(basename "$skill_file")"
        [ "$filename" = "README.md" ] && continue
        [ "$filename" = "normalization.md" ] && continue
        [ "$filename" = "loops.md" ] && continue
        [ "$filename" = "mermaid-patterns.md" ] && continue

        local name="${filename%.md}"
        local desc; desc="$(grep -i "^description:" "$skill_file" 2>/dev/null | head -n 1 | sed 's/^description: //I' || echo "Grounded workflow reasoning.")"
        agent_skills+="- **$name**: $desc\n"
      done
      
      # Gather Commands from lib/commands/
      for file in "$REPO_DIR"/lib/commands/*.sh; do
        [ -f "$file" ] || continue
        local key desc
        key="$(basename "${file%.sh}")"
        # Hide internal/utility commands
        case "$key" in agent|github|skills) continue ;; esac
        desc="$(grep "^# @description:" "$file" | cut -d: -f2- | sed 's/^ //' || echo "no description")"
        available_tools+="- **dev.kit $key**: $desc\n"
      done
      
      # Gather Memories
      if [[ "$src_tmpl" == *"GEMINI"* ]]; then
        if [ -f "$HOME/.gemini/GEMINI.md" ]; then
          memories="$(grep -A 100 "Gemini Added Memories" "$HOME/.gemini/GEMINI.md" | tail -n +2 || true)"
        fi
        [ -z "$memories" ] && memories="- (none)"
      fi
      
      export DEV_KIT_RENDER_DATE="$(date +%Y-%m-%d)"
      export DEV_KIT_RENDER_HOME="$HOME"
      export DEV_KIT_RENDER_DEV_KIT_HOME="$DEV_KIT_HOME"
      export DEV_KIT_RENDER_DEV_KIT_SOURCE="$DEV_KIT_SOURCE"
      export DEV_KIT_RENDER_DEV_KIT_STATE="$DEV_KIT_STATE"
      export DEV_KIT_RENDER_SKILLS="$agent_skills"
      export DEV_KIT_RENDER_TOOLS="$available_tools"
      export DEV_KIT_RENDER_MEMORIES="$memories"

      perl -pe '
        s/\{\{DATE\}\}/$ENV{DEV_KIT_RENDER_DATE}/g;
        s/\{\{HOME\}\}/$ENV{DEV_KIT_RENDER_HOME}/g;
        s/\{\{DEV_KIT_HOME\}\}/$ENV{DEV_KIT_RENDER_DEV_KIT_HOME}/g;
        s/\{\{DEV_KIT_SOURCE\}\}/$ENV{DEV_KIT_RENDER_DEV_KIT_SOURCE}/g;
        s/\{\{DEV_KIT_STATE\}\}/$ENV{DEV_KIT_RENDER_DEV_KIT_STATE}/g;
        s/\$\{AgentSkills\}/$ENV{DEV_KIT_RENDER_SKILLS}/g;
        s/\$\{AvailableTools\}/$ENV{DEV_KIT_RENDER_TOOLS}/g;
        s/\{\{MEMORIES\}\}/$ENV{DEV_KIT_RENDER_MEMORIES}/g;
      ' "$src_tmpl" > "$dst_path"
      ;;
    *)
      cp "$src_tmpl" "$dst_path"
      ;;
  esac
}

dev_kit_agent_apply_integration() {
  local key="$1"
  local mode="$2"
  local manifest
  manifest="$(dev_kit_agent_manifest)"
  
  [ ! -f "$manifest" ] && { echo "Error: Manifest not found." >&2; exit 1; }

  local integration_json
  integration_json="$(jq -r ".integrations[] | select(.key == \"$key\")" "$manifest")"
  [ -z "$integration_json" ] && { echo "Error: Integration '$key' not found." >&2; exit 1; }

  local target_dir
  target_dir="$(dev_kit_agent_expand_path "$(echo "$integration_json" | jq -r '.target_dir')")"
  local templates_dir="$REPO_DIR/$(echo "$integration_json" | jq -r '.templates_dir')"
  local skills_dst_dir="$target_dir/skills"

  local rendered
  rendered="$(mktemp -d)"
  
  local artifacts_count
  artifacts_count="$(echo "$integration_json" | jq '.artifacts | length')"
  
  for ((i=0; i<artifacts_count; i++)); do
    local art_src="$(echo "$integration_json" | jq -r ".artifacts[$i].src")"
    local art_dst="$(echo "$integration_json" | jq -r ".artifacts[$i].dst")"
    local art_type="$(echo "$integration_json" | jq -r ".artifacts[$i].type")"
    
    mkdir -p "$(dirname "$rendered/$art_dst")"
    dev_kit_agent_render_artifact "$art_type" "$templates_dir/$art_src" "$rendered/$art_dst" "$rendered"
  done

  # Process Skills (from docs/workflows/)
  mkdir -p "$rendered/skills_sync"
  for skill_file in "$REPO_DIR"/docs/workflows/*.md; do
    [ -f "$skill_file" ] || continue
    local filename; filename="$(basename "$skill_file")"
    [ "$filename" = "README.md" ] && continue
    [ "$filename" = "normalization.md" ] && continue
    [ "$filename" = "loops.md" ] && continue
    [ "$filename" = "mermaid-patterns.md" ] && continue

    local name="${filename%.md}"
    [[ "$name" != dev-kit-* ]] && name="dev-kit-$name"
    
    mkdir -p "$rendered/skills_sync/$name"
    cp "$skill_file" "$rendered/skills_sync/$name/SKILL.md"
    
    # If there is a matching workflow yaml in assets, include it
    local asset_yaml="$REPO_DIR/docs/workflows/assets/${filename%.md}.yaml"
    if [ -f "$asset_yaml" ]; then
      cp "$asset_yaml" "$rendered/skills_sync/$name/workflow.yaml"
    fi
    
    # Include templates if it's the visualizer
    if [[ "$filename" == "visualizer.md" ]]; then
      mkdir -p "$rendered/skills_sync/$name/assets"
      cp -R "$REPO_DIR/docs/workflows/assets/templates" "$rendered/skills_sync/$name/assets/"
      # Also include mermaid patterns as a reference
      mkdir -p "$rendered/skills_sync/$name/references"
      cp "$REPO_DIR/docs/workflows/mermaid-patterns.md" "$rendered/skills_sync/$name/references/"
    fi
  done

  if [ "$mode" = "plan" ]; then
    echo "--- PLAN: Integration for '$key' ---"
    echo "Target: $target_dir"
    echo "Skills: $skills_dst_dir"
    echo ""
    echo "Artifacts:"
    find "$rendered" -type f ! -path "*/skills_sync/*" | sed "s|^$rendered/||" | sed 's/^/- /'
    echo ""
    echo "Managed Skills:"
    ls "$rendered/skills_sync" | sed 's/^/- /'
    rm -rf "$rendered"
    return 0
  fi

  # Apply
  local backup_dir="$target_dir/.backup/dev.kit/$(date +%Y%m%d%H%M%S)"
  mkdir -p "$backup_dir"

  find "$rendered" -type f ! -path "*/skills_sync/*" | while IFS= read -r file; do
    local rel_path="${file#$rendered/}"
    local dst_file="$target_dir/$rel_path"
    [ -f "$dst_file" ] && { mkdir -p "$(dirname "$backup_dir/$rel_path")"; cp "$dst_file" "$backup_dir/$rel_path"; }
    mkdir -p "$(dirname "$dst_file")"
    cp "$file" "$dst_file"
    echo "Applied: $rel_path"
  done

  mkdir -p "$skills_dst_dir"
  find "$skills_dst_dir" -mindepth 1 -maxdepth 1 -name "dev-kit-*" -type d -exec rm -rf {} +
  cp -R "$rendered/skills_sync/." "$skills_dst_dir/"
  echo "Applied: skills"

  rm -rf "$rendered"
}

dev_kit_agent_disable_integration() {
  local key="$1"
  local manifest; manifest="$(dev_kit_agent_manifest)"
  local integration_json; integration_json="$(jq -r ".integrations[] | select(.key == \"$key\")" "$manifest")"
  [ -z "$integration_json" ] && return 1

  local target_dir; target_dir="$(dev_kit_agent_expand_path "$(echo "$integration_json" | jq -r '.target_dir')")"
  [ ! -d "$target_dir" ] && return 0

  local backup_dir="$target_dir/.backup/dev.kit/disabled-$(date +%Y%m%d%H%M%S)"
  mkdir -p "$backup_dir"

  echo "Disabling integration: $key (Backing up to $backup_dir)"
  
  # Backup artifacts
  local artifacts_count; artifacts_count="$(echo "$integration_json" | jq '.artifacts | length')"
  for ((i=0; i<artifacts_count; i++)); do
    local art_dst="$(echo "$integration_json" | jq -r ".artifacts[$i].dst")"
    local dst_file="$target_dir/$art_dst"
    if [ -f "$dst_file" ]; then
      mkdir -p "$(dirname "$backup_dir/$art_dst")"
      mv "$dst_file" "$backup_dir/$art_dst"
    fi
  done

  # Backup skills
  if [ -d "$target_dir/skills" ]; then
    mv "$target_dir/skills" "$backup_dir/skills"
  fi

  echo "Disabled: $key"
}

dev_kit_cmd_agent() {
  local sub="${1:-status}"
  local mode="apply"
  
  case "$sub" in
    status)
      echo "Integrations found in manifest:"
      jq -r '.integrations[].key' "$(dev_kit_agent_manifest)" | sed 's/^/- /'
      ;;
    restore)
      local key="${2:-}"
      [ -z "$key" ] && { echo "Usage: dev.kit agent restore <key>" >&2; exit 1; }
      local manifest; manifest="$(dev_kit_agent_manifest)"
      local target_dir; target_dir="$(dev_kit_agent_expand_path "$(jq -r ".integrations[] | select(.key == \"$key\") | .target_dir" "$manifest")")"
      local backup_base="$target_dir/.backup/dev.kit"
      
      if [ ! -d "$backup_base" ]; then
        echo "No backups found for $key."
        return 1
      fi

      local last_backup; last_backup="$(ls -d "$backup_base"/*/ | sort | tail -n 1)"
      if [ -z "$last_backup" ]; then
        echo "No backups found for $key."
        return 1
      fi

      echo "Restoring $key from $last_backup..."
      cp -R "$last_backup/." "$target_dir/"
      echo "Restore complete."
      ;;
    disable)
      local key="${2:-}"
      if [ "$key" = "all" ]; then
        for k in $(jq -r '.integrations[].key' "$(dev_kit_agent_manifest)"); do
          dev_kit_agent_disable_integration "$k"
        done
      else
        [ -z "$key" ] && { echo "Usage: dev.kit agent disable <key|all>" >&2; exit 1; }
        dev_kit_agent_disable_integration "$key"
      fi
      ;;
    skills)
      local key="${2:-}"
      [ -z "$key" ] && { echo "Usage: dev.kit agent skills <key>" >&2; exit 1; }
      local manifest="$(dev_kit_agent_manifest)"
      local target_dir="$(dev_kit_agent_expand_path "$(jq -r ".integrations[] | select(.key == \"$key\") | .target_dir" "$manifest")")"
      local skills_dst_dir="$target_dir/skills"
      echo "Managed Skills for '$key' ($skills_dst_dir):"
      [ -d "$skills_dst_dir" ] && ls "$skills_dst_dir" | sed 's/^/- /' || echo "(none)"
      ;;
    help|-h|--help)
      cat <<'AGENT_USAGE'
Usage: dev.kit agent <command>

Commands:
  status         Show status of all AI agent integrations
  skills <key>   List managed skills for a specific agent
  restore <key>  Restore latest backup for specific agent
  disable <key>  Safely backup and remove agent settings
  <key> [--plan] Apply configuration for specific agent (e.g., gemini)
  all   [--plan] Apply all supported agent configurations
AGENT_USAGE
      ;;
    all)
      shift
      [ "${1:-}" = "--plan" ] && mode="plan"
      for k in $(jq -r '.integrations[].key' "$(dev_kit_agent_manifest)"); do
        dev_kit_agent_apply_integration "$k" "$mode"
      done
      ;;
    *)
      local key="$sub"
      shift
      [ "${1:-}" = "--plan" ] && mode="plan"
      dev_kit_agent_apply_integration "$key" "$mode"
      ;;
  esac
}
