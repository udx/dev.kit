#!/usr/bin/env bash

# dev.kit Context Manager
# Orchestrates intent normalization, context hydration, and multi-repo resolution.

# Normalize user intent into a structured execution plan (workflow.md)
# Usage: dev_kit_context_normalize "please adjust infra config" [context_file]
dev_kit_context_normalize() {
  local intent="$1"
  local output_context="${2:-}"
  
  echo "Normalizing intent: $intent" >&2
  
  # 1. Discover relevant skills and sources
  local context_data
  context_data="$(dev_kit_context_resolve "$intent")"
  
  # 2. Map to deterministic steps (Drafting logic)
  # This typically calls the AI provider with a normalization prompt if enabled,
  # or uses local heuristic mapping for known patterns.
  
  if [ -n "$output_context" ]; then
    echo "$context_data" > "$output_context"
  fi
  
  echo "$context_data"
}

# Search for internal task mappings (YAML-based)
dev_kit_context_search_mappings() {
  local query="$1"
  local internal_file="$REPO_DIR/src/mappings/internal.yaml"
  local mesh_file="$REPO_DIR/src/mappings/mesh.yaml"
  
  # Search internal.yaml
  if [ -f "$internal_file" ]; then
    awk -v q="$query" '
      BEGIN { FS=":[[:space:]]*"; section=""; name=""; }
      /^skills:|^workflows:/ { section=$0; sub(/:/,"",section); next }
      /^[[:space:]]+- name:/ { name=$0; sub(/.*name:[[:space:]]*/,"",name); gsub(/"/,"",name); next }
      /^[[:space:]]+intent:/ {
        intent_line=$0;
        if (index(tolower(intent_line), tolower(q)) > 0) {
          printf "{\"name\": \"%s\", \"type\": \"mapping-%s\"},", name, section;
        }
      }
    ' "$internal_file"
  fi

  # Search mesh.yaml (External packages/mesh)
  if [ -f "$mesh_file" ]; then
    awk -v q="$query" '
      BEGIN { FS=":[[:space:]]*"; section=""; name=""; }
      /^mesh:|^packages:/ { section=$0; sub(/:/,"",section); next }
      /^[[:space:]]+- name:/ { name=$0; sub(/.*name:[[:space:]]*/,"",name); gsub(/"/,"",name); next }
      /^[[:space:]]+intent:/ {
        intent_line=$0;
        if (index(tolower(intent_line), tolower(q)) > 0) {
          # Check health for packages if npm module loaded
          health="unknown";
          if (section == "packages") {
            health="available"; # Default if mapping exists
          }
          printf "{\"name\": \"%s\", \"type\": \"mesh-%s\", \"health\": \"%s\"},", name, section, health;
        }
      }
    ' "$mesh_file"
  fi | sed 's/,$//'
}

# Resolve context and dependencies across the "Skill Mesh"
dev_kit_context_resolve() {
  local intent="$1"
  
  # Category 1: Explicit Task Mappings (Core Normalization)
  local mappings
  mappings="$(dev_kit_context_search_mappings "$intent")"
  
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
    "explicit": [$mappings],
    "internal_workflows": [$internal_workflows],
    "internal_skills": [$internal_skills],
    "external_references": [$external_refs]
  },
  "grounding_layer": "repo-centric",
  "resolution_version": "v1.1"
}
EOF
}

# Search for internal workflow definitions (docs/scenarios, tasks)
dev_kit_context_search_workflows() {
  local query="$1"
  local matches=()
  
  # Search in docs/scenarios and tasks/ for .md files matching intent
  local search_dirs=("$REPO_DIR/docs/scenarios" "$REPO_DIR/tasks")
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
  
  local data_dir="$REPO_DIR/src/ai/data/skill-packs"
  if [ -d "$data_dir" ]; then
    for skill in "$data_dir"/*; do
      [ -d "$skill" ] || continue
      local name
      name="$(basename "$skill")"
      
      # 1. Exact name match (Highest priority)
      if [[ "$name" == "$query" ]] || [[ "dev-kit-$name" == "$query" ]]; then
         matches+=("{\"name\": \"$name\", \"type\": \"skill\", \"priority\": \"high\"}")
         continue
      fi

      # 2. Keyword/Metadata match in SKILL.md
      if grep -qiE "$query|keywords:.*$query" "$skill/SKILL.md" 2>/dev/null; then
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
