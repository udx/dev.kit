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
      # Generic template rendering with core environment placeholders
      local memories=""
      local agent_skills=""
      local available_tools=""
      
      if [[ "$src_tmpl" == *"GEMINI"* || "$src_tmpl" == *"system.md"* ]]; then
        # Gather Managed Skills
        local skill_file=""
        while IFS= read -r skill_file; do
          [ -z "$skill_file" ] && continue
          local name desc usage
          name="$(jq -r '.name' "$skill_file")"
          desc="$(jq -r '.description' "$skill_file")"
          agent_skills+="- **$name**: $desc\n"
        done < <(find "$REPO_DIR/src/ai/data/skills" -type f -name '*.json' | sort)
        
        # Gather Available Tools (CLI Commands)
        local cmd_file="$REPO_DIR/src/ai/data/commands.json"
        if [ -f "$cmd_file" ]; then
          available_tools="$(jq -r '.commands[] | "- **dev.kit \(.key)**: \(.description)"' "$cmd_file")"
        fi
        
        # Gather Memories (if applicable)
        if [[ "$src_tmpl" == *"GEMINI"* ]]; then
          if [ -f "$HOME/.gemini/GEMINI.md" ]; then
            memories="$(grep -A 100 "Gemini Added Memories" "$HOME/.gemini/GEMINI.md" | tail -n +2 || true)"
          fi
          [ -z "$memories" ] && memories="- (none)"
        fi
      fi
      
      # Render using perl for robust multi-line replacement
      # (Export variables so perl can see them)
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
    codex_agents)
      # Minimal Codex Agents rendering
      local data="$REPO_DIR/src/ai/data/agents.json"
      export DEV_KIT_RENDER_TITLE="$(jq -r '.title' "$data")"
      export DEV_KIT_RENDER_INTRO="$(jq -r '.intro[]' "$data" | awk 'NR==1{print;next}{print "";print}')"
      export DEV_KIT_RENDER_SECTIONS="$(jq -r '.sections[] | "## " + .title + "\n" + (.bullets|map("- " + .)|join("\n"))' "$data" | awk 'NR==1{print;next}{print "";print}')"
      
      perl -pe '
        s/\{\{TITLE\}\}/$ENV{DEV_KIT_RENDER_TITLE}/g;
        s/\{\{INTRO\}\}/$ENV{DEV_KIT_RENDER_INTRO}/g;
        s/\{\{SECTIONS\}\}/$ENV{DEV_KIT_RENDER_SECTIONS}/g;
      ' "$src_tmpl" > "$dst_path"
      ;;
    codex_config)
      # Minimal Codex Config rendering
      local data="$REPO_DIR/src/ai/data/config.json"
      local body
      body="$(jq -r '
        def q: @json;
        "approval_policy = " + (.approval_policy|q),
        "sandbox_mode = " + (.sandbox_mode|q),
        "web_search = " + (.web_search|q),
        "personality = " + (.personality|q),
        "",
        "project_root_markers = " + (.project_root_markers|@json),
        "",
        (.mcp_servers|to_entries[]? | "[mcp_servers." + .key + "]\n"
          + (if .value.command then "command = " + (.value.command|q) + "\n" else "" end)
          + (if .value.args then "args = " + (.value.args|@json) + "\n" else "" end)
          + (if .value.url then "url = " + (.value.url|q) + "\n" else "" end)
        )
      ' "$data")"
      export DEV_KIT_RENDER_CONFIG_BODY="$body"
      perl -pe 's/\{\{CONFIG_BODY\}\}/$ENV{DEV_KIT_RENDER_CONFIG_BODY}/g' "$src_tmpl" > "$dst_path"
      ;;
    codex_rules)
      # Minimal Codex Rules rendering
      local data="$REPO_DIR/src/ai/data/rules.json"
      local body
      body="$(jq -r '
        (.header[]),
        "",
        (.groups[] | "# " + .title),
        (.groups[] | .rules[] | "prefix_rule(pattern=" + (.pattern|@json) + ", decision=\"" + .decision + "\")")
      ' "$data")"
      export DEV_KIT_RENDER_RULES_BODY="$body"
      perl -pe 's/\{\{RULES_BODY\}\}/$ENV{DEV_KIT_RENDER_RULES_BODY}/g' "$src_tmpl" > "$dst_path"
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
  
  # Set skills destination
  local skills_dst_dir="$target_dir/skills"

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

  # Process Skills: Prefix with dev-kit- for native discovery
  mkdir -p "$rendered/skills_sync"
  local skill_file=""
  while IFS= read -r skill_file; do
    [ -z "$skill_file" ] && continue
    local skill_name
    skill_name="$(basename "${skill_file%.json}")"
    # Ensure skill_name has dev-kit- prefix
    [[ "$skill_name" != dev-kit-* ]] && skill_name="dev-kit-$skill_name"
    
    local pack_dir="$REPO_DIR/src/ai/data/skill-packs/${skill_name}"
    # Fallback to unprefixed pack dir if prefixed doesn't exist
    if [ ! -d "$pack_dir" ]; then
       local unprefixed="${skill_name#dev-kit-}"
       pack_dir="$REPO_DIR/src/ai/data/skill-packs/$unprefixed"
    fi

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
    echo "Managed Skills (native skills/ directory):"
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

  # Apply skills to root skills/ directory with prefixes
  mkdir -p "$skills_dst_dir"
  cp -R "$rendered/skills_sync/." "$skills_dst_dir/"
  echo "Applied: skills (namespace: native)"

  echo "Backup: $backup_dir"
  rm -rf "$rendered"
}

dev_kit_cmd_agent() {
  
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
