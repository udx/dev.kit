#!/usr/bin/env bash

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_agent_gemini_dir() {
  echo "$HOME/.gemini"
}

dev_kit_agent_backup_dir() {
  local agent="$1"
  local base=""
  case "$agent" in
    gemini) base="$(dev_kit_agent_gemini_dir)" ;;
    codex) base="$(dev_kit_codex_dst_dir)" ;;
    *) return 1 ;;
  esac
  echo "$base/.backup/dev.kit"
}

dev_kit_agent_new_backup_dir() {
  local agent="$1"
  local base=""
  local stamp=""
  local candidate=""
  local i=0
  base="$(dev_kit_agent_backup_dir "$agent")"
  stamp="$(date +%Y%m%d%H%M%S)"
  while :; do
    if [ "$i" -eq 0 ]; then
      candidate="$base/$stamp"
    else
      candidate="$base/${stamp}-${i}"
    fi
    if mkdir -p "$candidate" 2>/dev/null; then
      printf "%s" "$candidate"
      return 0
    fi
    i=$((i + 1))
  done
}

dev_kit_agent_apply_gemini() {
  local mode="$1"
  local dst=""
  local templates_dir=""
  local rendered=""
  local backup_dir=""
  local gemini_skills_dir=""

  dst="$(dev_kit_agent_gemini_dir)"
  gemini_skills_dir="$dst/skills/dev.kit"
  templates_dir="$REPO_DIR/src/ai/integrations/gemini/templates"
  
  if [ ! -d "$templates_dir" ]; then
    echo "Error: Gemini templates directory not found: $templates_dir" >&2
    exit 1
  fi

  rendered="$(mktemp -d)"
  
  # Render GEMINI.md
  local memories=""
  memories="$(cat "$HOME/.udx/dev.kit/source/GEMINI.md" 2>/dev/null | grep -A 100 "Gemini Added Memories" | tail -n +2 || true)"
  if [ -z "$memories" ]; then
     memories="- (none)"
  fi

  sed -e "s/{{DATE}}/$(date +%Y-%m-%d)/g" \
      -e "/{{MEMORIES}}/r /dev/stdin" \
      -e "/{{MEMORIES}}/d" \
      "$templates_dir/GEMINI.md.tmpl" > "$rendered/GEMINI.md" <<< "$memories"

  cp "$templates_dir/system.md.tmpl" "$rendered/system.md"

  # Process Skills for Gemini
  mkdir -p "$rendered/skills"
  local skill_file=""
  while IFS= read -r skill_file; do
    [ -z "$skill_file" ] && continue
    local skill_name
    skill_name="$(basename "${skill_file%.json}")"
    
    # Render or copy SKILL.md
    local pack_dir="$REPO_DIR/src/ai/data/skill-packs/$skill_name"
    if [ -d "$pack_dir" ] && [ -f "$pack_dir/SKILL.md" ]; then
      mkdir -p "$rendered/skills/$skill_name"
      cp -R "$pack_dir/." "$rendered/skills/$skill_name/"
    else
      # Fallback: render basic SKILL.md from JSON (simplified)
      mkdir -p "$rendered/skills/$skill_name"
      echo "# Skill: $skill_name" > "$rendered/skills/$skill_name/SKILL.md"
      jq -r '.description' "$skill_file" >> "$rendered/skills/$skill_name/SKILL.md"
    fi
  done < <(find "$REPO_DIR/src/ai/data/skills" -type f -name '*.json' | sort)

  if [ "$mode" = "plan" ]; then
    echo "--- PLAN: Gemini Integration ---"
    echo "Target Directory: $dst"
    echo "Skills Directory: $gemini_skills_dir"
    echo ""
    echo "Core Artifacts:"
    echo "- GEMINI.md"
    echo "- system.md"
    echo ""
    echo "Managed Skills:"
    ls "$rendered/skills" | sed 's/^/- /'
    rm -rf "$rendered"
    return 0
  fi

  # Apply
  mkdir -p "$dst"
  backup_dir="$(dev_kit_agent_new_backup_dir "gemini")"
  
  # Backup and apply core files
  for file in "GEMINI.md" "system.md"; do
    if [ -f "$dst/$file" ]; then
      cp "$dst/$file" "$backup_dir/$file"
    fi
    cp "$rendered/$file" "$dst/$file"
    echo "Applied: $file"
  done

  # Backup and apply skills
  if [ -d "$gemini_skills_dir" ]; then
    mkdir -p "$backup_dir/skills"
    cp -R "$gemini_skills_dir" "$backup_dir/skills/"
    rm -rf "$gemini_skills_dir"
  fi
  mkdir -p "$(dirname "$gemini_skills_dir")"
  cp -R "$rendered/skills" "$gemini_skills_dir"
  echo "Applied: skills (dev.kit namespace)"

  echo "Backup: $backup_dir"
  rm -rf "$rendered"
}

dev_kit_cmd_agent() {
  shift || true
  local sub="${1:-status}"
  local mode="apply"
  
  case "$sub" in
    status)
      echo "Agents:"
      if [ -d "$(dev_kit_agent_gemini_dir)" ]; then
        echo "- gemini: installed at $(dev_kit_agent_gemini_dir)"
      else
        echo "- gemini: not found"
      fi
      if [ -d "$(dev_kit_codex_dst_dir)" ]; then
        echo "- codex: installed at $(dev_kit_codex_dst_dir)"
      else
        echo "- codex: not found"
      fi
      ;;
    gemini)
      shift
      while [ $# -gt 0 ]; do
        case "$1" in
          --plan) mode="plan" ;;
          *) echo "Unknown option: $1" >&2; exit 1 ;;
        esac
        shift
      done
      dev_kit_agent_apply_gemini "$mode"
      ;;
    codex)
      # Delegate to codex command for now
      dev_kit_cmd_codex "codex" "all" "${@:2}"
      ;;
    all)
       shift
       while [ $# -gt 0 ]; do
         case "$1" in
           --plan) mode="plan" ;;
           *) echo "Unknown option: $1" >&2; exit 1 ;;
         esac
         shift
       done
       dev_kit_agent_apply_gemini "$mode"
       dev_kit_cmd_codex "codex" "all" "--$mode"
       ;;
    help|-h|--help)
      cat <<'AGENT_USAGE'
Usage: dev.kit agent <command>

Commands:
  status         Show status of all AI agents
  gemini [--plan] Apply Gemini configuration
  codex  [--plan] Apply Codex configuration
  all    [--plan] Apply all supported agent configurations

Options:
  --plan         Dry-run: show what would be applied without making changes.
AGENT_USAGE
      ;;
    *)
      echo "Unknown agent command: $sub" >&2
      exit 1
      ;;
  esac
}
