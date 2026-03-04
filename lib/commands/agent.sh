#!/usr/bin/env bash

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_agent_manifest() {
  echo "$REPO_DIR/src/ai/data/integration-manifest.json"
}

dev_kit_agent_expand_path() {
  local val="$1"
  val="${val//\{\{HOME\}\}/$HOME}"
  val="${val//\{\{DEV_KIT_HOME\}\}/$DEV_KIT_HOME}"
  val="${val//\{\{DEV_KIT_STATE\}\}/$DEV_KIT_STATE}"
  echo "$val"
}

dev_kit_agent_backup() {
  local agent_key="$1"
  local target_dir="$2"
  local backup_base="$target_dir/.backup/dev.kit"
  local stamp
  stamp="$(date +%Y%m%d%H%M%S)"
  local backup_dir="$backup_base/$stamp"
  
  mkdir -p "$backup_dir"
  # We only backup managed items if they exist
  return 0 # (Simplified for now, will implement per artifact)
}

dev_kit_agent_render_artifact() {
  local type="$1"
  local src_tmpl="$2"
  local dst_path="$3"
  local base_rendered="$4"
  
  case "$type" in
    template)
      # Generic template rendering with basic placeholders
      local memories=""
      if [[ "$src_tmpl" == *"GEMINI"* ]]; then
        memories="$(cat "$HOME/.udx/dev.kit/source/GEMINI.md" 2>/dev/null | grep -A 100 "Gemini Added Memories" | tail -n +2 || true)"
        [ -z "$memories" ] && memories="- (none)"
      fi
      
      sed -e "s/{{DATE}}/$(date +%Y-%m-%d)/g" \
          -e "/{{MEMORIES}}/r /dev/stdin" \
          -e "/{{MEMORIES}}/d" \
          "$src_tmpl" > "$dst_path" <<< "$memories"
      ;;
    codex_agents)
      dev_kit_codex_render_agents "$base_rendered"
      ;;
    codex_config)
      dev_kit_codex_render_config "$base_rendered"
      ;;
    codex_rules)
      dev_kit_codex_render_rules "$base_rendered"
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
  
  if [ ! -f "$manifest" ]; then
    echo "Error: Manifest not found at $manifest" >&2
    exit 1
  fi

  local integration_json
  integration_json="$(jq -r ".integrations[] | select(.key == \"$key\")" "$manifest")"
  
  if [ -z "$integration_json" ]; then
    echo "Error: Integration '$key' not found in manifest." >&2
    exit 1
  fi

  local target_dir
  target_dir="$(dev_kit_agent_expand_path "$(echo "$integration_json" | jq -r '.target_dir')")"
  local templates_dir
  templates_dir="$REPO_DIR/$(echo "$integration_json" | jq -r '.templates_dir')"
  local skills_rel_dir
  skills_dir_rel="$(echo "$integration_json" | jq -r '.skills_dir')"
  local skills_dst_dir="$target_dir/$skills_dir_rel"

  local rendered
  rendered="$(mktemp -d)"
  
  # Render artifacts
  local i=0
  local artifacts_count
  artifacts_count="$(echo "$integration_json" | jq '.artifacts | length')"
  
  while [ "$i" -lt "$artifacts_count" ]; do
    local art_src
    art_src="$(echo "$integration_json" | jq -r ".artifacts[$i].src")"
    local art_dst
    art_dst="$(echo "$integration_json" | jq -r ".artifacts[$i].dst")"
    local art_type
    art_type="$(echo "$integration_json" | jq -r ".artifacts[$i].type")"
    
    mkdir -p "$(dirname "$rendered/$art_dst")"
    dev_kit_agent_render_artifact "$art_type" "$templates_dir/$art_src" "$rendered/$art_dst" "$rendered"
    i=$((i + 1))
  done

  # Process Skills
  mkdir -p "$rendered/skills_sync"
  local skill_file=""
  while IFS= read -r skill_file; do
    [ -z "$skill_file" ] && continue
    local skill_name
    skill_name="$(basename "${skill_file%.json}")"
    local pack_dir="$REPO_DIR/src/ai/data/skill-packs/$skill_name"
    
    if [ -d "$pack_dir" ] && [ -f "$pack_dir/SKILL.md" ]; then
      mkdir -p "$rendered/skills_sync/$skill_name"
      cp -R "$pack_dir/." "$rendered/skills_sync/$skill_name/"
    else
      mkdir -p "$rendered/skills_sync/$skill_name"
      echo "# Skill: $skill_name" > "$rendered/skills_sync/$skill_name/SKILL.md"
      jq -r '.description' "$skill_file" >> "$rendered/skills_sync/$skill_name/SKILL.md"
    fi
  done < <(find "$REPO_DIR/src/ai/data/skills" -type f -name '*.json' | sort)

  if [ "$mode" = "plan" ]; then
    echo "--- PLAN: Integration for '$key' ---"
    echo "Target Directory: $target_dir"
    echo "Skills Directory: $skills_dst_dir"
    echo ""
    echo "Artifacts to apply:"
    find "$rendered" -type f ! -path "*/skills_sync/*" | sed "s|^$rendered/||" | sed 's/^/- /'
    echo ""
    echo "Managed Skills (dev.kit namespace):"
    ls "$rendered/skills_sync" | sed 's/^/- /'
    rm -rf "$rendered"
    return 0
  fi

  # Apply
  local backup_dir
  backup_dir="$target_dir/.backup/dev.kit/$(date +%Y%m%d%H%M%S)"
  mkdir -p "$backup_dir"

  # Backup and apply artifacts
  find "$rendered" -type f ! -path "*/skills_sync/*" | while IFS= read -r file; do
    local rel_path="${file#$rendered/}"
    local dst_file="$target_dir/$rel_path"
    if [ -f "$dst_file" ]; then
      mkdir -p "$(dirname "$backup_dir/$rel_path")"
      cp "$dst_file" "$backup_dir/$rel_path"
    fi
    mkdir -p "$(dirname "$dst_file")"
    cp "$file" "$dst_file"
    echo "Applied: $rel_path"
  done

  # Backup and apply skills
  if [ -d "$skills_dst_dir" ]; then
    mkdir -p "$backup_dir/$skills_dir_rel"
    cp -R "$skills_dst_dir/." "$backup_dir/$skills_dir_rel/"
    rm -rf "$skills_dst_dir"
  fi
  mkdir -p "$skills_dst_dir"
  cp -R "$rendered/skills_sync/." "$skills_dst_dir/"
  echo "Applied: skills (namespace: $skills_dir_rel)"

  echo "Backup: $backup_dir"
  rm -rf "$rendered"
}

dev_kit_cmd_agent() {
  shift || true
  local sub="${1:-status}"
  local mode="apply"
  
  case "$sub" in
    status)
      echo "Integrations found in manifest:"
      jq -r '.integrations[].key' "$(dev_kit_agent_manifest)" | sed 's/^/- /'
      ;;
    skills)
      local key="${2:-}"
      if [ -z "$key" ]; then
        echo "Usage: dev.kit agent skills <integration_key>" >&2
        exit 1
      fi
      local manifest
      manifest="$(dev_kit_agent_manifest)"
      local integration_json
      integration_json="$(jq -r ".integrations[] | select(.key == \"$key\")" "$manifest")"
      if [ -z "$integration_json" ]; then
        echo "Error: Integration '$key' not found." >&2
        exit 1
      fi
      local target_dir
      target_dir="$(dev_kit_agent_expand_path "$(echo "$integration_json" | jq -r '.target_dir')")"
      local skills_dir_rel
      skills_dir_rel="$(echo "$integration_json" | jq -r '.skills_dir')"
      local skills_dst_dir="$target_dir/$skills_dir_rel"
      
      echo "Managed Skills for '$key' ($skills_dst_dir):"
      if [ -d "$skills_dst_dir" ]; then
        ls "$skills_dst_dir" | sed 's/^/- /'
      else
        echo "(none installed)"
      fi
      ;;
    help|-h|--help)
      cat <<'AGENT_USAGE'
Usage: dev.kit agent <command>

Commands:
  status         Show status of all AI agent integrations
  skills <key>   List managed skills for a specific agent
  <key> [--plan] Apply configuration for specific agent (e.g., gemini, codex)
  all   [--plan] Apply all supported agent configurations

Options:
  --plan         Dry-run: show what would be applied without making changes.
AGENT_USAGE
      ;;
    all)
      shift
      [ "${1:-}" = "--plan" ] && mode="plan"
      local keys
      keys="$(jq -r '.integrations[].key' "$(dev_kit_agent_manifest)")"
      for k in $keys; do
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
