#!/usr/bin/env bash

# dev.kit Context Manager
# Orchestrates intent normalization, context hydration, and multi-repo resolution.

# Normalize user intent into a structured execution plan (workflow.md)
# Usage: dev_kit_context_normalize "please adjust infra config" [context_file]
dev_kit_context_normalize() {
  local intent="$1"
  local output_context="${2:-}"
  
  # 1. Discover relevant skills and sources
  local context_data
  context_data="$(dev_kit_context_resolve "$intent")"
  
  # 2. Map to deterministic steps
  if [ -n "$output_context" ]; then
    echo "$context_data" > "$output_context"
  fi
  
  echo "$context_data"
}

# Search for capabilities via Dynamic Discovery Engine
dev_kit_context_search_discovery() {
  local query="$1"
  local matches=()

  # 1. Internal Commands (Scan lib/commands/*.sh)
  # Look for # @intent: ... headers
  for file in "$REPO_DIR"/lib/commands/*.sh; do
    [ -f "$file" ] || continue
    local name
    name="$(basename "${file%.sh}")"
    local intents
    intents="$(grep "^# @intent:" "$file" | cut -d: -f2- | tr ',' ' ')"
    
    # Check if name or intent matches query
    if [[ "$name" == *"$query"* ]] || echo "$intents" | grep -qi "$query"; then
       matches+=("{\"name\": \"$name\", \"type\": \"command\", \"priority\": \"high\"}")
    fi
  done

  # 2. Virtual Skills (Environment Probe)
  # Dynamically register skills based on available CLI tools
  if command -v gh >/dev/null 2>&1; then
    if [[ "github pr issue repo" =~ $query ]]; then
       matches+=("{\"name\": \"github\", \"type\": \"virtual-skill\", \"tool\": \"gh\", \"priority\": \"medium\"}")
    fi
  fi
  if command -v npm >/dev/null 2>&1; then
    if [[ "npm package node module" =~ $query ]]; then
       matches+=("{\"name\": \"npm\", \"type\": \"virtual-skill\", \"tool\": \"npm\", \"priority\": \"medium\"}")
    fi
  fi
  if command -v docker >/dev/null 2>&1; then
    if [[ "docker container image" =~ $query ]]; then
       matches+=("{\"name\": \"docker\", \"type\": \"virtual-skill\", \"tool\": \"docker\", \"priority\": \"medium\"}")
    fi
  fi

  (IFS=,; echo "${matches[*]}")
}

# Resolve context and dependencies across the "Skill Mesh"
dev_kit_context_resolve() {
  local intent="$1"
  
  # Category 1: Dynamic Command & Virtual Skill Discovery
  local discovery
  discovery="$(dev_kit_context_search_discovery "$intent")"
  
  # Category 2: Internal Workflows (Markdown-based engineering loops)
  local internal_workflows
  internal_workflows="$(dev_kit_context_search_workflows "$intent")"
  
  # Category 3: Internal Scripts & Skill Packs (Deterministic logic)
  local internal_skills
  internal_skills="$(dev_kit_context_search_local "$intent")"
  
  # Category 4: External References (References to outside repos/skills)
  local external_refs
  external_refs="$(dev_kit_context_search_remote "$intent")"
  
  # Combine and return a typed context manifest
  cat <<EOF
{
  "intent": "$intent",
  "mappings": {
    "discovery": [$discovery],
    "internal_workflows": [$internal_workflows],
    "internal_skills": [$internal_skills],
    "external_references": [$external_refs]
  },
  "grounding_layer": "dynamic-discovery",
  "resolution_version": "v2.0"
}
EOF
}

# Search for internal workflow definitions (docs/ai, docs/scenarios, tasks)
dev_kit_context_search_workflows() {
  local query="$1"
  local matches=()
  
  # Search in docs/ai, docs/scenarios and tasks/ for .md files matching intent
  local search_dirs=("$REPO_DIR/docs/ai" "$REPO_DIR/docs/scenarios" "$REPO_DIR/tasks")
  for dir in "${search_dirs[@]}"; do
    [ -d "$dir" ] || continue
    while IFS= read -r file; do
      [ -f "$file" ] || continue
      local name
      name="$(basename "${file%.md}")"
      # Match by exact name or keyword in content
      if [[ "$name" == "$query" ]] || grep -qi "$query" "$file" 2>/dev/null; then
        matches+=("{\"name\": \"$name\", \"path\": \"$file\", \"type\": \"workflow\"}")
      fi
    done < <(find "$dir" -name "*.md")
  done
  
  (IFS=,; echo "${matches[*]}")
}

# Search local skill-packs and deterministic scripts
dev_kit_context_search_local() {
  local query="$1"
  local matches=()
  
  local skill_dir="$REPO_DIR/docs/skills"
  if [ -d "$skill_dir" ]; then
    for skill in "$skill_dir"/*; do
      [ -d "$skill" ] || continue
      local name
      name="$(basename "$skill")"
      
      # 1. Exact name match (Highest priority)
      if [[ "$name" == "$query" ]] || [[ "dev-kit-$name" == "$query" ]]; then
         matches+=("{\"name\": \"$name\", \"type\": \"skill\", \"priority\": \"high\"}")
         continue
      fi

      # 2. Keyword/Metadata match in SKILL.md
      if [ -f "$skill/SKILL.md" ] && grep -qiE "$query|keywords:.*$query" "$skill/SKILL.md" 2>/dev/null; then
        matches+=("{\"name\": \"$name\", \"type\": \"skill\", \"priority\": \"medium\"}")
      fi
    done
  fi
  
  (IFS=,; echo "${matches[*]}")
}

# Search remote sources (GitHub, Context7 API)
dev_kit_context_search_remote() {
  local query="$1"
  
  # This will be implemented in lib/modules/context7.sh
  if command -v dev_kit_context7_search >/dev/null 2>&1; then
    dev_kit_context7_search "$query"
  else
    echo ""
  fi
}
